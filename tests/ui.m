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
@end
@interface ZZLabelViewButton : UIView @end
@implementation ZZLabelViewButton @end
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
        ZZPicker *picker=ZZPicker.shared;JSContext *js=[picker valueForKey:@"js"];NSDictionary *config=@{@"model":@"iPhone 15 Pro Max",@"autoFavorite":@YES};[picker setValue:config forKey:@"config"];
        JSValue *run=[js[@"ZZCore"][@"Run"]constructWithArguments:@[config]];[picker setValue:run forKey:@"run"];[run invokeMethod:@"start" withArguments:@[]];js[@"testRun"]=run;
        NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;NSDictionary *savedConfig=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"];
        NSDictionary *legacy=@{@"model":@"iPhone 15 Pro Max",@"minIOS":@"18",@"maxIOS":@"27",@"capacities":@[@"512"],@"conditions":@[@"99新"],@"autoFavorite":@NO};
        [defaults setObject:legacy forKey:@"com.codex.zzpicker.config.v2"];ZZPicker *migrated=[ZZPicker new];
        CHECK(([migrated.config[@"channels"]isEqual:@[@"国行"]]&&[migrated.config[@"maxIOS"]isEqual:@"27"]&&![migrated.config[@"autoFavorite"]boolValue]),@"adding default channel changed existing iOS criteria or favorite preference");
        NSMutableDictionary *unrestricted=[legacy mutableCopy];unrestricted[@"channels"]=@[];[defaults setObject:unrestricted forKey:@"com.codex.zzpicker.config.v2"];CHECK([[[ZZPicker new]config][@"channels"]isEqual:@[]],@"explicit unrestricted channel selection was overwritten on reload");
        if(savedConfig)[defaults setObject:savedConfig forKey:@"com.codex.zzpicker.config.v2"];else[defaults removeObjectForKey:@"com.codex.zzpicker.config.v2"];
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
        ZZHideTaskPanel();[picker setValue:migrated.config forKey:@"config"];UITableViewController *renderSettings=[(UITableViewController *)[NSClassFromString(@"ZZSettingsController")alloc]initWithStyle:UITableViewStyleInsetGrouped];
        self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:renderSettings];[self.window layoutIfNeeded];[renderSettings.tableView layoutIfNeeded];[self saveScreenshot:@"ui-settings-top.png"];
        CHECK([renderSettings.tableView.dataSource numberOfSectionsInTableView:renderSettings.tableView]==8,@"settings lacks separate limits section");
        if([renderSettings.tableView.dataSource numberOfSectionsInTableView:renderSettings.tableView]==8){UITableViewCell *limit=[renderSettings.tableView.dataSource tableView:renderSettings.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:5]];CHECK([((UITextField *)limit.accessoryView).text isEqual:@"100"],@"settings did not show limit default");}
        [renderSettings.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:6] atScrollPosition:UITableViewScrollPositionBottom animated:NO];[renderSettings.tableView layoutIfNeeded];[self saveScreenshot:@"ui-settings-bottom.png"];
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
