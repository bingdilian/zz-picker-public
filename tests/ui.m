#import "ZZPicker.h"
#import "Embedded.h"
static UIView *FindTestView(UIView *root,NSString *identifier){if([root.accessibilityIdentifier isEqual:identifier])return root;for(UIView *child in root.subviews){UIView *found=FindTestView(child,identifier);if(found)return found;}return nil;}
static void SettleNavigation(UINavigationController *navigation){NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:2];do{[NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];}while((navigation.transitionCoordinator||navigation.visibleViewController!=navigation.topViewController||!navigation.topViewController.view.window)&&deadline.timeIntervalSinceNow>0);[navigation.view layoutIfNeeded];}
static void SettleModal(UIViewController *modal,BOOL visible){NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:2];do{[NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];}while((visible?(modal.isBeingPresented||!modal.view.window):(modal.isBeingDismissed||modal.view.window))&&deadline.timeIntervalSinceNow>0);}
@interface ZZPicker (UITestDriving)
- (void)drive:(NSDictionary *)action;
- (void)setEnabled:(BOOL)enabled;
- (NSDictionary *)context;
- (NSDictionary *)environment;
- (NSString *)diagnosticsWithDetails:(BOOL)includeDetails;
- (NSString *)startWithConfig:(NSDictionary *)config allowUnverified:(BOOL)allow;
- (void)checkTaskBudget;
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults;
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults coreSource:(NSString *)source;
- (NSString *)saveConfigurationDraft:(NSDictionary *)draft;
- (NSString *)resolveConfigurationRecovery:(NSString *)choice;
- (NSDictionary *)configLoadState;
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
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(runScheduledTests:) userInfo:nil repeats:NO];
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
- (void)runScheduledTests:(NSTimer *)timer {(void)timer;[self runTests];}
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
        NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;NSDictionary *savedConfig=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"];id savedV3=[defaults objectForKey:@"com.codex.zzpicker.config.v3"];
        CHECK([ZZPicker instancesRespondToSelector:@selector(initWithDefaults:)],@"v3 isolated defaults initializer is missing");
        if([ZZPicker instancesRespondToSelector:@selector(initWithDefaults:)]){
            NSString *suite=[@"local.zzpicker.recovery." stringByAppendingString:NSUUID.UUID.UUIDString];NSUserDefaults *isolated=[[NSUserDefaults alloc]initWithSuiteName:suite];
            [isolated setObject:@"broken" forKey:@"com.codex.zzpicker.config.v3"];NSDictionary *old=@{@"model":@"iPhone 14 Pro Max",@"minIOS":@"16.0",@"maxIOS":@"17",@"autoFavorite":@YES};[isolated setObject:old forKey:@"com.codex.zzpicker.config.v2"];
            ZZPicker *recovery=[[ZZPicker alloc]initWithDefaults:isolated];CHECK([recovery.configLoadState[@"status"]isEqual:@"recovery"]&&recovery.config.count==0,@"bad v3 silently fell back");
            CHECK([recovery resolveConfigurationRecovery:@"cancel"]!=nil&&[[isolated objectForKey:@"com.codex.zzpicker.config.v3"]isEqual:@"broken"],@"cancel recovery mutated damaged state");
            CHECK([recovery resolveConfigurationRecovery:@"restoreBackup"]==nil&&[recovery.config[@"autoFavorite"]boolValue]&&![recovery.config[@"requireTrollStore"]boolValue],@"restore lost favorite intent or enabled purpose");
            CHECK([[[[ZZPicker alloc]initWithDefaults:isolated]config]isEqual:recovery.config]&&[[isolated objectForKey:@"com.codex.zzpicker.config.v2"]isEqual:old],@"v3 reopen or old backup preservation failed");
            JSContext *localJS=[recovery valueForKey:@"js"];JSValue *active=[localJS[@"ZZCore"][@"Run"]constructWithArguments:@[recovery.config]];[recovery setValue:active forKey:@"run"];[active invokeMethod:@"start" withArguments:@[]];[active invokeMethod:@"pause" withArguments:@[@"editing"]];
            NSDictionary *next=[[localJS[@"ZZConfig"]invokeMethod:@"applyConfigEdit" withArguments:@[recovery.config,@{@"type":@"selectModel",@"modelId":@"iphone-15-pro-max"},[localJS[@"ZZCompatibility"]invokeMethod:@"defaultRuleContext" withArguments:@[]]]]toDictionary];
            CHECK([recovery saveConfigurationDraft:next]==nil&&[recovery.config[@"modelId"]isEqual:@"iphone-15-pro-max"]&&[[recovery valueForKey:@"activeTaskConfig"][@"modelId"]isEqual:@"iphone-14-pro-max"],@"saving next config changed the active native task");
            NSDictionary *before=recovery.snapshot;NSMutableDictionary *invalid=[next mutableCopy];invalid[@"capacities"]=@[@"128"];
            CHECK([recovery startWithConfig:invalid allowUnverified:YES]!=nil&&[recovery.snapshot isEqual:before],@"failed new run preflight replaced the old task");
            [isolated removePersistentDomainForName:suite];
        }
        CHECK([ZZPicker instancesRespondToSelector:@selector(initWithDefaults:coreSource:)],@"runtime initialization fault injection seam is missing");
        if([ZZPicker instancesRespondToSelector:@selector(initWithDefaults:coreSource:)]){
            NSString *suite=[@"local.zzpicker.runtime-fault." stringByAppendingString:NSUUID.UUID.UUIDString];NSUserDefaults *isolated=[[NSUserDefaults alloc]initWithSuiteName:suite];[isolated setObject:@"raw-secret-retained" forKey:@"com.codex.zzpicker.config.v3"];
            NSString *healthy=[[NSString alloc]initWithBytes:ZZCoreBytes length:ZZCoreLength encoding:NSUTF8StringEncoding];
            NSArray *sources=@[@"function broken( {",[healthy stringByAppendingString:@";ZZCompatibility=undefined;"],[healthy stringByAppendingString:@";ZZCompatibility.defaultRuleContext=function(){return null;};"],[healthy stringByAppendingString:@";ZZConfig=undefined;"]];
            for(NSString *source in sources){ZZPicker *fault=[[ZZPicker alloc]initWithDefaults:isolated coreSource:source];NSDictionary *diagnosis=[NSJSONSerialization JSONObjectWithData:[fault.diagnostics dataUsingEncoding:NSUTF8StringEncoding]options:0 error:nil];CHECK([fault.configLoadState[@"status"]isEqual:@"unavailable"]&&[fault saveConfigurationDraft:config]!=nil&&[fault startWithConfig:config allowUnverified:YES]!=nil,@"faulty runtime did not safely block start/save");CHECK([diagnosis[@"runtimeError"]length]>0&&![fault.diagnostics containsString:@"raw-secret-retained"]&&[[isolated objectForKey:@"com.codex.zzpicker.config.v3"]isEqual:@"raw-secret-retained"],@"runtime fault lost configuration or hid/leaked its diagnostic");CHECK(![[fault effectiveRangeForConfig:config][@"canStart"]boolValue]&&fault.presentation!=nil,@"fault fallback accessed unavailable JS helpers");}
            NSString *partial=[healthy stringByAppendingString:@";ZZCompatibility.defaultRuleContext=(function(original){return function(){var c=original();c.capabilitiesAvailable=false;c.tools=[];c.issues=['compatibility unavailable'];return c;};})(ZZCompatibility.defaultRuleContext);"];
            [isolated removeObjectForKey:@"com.codex.zzpicker.config.v3"];ZZPicker *ordinary=[[ZZPicker alloc]initWithDefaults:isolated coreSource:partial];CHECK([[ordinary effectiveRangeForConfig:config][@"canStart"]boolValue],@"partial capability data unnecessarily disabled available ordinary filtering");[isolated removePersistentDomainForName:suite];
        }
        NSDictionary *legacy=@{@"model":@"iPhone 15 Pro Max",@"minIOS":@"18",@"maxIOS":@"27",@"capacities":@[@"512"],@"conditions":@[@"99新"],@"autoFavorite":@NO};
        [defaults removeObjectForKey:@"com.codex.zzpicker.config.v3"];[defaults setObject:legacy forKey:@"com.codex.zzpicker.config.v2"];ZZPicker *migrated=[ZZPicker new];
        CHECK(([migrated.config[@"channels"]isEqual:@[@"国行"]]&&[migrated.config[@"manualMaxIOS"]isEqual:@"27"]&&![migrated.config[@"autoFavorite"]boolValue]),@"adding default channel changed existing iOS criteria or favorite preference");
        NSMutableDictionary *unrestricted=[legacy mutableCopy];unrestricted[@"channels"]=@[];[defaults removeObjectForKey:@"com.codex.zzpicker.config.v3"];[defaults setObject:unrestricted forKey:@"com.codex.zzpicker.config.v2"];CHECK([[[ZZPicker new]config][@"channels"]isEqual:@[]],@"explicit unrestricted channel selection was overwritten on reload");
        if(savedV3)[defaults setObject:savedV3 forKey:@"com.codex.zzpicker.config.v3"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v3"];if(savedConfig)[defaults setObject:savedConfig forKey:@"com.codex.zzpicker.config.v2"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];
        [picker setValue:migrated.config forKey:@"config"];UITableViewController *settings=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];[settings loadViewIfNeeded];
        UITableViewCell *channelCell=[settings.tableView.dataSource tableView:settings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
        UIButton *mainland=(id)FindTestView(channelCell,@"channels|国行"),*us=(id)FindTestView(channelCell,@"channels|美版");
        CHECK(mainland&&us&&(mainland.accessibilityTraits&UIAccessibilityTraitSelected)&&!(us.accessibilityTraits&UIAccessibilityTraitSelected),@"settings did not display default mainland and unselected alternate channels");
        [us sendActionsForControlEvents:UIControlEventTouchUpInside];CHECK(([[settings valueForKey:@"draft"][@"channels"]isEqual:@[@"国行",@"美版"]]),@"channel choices were exclusive instead of multi-select");
        [mainland sendActionsForControlEvents:UIControlEventTouchUpInside];[us sendActionsForControlEvents:UIControlEventTouchUpInside];CHECK(([[settings valueForKey:@"draft"][@"channels"]isEqual:@[]]),@"clearing all channels did not preserve unrestricted selection");
        CHECK([[settings valueForKey:@"draft"][@"manualMaxIOS"]isEqual:@"27"]&&![[settings valueForKey:@"draft"][@"autoFavorite"]boolValue],@"channel UI changed other criteria or favorite switch");
        [picker setValue:config forKey:@"config"];
        [js evaluateScript:@"testRun.state=testRun.phase='hit';testRun.current={id:'123',title:'商品'};testRun.currentProduct={id:'123',title:'商品',ios:'17.0'};testRun.currentEvaluation={status:'match',reasons:[],checks:[],evidence:{},ruleVersion:testRun.ruleContext.ruleVersion};testRun.hit={id:'123',title:'商品',status:'match'};"];
        [picker showTask];UIView *panel=nil;for(UIView *v in self.window.subviews)if([NSStringFromClass(v.class)isEqual:@"ZZTaskPanel"])panel=v;
        NSDictionary *panelConfig=@{@"model":@"iPhone 15 Pro Max",@"channels":@[@"国行"],@"capacities":@[@"512"],@"conditions":@[@"99新"],@"minIOS":@"18",@"maxIOS":@"27"};[picker setValue:panelConfig forKey:@"config"];
        [js evaluateScript:@"testRun.hit={id:'123',title:'商品',status:'match',ios:'26.0',channel:'国行',capacity:'512',condition:'99新'};"];
        [picker showTask];UILabel *criteriaLabel=(id)FindTestView(panel,@"taskCriteria"),*detailsLabel=(id)FindTestView(panel,@"matchedDetails");
        CHECK([criteriaLabel.text containsString:@"国行"]&&[detailsLabel.text containsString:@"iOS 26.0 · 国行 · 512G · 99新"],@"task and hit presentation omitted channel or used the wrong priority");[panel layoutIfNeeded];[self saveScreenshot:@"ui-task.png"];[picker setValue:config forKey:@"config"];
        CHECK(panel!=nil,@"task panel was not created");
        CHECK([criteriaLabel.text containsString:@"compat-2026-10-21.1"]&&[criteriaLabel.text containsString:@"不限"],@"panel omitted pinned rule version or used next-task range");
        CHECK([panel hitTest:CGPointMake(2,self.window.safeAreaInsets.top+80) withEvent:nil]==nil,@"expanded panel blocks recovery touches outside the card");
        [picker pause:@"manual recovery"];CHECK([panel hitTest:CGPointMake(2,self.window.safeAreaInsets.top+80) withEvent:nil]==nil,@"paused panel blocks list recovery");
        [panel setValue:@YES forKey:@"collapsed"];[panel setNeedsLayout];[panel layoutIfNeeded];[picker log:@"same-state panel refresh"];CHECK([[panel valueForKey:@"collapsed"]boolValue],@"paused panel cannot remain collapsed after refresh");
        [panel layoutIfNeeded];panel.hidden=YES;UIView *mini=[panel valueForKey:@"mini"];CHECK([panel hitTest:mini.center withEvent:nil]==nil,@"hidden collapsed panel still intercepts touches");panel.hidden=NO;
        JSValue *gate=[picker valueForKey:@"mutations"];NSDictionary *token=@{@"run":[picker snapshot][@"token"][@"run"],@"step":@1};[gate invokeMethod:@"begin" withArguments:@[@"123",token]];
        __block NSUInteger updates=0;id observer=[[NSNotificationCenter defaultCenter]addObserverForName:@"ZZPickerUpdated" object:nil queue:nil usingBlock:^(NSNotification *note){(void)note;updates++;}];
        [picker observeJSON:@{@"respCode":@0} metadata:@{@"path":@"/zz/transfer/addLoveInfo",@"id":@"123",@"token":token} webView:nil];
        CHECK(![[gate invokeMethod:@"pending" withArguments:@[]]toBool],@"late favorite response did not release gate");
        CHECK(updates>0,@"gate release did not notify task panel");[[NSNotificationCenter defaultCenter]removeObserver:observer];
        [run invokeMethod:@"start" withArguments:@[]];[js evaluateScript:@"testRun.state=testRun.phase='verify';testRun.current={id:'123',title:'商品'};testRun.currentProduct={id:'123',title:'商品',ios:'17.0'};testRun.currentEvaluation={status:'match',reasons:[],checks:[],evidence:{},ruleVersion:testRun.ruleContext.ruleVersion};testRun.intent={type:'verify',id:'123',token:{run:testRun.run,step:testRun.step}};"];
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
        [defaults removeObjectForKey:@"com.codex.zzpicker.config.v3"];[defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];[defaults removeObjectForKey:@"com.codex.zzpicker.config.v1"];
        ZZPicker *fresh=[ZZPicker new];CHECK(![fresh.config[@"autoFavorite"]boolValue]&&[fresh.config[@"maxProducts"]integerValue]==100&&[fresh.config[@"maxMinutes"]integerValue]==15,@"fresh public defaults must be manual favorite with finite limits");
        [defaults setObject:legacy forKey:@"com.codex.zzpicker.config.v1"];CHECK(![[[ZZPicker new]config][@"autoFavorite"]boolValue],@"v1 migration enabled favorite without consent");
        NSMutableDictionary *optedIn=[legacy mutableCopy];optedIn[@"autoFavorite"]=@YES;[defaults removeObjectForKey:@"com.codex.zzpicker.config.v3"];[defaults setObject:optedIn forKey:@"com.codex.zzpicker.config.v2"];CHECK([[[ZZPicker new]config][@"autoFavorite"]boolValue],@"public update erased explicit favorite preference");
        if(savedV3)[defaults setObject:savedV3 forKey:@"com.codex.zzpicker.config.v3"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v3"];if(savedConfig)[defaults setObject:savedConfig forKey:@"com.codex.zzpicker.config.v2"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];
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
        CHECK(NSClassFromString(@"ZZModelPickerController")!=nil&&NSClassFromString(@"ZZRecoveryController")!=nil,@"native model picker or recovery page is missing");
        UITableViewCell *rangeCell=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        CHECK([rangeCell.accessibilityIdentifier isEqual:@"effectiveRange"]&&rangeCell.detailTextLabel.text.length>0,@"actual multi-segment range is missing before manual fields");
        if(NSClassFromString(@"ZZModelPickerController")){
            NSDictionary *savedDraft=[[renderSettings valueForKey:@"draft"]copy];NSMutableDictionary *working=[[[js[@"ZZConfig"]invokeMethod:@"freshConfig" withArguments:@[]]toDictionary]mutableCopy];
            working=[[picker configurationByEditing:working event:@{@"type":@"selectModel",@"modelId":@"iphone-14-pro-max"}]mutableCopy];working[@"capacities"]=@[@"128"];[renderSettings setValue:working forKey:@"draft"];
            for(NSInteger row=0;row<2;row++){UITableViewCell *purpose=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];UISwitch *toggle=(id)purpose.accessoryView;CHECK(!toggle.on,@"new purpose must default off");toggle.on=YES;[toggle sendActionsForControlEvents:UIControlEventValueChanged];}
            rangeCell=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];CHECK([rangeCell.textLabel.text containsString:@"16.6.1"]&&[rangeCell.textLabel.text containsString:@"17.0"],@"purpose UI flattened disjoint range");
            UISegmentedControl *mode=(id)[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]].accessoryView;mode.selectedSegmentIndex=1;[mode sendActionsForControlEvents:UIControlEventValueChanged];
            for(NSInteger row=2;row<=3;row++){UITextField *field=(id)[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:2]].accessoryView;field.text=row==2?@"16.7":@"16.7.2";[field sendActionsForControlEvents:UIControlEventEditingChanged];}
            CHECK(![[renderSettings valueForKey:@"rangeState"][@"canStart"]boolValue],@"empty intersection still enables start");
            mode.selectedSegmentIndex=0;[mode sendActionsForControlEvents:UIControlEventValueChanged];mode.selectedSegmentIndex=1;[mode sendActionsForControlEvents:UIControlEventValueChanged];CHECK([[renderSettings valueForKey:@"draft"][@"manualMinIOS"]isEqual:@"16.7"],@"mode switch erased original manual input");
            mode.selectedSegmentIndex=0;[mode sendActionsForControlEvents:UIControlEventValueChanged];[renderSettings.tableView.delegate tableView:renderSettings.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            SettleNavigation(settingsNav);UITableViewController *modelPicker=(id)settingsNav.topViewController;[modelPicker loadViewIfNeeded];CHECK([modelPicker.title isEqual:@"手机型号"],@"model picker did not open");
            UISearchController *search=[modelPicker valueForKey:@"search"];search.searchBar.text=@"not-in-catalog";[search.searchResultsUpdater updateSearchResultsForSearchController:search];CHECK([modelPicker.tableView.dataSource tableView:modelPicker.tableView numberOfRowsInSection:0]==0&&[((UILabel *)modelPicker.tableView.backgroundView).text isEqual:@"本次目录未收录该机型"],@"unlisted search guessed a model or claimed incompatibility");search.searchBar.text=@"";[search.searchResultsUpdater updateSearchResultsForSearchController:search];[self saveScreenshot:@"ui-v2-models.png"];
            [modelPicker.tableView.delegate tableView:modelPicker.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            SettleNavigation(settingsNav);CHECK(settingsNav.topViewController==renderSettings&&renderSettings.navigationItem.searchController==nil,@"model picker navigation leaked into settings");
            CHECK(([[renderSettings valueForKey:@"draft"][@"capacities"]isEqual:@[@"128"]])&&![[renderSettings valueForKey:@"rangeState"][@"canStart"]boolValue],@"model switch silently cleared conflicting 128G");
            UITableViewCell *capacityCell=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:4]];UIButton *bad=(id)FindTestView(capacityCell,@"capacities|128");CHECK([bad.accessibilityValue containsString:@"冲突"],@"conflicting capacity is not identified to the user");[bad sendActionsForControlEvents:UIControlEventTouchUpInside];CHECK([[renderSettings valueForKey:@"rangeState"][@"canStart"]boolValue],@"explicit capacity correction did not restore start");
            NSMutableDictionary *unavailable=[[picker compatibilityCatalog]mutableCopy];unavailable[@"capabilitiesAvailable"]=@NO;unavailable[@"tools"]=@[];[picker setValue:unavailable forKey:@"ruleContext"];[[NSNotificationCenter defaultCenter]postNotificationName:@"ZZPickerUpdated" object:nil];CHECK(![[renderSettings valueForKey:@"rangeState"][@"canStart"]boolValue],@"unavailable rules still allow a capability scan");[renderSettings.tableView.delegate tableView:renderSettings.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:2]];CHECK([[renderSettings valueForKey:@"rangeState"][@"canStart"]boolValue],@"local rule retry did not restore the next-task range");
            [renderSettings.tableView reloadData];[renderSettings.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];[self saveScreenshot:@"ui-v2-range.png"];
            ZZPushCompatibilityEvidence(settingsNav,[picker compatibilityEvidenceForConfig:[renderSettings valueForKey:@"draft"]]);SettleNavigation(settingsNav);UITableViewController *basis=(id)settingsNav.topViewController;NSMutableString *basisText=[NSMutableString new];for(NSInteger section=0;section<[basis.tableView.dataSource numberOfSectionsInTableView:basis.tableView];section++){[basisText appendString:[basis.tableView.dataSource tableView:basis.tableView titleForHeaderInSection:section]?:@""];for(NSInteger row=0;row<[basis.tableView.dataSource tableView:basis.tableView numberOfRowsInSection:section];row++){UITableViewCell *cell=[basis.tableView.dataSource tableView:basis.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];[basisText appendString:cell.detailTextLabel.text?:@""];}}CHECK([basisText containsString:@"TrollStore 2.1.1"]&&[basisText containsString:@"需要电脑"]&&[basisText containsString:@"2026-10-21"],@"basis page omitted pinned tool, computer prerequisite or review date");[self saveScreenshot:@"ui-v2-evidence.png"];[settingsNav popViewControllerAnimated:NO];SettleNavigation(settingsNav);
            __block NSUInteger recoveryChoices=0;ZZPushConfigRecovery(settingsNav,@{@"status":@"recovery",@"issues":@[@"合成损坏配置"],@"backup":migrated.config},^(NSString *choice){(void)choice;recoveryChoices++;});SettleNavigation(settingsNav);UITableViewController *recoveryPage=(id)settingsNav.topViewController;[self saveScreenshot:@"ui-v2-recovery.png"];[recoveryPage.tableView.delegate tableView:recoveryPage.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];UIAlertController *confirmation=(id)recoveryPage.presentedViewController;SettleModal(confirmation,YES);self.lastMetadata=@{@"recoveryTitle":recoveryPage.title?:@"",@"presentedClass":confirmation?NSStringFromClass(confirmation.class):@"none",@"stackCount":@(settingsNav.viewControllers.count)};CHECK([confirmation isKindOfClass:UIAlertController.class]&&confirmation.actions.firstObject.style==UIAlertActionStyleCancel&&recoveryChoices==0,@"recovery must preview and confirm without immediate writes");[self saveScreenshot:@"ui-v2-recovery-confirm.png"];[confirmation dismissViewControllerAnimated:NO completion:nil];SettleModal(confirmation,NO);CHECK(confirmation.presentingViewController==nil,@"recovery confirmation did not dismiss");SettleNavigation(settingsNav);[settingsNav popViewControllerAnimated:NO];SettleNavigation(settingsNav);CHECK(recoveryChoices==0,@"leaving recovery changed settings");
            [renderSettings setValue:[savedDraft mutableCopy] forKey:@"draft"];[[NSNotificationCenter defaultCenter]postNotificationName:@"ZZPickerUpdated" object:nil];SettleNavigation(settingsNav);[renderSettings.tableView layoutIfNeeded];
        }
        CGRect barRect=[settingsNav.navigationBar convertRect:settingsNav.navigationBar.bounds toView:self.window],tableViewport=[renderSettings.tableView convertRect:renderSettings.tableView.bounds toView:self.window];
        CHECK(CGRectGetMinY(tableViewport)>=CGRectGetMaxY(barRect)-0.5,@"settings content viewport extends behind the navigation buttons");
        [renderSettings.tableView layoutIfNeeded];[renderSettings.tableView setContentOffset:CGPointMake(0,-renderSettings.tableView.adjustedContentInset.top) animated:NO];[renderSettings.tableView layoutIfNeeded];[renderSettings.tableView setContentOffset:CGPointMake(0,28-renderSettings.tableView.adjustedContentInset.top) animated:NO];[renderSettings.tableView layoutIfNeeded];UITableViewHeaderFooterView *sourceHeader=[renderSettings.tableView headerViewForSection:0];
        CGRect sourceRect=[sourceHeader.textLabel convertRect:sourceHeader.textLabel.bounds toView:self.window];tableViewport=[renderSettings.tableView convertRect:renderSettings.tableView.bounds toView:self.window];
        self.lastMetadata=@{@"headerExists":@(sourceHeader!=nil),@"sourceRect":NSStringFromCGRect(sourceRect),@"viewport":NSStringFromCGRect(tableViewport),@"bar":NSStringFromCGRect(barRect),@"top":settingsNav.topViewController.title?:@"",@"visible":settingsNav.visibleViewController.title?:@"",@"modal":settingsNav.presentedViewController?NSStringFromClass(settingsNav.presentedViewController.class):@"none",@"offset":NSStringFromCGPoint(renderSettings.tableView.contentOffset)};CHECK(sourceHeader&&!CGRectIntersectsRect(CGRectIntersection(sourceRect,tableViewport),barRect),@"scrolled source label overlaps explanation and close controls");[self saveScreenshot:@"ui-settings-scrolled.png"];
        UIViewController *about=[(UIViewController *)[NSClassFromString(@"ZZAboutController")alloc]init];[settingsNav pushViewController:about animated:NO];[settingsNav popViewControllerAnimated:NO];[settingsNav.view layoutIfNeeded];
        barRect=[settingsNav.navigationBar convertRect:settingsNav.navigationBar.bounds toView:self.window];tableViewport=[renderSettings.tableView convertRect:renderSettings.tableView.bounds toView:self.window];CHECK(CGRectGetMinY(tableViewport)>=CGRectGetMaxY(barRect)-0.5,@"returning from environment help restored overlapping settings layout");
        CHECK([renderSettings.tableView.dataSource numberOfSectionsInTableView:renderSettings.tableView]==10,@"settings lacks separate limits section");
        NSArray *originalCapacities=[renderSettings valueForKey:@"capacities"];
        for(NSArray *capacities in @[@[@"256G",@"512G",@"1T"],@[@"64G",@"128G",@"256G",@"512G",@"1T"]]){
            [renderSettings setValue:capacities forKey:@"capacities"];
            for(NSNumber *width in @[@320,@390,@736])for(NSInteger section=3;section<=5;section++){
                NSIndexPath *path=[NSIndexPath indexPathForRow:0 inSection:section];CGFloat height=[renderSettings.tableView.delegate tableView:renderSettings.tableView heightForRowAtIndexPath:path];UITableViewCell *cell=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:path];cell.frame=CGRectMake(0,0,width.doubleValue,height);[cell setNeedsLayout];[cell layoutIfNeeded];
                NSString *key=section==3?@"channels":section==4?@"capacities":@"conditions";NSArray *values=section==3?picker.purchaseChannels:section==4?capacities:@[@"99新",@"95新",@"9成新",@"8成新"];BOOL uniform=YES,spacing=YES;CGRect previous=CGRectZero;
                for(NSString *value in values){NSString *normalized=section==4?[picker normalizedCapacity:value]:value;UIView *button=FindTestView(cell,[NSString stringWithFormat:@"%@|%@",key,normalized]);CGRect rect=[button convertRect:button.bounds toView:cell.contentView];if(!button||fabs(CGRectGetHeight(rect)-28)>0.5||CGRectGetMinY(rect)<5.5||CGRectGetMaxY(rect)>height-5.5)uniform=NO;if(!CGRectIsEmpty(previous)&&CGRectGetMinY(rect)>CGRectGetMinY(previous)+1&&fabs(CGRectGetMinY(rect)-CGRectGetMaxY(previous)-6)>0.5)spacing=NO;previous=rect;}
                CHECK(uniform&&spacing,@"channel/capacity/condition choices must all be 28pt high with 6pt row gaps");
            }
        }
        [renderSettings setValue:originalCapacities forKey:@"capacities"];
        NSMutableDictionary *choiceDraft=[renderSettings valueForKey:@"draft"];NSDictionary *beforeChoices=[choiceDraft copy];choiceDraft[@"channels"]=@[@"国行",@"美版",@"港澳台版",@"日版"];choiceDraft[@"capacities"]=@[@"512",@"1024"];choiceDraft[@"conditions"]=@[@"8成新"];[renderSettings setValue:@[@"256G",@"512G",@"1T"] forKey:@"capacities"];[renderSettings.tableView reloadData];[renderSettings.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:NO];[self saveScreenshot:@"ui-settings-choices.png"];[choiceDraft setDictionary:beforeChoices];[renderSettings setValue:originalCapacities forKey:@"capacities"];[renderSettings.tableView reloadData];
        if([renderSettings.tableView.dataSource numberOfSectionsInTableView:renderSettings.tableView]==10){UITableViewCell *limit=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:7]];CHECK([((UITextField *)limit.accessoryView).text isEqual:@"100"],@"settings did not show limit default");}
        UITapGestureRecognizer *dismissTap=nil;for(UIGestureRecognizer *gesture in renderSettings.tableView.gestureRecognizers)if([gesture.name isEqual:@"dismissSettingsKeyboard"])dismissTap=(id)gesture;
        CHECK(dismissTap&&!dismissTap.cancelsTouchesInView,@"blank-area dismissal is missing or consumes setting controls");
        if(dismissTap){ZZTestTouch *touch=[ZZTestTouch new];touch.targetView=renderSettings.tableView;BOOL blank=[dismissTap.delegate gestureRecognizer:dismissTap shouldReceiveTouch:touch];UITextField *input=[UITextField new];UILabel *inside=[UILabel new];[input addSubview:inside];touch.targetView=inside;BOOL editing=[dismissTap.delegate gestureRecognizer:dismissTap shouldReceiveTouch:touch];UIButton *choice=[UIButton buttonWithType:UIButtonTypeSystem];[choice addSubview:inside];touch.targetView=inside;BOOL choosing=[dismissTap.delegate gestureRecognizer:dismissTap shouldReceiveTouch:touch];CHECK(blank&&!editing&&!choosing,@"dismiss gesture must accept blank areas and leave field/choice touches alone");}
        CHECK(renderSettings.tableView.keyboardDismissMode==UIScrollViewKeyboardDismissModeInteractive,@"dragging settings does not dismiss the keyboard");
        for(NSIndexPath *path in @[[NSIndexPath indexPathForRow:0 inSection:0],[NSIndexPath indexPathForRow:2 inSection:2],[NSIndexPath indexPathForRow:3 inSection:2],[NSIndexPath indexPathForRow:0 inSection:7],[NSIndexPath indexPathForRow:1 inSection:7]]){
            [renderSettings.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];[renderSettings.tableView layoutIfNeeded];UITextField *field=(id)[renderSettings.tableView cellForRowAtIndexPath:path].accessoryView;
            CHECK(field&&[field becomeFirstResponder]&&field.isFirstResponder,@"settings field cannot begin editing");NSString *key=field.accessibilityIdentifier;NSString *value=[key isEqual:@"model"]?@"iPhone 16 Pro":@"19";field.text=value;[field sendActionsForControlEvents:UIControlEventEditingChanged];CHECK(field.isFirstResponder,@"live validation replaced the editing field");
            if(dismissTap&&[renderSettings respondsToSelector:@selector(dismissKeyboard)])[UIApplication.sharedApplication sendAction:@selector(dismissKeyboard) to:renderSettings from:dismissTap forEvent:nil];
            CHECK(!field.isFirstResponder&&[[renderSettings valueForKey:@"draft"][key]isEqual:value],@"blank-area dismissal lost focus or edited value");
            [field becomeFirstResponder];UIToolbar *toolbar=[field.inputAccessoryView isKindOfClass:UIToolbar.class]?(id)field.inputAccessoryView:nil;UIBarButtonItem *done=toolbar.items.lastObject;BOOL sent=done&&[UIApplication.sharedApplication sendAction:done.action to:done.target from:done forEvent:nil];CHECK(sent&&!field.isFirstResponder,@"keyboard Done does not finish editing this settings field");
            [field becomeFirstResponder];if([field.delegate respondsToSelector:@selector(textFieldShouldReturn:)])[field.delegate textFieldShouldReturn:field];CHECK(!field.isFirstResponder,@"keyboard Return does not finish editing this settings field");[field resignFirstResponder];
        }
        [renderSettings.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:8] atScrollPosition:UITableViewScrollPositionBottom animated:NO];[renderSettings.tableView layoutIfNeeded];[self saveScreenshot:@"ui-settings-bottom.png"];
        [renderSettings.tableView setContentOffset:CGPointMake(0,-renderSettings.tableView.adjustedContentInset.top) animated:NO];self.window.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;[renderSettings.tableView reloadData];[self saveScreenshot:@"ui-v2-dark.png"];self.window.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;
        if(@available(iOS 17.0,*)){renderSettings.traitOverrides.preferredContentSizeCategory=UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;[renderSettings.tableView reloadData];[self saveScreenshot:@"ui-v2-large.png"];CHECK(renderSettings.tableView.contentSize.width<=renderSettings.tableView.bounds.size.width+1,@"large type caused horizontal overflow");renderSettings.traitOverrides.preferredContentSizeCategory=UIContentSizeCategoryLarge;}
        CHECK(NSClassFromString(@"ZZRecordsController")!=nil,@"native all/reject/unknown records and detail navigation are missing");
        [js evaluateScript:@"var recordsConfig=ZZConfig.applyConfigEdit(ZZConfig.freshConfig(),{type:'selectModel',modelId:'iphone-14-pro-max'});recordsConfig.requireTrollStore=true;recordsConfig.requireJailbreak=true;var recordRows=['match','reject','unknown'].map(function(kind,i){var p=ZZCore.normalizeProduct({id:String(i+1),item:{title:'iPhone 14 Pro Max'},base:{respCode:0,respData:{title:'iPhone 14 Pro Max',isSoldOut:false,collected:false}},more:{respCode:0,respData:{report:{title:'iPhone 14 Pro Max',params:[{key:'系统版本',value:kind==='reject'?'17.2':'17.0'},{key:'购买渠道',value:kind==='match'?'国行':''},{key:'存储容量',value:'256G'}]}}}});var e=ZZCore.matchProduct(p,recordsConfig);return Object.assign({},p,{status:kind==='match'?'favoriteUnknown':e.status,reasons:e.reasons,evaluation:e});});var recordsSnapshot={allResults:recordRows,ruleVersion:recordRows[0].evaluation.ruleVersion};"];
        CHECK(!js.exception,@"synthetic records failed evaluation");
        ZZPushRunRecords(settingsNav,[js[@"recordsSnapshot"]toDictionary]);SettleNavigation(settingsNav);UITableViewController *records=(id)settingsNav.topViewController;
        UISegmentedControl *recordFilter=[records valueForKey:@"filter"];
        CHECK([records.tableView.dataSource tableView:records.tableView numberOfRowsInSection:0]==3,@"all records omitted reject or unknown");[self saveScreenshot:@"ui-v2-records.png"];
        for(NSInteger selected=1;selected<4;selected++){recordFilter.selectedSegmentIndex=selected;[recordFilter sendActionsForControlEvents:UIControlEventValueChanged];NSArray *visible=[records valueForKey:@"visibleRecords"];CHECK((visible.count==1&&[visible[0][@"evaluation"][@"status"]isEqual:@[@"",@"match",@"reject",@"unknown"][selected]]),@"record filter confused compatibility with favorite state");}
        recordFilter.selectedSegmentIndex=1;[recordFilter sendActionsForControlEvents:UIControlEventValueChanged];UITableViewCell *matchRow=[records.tableView.dataSource tableView:records.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];CHECK([matchRow.detailTextLabel.text containsString:@"符合"]&&[matchRow.detailTextLabel.text containsString:@"收藏待确认"],@"favorite unknown changed compatibility or pretended success");
        [records.tableView.delegate tableView:records.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];SettleNavigation(settingsNav);UITableViewController *detail=(id)settingsNav.topViewController;NSArray *detailSections=[detail valueForKey:@"sections"];
        CHECK([detailSections[1][@"rows"][4][@"value"]isEqual:@"未提供"]&&[detailSections[1][@"rows"][5][@"value"]containsString:@"未独立验证"],@"detail invented a build or verified release channel");
        CHECK([detailSections[3][@"rows"][0][@"evidence"]isEqual:[js[@"recordRows"]toArray][0][@"evaluation"][@"evidence"]],@"detail replaced the frozen evaluation evidence");[self saveScreenshot:@"ui-v2-detail.png"];
        [settingsNav popViewControllerAnimated:NO];SettleNavigation(settingsNav);recordFilter.selectedSegmentIndex=2;[recordFilter sendActionsForControlEvents:UIControlEventValueChanged];[records.tableView.delegate tableView:records.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];SettleNavigation(settingsNav);detail=(id)settingsNav.topViewController;NSMutableString *checkText=[NSMutableString new];for(NSDictionary *row in [detail valueForKey:@"sections"][2][@"rows"])[checkText appendFormat:@"%@ %@",row[@"label"],row[@"value"]];CHECK([checkText containsString:@"不符合"]&&[checkText containsString:@"待确认"],@"reject detail dropped independent unknown reasons");
        [settingsNav popViewControllerAnimated:NO];SettleNavigation(settingsNav);[settingsNav popViewControllerAnimated:NO];SettleNavigation(settingsNav);
        [picker setValue:@"合成初始化失败：原设置保留，请重新安装完整测试包" forKey:@"initializationError"];UITableViewController *unavailable=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];[settingsNav pushViewController:unavailable animated:NO];SettleNavigation(settingsNav);CHECK([unavailable.tableView.dataSource numberOfSectionsInTableView:unavailable.tableView]==1&&[[unavailable.tableView.dataSource tableView:unavailable.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].accessibilityIdentifier isEqual:@"runtimeUnavailable"],@"unavailable runtime exposed an editable configuration form");[self saveScreenshot:@"ui-v2-runtime-unavailable.png"];[picker setValue:nil forKey:@"initializationError"];[settingsNav popViewControllerAnimated:NO];SettleNavigation(settingsNav);
        if(previewClass){self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:[(UIViewController *)[previewClass alloc]init]];[self.window layoutIfNeeded];[self saveScreenshot:@"ui-diagnostic-preview.png"];}

    }@catch(NSException *exception){[failures addObject:exception.reason?:@"native exception"];}
    NSString *folder=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;NSDictionary *result=@{@"checks":@(checks),@"failures":failures,@"snapshot":ZZPicker.shared.snapshot,@"logs":ZZPicker.shared.logs,@"metadata":self.lastMetadata?:@{}};[[NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil]writeToFile:[folder stringByAppendingPathComponent:@"ui-result.json"]atomically:YES];
}
@end
@interface TestDelegate : UIResponder <UIApplicationDelegate> @end
@implementation TestDelegate
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {(void)application;(void)options;UISceneConfiguration *config=[[UISceneConfiguration alloc]initWithName:@"Tests" sessionRole:session.role];config.delegateClass=TestScene.class;return config;}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(TestDelegate.class));}}
