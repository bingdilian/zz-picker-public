#import "ZZPicker.h"
static WKWebView *ZZCollector;
static UIView *ZZCollectorHost;
static __weak UINavigationController *ZZViewer;
WKWebView *ZZLoadCollector(NSDictionary *item,BOOL reloadOnly) {
    ZZPicker *picker=ZZPicker.shared;UIWindow *window=ZZAppWindow();if(!window||!picker.borrowedConfiguration)return nil;
    if(!ZZCollector){
        ZZCollectorHost=[[UIView alloc]initWithFrame:CGRectMake(-window.bounds.size.width-100,0,window.bounds.size.width,window.bounds.size.height)];ZZCollectorHost.tag=ZZPickerOwnViewTag;ZZCollectorHost.userInteractionEnabled=NO;
        ZZCollector=[[WKWebView alloc]initWithFrame:ZZCollectorHost.bounds configuration:[picker.borrowedConfiguration copy]];ZZCollector.customUserAgent=picker.borrowedUserAgent;ZZCollector.tag=ZZPickerOwnViewTag;[ZZCollectorHost addSubview:ZZCollector];
    }
    if(ZZCollectorHost.superview!=window){[ZZCollectorHost removeFromSuperview];[window insertSubview:ZZCollectorHost atIndex:0];}
    picker.detailWeb=ZZCollector;[picker installWebView:ZZCollector];
    if(reloadOnly)[ZZCollector reload];else{[ZZCollector stopLoading];[ZZCollector loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:item[@"jumpUrl"]]]];}
    return ZZCollector;
}
void ZZStopCollector(void) {[ZZCollector stopLoading];[ZZCollector removeFromSuperview];[ZZCollectorHost removeFromSuperview];ZZCollector=nil;ZZCollectorHost=nil;ZZPicker.shared.detailWeb=nil;}
@interface ZZProductViewer : UIViewController
@property(nonatomic,strong) WKWebView *web;
@property(nonatomic) BOOL returnToTask;
@end
@implementation ZZProductViewer
- (void)viewDidLoad {[super viewDidLoad];self.view.backgroundColor=UIColor.systemBackgroundColor;self.web.frame=self.view.bounds;self.web.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;[self.view addSubview:self.web];self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"返回列表" style:UIBarButtonItemStylePlain target:self action:@selector(close)];}
- (void)close {[self dismissViewControllerAnimated:YES completion:^{ZZViewer=nil;if(self.returnToTask)[ZZPicker.shared returnedFromDetails];}];}
@end
BOOL ZZViewerVisible(void) {return ZZViewer!=nil;}
static void ZZOpenProduct(NSDictionary *item,BOOL returnToTask) {
    ZZPicker *picker=ZZPicker.shared;UIViewController *top=ZZTopController();if(!top||ZZViewer||!picker.borrowedConfiguration){[picker log:@"商品查看入口尚未建立"];return;}
    ZZHideTaskPanel();ZZProductViewer *detail=[ZZProductViewer new];detail.title=@"商品详情";detail.returnToTask=returnToTask;
    detail.web=[[WKWebView alloc]initWithFrame:CGRectZero configuration:[picker.borrowedConfiguration copy]];detail.web.customUserAgent=picker.borrowedUserAgent;
    UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:detail];navigation.modalPresentationStyle=UIModalPresentationFullScreen;ZZViewer=navigation;
    [top presentViewController:navigation animated:YES completion:^{
        if(ZZViewer==navigation)[detail.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:item[@"jumpUrl"]]]];
    }];
}

void ZZShowMatchedProduct(NSDictionary *item) {ZZOpenProduct(item,YES);}
void ZZShowRecordedProduct(NSDictionary *item) {ZZOpenProduct(item,NO);}
