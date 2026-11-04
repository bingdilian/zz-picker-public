#import "ZZPicker.h"

@interface ZZDiagnosticsController : UIViewController
@property(nonatomic,strong) UITextView *text;
@property(nonatomic,strong) UISwitch *details;
@property(nonatomic,copy) NSString *payload;
@end
@implementation ZZDiagnosticsController
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"诊断预览";self.view.tag=ZZPickerOwnViewTag;self.view.backgroundColor=UIColor.systemBackgroundColor;
    UIStackView *stack=[UIStackView new];stack.axis=UILayoutConstraintAxisVertical;stack.spacing=12;stack.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:stack];
    UILabel *note=[UILabel new];note.numberOfLines=0;note.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];note.text=@"默认仅导出环境、筛选条件、计数和运行诊断。开启商品明细后将包含商品标题、ID及核验结果。请查看下方内容，再选择分享。插件不会自动上传。";[stack addArrangedSubview:note];
    UIStackView *row=[UIStackView new];row.axis=UILayoutConstraintAxisHorizontal;row.alignment=UIStackViewAlignmentCenter;UILabel *label=[UILabel new];label.text=@"包含商品明细";[row addArrangedSubview:label];self.details=[UISwitch new];self.details.accessibilityIdentifier=@"includeProductDetails";self.details.accessibilityLabel=@"包含商品明细";[self.details addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];[row addArrangedSubview:self.details];[stack addArrangedSubview:row];
    self.text=[UITextView new];self.text.accessibilityIdentifier=@"diagnosticPreview";self.text.editable=NO;self.text.font=[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];self.text.backgroundColor=UIColor.secondarySystemBackgroundColor;self.text.layer.cornerRadius=10;[stack addArrangedSubview:self.text];
    UIButton *share=[UIButton buttonWithType:UIButtonTypeSystem];share.accessibilityIdentifier=@"shareDiagnostic";[share setTitle:@"分享当前预览内容" forState:UIControlStateNormal];share.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];[share.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;[share addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];[stack addArrangedSubview:share];
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;[NSLayoutConstraint activateConstraints:@[[stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:18],[stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-18],[stack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],[stack.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-12]]];[self refresh];
}
- (void)refresh {self.payload=[ZZPicker.shared diagnosticsWithDetails:self.details.on];self.text.text=self.payload;}
- (void)share:(UIButton *)button {
    UIActivityViewController *share=[[UIActivityViewController alloc]initWithActivityItems:@[self.payload?:@""] applicationActivities:nil];share.view.tag=ZZPickerOwnViewTag;share.popoverPresentationController.sourceView=button;share.popoverPresentationController.sourceRect=button.bounds;[self presentViewController:share animated:YES completion:nil];
}
@end

@interface ZZAboutController : UIViewController @end
@implementation ZZAboutController
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"说明 / 环境";self.view.tag=ZZPickerOwnViewTag;self.view.backgroundColor=UIColor.systemBackgroundColor;
    NSDictionary *e=ZZPicker.shared.environment;UITextView *text=[UITextView new];text.editable=NO;text.accessibilityIdentifier=@"environmentInfo";text.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];text.textContainerInset=UIEdgeInsetsMake(18,18,24,18);text.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;text.frame=self.view.bounds;[self.view addSubview:text];
    text.text=[NSString stringWithFormat:@"转转选机助手 %@\n社区免费试用版\n\n设备型号：%@\niOS：%@\n转转版本：%@\n适配基线：%@\n编译变体：%@\n插件：%@\n\n使用步骤\n1. 在首页或商品列表打开选机设置。\n2. 输入待售手机型号，选择 iOS 范围、渠道、容量和成色；同组选项满足任一，跨组必须全部符合。\n3. 首次测试保持自动收藏关闭，开始搜索并扫描。转转需保持前台，插件隐藏逐件查看报告的过程。\n4. 命中后可暂停查看，也可开启“命中后继续扫描”。命中商品可从设置中的“命中记录”查看，保留最近 10 次有命中的任务。未知或冲突数据不会作为命中。\n\n任务上限\n默认最多处理100件、有效运行15分钟。暂停和查看命中详情不计时。任一上限触发后暂停，请调整条件新建任务。已经发出的收藏先核验，停止或停用不能撤回。\n\n兼容说明\n旧版仅在 iPhone 13 Pro Max / iOS 15.4.1 / TrollFools 有部分流程记录。本版新增功能、连续翻页、收藏回读及 rootless / RootHide 加载仍需真机验证。转转更新可能需要重新适配。\n\n遇到暂停\n先查看任务提示，再打开诊断预览。基础诊断不含商品明细，详细内容由你主动选择和分享。\n\n安装与卸载\nTrollFools 请先移除旧注入再添加本版；deb 请只安装对应越狱环境的一个包。卸载需在原注入工具或包管理器移除，并完全重开转转。\n\n本插件没有更新服务器，不会自动发布或上传诊断。",e[@"plugin"],e[@"deviceModel"],e[@"iOS"],e[@"appVersion"],e[@"expectedAppVersion"],e[@"variant"],[e[@"enabled"]boolValue]?@"启用":@"停用"];
}
@end
void ZZPresentDiagnostics(void){UIViewController *top=ZZTopController();if(!top)return;ZZDiagnosticsController *preview=[ZZDiagnosticsController new];if(top.navigationController)[top.navigationController pushViewController:preview animated:YES];else[top presentViewController:[[UINavigationController alloc]initWithRootViewController:preview]animated:YES completion:nil];}
