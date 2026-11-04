#import "ZZPicker.h"
static UIView *FindTestView(UIView *root,NSString *identifier){if([root.accessibilityIdentifier isEqual:identifier])return root;for(UIView *child in root.subviews){UIView *found=FindTestView(child,identifier);if(found)return found;}return nil;}
@interface ZZPicker (UITestDriving)
- (void)drive:(NSDictionary *)action;
- (void)setEnabled:(BOOL)enabled;
- (NSDictionary *)context;
- (NSDictionary *)environment;
- (NSString *)diagnosticsWithDetails:(BOOL)includeDetails;
- (NSString *)startWithConfig:(NSDictionary *)config allowUnverified:(BOOL)allow;
- (void)checkTaskBudget;
- (void)pump;
- (void)handleFavoriteConfirmation:(NSDictionary *)message webView:(WKWebView *)web;
- (NSString *)saveConfigurationDraft:(NSDictionary *)draft;
@end
@interface ZZBatteryTestWebView : WKWebView
@property(nonatomic,strong) NSURL *testURL;
@property(nonatomic) NSUInteger confirmations;
@end
@implementation ZZBatteryTestWebView
- (NSURL *)URL {return self.testURL;}
- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^)(id,NSError *))completion {
    if([script containsString:@"confirmBatteryFavorite("])self.confirmations++;
    if(completion)completion(@YES,nil);
}
@end
@interface ZZLabelViewButton : UIView @end
@implementation ZZLabelViewButton @end
// UIKit delivers these touch targets; only delivery is substituted in this harness.
@interface ZZTestTouch : UITouch
@property(nonatomic,weak) UIView *targetView;
@end
@implementation ZZTestTouch
- (UIView *)view {return self.targetView;}
@end
@interface ZZTestEntryPan : UIPanGestureRecognizer
@property(nonatomic) UIGestureRecognizerState eventState;
@property(nonatomic) CGPoint movement;
@end
@implementation ZZTestEntryPan
- (UIGestureRecognizerState)state {return self.eventState;}
- (CGPoint)translationInView:(UIView *)view {(void)view;return self.movement;}
@end
// The external refresh library is unavailable in the test host; UIKit lists remain real.
@interface MJRefreshFooter : UIView
@property(nonatomic) NSInteger state;
@property(nonatomic,weak) UIScrollView *scrollView;
@property(nonatomic) NSUInteger beginCount;
- (void)beginRefreshing;
@end
@implementation MJRefreshFooter
- (void)beginRefreshing {self.beginCount++;self.state=3;}
@end
@interface TestScene : UIResponder <UIWindowSceneDelegate,UITextFieldDelegate>
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) NSDictionary *filterResponse;
@property(nonatomic) BOOL observedFinalCommit;
@property(nonatomic) NSUInteger searchEntryCalls;
@property(nonatomic) NSUInteger searchSubmitCalls;
@property(nonatomic) NSUInteger defaultSearchCalls;
@property(nonatomic) NSUInteger innerOptionCalls;
@property(nonatomic) NSUInteger wrapperOptionCalls;
@property(nonatomic,strong) NSDictionary *lastMetadata;
@end
@implementation TestScene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    (void)session;(void)options;self.window=[[UIWindow alloc]initWithWindowScene:(UIWindowScene *)scene];self.window.rootViewController=UIViewController.new;[self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{[self runTests];});
}
- (void)finalConfirm:(UIButton *)button {
    [button removeFromSuperview];NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://app.zhuanzhuan.com/zz/transfer/search"]];request.HTTPBody=[@"keyword=iPhone%2015%20Pro%20Max&pagenum=1&filterModuleServerParamsInput=%7B%7D" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *metadata=[ZZPicker.shared requestContext:request];self.lastMetadata=metadata;self.observedFinalCommit=[metadata[@"filterCommit"]boolValue];[ZZPicker.shared observeRequest:metadata];[ZZPicker.shared observeJSON:self.filterResponse metadata:metadata webView:nil];
}
- (void)defaultSearchTapped:(id)sender {(void)sender;self.defaultSearchCalls++;}
- (void)searchEntryTapped:(id)sender {(void)sender;self.searchEntryCalls++;}
- (void)innerOptionTapped {(self.innerOptionCalls)++;}
- (void)wrapperOptionTapped:(id)sender {(void)sender;self.wrapperOptionCalls++;}
- (ZZLabelViewButton *)wrappedOption {
    ZZLabelViewButton *wrapper=[[ZZLabelViewButton alloc]initWithFrame:CGRectMake(20,360,180,60)];
    UICollectionViewCell *cell=[[UICollectionViewCell alloc]initWithFrame:wrapper.bounds];[wrapper addSubview:cell];
    UIControl *inner=[[UIControl alloc]initWithFrame:cell.bounds];[inner addTarget:self action:@selector(innerOptionTapped) forControlEvents:UIControlEventTouchUpInside];[cell.contentView addSubview:inner];
    UILabel *label=[[UILabel alloc]initWithFrame:inner.bounds];label.text=@"512G";[inner addSubview:label];return wrapper;
}
- (void)saveScreenshot:(NSString *)name {
    [self.window layoutIfNeeded];UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithBounds:self.window.bounds];
    UIImage *image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){(void)context;[self.window drawViewHierarchyInRect:self.window.bounds afterScreenUpdates:YES];}];
    NSString *folder=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;[UIImagePNGRepresentation(image)writeToFile:[folder stringByAppendingPathComponent:name]atomically:YES];
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {(void)field;self.searchSubmitCalls++;return YES;}
- (void)runTests {
    NSMutableArray *failures=[NSMutableArray new];NSUInteger checks=0;
#define CHECK(condition, message) do {checks++;if(!(condition))[failures addObject:message];}while(0)
    @try {
        UIView *different=[[UIView alloc]initWithFrame:CGRectMake(20,90,250,44)];UILabel *current=[[UILabel alloc]initWithFrame:different.bounds];current.text=@"iphone 16 pro max";[different addSubview:current];[different addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(searchEntryTapped:)]];[self.window.rootViewController.view addSubview:different];
        UIButton *defaultSearch=[UIButton buttonWithType:UIButtonTypeSystem];defaultSearch.frame=CGRectMake(300,90,100,44);[defaultSearch setTitle:@"搜索" forState:UIControlStateNormal];[defaultSearch addTarget:self action:@selector(defaultSearchTapped:) forControlEvents:UIControlEventTouchUpInside];[self.window.rootViewController.view addSubview:defaultSearch];
        ZZSubmitSearch(@"iPhone 15 Pro Max");CHECK(self.searchEntryCalls==1&&self.defaultSearchCalls==0,@"home submitted placeholder model instead of entering editor for configured model");[different removeFromSuperview];[defaultSearch removeFromSuperview];self.searchEntryCalls=0;
        UIView *entry=[[UIView alloc]initWithFrame:CGRectMake(20,90,300,50)];UILabel *hint=[[UILabel alloc]initWithFrame:entry.bounds];hint.text=@"iphone 15 pro max";[entry addSubview:hint];[entry addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(searchEntryTapped:)]];[self.window.rootViewController.view addSubview:entry];
        ZZSubmitSearch(@"iPhone 15 Pro Max");CHECK(self.searchEntryCalls==1,@"lowercase home placeholder did not activate its registered entry");[entry removeFromSuperview];
        UIButton *accessible=[UIButton buttonWithType:UIButtonTypeSystem];accessible.frame=CGRectMake(20,90,200,44);accessible.accessibilityLabel=@"搜索";[accessible addTarget:self action:@selector(searchEntryTapped:) forControlEvents:UIControlEventTouchUpInside];[self.window.rootViewController.view addSubview:accessible];NSUInteger before=self.searchEntryCalls;
        CHECK(ZZActivateText(@"搜索",NO,YES)&&self.searchEntryCalls==before+1,@"icon search button accessibility label was ignored");[accessible removeFromSuperview];
        UIButton *capacity=[UIButton buttonWithType:UIButtonTypeSystem];capacity.frame=CGRectMake(20,360,150,44);[capacity setTitle:@"容量" forState:UIControlStateNormal];[capacity addTarget:self action:@selector(searchEntryTapped:) forControlEvents:UIControlEventTouchUpInside];[self.window.rootViewController.view addSubview:capacity];before=self.searchEntryCalls;
        ZZFilterDriver *belowHeader=[[ZZFilterDriver alloc]initWithConfig:@{@"capacities":@[@"512"]} fields:@[@"capacities"]];[belowHeader step];CHECK(self.searchEntryCalls==before+1,@"filter entry below model summary card was rejected by search-header limit");CHECK([ZZSearchDiagnostics()[@"activationHistory"]count]>0,@"semantic activation history is missing from diagnosis");[capacity removeFromSuperview];
        ZZLabelViewButton *wrapped=[self wrappedOption];[wrapped addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(wrapperOptionTapped:)]];[self.window.rootViewController.view addSubview:wrapped];
        CHECK(ZZActivateText(@"512G",NO,NO)&&self.wrapperOptionCalls==1&&self.innerOptionCalls==0,@"wrapped capacity option invoked the embedded cell instead of the outer registered button");[wrapped removeFromSuperview];
        wrapped=[self wrappedOption];UIButton *backdrop=[UIButton buttonWithType:UIButtonTypeCustom];backdrop.frame=self.window.rootViewController.view.bounds;[backdrop addTarget:self action:@selector(defaultSearchTapped:) forControlEvents:UIControlEventTouchUpInside];[backdrop addSubview:wrapped];[self.window.rootViewController.view addSubview:backdrop];
        NSUInteger noOpBefore=self.innerOptionCalls,backdropBefore=self.defaultSearchCalls;
        CHECK(!ZZActivateText(@"512G",NO,NO)&&self.innerOptionCalls==noOpBefore&&self.defaultSearchCalls==backdropBefore,@"unsupported capacity wrapper fell through to an inert cell or dismissing backdrop");[backdrop removeFromSuperview];
        UITextField *searchField=[[UITextField alloc]initWithFrame:CGRectMake(20,90,300,44)];searchField.placeholder=@"iphone 15 pro max";searchField.returnKeyType=UIReturnKeySearch;searchField.delegate=self;[self.window.rootViewController.view addSubview:searchField];
        CHECK(ZZSubmitSearch(@"iPhone 15 Pro Max")&&self.searchSubmitCalls==1&&[searchField.text isEqual:@"iPhone 15 Pro Max"],@"nonfocused search field with model placeholder was not submitted");[searchField removeFromSuperview];
        UITableView *list=[[UITableView alloc]initWithFrame:CGRectMake(20,180,350,500) style:UITableViewStylePlain];list.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever;[self.window.rootViewController.view addSubview:list];list.contentSize=CGSizeMake(350,1000);list.contentOffset=CGPointMake(0,500);ZZResetPagination(2);
        CHECK(!ZZScrollSearchList(),@"unsupported list at bottom reported successful progress forever");
        MJRefreshFooter *footer=[[MJRefreshFooter alloc]initWithFrame:CGRectMake(0,1000,350,60)];footer.scrollView=list;footer.state=1;[list addSubview:footer];
        CHECK(ZZScrollSearchList()&&footer.beginCount==1,@"bottom paging did not invoke the owned footer loading entry");
        CHECK(ZZSearchIsLoading(),@"refreshing footer without a spinner was not recognized as loading");
        footer.state=1;CHECK(ZZScrollSearchList()&&footer.beginCount==1,@"same page repeatedly invoked the loading entry without a response");
        NSDictionary *paging=ZZSearchDiagnostics()[@"pagination"];CHECK([paging[@"status"]isEqual:@"waitingResponse"]&&[paging[@"footer"][@"class"]isEqual:@"MJRefreshFooter"]&&[paging[@"contentHeight"]doubleValue]==1000,@"pagination diagnostics lost the selected list and footer state");
        UITableView *replacement=[[UITableView alloc]initWithFrame:CGRectMake(20,120,388,600) style:UITableViewStylePlain];replacement.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever;[self.window.rootViewController.view addSubview:replacement];replacement.contentSize=CGSizeMake(388,1000);replacement.contentOffset=CGPointMake(0,400);MJRefreshFooter *replacementFooter=[[MJRefreshFooter alloc]initWithFrame:CGRectMake(0,1000,388,60)];replacementFooter.scrollView=replacement;replacementFooter.state=1;[replacement addSubview:replacementFooter];
        CHECK(ZZScrollSearchList()&&replacementFooter.beginCount==0,@"replacing the list bypassed the one-trigger-per-page guard");[replacement removeFromSuperview];
        footer.state=5;CHECK(!ZZScrollSearchList()&&[ZZSearchDiagnostics()[@"pagination"][@"status"]isEqual:@"noMore"]&&footer.beginCount==1,@"no-more footer was restarted instead of ending pagination");[footer removeFromSuperview];
        ZZResetPagination(2);footer=[[MJRefreshFooter alloc]initWithFrame:CGRectMake(0,1000,350,60)];footer.scrollView=list;footer.state=1;[list addSubview:footer];MJRefreshFooter *duplicate=[[MJRefreshFooter alloc]initWithFrame:footer.frame];duplicate.scrollView=list;duplicate.state=1;[list addSubview:duplicate];
        CHECK(!ZZScrollSearchList()&&footer.beginCount==0&&duplicate.beginCount==0,@"ambiguous refresh footers were activated");[duplicate removeFromSuperview];
        UITableView *disabled=[[UITableView alloc]initWithFrame:CGRectMake(0,100,410,700) style:UITableViewStylePlain];disabled.scrollEnabled=NO;disabled.contentSize=CGSizeMake(410,2000);[self.window.rootViewController.view addSubview:disabled];
        CHECK(ZZScrollSearchList()&&footer.beginCount==1,@"paging selected a larger disabled list");ZZResetPagination(3);footer.state=1;CHECK(ZZScrollSearchList()&&footer.beginCount==2,@"new page did not reset the one-trigger loading guard");[disabled removeFromSuperview];[footer removeFromSuperview];ZZResetPagination(4);
        UITableViewCell *nested=[[UITableViewCell alloc]initWithFrame:CGRectMake(0,500,350,120)];[list addSubview:nested];footer=[[MJRefreshFooter alloc]initWithFrame:CGRectMake(0,0,300,60)];footer.scrollView=list;footer.state=1;[nested.contentView addSubview:footer];
        CHECK(!ZZScrollSearchList()&&footer.beginCount==0,@"paging invoked a nested product-cell refresh control");[nested removeFromSuperview];[list removeFromSuperview];
        list=[[UITableView alloc]initWithFrame:CGRectMake(20,180,350,500) style:UITableViewStylePlain];list.contentInsetAdjustmentBehavior=UIScrollViewContentInsetAdjustmentNever;[self.window.rootViewController.view addSubview:list];list.contentSize=CGSizeMake(350,200);footer=[[MJRefreshFooter alloc]initWithFrame:CGRectMake(0,500,350,60)];footer.scrollView=list;footer.state=1;[list addSubview:footer];
        CHECK(ZZScrollSearchList()&&footer.beginCount==1,@"short first page with a load-more footer was rejected");[list removeFromSuperview];
        ZZPicker *picker=ZZPicker.shared;JSContext *js=[picker valueForKey:@"js"];NSDictionary *config=@{@"model":@"iPhone 15 Pro Max",@"autoFavorite":@YES};[picker setValue:config forKey:@"config"];
        JSValue *run=[js[@"ZZCore"][@"Run"]constructWithArguments:@[config]];[picker setValue:run forKey:@"run"];[run invokeMethod:@"start" withArguments:@[]];js[@"testRun"]=run;
        NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;NSDictionary *savedConfig=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"];
        NSDictionary *legacy=@{@"model":@"iPhone 15 Pro Max",@"minIOS":@"18",@"maxIOS":@"27",@"capacities":@[@"512"],@"conditions":@[@"99新"],@"autoFavorite":@NO};
        [defaults setObject:legacy forKey:@"com.codex.zzpicker.config.v2"];ZZPicker *migrated=[ZZPicker new];
        CHECK(([migrated.config[@"channels"]isEqual:@[@"国行"]]&&[migrated.config[@"maxIOS"]isEqual:@"27"]&&![migrated.config[@"autoFavorite"]boolValue]),@"adding default channel changed existing iOS criteria or favorite preference");
        NSMutableDictionary *unrestricted=[legacy mutableCopy];unrestricted[@"channels"]=@[];[defaults setObject:unrestricted forKey:@"com.codex.zzpicker.config.v2"];CHECK([[[ZZPicker new]config][@"channels"]isEqual:@[]],@"explicit unrestricted channel selection was overwritten on reload");
        if(savedConfig)[defaults setObject:savedConfig forKey:@"com.codex.zzpicker.config.v2"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];
        CHECK([migrated inspectionSummary:migrated.config[@"reportFilters"]].count==0,@"legacy settings enabled report restrictions");
        UITableViewController *inspection=(id)ZZInspectionSettings(@{@"screen":@{@"mode":@"selected",@"items":@[@"屏幕显示›坏点"]}},^(NSDictionary *filters){(void)filters;});
        [inspection loadViewIfNeeded];
        CHECK([inspection numberOfSectionsInTableView:inspection.tableView]==5,@"inspection UI did not provide five categories");
        CHECK([[inspection tableView:inspection.tableView titleForHeaderInSection:0] hasPrefix:@"外观"]&&
              [[inspection tableView:inspection.tableView titleForHeaderInSection:4] hasPrefix:@"维修浸液"],@"inspection UI did not follow report order");
        UITableViewCell *selectedDefect=[inspection tableView:inspection.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:2]];
        CHECK([selectedDefect.textLabel.text isEqual:@"坏点"]&&selectedDefect.accessoryType==UITableViewCellAccessoryCheckmark,@"inspection UI lost selected screen path");
        [picker setValue:migrated.config forKey:@"config"];UITableViewController *settings=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];[settings loadViewIfNeeded];
        UITableViewCell *channelCell=[settings.tableView.dataSource tableView:settings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        UIButton *mainland=(id)FindTestView(channelCell,@"channels|国行"),*us=(id)FindTestView(channelCell,@"channels|美版");
        CHECK(mainland&&us&&(mainland.accessibilityTraits&UIAccessibilityTraitSelected)&&!(us.accessibilityTraits&UIAccessibilityTraitSelected),@"settings did not display default mainland and unselected alternate channels");
        [us sendActionsForControlEvents:UIControlEventTouchUpInside];CHECK(([[settings valueForKey:@"draft"][@"channels"]isEqual:@[@"国行",@"美版"]]),@"channel choices were exclusive instead of multi-select");
        [mainland sendActionsForControlEvents:UIControlEventTouchUpInside];[us sendActionsForControlEvents:UIControlEventTouchUpInside];CHECK(([[settings valueForKey:@"draft"][@"channels"]isEqual:@[]]),@"clearing all channels did not preserve unrestricted selection");
        CHECK([[settings valueForKey:@"draft"][@"maxIOS"]isEqual:@"27"]&&![[settings valueForKey:@"draft"][@"autoFavorite"]boolValue],@"channel UI changed other criteria or favorite switch");
        [picker setValue:config forKey:@"config"];
        [js evaluateScript:@"testRun.state=testRun.phase='hit';testRun.current={id:'123',title:'商品'};testRun.currentProduct={id:'123',title:'商品',ios:'17.0'};testRun.hit={id:'123',title:'商品',status:'match'};"];
        [picker showTask];UIView *panel=nil;for(UIView *v in self.window.subviews)if([NSStringFromClass(v.class)isEqual:@"ZZTaskPanel"])panel=v;
        NSDictionary *panelConfig=@{@"model":@"iPhone 15 Pro Max",@"channels":@[@"国行"],@"capacities":@[@"512"],@"conditions":@[@"99新"],@"minIOS":@"18",@"maxIOS":@"27"};[picker setValue:panelConfig forKey:@"config"];
        [js evaluateScript:@"testRun.hit={id:'123',title:'商品',status:'match',ios:'26.0',channel:'国行',capacity:'512',condition:'99新'};"];
        [picker showTask];UILabel *criteriaLabel=(id)FindTestView(panel,@"taskCriteria"),*detailsLabel=(id)FindTestView(panel,@"matchedDetails");
        CHECK([criteriaLabel.text containsString:@"国行"]&&[detailsLabel.text containsString:@"iOS 26.0 · 国行 · 512G · 99新"],@"task and hit presentation omitted channel or used the wrong priority");[panel layoutIfNeeded];[self saveScreenshot:@"ui-task.png"];[picker setValue:config forKey:@"config"];
        CHECK(panel!=nil,@"task panel was not created");
        CHECK([panel hitTest:CGPointMake(2,self.window.safeAreaInsets.top+80) withEvent:nil]==nil,@"expanded panel blocks recovery touches outside the card");
        [picker pause:@"manual recovery"];CHECK([panel hitTest:CGPointMake(2,self.window.safeAreaInsets.top+80) withEvent:nil]==nil,@"paused panel blocks list recovery");
        [panel setValue:@YES forKey:@"collapsed"];[panel setNeedsLayout];[panel layoutIfNeeded];[picker log:@"same-state panel refresh"];CHECK([[panel valueForKey:@"collapsed"]boolValue],@"paused panel cannot remain collapsed after refresh");
        [panel layoutIfNeeded];panel.hidden=YES;UIView *mini=[panel valueForKey:@"mini"];CHECK([panel hitTest:mini.center withEvent:nil]==nil,@"hidden collapsed panel still intercepts touches");panel.hidden=NO;
        JSValue *gate=[picker valueForKey:@"mutations"];NSDictionary *token=@{@"run":[picker snapshot][@"token"][@"run"],@"step":@1};[gate invokeMethod:@"begin" withArguments:@[@"123",token]];
        __block NSUInteger updates=0;id observer=[[NSNotificationCenter defaultCenter]addObserverForName:@"ZZPickerUpdated" object:nil queue:nil usingBlock:^(NSNotification *note){(void)note;updates++;}];
        [picker observeJSON:@{@"respCode":@0} metadata:@{@"path":@"/zz/transfer/addLoveInfo",@"id":@"123",@"token":token} webView:nil];
        CHECK(![[gate invokeMethod:@"pending" withArguments:@[]]toBool],@"late favorite response did not release gate");
        CHECK(updates>0,@"gate release did not notify task panel");[[NSNotificationCenter defaultCenter]removeObserver:observer];
        JSValue *settlementRun=[js evaluateScript:@"(function(){var r=new ZZCore.Run({model:'iPhone 15 Pro Max',autoFavorite:true});r.start();r.current={id:'123',title:'商品'};r.currentProduct={id:'123',title:'商品',ios:'17.0'};r._issue('favorite',{id:'123'});return r;})()"];
        [picker setValue:settlementRun forKey:@"run"];NSDictionary *favoriteAction=[[settlementRun invokeMethod:@"next" withArguments:@[]]toDictionary];[picker setValue:favoriteAction forKey:@"action"];[gate invokeMethod:@"begin" withArguments:@[@"123",favoriteAction[@"token"]]];
        [settlementRun invokeMethod:@"failed" withArguments:@[@"timeout",favoriteAction[@"token"]]];NSDictionary *verifyAction=[[settlementRun invokeMethod:@"next" withArguments:@[]]toDictionary];[settlementRun invokeMethod:@"verified" withArguments:@[NSNull.null,verifyAction[@"token"]]];[picker pump];
        CHECK(![[gate invokeMethod:@"pending" withArguments:@[]]toBool],@"terminal unknown favorite left the process-wide wait stuck");
        [picker returnedFromDetails];CHECK([[picker snapshot][@"phase"]isEqual:@"verify"]&&![[picker context][@"allowFavorite"]boolValue],@"returning from manual favorite did not perform read-only verification");
        NSDictionary *manualToken=[picker snapshot][@"token"];[picker observeJSON:@{@"respCode":@0,@"respData":@{@"collected":@YES}} metadata:@{@"path":@"/zzopen/waresshow/baseInfo",@"id":@"123",@"token":manualToken} webView:nil];
        CHECK([[picker snapshot][@"counts"][@"favorited"]integerValue]==1&&[[picker snapshot][@"counts"][@"favoriteUnknown"]integerValue]==0&&![[gate invokeMethod:@"pending" withArguments:@[]]toBool],@"manual favorite readback did not reconcile counts and settle the gate");
        NSDictionary *plainFavorite=[NSJSONSerialization JSONObjectWithData:[[picker diagnostics]dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil],*detailedFavorite=[NSJSONSerialization JSONObjectWithData:[[picker diagnosticsWithDetails:YES]dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];BOOL privateIDs=NO;for(NSDictionary *entry in plainFavorite[@"favoriteTrace"])if(entry[@"id"])privateIDs=YES;CHECK([plainFavorite[@"favoriteTrace"]count]>0&&!privateIDs&&[detailedFavorite[@"favoriteTrace"]lastObject][@"id"]!=nil,@"favorite diagnostics failed to hide product IDs unless explicitly included");
        [picker setValue:run forKey:@"run"];
        [run invokeMethod:@"start" withArguments:@[]];[js evaluateScript:@"testRun.state=testRun.phase='verify';testRun.current={id:'123',title:'商品'};testRun.currentProduct={id:'123',title:'商品',ios:'17.0'};testRun.intent={type:'verify',id:'123',token:{run:testRun.run,step:testRun.step}};"];
        token=[picker snapshot][@"token"];[picker pause:@"等待结束确认"];
        [picker observeJSON:@{@"respCode":@0,@"respData":@{@"collected":@YES}} metadata:@{@"path":@"/zzopen/waresshow/baseInfo",@"id":@"123",@"token":token} webView:nil];
        CHECK([[picker snapshot][@"counts"][@"favorited"]unsignedIntegerValue]==1,@"paused native verification discarded collected=true");
        CHECK(([@[@"hit",@"paused"]containsObject:[picker snapshot][@"state"]]),@"paused settlement restarted queue");
        [picker stop];CHECK([[picker snapshot][@"counts"][@"favoriteUnknown"]unsignedIntegerValue]==0,@"end confirmation lost verified favorite");
        ZZHideTaskPanel();[run invokeMethod:@"start" withArguments:@[]];[js evaluateScript:@"testRun._issue('filters',{page:1,applyFields:['capacities','conditions']});"];
        NSDictionary *filterAction=[[run invokeMethod:@"next" withArguments:@[]]toDictionary];[picker setValue:filterAction forKey:@"action"];
        ZZFilterDriver *driver=[[ZZFilterDriver alloc]initWithConfig:picker.config fields:@[@"capacities",@"conditions"]];[driver setValue:@1 forKey:@"group"];[driver setValue:@2 forKey:@"stage"];[picker setValue:driver forKey:@"filterDriver"];
        self.filterResponse=@{@"respCode":@0,@"respData":@{@"infos":@[@{@"infoId":@"123",@"title":@"商品"}]}};
        NSDictionary *middle=@{@"token":filterAction[@"token"],@"keyword":@"iPhone 15 Pro Max",@"page":@1,@"path":@"/zz/transfer/search",@"selection":@{},@"filterCommit":@NO};
        [picker observeJSON:self.filterResponse metadata:middle webView:nil];CHECK([[picker snapshot][@"state"]isEqual:@"filters"],@"intermediate native response interrupted filter popup");
        [driver setValue:@3 forKey:@"stage"];UIButton *confirm=[UIButton buttonWithType:UIButtonTypeSystem];confirm.frame=CGRectMake(20,140,120,44);[confirm setTitle:@"确定" forState:UIControlStateNormal];[confirm addTarget:self action:@selector(finalConfirm:) forControlEvents:UIControlEventTouchUpInside];[self.window.rootViewController.view addSubview:confirm];
        [picker drive:filterAction];CHECK(self.observedFinalCommit&&CFGetTypeID((__bridge CFTypeRef)self.lastMetadata[@"filterCommit"])==CFBooleanGetTypeID(),@"final confirmation request lost boolean commit marker");CHECK(driver.complete&&confirm.superview==nil,@"filter transaction consumed response before closing popup");CHECK([[picker snapshot][@"state"]isEqual:@"open"],@"synchronous final response was not buffered and processed");
        NSDictionary *activation=[ZZSearchDiagnostics()[@"activationHistory"]lastObject],*match=[activation[@"matches"]firstObject];
        CHECK([match[@"before"][@"attached"]boolValue]&&![match[@"after"][@"attached"]boolValue]&&[match[@"before"][@"frame"]containsString:@"140"],@"activation diagnosis lost the control frame before confirmation detached it");
        NSDictionary *filteredConfig=@{@"model":@"iPhone 15 Pro Max",@"autoFavorite":@NO,@"capacities":@[@"512"],@"conditions":@[@"99新"]};[picker setValue:filteredConfig forKey:@"config"];
        run=[js[@"ZZCore"][@"Run"]constructWithArguments:@[filteredConfig]];[picker setValue:run forKey:@"run"];[run invokeMethod:@"start" withArguments:@[]];js[@"testRun"]=run;
        [js evaluateScript:@"testRun.options={capacities:[{label:'512G',value:'5170',cmd:'params_new6651=1080730'}],conditions:[{label:'99新',value:'28076',cmd:'params_new6664=1145139'}]};testRun._issue('filters',{page:1,applyFields:['capacities','conditions']});"];
        filterAction=[[run invokeMethod:@"next" withArguments:@[]]toDictionary];[picker setValue:filterAction forKey:@"action"];[picker setValue:[[ZZFilterDriver alloc]initWithConfig:filteredConfig fields:@[]] forKey:@"filterDriver"];
        [picker observeJSON:self.filterResponse metadata:@{@"path":@"/zz/transfer/search",@"keyword":@"iPhone 15 Pro Max",@"page":@1,@"token":filterAction[@"token"],@"filterCommit":@YES,@"selection":@{@"69":@[],@"285":@[@{@"value":@"28076",@"cmd":@"params_new6664=1145139"}]}} webView:nil];
        CHECK([[picker snapshot][@"state"]isEqual:@"paused"]&&[picker valueForKey:@"action"]==nil,@"final filter mismatch left a native action active after pausing the core");

        [run invokeMethod:@"resume" withArguments:@[]];filterAction=[[run invokeMethod:@"next" withArguments:@[]]toDictionary];[picker setValue:filterAction forKey:@"action"];
        NSMutableURLRequest *countRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://app.zhuanzhuan.com/zz/v2/zzsearchfilteritem/getStockCount"]];
        [countRequest setValue:@"private-test-marker" forHTTPHeaderField:@"Authorization"];
        NSString *filterJSON=@"{\"clickItems\":{\"69\":[{\"value\":\"5170\",\"cmd\":\"params_new6651=1080730\",\"token\":\"private-test-marker\"}]},\"cookie\":\"private-test-marker\"}";
        countRequest.HTTPBody=[[NSString stringWithFormat:@"filterParam=%@",[filterJSON stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *countMetadata=[picker requestContext:countRequest];[picker observeRequest:countMetadata];
        CHECK([countMetadata[@"selection"][@"69"][0][@"value"]isEqual:@"5170"],@"inventory filterParam lost the public capacity selection");
        NSDictionary *diagnosis=[NSJSONSerialization JSONObjectWithData:[[picker diagnostics]dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];NSDictionary *trace=[diagnosis[@"searchTrace"]lastObject];
        CHECK([trace[@"selection"][@"69"][0][@"value"]isEqual:@"5170" ]&&![[picker diagnostics]containsString:@"private-test-marker"],@"filter diagnosis lost public selection or retained unrelated private fields");
        [picker observeFailure:countMetadata];CHECK([[picker snapshot][@"state"]isEqual:@"filters"]&&[picker valueForKey:@"action"]!=nil,@"read-only inventory observation failure interrupted the filter transaction");

        NSDictionary *savedV1=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v1"];
        [defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];[defaults removeObjectForKey:@"com.codex.zzpicker.config.v1"];
        ZZPicker *fresh=[ZZPicker new];CHECK(![fresh.config[@"autoFavorite"]boolValue]&&[fresh.config[@"maxProducts"]integerValue]==100&&[fresh.config[@"maxMinutes"]integerValue]==15,@"fresh public defaults must be manual favorite with finite limits");
        CHECK([fresh inspectionSummary:fresh.config[@"reportFilters"]].count==4,@"new configuration lacks four default report restrictions");
        [defaults setObject:legacy forKey:@"com.codex.zzpicker.config.v1"];CHECK(![[[ZZPicker new]config][@"autoFavorite"]boolValue],@"v1 migration enabled favorite without consent");
        NSMutableDictionary *optedIn=[legacy mutableCopy];optedIn[@"autoFavorite"]=@YES;[defaults setObject:optedIn forKey:@"com.codex.zzpicker.config.v2"];CHECK([[[ZZPicker new]config][@"autoFavorite"]boolValue],@"public update erased explicit favorite preference");
        if(savedConfig)[defaults setObject:savedConfig forKey:@"com.codex.zzpicker.config.v2"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];
        if(savedV1)[defaults setObject:savedV1 forKey:@"com.codex.zzpicker.config.v1"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v1"];
        CHECK([picker respondsToSelector:@selector(setEnabled:)],@"global disable is missing");
        if([picker respondsToSelector:@selector(setEnabled:)]){
            NSDictionary *beforeConfig=picker.config;[picker setEnabled:NO];CHECK([[picker snapshot][@"state"]isEqual:@"stopped"]&&[picker context].count==0&&[picker valueForKey:@"action"]==nil,@"disable left automation active");
            CHECK([picker startWithConfig:beforeConfig].length>0&&[picker.config isEqual:beforeConfig],@"disabled task restarted or lost settings");[picker setEnabled:YES];
        }
        CHECK([picker respondsToSelector:@selector(environment)],@"runtime self-check is missing");
        if([picker respondsToSelector:@selector(environment)]){
            NSDictionary *environment=[picker environment];CHECK([environment[@"deviceModel"]length]>0&&[environment[@"expectedAppVersion"]isEqual:@"12.8.5"]&&![environment[@"verifiedAppVersion"]boolValue],@"self-check mistook test app for verified Zhuanzhuan");
            NSDictionary *beforeSnapshot=[picker snapshot];CHECK([picker startWithConfig:picker.config allowUnverified:NO].length>0&&[[picker snapshot]isEqual:beforeSnapshot],@"unverified app started without explicit confirmation");
        }
        if([picker respondsToSelector:@selector(checkTaskBudget)]){
            __block double now=1000;JSValue *nativeClock=js[@"ZZNow"];js[@"ZZNow"]=^double{return now;};
            JSValue *limited=[js[@"ZZCore"][@"Run"]constructWithArguments:@[@{@"model":@"iPhone 15 Pro Max",@"maxMinutes":@1}]];[picker setValue:limited forKey:@"run"];[limited invokeMethod:@"start" withArguments:@[]];[picker setValue:[[limited invokeMethod:@"next" withArguments:@[]]toDictionary]forKey:@"action"];
            now+=60001;[picker checkTaskBudget];CHECK([[picker snapshot][@"state"]isEqual:@"paused"]&&[[picker snapshot][@"budgetExceeded"]boolValue]&&[picker valueForKey:@"action"]==nil,@"native budget poll did not stop outstanding search action");
            [picker setValue:run forKey:@"run"];js[@"ZZNow"]=nativeClock;
        }
        [js evaluateScript:@"testRun.current={id:'123',title:'private-product-title'};testRun.hit={id:'123',title:'private-product-title',item:{jumpUrl:'private-query-token'}};testRun.results=[{id:'123',title:'private-product-title'}];"];
        CHECK(![[picker diagnostics]containsString:@"private-product-title"],@"default diagnostic leaked product details");
        CHECK([picker respondsToSelector:@selector(diagnosticsWithDetails:)],@"opt-in diagnostic details are missing");
        if([picker respondsToSelector:@selector(diagnosticsWithDetails:)]){NSString *detail=[picker diagnosticsWithDetails:YES];CHECK([detail containsString:@"private-product-title"]&&![detail containsString:@"private-query-token"],@"explicit diagnostic details lost products or leaked product URL");}
        Class previewClass=NSClassFromString(@"ZZDiagnosticsController");CHECK(previewClass!=nil,@"diagnostic preview is missing");
        if(previewClass){UIViewController *preview=[(UIViewController *)[previewClass alloc]init];[preview loadViewIfNeeded];UISwitch *details=(id)FindTestView(preview.view,@"includeProductDetails");UITextView *text=(id)FindTestView(preview.view,@"diagnosticPreview");CHECK(details&&!details.on&&text&&!text.editable&&![text.text containsString:@"private-product-title"],@"diagnostic preview must default to public fields only");details.on=YES;[details sendActionsForControlEvents:UIControlEventValueChanged];CHECK([text.text containsString:@"private-product-title"],@"preview did not refresh after explicit detail opt-in");CHECK(FindTestView(preview.view,@"shareDiagnostic")!=nil,@"preview requires a separate share action");}
        ZZHideTaskPanel();[picker setValue:migrated.config forKey:@"config"];[defaults setBool:YES forKey:@"com.codex.zzpicker.helpSeen"];UITableViewController *renderSettings=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];
        UINavigationController *settingsNav=[[UINavigationController alloc]initWithRootViewController:renderSettings];UINavigationBarAppearance *hostAppearance=[UINavigationBarAppearance new];[hostAppearance configureWithTransparentBackground];settingsNav.navigationBar.standardAppearance=hostAppearance;settingsNav.navigationBar.scrollEdgeAppearance=hostAppearance;settingsNav.navigationBar.translucent=YES;
        self.window.rootViewController=settingsNav;[self.window layoutIfNeeded];[renderSettings.tableView layoutIfNeeded];[self saveScreenshot:@"ui-settings-top.png"];
        CGRect barRect=[settingsNav.navigationBar convertRect:settingsNav.navigationBar.bounds toView:self.window],tableViewport=[renderSettings.tableView convertRect:renderSettings.tableView.bounds toView:self.window];
        CHECK(CGRectGetMinY(tableViewport)>=CGRectGetMaxY(barRect)-0.5,@"settings content viewport extends behind the navigation buttons");
        [renderSettings.tableView setContentOffset:CGPointMake(0,28-renderSettings.tableView.adjustedContentInset.top) animated:NO];[renderSettings.tableView layoutIfNeeded];UITableViewHeaderFooterView *sourceHeader=[renderSettings.tableView headerViewForSection:0];
        CGRect sourceRect=[sourceHeader.textLabel convertRect:sourceHeader.textLabel.bounds toView:self.window];tableViewport=[renderSettings.tableView convertRect:renderSettings.tableView.bounds toView:self.window];
        CHECK(sourceHeader&&!CGRectIntersectsRect(CGRectIntersection(sourceRect,tableViewport),barRect),@"scrolled source label overlaps explanation and close controls");[self saveScreenshot:@"ui-settings-scrolled.png"];
        UIViewController *about=[(UIViewController *)[NSClassFromString(@"ZZAboutController")alloc]init];[settingsNav pushViewController:about animated:NO];[settingsNav popViewControllerAnimated:NO];[settingsNav.view layoutIfNeeded];
        barRect=[settingsNav.navigationBar convertRect:settingsNav.navigationBar.bounds toView:self.window];tableViewport=[renderSettings.tableView convertRect:renderSettings.tableView.bounds toView:self.window];CHECK(CGRectGetMinY(tableViewport)>=CGRectGetMaxY(barRect)-0.5,@"returning from environment help restored overlapping settings layout");
        CHECK([renderSettings.tableView.dataSource numberOfSectionsInTableView:renderSettings.tableView]==8,@"settings lacks separate limits section");
        NSArray *originalCapacities=[renderSettings valueForKey:@"capacities"];
        for(NSArray *capacities in @[@[@"256G",@"512G",@"1T"],@[@"64G",@"128G",@"256G",@"512G",@"1T"]]){
            [renderSettings setValue:capacities forKey:@"capacities"];
            for(NSNumber *width in @[@320,@430])for(NSInteger section=1;section<=3;section++){
                NSIndexPath *path=[NSIndexPath indexPathForRow:0 inSection:section];CGFloat height=[renderSettings.tableView.delegate tableView:renderSettings.tableView heightForRowAtIndexPath:path];UITableViewCell *cell=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:path];cell.frame=CGRectMake(0,0,width.doubleValue,height);[cell setNeedsLayout];[cell layoutIfNeeded];
                NSString *key=section==1?@"channels":section==2?@"capacities":@"conditions";NSArray *values=section==1?picker.purchaseChannels:section==2?capacities:@[@"99新",@"95新",@"9成新",@"8成新"];BOOL uniform=YES,spacing=YES;CGRect previous=CGRectZero;
                for(NSString *value in values){NSString *normalized=section==2?[picker normalizedCapacity:value]:value;UIView *button=FindTestView(cell,[NSString stringWithFormat:@"%@|%@",key,normalized]);CGRect rect=[button convertRect:button.bounds toView:cell.contentView];if(!button||fabs(CGRectGetHeight(rect)-28)>0.5||CGRectGetMinY(rect)<5.5||CGRectGetMaxY(rect)>height-5.5)uniform=NO;if(!CGRectIsEmpty(previous)&&CGRectGetMinY(rect)>CGRectGetMinY(previous)+1&&fabs(CGRectGetMinY(rect)-CGRectGetMaxY(previous)-6)>0.5)spacing=NO;previous=rect;}
                CHECK(uniform&&spacing,@"channel/capacity/condition choices must all be 28pt high with 6pt row gaps");
            }
        }
        [renderSettings setValue:originalCapacities forKey:@"capacities"];
        NSMutableDictionary *choiceDraft=[renderSettings valueForKey:@"draft"];NSDictionary *beforeChoices=[choiceDraft copy];choiceDraft[@"channels"]=@[@"国行",@"美版",@"港澳台版",@"日版"];choiceDraft[@"capacities"]=@[@"512",@"1024"];choiceDraft[@"conditions"]=@[@"8成新"];[renderSettings setValue:@[@"256G",@"512G",@"1T"] forKey:@"capacities"];[renderSettings.tableView reloadData];[renderSettings.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];[self saveScreenshot:@"ui-settings-choices.png"];[choiceDraft setDictionary:beforeChoices];[renderSettings setValue:originalCapacities forKey:@"capacities"];[renderSettings.tableView reloadData];
        if([renderSettings.tableView.dataSource numberOfSectionsInTableView:renderSettings.tableView]==8){UITableViewCell *limit=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:5]];CHECK([((UITextField *)limit.accessoryView).text isEqual:@"100"],@"settings did not show limit default");}
        UITapGestureRecognizer *dismissTap=nil;for(UIGestureRecognizer *gesture in renderSettings.tableView.gestureRecognizers)if([gesture.name isEqual:@"dismissSettingsKeyboard"])dismissTap=(id)gesture;
        CHECK(dismissTap&&!dismissTap.cancelsTouchesInView,@"blank-area dismissal is missing or consumes setting controls");
        if(dismissTap){ZZTestTouch *touch=[ZZTestTouch new];touch.targetView=renderSettings.tableView;BOOL blank=[dismissTap.delegate gestureRecognizer:dismissTap shouldReceiveTouch:touch];UITextField *input=[UITextField new];UILabel *inside=[UILabel new];[input addSubview:inside];touch.targetView=inside;BOOL editing=[dismissTap.delegate gestureRecognizer:dismissTap shouldReceiveTouch:touch];UIButton *choice=[UIButton buttonWithType:UIButtonTypeSystem];[choice addSubview:inside];touch.targetView=inside;BOOL choosing=[dismissTap.delegate gestureRecognizer:dismissTap shouldReceiveTouch:touch];CHECK(blank&&!editing&&!choosing,@"dismiss gesture must accept blank areas and leave field/choice touches alone");}
        CHECK(renderSettings.tableView.keyboardDismissMode==UIScrollViewKeyboardDismissModeInteractive,@"dragging settings does not dismiss the keyboard");
        for(NSIndexPath *path in @[[NSIndexPath indexPathForRow:0 inSection:0],[NSIndexPath indexPathForRow:1 inSection:0],[NSIndexPath indexPathForRow:2 inSection:0],[NSIndexPath indexPathForRow:0 inSection:5],[NSIndexPath indexPathForRow:1 inSection:5]]){
            [renderSettings.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];[renderSettings.tableView layoutIfNeeded];UITextField *field=(id)[renderSettings.tableView cellForRowAtIndexPath:path].accessoryView;
            CHECK(field&&[field becomeFirstResponder]&&field.isFirstResponder,@"settings field cannot begin editing");NSString *key=field.accessibilityIdentifier;NSString *value=[key isEqual:@"model"]?@"iPhone 16 Pro":@"19";field.text=value;[field sendActionsForControlEvents:UIControlEventEditingChanged];
            if(dismissTap&&[renderSettings respondsToSelector:@selector(dismissKeyboard)])[UIApplication.sharedApplication sendAction:@selector(dismissKeyboard) to:renderSettings from:dismissTap forEvent:nil];
            CHECK(!field.isFirstResponder&&[[renderSettings valueForKey:@"draft"][key]isEqual:value],@"blank-area dismissal lost focus or edited value");
            [field becomeFirstResponder];UIToolbar *toolbar=[field.inputAccessoryView isKindOfClass:UIToolbar.class]?(id)field.inputAccessoryView:nil;UIBarButtonItem *done=toolbar.items.lastObject;BOOL sent=done&&[UIApplication.sharedApplication sendAction:done.action to:done.target from:done forEvent:nil];CHECK(sent&&!field.isFirstResponder,@"keyboard Done does not finish editing this settings field");
            [field becomeFirstResponder];if([field.delegate respondsToSelector:@selector(textFieldShouldReturn:)])[field.delegate textFieldShouldReturn:field];CHECK(!field.isFirstResponder,@"keyboard Return does not finish editing this settings field");[field resignFirstResponder];
        }
        [renderSettings.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:6] atScrollPosition:UITableViewScrollPositionBottom animated:NO];[renderSettings.tableView layoutIfNeeded];[self saveScreenshot:@"ui-settings-bottom.png"];
        if(previewClass){self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:[(UIViewController *)[previewClass alloc]init]];[self.window layoutIfNeeded];[self saveScreenshot:@"ui-diagnostic-preview.png"];}
        NSDictionary *beforeSaveConfig=picker.config,*beforeSaveDefaults=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"];JSValue *beforeSaveRun=[picker valueForKey:@"run"];NSDictionary *beforeRunConfig=[picker snapshot][@"config"];id beforeSaveAction=[picker valueForKey:@"action"];
        [picker setValue:migrated.config forKey:@"config"];
        for(NSNumber *enabled in @[@YES,@NO]){
            UITableViewController *editor=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];[editor loadViewIfNeeded];
            UITableViewCell *cell=[editor.tableView.dataSource tableView:editor.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:4]];UISwitch *toggle=(id)cell.accessoryView;toggle.on=enabled.boolValue;[toggle sendActionsForControlEvents:UIControlEventValueChanged];
            for(NSArray *input in @[@[@0,@0,@"iPhone 16 Pro"],@[@0,@1,@"17.0"],@[@0,@2,@"17.3.1"],@[@5,@0,@"25"],@[@5,@1,@"3"]]){cell=[editor.tableView.dataSource tableView:editor.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[input[1]integerValue] inSection:[input[0]integerValue]]];UITextField *field=(id)cell.accessoryView;field.text=input[2];[field sendActionsForControlEvents:UIControlEventEditingChanged];}
            UIBarButtonItem *close=editor.navigationItem.rightBarButtonItem;[UIApplication.sharedApplication sendAction:close.action to:close.target from:close forEvent:nil];
            CHECK([picker.config[@"autoFavorite"]boolValue]==enabled.boolValue&&[[[ZZPicker new]config][@"autoFavorite"]boolValue]==enabled.boolValue,@"closing settings did not persist the auto-favorite choice");
            UITableViewController *reopened=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];[reopened loadViewIfNeeded];cell=[reopened.tableView.dataSource tableView:reopened.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:4]];
            CHECK(((UISwitch *)cell.accessoryView).on==enabled.boolValue,@"reopening settings lost the auto-favorite choice");
            NSDictionary *reloaded=[[ZZPicker new]config];CHECK([reloaded[@"model"]isEqual:@"iPhone 16 Pro"]&&[reloaded[@"minIOS"]isEqual:@"17.0"]&&[reloaded[@"maxIOS"]isEqual:@"17.3.1"]&&[reloaded[@"maxProducts"]integerValue]==25&&[reloaded[@"maxMinutes"]integerValue]==3,@"closing settings did not save the other edited fields");
        }
        CHECK([picker valueForKey:@"run"]==beforeSaveRun&&[[picker snapshot][@"config"]isEqual:beforeRunConfig]&&[picker valueForKey:@"action"]==beforeSaveAction,@"saving settings restarted or changed the existing task");
        JSValue *originalCriteriaRun=[js[@"ZZCore"][@"Run"]constructWithArguments:@[migrated.config]];[picker setValue:originalCriteriaRun forKey:@"run"];[originalCriteriaRun invokeMethod:@"start" withArguments:@[]];NSDictionary *originalSearch=[[originalCriteriaRun invokeMethod:@"next" withArguments:@[]]toDictionary];[picker setValue:originalSearch forKey:@"action"];
        NSDictionary *originalRequest=@{@"path":@"/zz/transfer/search",@"keyword":@"iPhone 15 Pro Max",@"page":@1,@"token":originalSearch[@"token"]};[picker observeRequest:originalRequest];CHECK([[picker snapshot][@"waitingResponse"]boolValue],@"saved model replaced the existing task's search keyword");
        [picker observeJSON:@{@"respCode":@403} metadata:originalRequest webView:nil];CHECK([[picker snapshot][@"state"]isEqual:@"paused"],@"existing task ignored its own search response after settings changed");
        [picker showTask];CHECK([((UILabel *)FindTestView(panel,@"taskCriteria")).text containsString:@"iOS 18–27"],@"task panel displayed newly saved criteria for an older task");ZZHideTaskPanel();[picker setValue:beforeSaveRun forKey:@"run"];[picker setValue:beforeSaveAction forKey:@"action"];
        if([picker respondsToSelector:@selector(saveConfigurationDraft:)]){
            NSDictionary *valid=picker.config,*stored=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"];NSMutableDictionary *invalid=[valid mutableCopy];invalid[@"minIOS"]=@"27";invalid[@"maxIOS"]=@"17";invalid[@"autoFavorite"]=@YES;
            CHECK([picker saveConfigurationDraft:invalid].length>0&&[picker.config isEqual:valid]&&[[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"]isEqual:stored],@"invalid draft overwrote the last valid settings");
            [UIView setAnimationsEnabled:NO];UITableViewController *invalidEditor=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:invalidEditor];[invalidEditor loadViewIfNeeded];[invalidEditor setValue:invalid forKey:@"draft"];UIBarButtonItem *close=invalidEditor.navigationItem.rightBarButtonItem;[UIApplication.sharedApplication sendAction:close.action to:close.target from:close forEvent:nil];
            UIAlertController *alert=[invalidEditor.presentedViewController isKindOfClass:UIAlertController.class]?(id)invalidEditor.presentedViewController:nil;BOOL canEdit=NO,canDiscard=NO;for(UIAlertAction *choice in alert.actions){if(choice.style==UIAlertActionStyleCancel)canEdit=YES;if(choice.style==UIAlertActionStyleDestructive)canDiscard=YES;}
            CHECK(alert&&canEdit&&canDiscard&&[picker.config isEqual:valid]&&[[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"]isEqual:stored],@"invalid close did not offer editing or discard while preserving saved settings");[self saveScreenshot:@"ui-settings-invalid-save.png"];[invalidEditor dismissViewControllerAnimated:NO completion:nil];[UIView setAnimationsEnabled:YES];self.window.rootViewController=UIViewController.new;
        }else CHECK(NO,@"settings cannot be saved independently of starting a task");
        [picker setValue:beforeSaveConfig forKey:@"config"];if(beforeSaveDefaults)[defaults setObject:beforeSaveDefaults forKey:@"com.codex.zzpicker.config.v2"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];
        [UIView setAnimationsEnabled:NO];ZZPresentSettings();UINavigationController *sheet=(id)self.window.rootViewController.presentedViewController;CHECK([sheet isKindOfClass:UINavigationController.class]&&sheet.modalInPresentation,@"swipe dismissal can bypass settings validation and saving");ZZDismissSettings(^{ });[UIView setAnimationsEnabled:YES];
        NSString *positionKey=@"com.codex.zzpicker.entryPosition";id savedPosition=[defaults objectForKey:positionKey];[defaults removeObjectForKey:positionKey];ZZPicker *entryPicker=[ZZPicker new];[entryPicker install];UIButton *entryButton=[entryPicker valueForKey:@"entryButton"];
        BOOL hasEntryPan=NO;for(UIGestureRecognizer *gesture in entryButton.gestureRecognizers)if([gesture isKindOfClass:UIPanGestureRecognizer.class])hasEntryPan=YES;CHECK(hasEntryPan,@"settings entry has no drag gesture");
        if([entryPicker respondsToSelector:@selector(entryDragged:)]){
            ZZTestEntryPan *pan=[ZZTestEntryPan new];pan.eventState=UIGestureRecognizerStateBegan;[UIApplication.sharedApplication sendAction:@selector(entryDragged:) to:entryPicker from:pan forEvent:nil];pan.eventState=UIGestureRecognizerStateChanged;pan.movement=CGPointMake(-150,220);[UIApplication.sharedApplication sendAction:@selector(entryDragged:) to:entryPicker from:pan forEvent:nil];CGPoint dragged=entryButton.center;
            [UIApplication.sharedApplication sendAction:@selector(attachEntry) to:entryPicker from:nil forEvent:nil];CHECK(CGPointEqualToPoint(entryButton.center,dragged),@"periodic attachment resets settings entry during drag");
            pan.eventState=UIGestureRecognizerStateEnded;[UIApplication.sharedApplication sendAction:@selector(entryDragged:) to:entryPicker from:pan forEvent:nil];[UIApplication.sharedApplication sendAction:@selector(attachEntry) to:entryPicker from:nil forEvent:nil];CHECK(CGPointEqualToPoint(entryButton.center,dragged)&&[defaults dictionaryForKey:positionKey]!=nil,@"settings entry position was not saved after dragging");
            pan.eventState=UIGestureRecognizerStateBegan;pan.movement=CGPointZero;[UIApplication.sharedApplication sendAction:@selector(entryDragged:) to:entryPicker from:pan forEvent:nil];pan.eventState=UIGestureRecognizerStateChanged;pan.movement=CGPointMake(-10000,10000);[UIApplication.sharedApplication sendAction:@selector(entryDragged:) to:entryPicker from:pan forEvent:nil];CGRect safe=UIEdgeInsetsInsetRect(self.window.bounds,self.window.safeAreaInsets);CHECK(CGRectContainsRect(safe,entryButton.frame),@"dragging can move settings entry outside usable screen bounds");pan.eventState=UIGestureRecognizerStateEnded;[UIApplication.sharedApplication sendAction:@selector(entryDragged:) to:entryPicker from:pan forEvent:nil];
            ZZTestTouch *touch=[ZZTestTouch new];touch.targetView=entryButton;id<UIGestureRecognizerDelegate> delegate=(id)entryPicker;CHECK(![delegate gestureRecognizer:[entryPicker valueForKey:@"manualPan"] shouldReceiveTouch:touch],@"dragging own settings entry is treated as a manual search-list operation");
        }else CHECK(NO,@"settings entry drag handler is missing");
        [[entryPicker valueForKey:@"entryTimer"]invalidate];[entryButton removeFromSuperview];for(NSString *key in @[@"manualTap",@"manualPan"]){UIGestureRecognizer *g=[entryPicker valueForKey:key];[g.view removeGestureRecognizer:g];}if(savedPosition)[defaults setObject:savedPosition forKey:positionKey];else[defaults removeObjectForKey:positionKey];

        JSValue *historyRun=[js evaluateScript:@"(function(){var r=new ZZCore.Run({model:'iPhone 15 Pro Max',autoFavorite:true,continueAfterHit:true});r.start();r.current={id:'456',title:'连续扫描测试商品',jumpUrl:'https://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail?infoId=456&trace=private-test'};r.currentProduct={id:'456',title:r.current.title,ios:'17.0',channel:'国行',capacity:'512',condition:'99新'};r.pendingMatch=r._record(r.currentProduct,'favoritePending',[]);r._issue('favorite',{id:'456'});return r;})()"];
        [picker setValue:historyRun forKey:@"run"];
        NSDictionary *historyAction=[[historyRun invokeMethod:@"next" withArguments:@[]]toDictionary];
        [gate invokeMethod:@"begin" withArguments:@[@"456",historyAction[@"token"]]];
        [historyRun invokeMethod:@"favoriteNeedsConfirmation" withArguments:@[historyAction[@"token"]]];
        [picker pump];
        CHECK(![[gate invokeMethod:@"pending" withArguments:@[]]toBool]&&[[[picker valueForKey:@"action"]objectForKey:@"type"]isEqual:@"back"],@"continuous favorite confirmation did not release the native gate and advance");
        ZZPicker *reopened=[ZZPicker new];
        NSDictionary *latest=reopened.hitHistory.firstObject;
        NSDictionary *savedHit=[latest[@"rows"]firstObject];
        CHECK([savedHit[@"status"]isEqual:@"favoriteManual"]&&[savedHit[@"id"]isEqual:@"456"],@"reopened picker did not load the saved confirmation record");
        CHECK([savedHit[@"detailPath"]isEqual:@"https://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail"]&&savedHit[@"jumpUrl"]==nil,@"history stored unneeded product URL parameters");
        UITableViewController *recordScreen=[(UITableViewController *)[NSClassFromString(@"ZZHitHistoryController")alloc]initWithStyle:UITableViewStyleInsetGrouped];
        [recordScreen loadViewIfNeeded];[recordScreen viewWillAppear:NO];
        UISegmentedControl *historyFilter=(UISegmentedControl *)recordScreen.navigationItem.titleView;
        CHECK(recordScreen.tableView.numberOfSections>0&&[historyFilter.accessibilityIdentifier isEqual:@"hitHistoryFilter"],@"history screen did not render saved results");
        historyFilter.selectedSegmentIndex=1;[historyFilter sendActionsForControlEvents:UIControlEventValueChanged];
        NSArray *filtered=[recordScreen valueForKey:@"tasks"];BOOL onlyCollected=YES;
        for(NSDictionary *task in filtered)for(NSDictionary *row in task[@"rows"])if(![@[@"already",@"favorited"]containsObject:row[@"status"]])onlyCollected=NO;
        CHECK(onlyCollected,@"collected filter showed an unconfirmed favorite");
        [historyRun invokeMethod:@"stop" withArguments:@[]];
        [picker setValue:nil forKey:@"action"];

        for(NSNumber *optIn in @[@NO,@YES]){
            NSString *ident=optIn.boolValue?@"790":@"789";
            JSValue *batteryRun=[js evaluateScript:[NSString stringWithFormat:@"(function(){var r=new ZZCore.Run({model:'iPhone 15 Pro Max',autoFavorite:true,autoConfirmBattery:%@,continueAfterHit:true});r.start();r.current={id:'%@',title:'换新电池商品'};r.currentProduct={id:r.current.id,title:r.current.title};r._issue('favorite',{id:r.current.id,allowBatteryConfirmation:r.config.autoConfirmBattery});return r;})()",optIn.boolValue?@"true":@"false",ident]];
            [picker setValue:batteryRun forKey:@"run"];
            NSDictionary *action=[[batteryRun invokeMethod:@"next" withArguments:@[]]toDictionary];
            [picker setValue:action forKey:@"action"];
            [gate invokeMethod:@"begin" withArguments:@[ident,action[@"token"]]];
            ZZBatteryTestWebView *web=[[ZZBatteryTestWebView alloc]initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
            web.testURL=[NSURL URLWithString:[@"https://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail?infoId=" stringByAppendingString:ident]];
            picker.detailWeb=web;
            NSDictionary *event=@{@"id":ident,@"token":action[@"token"]};
            [picker handleFavoriteConfirmation:event webView:web];
            [picker handleFavoriteConfirmation:event webView:web];
            CHECK(web.confirmations==(optIn.boolValue?1:0),@"native battery confirmation ignored opt-in or clicked twice");
            CHECK([[picker snapshot][@"counts"][@"favorited"]integerValue]==0,@"confirmation click counted as collected without readback");
            if(optIn.boolValue){
                [picker observeJSON:@{@"respCode":@0} metadata:@{@"path":@"/zz/transfer/addLoveInfo",@"id":ident,@"token":action[@"token"]} webView:web];
                NSDictionary *verifyToken=[picker snapshot][@"token"];
                CHECK([[picker snapshot][@"phase"]isEqual:@"verify"]&&[[picker snapshot][@"counts"][@"favorited"]integerValue]==0,@"successful favorite response skipped independent readback");
                [picker observeJSON:@{@"respCode":@0,@"respData":@{@"collected":@YES}} metadata:@{@"path":@"/zzopen/waresshow/baseInfo",@"id":ident,@"token":verifyToken} webView:web];
                CHECK([[picker snapshot][@"counts"][@"favorited"]integerValue]==1,@"verified battery favorite was not counted");
            }else CHECK([[[picker snapshot][@"results"]firstObject][@"status"]isEqual:@"favoriteManual"],@"opt-out did not keep manual confirmation");
            CHECK([[picker snapshot][@"phase"]isEqual:@"back"]&&![[gate invokeMethod:@"pending" withArguments:@[]]toBool],@"battery favorite left the scan blocked");
            [batteryRun invokeMethod:@"stop" withArguments:@[]];
            [picker setValue:nil forKey:@"action"];
            picker.detailWeb=nil;
        }

    }@catch(NSException *exception){[failures addObject:exception.reason?:@"native exception"];}
    NSString *folder=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;NSDictionary *result=@{@"checks":@(checks),@"failures":failures,@"snapshot":ZZPicker.shared.snapshot,@"logs":ZZPicker.shared.logs,@"metadata":self.lastMetadata?:@{}};[[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil]writeToFile:[folder stringByAppendingPathComponent:@"ui-result.json"]atomically:YES];
}
@end
@interface TestDelegate : UIResponder <UIApplicationDelegate> @end
@implementation TestDelegate
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {(void)application;(void)options;UISceneConfiguration *config=[[UISceneConfiguration alloc]initWithName:@"Tests" sessionRole:session.role];config.delegateClass=TestScene.class;return config;}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(TestDelegate.class));}}
