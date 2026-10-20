#import "ZZPicker.h"
#import "Embedded.h"
#import "ZZRuntime.h"
#import <objc/runtime.h>
#import <sys/utsname.h>
#ifndef ZZ_VARIANT
#define ZZ_VARIANT "development"
#endif
@interface ZZPicker () <UIGestureRecognizerDelegate>
@property(nonatomic,strong) JSContext *js;
@property(nonatomic,strong) JSValue *run;
@property(nonatomic,strong) JSValue *mutations;
@property(nonatomic,strong) JSValue *pageWait;
@property(nonatomic,strong) ZZFilterDriver *filterDriver;
@property(nonatomic,strong) NSDictionary *pendingFilterResponse;
@property(nonatomic,copy) NSDictionary *config;
@property(nonatomic,strong) NSMutableArray *mutableLogs;
@property(nonatomic,strong) NSMutableArray *searchTrace;
@property(nonatomic,strong) NSHashTable<WKWebView *> *webViews;
@property(nonatomic,strong) NSDictionary *action;
@property(nonatomic,strong) NSMutableDictionary *detailParts;
@property(nonatomic,strong) NSTimer *entryTimer;
@property(nonatomic,strong) UIButton *entryButton;
@property(nonatomic) BOOL entryDragging;
@property(nonatomic) CGPoint entryDragStart;
@property(nonatomic) NSUInteger uiAttempts;
@property(nonatomic,strong) UITapGestureRecognizer *manualTap;
@property(nonatomic,strong) UIPanGestureRecognizer *manualPan;
@end
static NSString *ZZSource(const unsigned char *bytes,NSUInteger length){return [[NSString alloc]initWithBytes:bytes length:length encoding:NSUTF8StringEncoding]?:@"";}
@implementation ZZPicker
+ (instancetype)shared {static ZZPicker *p;static dispatch_once_t once;dispatch_once(&once,^{p=[ZZPicker new];});return p;}
- (instancetype)init {
    if((self=[super init])){
        _js=[JSContext new];_mutableLogs=[NSMutableArray new];_searchTrace=[NSMutableArray new];_webViews=[NSHashTable weakObjectsHashTable];_detailParts=[NSMutableDictionary new];
        __weak ZZPicker *weakSelf=self;_js.exceptionHandler=^(JSContext *context,JSValue *exception){(void)context;(void)exception;[weakSelf pause:@"规则执行异常，请导出诊断"];};
        _js[@"ZZNow"]=^double{return NSProcessInfo.processInfo.systemUptime*1000;};
        [_js evaluateScript:ZZSource(ZZCoreBytes,ZZCoreLength)];_mutations=[_js[@"ZZCore"][@"MutationGate"]constructWithArguments:@[]];
        NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;NSDictionary *saved=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v2"];
        if(!saved)saved=[defaults dictionaryForKey:@"com.codex.zzpicker.config.v1"]?:@{@"model":@"iPhone 15 Pro Max",@"minIOS":@"",@"maxIOS":@"",@"conditions":@[],@"capacities":@[]};
        NSDictionary *checked=[[_js[@"ZZCore"]invokeMethod:@"validateConfig" withArguments:@[saved]]toDictionary];
        _config=[checked[@"ok"]boolValue]?checked[@"config"]:@{@"model":@"iPhone 15 Pro Max",@"minIOS":@"",@"maxIOS":@"",@"channels":@[@"国行"],@"conditions":@[],@"capacities":@[],@"autoFavorite":@NO,@"maxProducts":@100,@"maxMinutes":@15};
    }return self;
}
- (NSArray *)logs {return [self.mutableLogs copy];}
- (void)log:(NSString *)message {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self log:message];});return;}
    NSDateFormatter *f=[NSDateFormatter new];f.dateFormat=@"HH:mm:ss";[self.mutableLogs addObject:[NSString stringWithFormat:@"%@ %@",[f stringFromDate:NSDate.date],message]];
    if(self.mutableLogs.count>200)[self.mutableLogs removeObjectAtIndex:0];[self changed];
}
- (void)changed {[[NSNotificationCenter defaultCenter]postNotificationName:@"ZZPickerUpdated" object:nil];}
- (NSDictionary *)snapshot {return self.run?[[self.run invokeMethod:@"snapshot" withArguments:@[]]toDictionary]:@{@"state":@"idle",@"phase":@"idle",@"config":self.config,@"page":@1,@"counts":@{},@"results":@[]};}
- (NSDictionary *)presentation {return [[self.js[@"ZZCore"]invokeMethod:@"presentation" withArguments:@[[self snapshot],@([[self.mutations invokeMethod:@"pending" withArguments:@[]]toBool])]]toDictionary];}
- (NSString *)normalizedCapacity:(NSString *)label {JSValue *v=[self.js[@"ZZCore"]invokeMethod:@"normalizeCapacity" withArguments:@[label]];return v.isNull||v.isUndefined?nil:v.toString;}
- (NSArray<NSString *> *)purchaseChannels {return [self.js[@"ZZCore"][@"channelChoices"]toArray]?:@[];}
- (BOOL)isEnabled {id value=[NSUserDefaults.standardUserDefaults objectForKey:@"com.codex.zzpicker.enabled"];return !value||[value boolValue];}
- (void)setEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:@"com.codex.zzpicker.enabled"];
    if(!enabled){[self stop];[self log:@"插件已停用；设置和结果保留，重新启用后才能开始新任务"];}
    else [self log:@"插件已启用，等待手动开始任务"];[self changed];
}
- (NSDictionary *)environment {
    struct utsname machine;NSString *model=uname(&machine)==0?[NSString stringWithUTF8String:machine.machine]:@"unknown";
    model=NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"]?:model;
    NSString *app=[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]?:@"unknown";
    return @{@"plugin":ZZPickerVersion,@"variant":@ZZ_VARIANT,@"appVersion":app,@"expectedAppVersion":@"12.8.5",@"verifiedAppVersion":@([app isEqual:@"12.8.5"]),@"iOS":UIDevice.currentDevice.systemVersion,@"deviceModel":model?:@"unknown",@"enabled":@(self.enabled)};
}
- (NSString *)diagnostics {return [self diagnosticsWithDetails:NO];}
- (NSString *)diagnosticsWithDetails:(BOOL)includeDetails {
    NSDictionary *snap=[[self.js[@"ZZCore"]invokeMethod:@"diagnosticSnapshot" withArguments:@[[self snapshot],@(includeDetails)]]toDictionary]?:@{};
    NSMutableDictionary *info=[[self environment]mutableCopy];[info addEntriesFromDictionary:@{@"includesProductDetails":@(includeDetails),@"snapshot":snap,@"searchUI":ZZSearchDiagnostics(),@"filterUI":self.filterDriver.diagnostics?:@{},@"searchTrace":[self.searchTrace copy],@"logs":self.logs}];
    return [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:nil]encoding:NSUTF8StringEncoding]?:@"诊断编码失败";
}
- (void)install {
    [self log:[NSString stringWithFormat:@"插件%@已加载：%s；隐藏采集模式",ZZPickerVersion,ZZ_VARIANT]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(background:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    self.entryButton=[UIButton buttonWithType:UIButtonTypeSystem];self.entryButton.tag=ZZPickerOwnViewTag;[self.entryButton setTitle:@"选机设置" forState:UIControlStateNormal];self.entryButton.accessibilityLabel=@"选机设置与任务";self.entryButton.accessibilityHint=@"轻点打开，拖动可移动位置";
    self.entryButton.backgroundColor=[UIColor colorWithRed:1 green:0.94 blue:0.94 alpha:1];[self.entryButton setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal];self.entryButton.layer.cornerRadius=18;self.entryButton.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [self.entryButton addTarget:self action:@selector(entryTapped) forControlEvents:UIControlEventTouchUpInside];[self attachEntry];__weak ZZPicker *weakSelf=self;
    [self.entryButton addGestureRecognizer:[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(entryDragged:)]];
    self.entryTimer=[NSTimer scheduledTimerWithTimeInterval:2 repeats:YES block:^(NSTimer *timer){(void)timer;[weakSelf checkTaskBudget];[weakSelf attachEntry];}];
}
- (void)entryTapped {NSString *state=[self snapshot][@"state"];if(![@[@"idle",@"stopped",@"finished"]containsObject:state])[self showTask];else[self showSettings];}
- (CGRect)entryTravel:(UIWindow *)window {
    CGRect safe=UIEdgeInsetsInsetRect(window.bounds,window.safeAreaInsets);
    return CGRectMake(CGRectGetMinX(safe)+8+43,CGRectGetMinY(safe)+6+18,MAX(0,safe.size.width-16-86),MAX(0,safe.size.height-12-36));
}
- (void)entryDragged:(UIPanGestureRecognizer *)pan {
    UIWindow *window=self.entryButton.window;if(!window)return;CGRect travel=[self entryTravel:window];
    if(pan.state==UIGestureRecognizerStateBegan){self.entryDragging=YES;self.entryDragStart=self.entryButton.center;}
    if(pan.state==UIGestureRecognizerStateBegan||pan.state==UIGestureRecognizerStateChanged||pan.state==UIGestureRecognizerStateEnded){
        CGPoint delta=[pan translationInView:window];self.entryButton.center=CGPointMake(MIN(CGRectGetMaxX(travel),MAX(travel.origin.x,self.entryDragStart.x+delta.x)),MIN(CGRectGetMaxY(travel),MAX(travel.origin.y,self.entryDragStart.y+delta.y)));
    }
    if(pan.state==UIGestureRecognizerStateEnded){CGPoint point=self.entryButton.center;[NSUserDefaults.standardUserDefaults setObject:@{@"x":@(travel.size.width?(point.x-travel.origin.x)/travel.size.width:0),@"y":@(travel.size.height?(point.y-travel.origin.y)/travel.size.height:0)} forKey:@"com.codex.zzpicker.entryPosition"];}
    if(pan.state==UIGestureRecognizerStateEnded||pan.state==UIGestureRecognizerStateCancelled||pan.state==UIGestureRecognizerStateFailed){self.entryDragging=NO;[self attachEntry];}
}
- (void)attachEntry {
    UIWindow *window=ZZAppWindow();if(!window)return;if(self.entryButton.superview!=window){[self.entryButton removeFromSuperview];[window addSubview:self.entryButton];}
    self.entryButton.hidden=ZZSettingsVisible()||ZZViewerVisible();if(!self.entryDragging){CGRect travel=[self entryTravel:window];NSDictionary *saved=[NSUserDefaults.standardUserDefaults dictionaryForKey:@"com.codex.zzpicker.entryPosition"];id x=saved[@"x"],y=saved[@"y"];BOOL valid=[x isKindOfClass:NSNumber.class]&&[y isKindOfClass:NSNumber.class]&&isfinite([x doubleValue])&&isfinite([y doubleValue]);self.entryButton.bounds=CGRectMake(0,0,86,36);self.entryButton.center=CGPointMake(travel.origin.x+travel.size.width*(valid?MIN(1,MAX(0,[x doubleValue])):1),travel.origin.y+travel.size.height*(valid?MIN(1,MAX(0,[y doubleValue])):0));}[window bringSubviewToFront:self.entryButton];
    if(!self.manualTap){self.manualTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(manualTouch:)];self.manualPan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(manualTouch:)];for(UIGestureRecognizer *g in @[self.manualTap,self.manualPan]){g.delegate=self;g.cancelsTouchesInView=NO;g.delaysTouchesEnded=NO;}}
    if(self.manualTap.view!=window){[self.manualTap.view removeGestureRecognizer:self.manualTap];[self.manualPan.view removeGestureRecognizer:self.manualPan];[window addGestureRecognizer:self.manualTap];[window addGestureRecognizer:self.manualPan];}
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {(void)gesture;for(UIView *v=touch.view;v;v=v.superview)if(v.tag==ZZPickerOwnViewTag)return NO;return ![@[@"idle",@"paused",@"hit",@"stopped",@"finished"]containsObject:[self snapshot][@"state"]];}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {(void)gesture;(void)other;return YES;}
- (void)manualTouch:(UIGestureRecognizer *)g {if(g.state==UIGestureRecognizerStateBegan||g.state==UIGestureRecognizerStateRecognized)[self pause:@"检测到手动操作，任务已暂停"];}
- (void)background:(NSNotification *)n {(void)n;[self pause:@"转转离开前台，任务已暂停"];}
- (void)showSettings {[self pause:@"打开设置，任务已暂停"];ZZHideTaskPanel();ZZPresentSettings();[self attachEntry];}
- (void)showTask {[self attachEntry];if(![[self snapshot][@"state"]isEqual:@"idle"]&&!ZZSettingsVisible()&&!ZZViewerVisible())ZZShowTaskPanel();}
- (NSString *)startWithConfig:(NSDictionary *)config {
    return [self startWithConfig:config allowUnverified:NO];
}
- (NSString *)startWithConfig:(NSDictionary *)config allowUnverified:(BOOL)allow {
    if(!self.enabled)return @"插件已停用，请先打开“启用插件”";
    if(![self.environment[@"verifiedAppVersion"]boolValue]&&!allow)return @"当前转转版本尚未验证，请先查看版本说明并确认仅本次测试";
    if([[self.mutations invokeMethod:@"pending" withArguments:@[]]toBool])return @"上一笔收藏仍在处理中，请先等待结果或重开转转核对收藏";
    NSDictionary *checked=[[self.js[@"ZZCore"]invokeMethod:@"validateConfig" withArguments:@[config]]toDictionary];if(![checked[@"ok"]boolValue])return [checked[@"errors"]componentsJoinedByString:@"；"]?:@"配置无效";
    if(self.run)[self.run invokeMethod:@"stop" withArguments:@[]];ZZStopCollector();self.config=checked[@"config"];[NSUserDefaults.standardUserDefaults setObject:self.config forKey:@"com.codex.zzpicker.config.v2"];
    self.run=[self.js[@"ZZCore"][@"Run"]constructWithArguments:@[self.config]];[self.run invokeMethod:@"start" withArguments:@[]];self.searchController=nil;[self.detailParts removeAllObjects];[self.searchTrace removeAllObjects];ZZResetPagination(0);
    JSValue *started=self.run;[self log:[NSString stringWithFormat:@"从%@开始新任务；等待实际筛选请求确认",ZZSearchSurface()]];
    ZZDismissSettings(^{if(self.run==started&&[[self snapshot][@"state"]isEqual:@"search"]){[self attachEntry];[self pump];[self showTask];}});return nil;
}
- (void)pause:(NSString *)reason {if(!self.run)return;[self.run invokeMethod:@"pause" withArguments:@[reason]];@synchronized(self){self.action=nil;}[self prepareAllWebViews];[self log:reason];}
- (void)resume {if(!self.enabled||!self.run||ZZViewerVisible())return;[self.run invokeMethod:@"resume" withArguments:@[]];[self pump];[self showTask];}
- (void)stop {if(self.run)[self.run invokeMethod:@"stop" withArguments:@[]];@synchronized(self){self.action=nil;}[self prepareAllWebViews];ZZStopCollector();[self log:@"任务已结束，结果与已完成收藏已保留"];[self showTask];}
- (void)viewMatched {
    NSDictionary *hit=[self snapshot][@"hit"],*item=hit[@"item"];if(!item)return;
    BOOL safe=[[self.js[@"ZZCore"]invokeMethod:@"safeProductURL" withArguments:@[item[@"jumpUrl"]?:@"",item[@"id"]?:@""]]toBool];
    if(safe&&[[self.run invokeMethod:@"beginViewing" withArguments:@[]]toBool]){ZZShowMatchedProduct(item);[self attachEntry];[self changed];}
}
- (void)returnedFromDetails {[self.run invokeMethod:@"viewed" withArguments:@[]];[self attachEntry];[self changed];[self showTask];}
- (NSDictionary *)context {@synchronized(self){if(!self.action)return @{};return @{@"token":self.action[@"token"],@"id":self.action[@"id"]?:self.action[@"item"][@"id"]?:@"",@"allowFavorite":@([self.action[@"type"]isEqual:@"favorite"]),@"filterCommit":(self.filterDriver.willCommit||self.filterDriver.complete)?@YES:@NO};}}
- (void)checkTaskBudget {
    if(!self.run)return;BOOL exceeded=[[self snapshot][@"budgetExceeded"]boolValue];
    BOOL paused=[[self.run invokeMethod:@"checkBudget" withArguments:@[]]toBool];
    if(!exceeded&&[[self snapshot][@"budgetExceeded"]boolValue])[self log:[self snapshot][@"limitReason"]?:@"已达到任务上限"];
    if(paused)[self pump];
}
- (BOOL)isCurrent:(NSDictionary *)a {NSDictionary *s=[self snapshot];return ![@[@"paused",@"hit",@"stopped",@"finished"]containsObject:s[@"state"]]&&[s[@"token"]isEqual:a[@"token"]];}
- (void)traceSearch:(NSDictionary *)metadata event:(NSString *)event response:(NSDictionary *)json {
    if(![@[@"/zz/transfer/search",@"/zz/v2/zzsearchfilteritem/getStockCount",@"/zz/v2/zzsearchfilteritem/getFilterItemDTO"]containsObject:metadata[@"path"]?:@""])return;
    // Whitelist the two public filter groups; never retain request headers or unrelated body fields.
    NSDictionary *selection=nil;id raw=metadata[@"selection"];if([raw isKindOfClass:NSDictionary.class]){NSData *bytes=[NSJSONSerialization dataWithJSONObject:@{@"clickItems":raw} options:0 error:nil];if(bytes)selection=ZZSearchSelection([[NSString alloc]initWithData:bytes encoding:NSUTF8StringEncoding]);}
    NSMutableDictionary *entry=[@{@"time":@(NSDate.date.timeIntervalSince1970),@"event":event,@"path":metadata[@"path"]?:@"",@"keywordMatches":@([metadata[@"keyword"]isEqual:self.config[@"model"]]),@"page":[metadata[@"page"]isKindOfClass:NSString.class]||[metadata[@"page"]isKindOfClass:NSNumber.class]?metadata[@"page"]:@0,@"filterCommit":@([metadata[@"filterCommit"]boolValue]),@"selection":selection?:NSNull.null,@"filterUI":self.filterDriver.diagnostics?:@{},@"state":[self snapshot][@"state"]?:@"idle"}mutableCopy];
    if(json){id infos=[json[@"respData"]isKindOfClass:NSDictionary.class]?json[@"respData"][@"infos"]:nil;entry[@"itemCount"]=[infos isKindOfClass:NSArray.class]?@([infos count]):@0;entry[@"responseOK"]=@([[json[@"respCode"]description]isEqual:@"0"]);}
    [self.searchTrace addObject:entry];if(self.searchTrace.count>40)[self.searchTrace removeObjectAtIndex:0];
}
- (NSDictionary *)requestContext:(NSURLRequest *)request {
    if(!ZZIsObservedURL(request.URL))return nil;NSDictionary *context=[self context];if(!context[@"token"])return nil;
    NSDictionary *query=ZZFormValues([NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO].percentEncodedQuery?:@"");NSString *body=request.HTTPBody?[[NSString alloc]initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]:nil;NSDictionary *form=ZZFormValues(body?:@"");
    NSString *filters=form[@"filterModuleServerParamsInput"]?:query[@"filterModuleServerParamsInput"]?:form[@"filterParam"]?:query[@"filterParam"]?:@"{}";
    return @{@"filterCommit":context[@"filterCommit"]?:@NO,@"token":context[@"token"],@"path":request.URL.path?:@"",@"id":query[@"infoId"]?:@"",@"page":form[@"pagenum"]?:query[@"pagenum"]?:@1,@"keyword":form[@"keyword"]?:query[@"keyword"]?:@"",@"selection":ZZSearchSelection(filters)?:NSNull.null};
}
- (void)observeRequest:(NSDictionary *)m {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self observeRequest:m];});return;}
    [self traceSearch:m event:@"requestStarted" response:nil];
    if(![m[@"path"]isEqual:@"/zz/transfer/search"]||![m[@"keyword"]isEqual:self.config[@"model"]]||!self.action||![self isCurrent:self.action])return;
    [self.run invokeMethod:@"searchStarted" withArguments:@[m[@"page"]?:@0,m[@"token"]?:@{}]];
    if(self.pageWait&&!self.pageWait[@"requestSeen"].toBool&&[[self.pageWait invokeMethod:@"requestStarted" withArguments:@[m[@"page"]?:@0,m[@"token"]?:@{}]]toBool])[self log:[NSString stringWithFormat:@"第%@页请求已启动，等待返回",m[@"page"]]];
}
- (void)observeFailure:(NSDictionary *)m {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self observeFailure:m];});return;}
    if(![m[@"token"]isKindOfClass:NSDictionary.class])return;
    [self traceSearch:m event:@"requestFailed" response:nil];
    if([m[@"path"]isEqual:@"/zz/v2/zzsearchfilteritem/getStockCount"])return;
    if([m[@"path"]isEqual:@"/zz/transfer/search"]){if([[self.run invokeMethod:@"searchFailed" withArguments:@[m[@"page"]?:@0,m[@"token"]]]toBool]){[self pump];[self changed];}return;}
    NSDictionary *a=self.action;if(![a[@"token"]isEqual:m[@"token"]]||![self isCurrent:a])return;
    [self.run invokeMethod:@"failed" withArguments:@[@"商品请求失败，任务已暂停或等待核对",a[@"token"]]];[self pump];
}
- (void)observeJSON:(NSDictionary *)json metadata:(NSDictionary *)m webView:(WKWebView *)web {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self observeJSON:json metadata:m webView:web];});return;}
    if(![json isKindOfClass:NSDictionary.class]||![m[@"token"]isKindOfClass:NSDictionary.class])return;NSString *path=m[@"path"];
    [self traceSearch:m event:@"responseReceived" response:json];
    if([path isEqual:@"/zz/transfer/addLoveInfo"]&&[[self.mutations invokeMethod:@"complete" withArguments:@[m[@"id"]?:@"",m[@"token"]]]toBool])[self changed];
    if([[self snapshot][@"state"]isEqual:@"stopped"]){[self.run invokeMethod:@"settleStopped" withArguments:@[path.lastPathComponent,json,m[@"id"]?:@"",m[@"token"]]];[self changed];return;}
    if([path isEqual:@"/zz/transfer/search"]&&[m[@"keyword"]isEqual:self.config[@"model"]]){
        NSDictionary *s=[self snapshot];NSUInteger page=[m[@"page"]integerValue];
        if([s[@"phase"]isEqual:@"filters"]&&self.filterDriver&&!self.filterDriver.complete){if([m[@"filterCommit"]boolValue]&&[s[@"token"]isEqual:m[@"token"]])self.pendingFilterResponse=@{@"json":json,@"metadata":m};return;}
        if(page>[s[@"page"]unsignedIntegerValue])[self.run invokeMethod:@"prefetch" withArguments:@[json,@(page),m[@"token"],m[@"selection"]?:NSNull.null]];
        else if([[self.run invokeMethod:@"search" withArguments:@[json,@(page),m[@"token"],m[@"selection"]?:NSNull.null,m[@"filterCommit"]?:@NO]]toBool]){self.searchController=ZZTopController();[self log:[NSString stringWithFormat:@"收到第%lu页，已验证筛选或进入筛选流程",(unsigned long)page]];[self pump];}
        if([[self snapshot][@"state"]isEqual:@"paused"]&&self.action){[self log:[self snapshot][@"note"]];[self pump];}
        [self changed];return;
    }
    if([path isEqual:@"/zz/v2/zzsearchfilteritem/getFilterItemDTO"]){if([m[@"token"][@"run"]isEqual:[self snapshot][@"token"][@"run"]])[self.run invokeMethod:@"updateOptions" withArguments:@[json]];return;}
    NSDictionary *snapshot=[self snapshot];
    if([snapshot[@"current"][@"id"]isEqual:m[@"id"]]){
        if([path isEqual:@"/zz/transfer/addLoveInfo"]&&[[self.run invokeMethod:@"favoriteResult" withArguments:@[json,m[@"token"]]]toBool]){[self pump];return;}
        if([path isEqual:@"/zzopen/waresshow/baseInfo"]&&[snapshot[@"phase"]isEqual:@"verify"]){id value=[[self.js[@"ZZCore"]invokeMethod:@"collectedState" withArguments:@[json]]toObject]?:NSNull.null;if([[self.run invokeMethod:@"verified" withArguments:@[value,m[@"token"]]]toBool]){[self pump];return;}}
    }
    NSDictionary *a=self.action;if(!a||![a[@"token"]isEqual:m[@"token"]]||![self isCurrent:a])return;
    NSString *ident=a[@"id"]?:a[@"item"][@"id"];if(![ident isEqual:m[@"id"]])return;NSString *type=a[@"type"];(void)web;
    if([type isEqual:@"open"]){
        if([path isEqual:@"/zzopen/waresshow/baseInfo"])self.detailParts[@"base"]=json;else if([path isEqual:@"/zzopen/waresshow/moreInfo"])self.detailParts[@"more"]=json;else return;
        if(self.detailParts[@"base"]&&self.detailParts[@"more"]){JSValue *p=[self.js[@"ZZCore"]invokeMethod:@"normalizeProduct" withArguments:@[@{@"id":ident,@"item":a[@"item"],@"base":self.detailParts[@"base"],@"more":self.detailParts[@"more"]}]];[self.run invokeMethod:@"detail" withArguments:@[p,a[@"token"]]];[self pump];}
    }
}
- (void)pump {
    NSDictionary *next=[[self.run invokeMethod:@"next" withArguments:@[]]toDictionary];@synchronized(self){self.action=next;}
    if(!next){[self prepareAllWebViews];NSString *state=[self snapshot][@"state"];if([@[@"stopped",@"finished"]containsObject:state]||([state isEqual:@"hit"]&&![[self.mutations invokeMethod:@"pending" withArguments:@[]]toBool]))ZZStopCollector();[self changed];return;}
    self.uiAttempts=0;NSString *type=next[@"type"];self.pendingFilterResponse=nil;
    self.filterDriver=[type isEqual:@"filters"]?[[ZZFilterDriver alloc]initWithConfig:self.config fields:next[@"applyFields"]?:@[@"capacities",@"conditions"]]:nil;
    self.pageWait=[type isEqual:@"nextPage"]?[self.js[@"ZZCore"][@"PageWait"]constructWithArguments:@[next[@"token"],next[@"page"],@(NSProcessInfo.processInfo.systemUptime*1000)]]:nil;
    if([type isEqual:@"nextPage"])ZZResetPagination([next[@"page"]unsignedIntegerValue]);
    if(self.pageWait&&[[self snapshot][@"waitingResponse"]boolValue])[self.pageWait invokeMethod:@"requestStarted" withArguments:@[next[@"page"],next[@"token"]]];
    if([type isEqual:@"open"])[self.detailParts removeAllObjects];[self prepareAllWebViews];[self changed];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,350*NSEC_PER_MSEC),dispatch_get_main_queue(),^{[self drive:next];});
    NSInteger seconds=[type isEqual:@"filters"]?60:25;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,seconds*NSEC_PER_SEC),dispatch_get_main_queue(),^{if(![self isCurrent:next]||[type isEqual:@"nextPage"])return;
        NSString *reason=[type isEqual:@"open"]?@"隐藏采集超时，未弹出详情；请导出诊断":@"等待页面或接口超时，请查看诊断";
        if([type isEqual:@"filters"]){NSDictionary *d=self.filterDriver.diagnostics;reason=self.filterDriver.complete?@"筛选界面操作已完成，但未收到可确认的搜索响应，请导出诊断":[NSString stringWithFormat:@"筛选未完成：%@／%@；请导出诊断",d[@"field"]?:@"",d[@"stageName"]?:@""];}
        [self.run invokeMethod:@"failed" withArguments:@[reason,next[@"token"]]];[self log:reason];[self pump];});
}
- (void)drive:(NSDictionary *)a {
    [self checkTaskBudget];
    if(![self isCurrent:a])return;if(UIApplication.sharedApplication.applicationState!=UIApplicationStateActive){[self pause:@"转转离开前台，任务已暂停"];return;}NSString *type=a[@"type"];
    if([type isEqual:@"search"]){if(!ZZSubmitSearch(a[@"keyword"])){if(++self.uiAttempts<16)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,650*NSEC_PER_MSEC),dispatch_get_main_queue(),^{[self drive:a];});else[self pause:[NSString stringWithFormat:@"%@的搜索入口暂未识别，设置已保留；请导出诊断",ZZSearchSurface()]];}}
    else if([type isEqual:@"filters"]){[self prepareAllWebViews];[self.filterDriver step];if(self.filterDriver.complete&&self.pendingFilterResponse){NSDictionary *pending=self.pendingFilterResponse;self.pendingFilterResponse=nil;[self observeJSON:pending[@"json"] metadata:pending[@"metadata"] webView:nil];if(![self isCurrent:a])return;}dispatch_after(dispatch_time(DISPATCH_TIME_NOW,650*NSEC_PER_MSEC),dispatch_get_main_queue(),^{if([self isCurrent:a])[self drive:a];});}
    else if([type isEqual:@"open"]){BOOL safe=[[self.js[@"ZZCore"]invokeMethod:@"safeProductURL" withArguments:@[a[@"item"][@"jumpUrl"]?:@"",a[@"item"][@"id"]]]toBool];if(!safe||!ZZLoadCollector(a[@"item"],NO))[self pause:@"隐藏详情采集尚未建立；请手动打开一件商品后返回列表，再继续。不会自动弹出详情"];}
    else if([type isEqual:@"nextPage"]){
        NSString *decision=[[self.pageWait invokeMethod:@"poll" withArguments:@[@(NSProcessInfo.processInfo.systemUptime*1000),@(ZZSearchIsLoading())]]toString];
        if([decision isEqual:@"timeout"]){[self pause:self.pageWait[@"requestSeen"].toBool?@"下一页请求在60秒内未返回，队列已保留":@"60秒内未观察到下一页请求；请导出翻页诊断核对加载控件"];return;}
        if([decision isEqual:@"scroll"]){BOOL accepted=ZZScrollSearchList();NSDictionary *info=ZZSearchDiagnostics()[@"pagination"];NSString *status=info[@"status"];
            if([status isEqual:@"noMore"]){[self.run invokeMethod:@"endOfList" withArguments:@[a[@"token"]]];[self log:@"列表加载控件已确认没有更多商品"];[self pump];return;}
            if(!accepted){[self pause:[status isEqual:@"missingList"]?@"商品列表滚动入口未识别，队列已保留":@"列表已到底部，但上拉加载控件未确认；任务已暂停，请导出翻页诊断以继续适配"];return;}
            if([status isEqual:@"triggered"])[self log:[NSString stringWithFormat:@"第%@页：已调用%@的加载入口，等待实际搜索请求",a[@"page"],info[@"footer"][@"class"]]];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,1200*NSEC_PER_MSEC),dispatch_get_main_queue(),^{if([self isCurrent:a])[self drive:a];});
    }
    else if([type isEqual:@"favorite"]){if(!self.detailWeb){[self pause:@"隐藏收藏页面未建立"];return;}if(![[self.mutations invokeMethod:@"begin" withArguments:@[a[@"id"],a[@"token"]]]toBool]){[self pause:@"上一笔收藏尚未返回，已暂停"];return;}
        [self.detailWeb evaluateJavaScript:[NSString stringWithFormat:@"window.ZZWeb?window.ZZWeb.favorite(%@):({ok:false,reason:'收藏桥接未建立'})",[self jsonString:a[@"id"]]] completionHandler:^(id result,NSError *error){
            BOOL refused=!error&&[result isKindOfClass:NSDictionary.class]&&[result[@"ok"]isEqual:@NO];if(refused)[self.mutations invokeMethod:@"complete" withArguments:@[a[@"id"],a[@"token"]]];
            if(![self isCurrent:a])return;if(error||refused||![result isKindOfClass:NSDictionary.class]){[self.run invokeMethod:@"failed" withArguments:@[@"收藏入口未确认，改为读取状态",a[@"token"]]];[self pump];}
        }];
    }else if([type isEqual:@"verify"]){if(!ZZLoadCollector(@{},YES)){[self.run invokeMethod:@"verified" withArguments:@[NSNull.null,a[@"token"]]];[self pump];}}
    else if([type isEqual:@"back"]){[self.detailWeb stopLoading];[self.run invokeMethod:@"returned" withArguments:@[a[@"token"]]];[self pump];}
}
- (NSString *)jsonString:(id)value {return [[NSString alloc]initWithData:[NSJSONSerialization dataWithJSONObject:value?:NSNull.null options:NSJSONWritingFragmentsAllowed error:nil]encoding:NSUTF8StringEncoding]?:@"null";}
- (void)prepareAllWebViews {for(WKWebView *web in self.webViews){[self installWebView:web];[web evaluateJavaScript:[NSString stringWithFormat:@"window.ZZWeb&&window.ZZWeb.setContext(%@)",[self jsonString:[self context]]]completionHandler:nil];}}
- (void)installWebView:(WKWebView *)web {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self installWebView:web];});return;}[self.webViews addObject:web];WKUserContentController *ucc=web.configuration.userContentController;const void *key=sel_registerName("zzPickerWebHandlerInstalled");
    if(!objc_getAssociatedObject(ucc,key)){@try{[ucc addScriptMessageHandler:self name:@"zzPicker"];objc_setAssociatedObject(ucc,key,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}@catch(NSException *exception){(void)exception;[self log:@"WebKit消息通道冲突"];return;}}
    NSArray *previous=ucc.userScripts;[ucc removeAllUserScripts];for(WKUserScript *s in previous)if(![s.source hasPrefix:@"/*ZZPickerV1*/"])[ucc addUserScript:s];
    NSString *source=[NSString stringWithFormat:@"/*ZZPickerV1*/window.__zzPickerInitialContext=%@;\n%@",[self jsonString:[self context]],ZZSource(ZZWebBytes,ZZWebLength)];[ucc addUserScript:[[WKUserScript alloc]initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
    if(web.tag!=ZZPickerOwnViewTag&&!self.borrowedConfiguration){self.borrowedConfiguration=[web.configuration copy];self.borrowedUserAgent=web.customUserAgent;}
}
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    (void)controller;if(![message.body isKindOfClass:NSDictionary.class])return;WKWebView *web=message.webView;WKFrameInfo *frame=message.frameInfo;
    if(!ZZTrustedBridgeFrame(web.URL,frame.request.URL,frame.securityOrigin.protocol,frame.securityOrigin.host,frame.mainFrame)||(frame.securityOrigin.port!=0&&frame.securityOrigin.port!=443))return;NSDictionary *m=message.body;
    if([m[@"kind"]isEqual:@"ready"]){[web evaluateJavaScript:[NSString stringWithFormat:@"window.ZZWeb&&window.ZZWeb.setContext(%@)",[self jsonString:[self context]]]completionHandler:nil];return;}
    if([m[@"kind"]isEqual:@"request"])[self observeRequest:m];else if([m[@"kind"]isEqual:@"failure"])[self observeFailure:m];else if([m[@"kind"]isEqual:@"response"]&&[m[@"data"]isKindOfClass:NSDictionary.class])[self observeJSON:m[@"data"]metadata:m webView:web];
}
@end
__attribute__((constructor)) static void ZZEntry(void) {
    @autoreleasepool {
        if(![NSBundle.mainBundle.bundleIdentifier isEqual:@"com.wuba.zhuanzhuan"])return;
        const void *key=sel_registerName("zzPickerProcessInstalledV1");
        @synchronized(NSProcessInfo.processInfo){if(objc_getAssociatedObject(NSProcessInfo.processInfo,key))return;objc_setAssociatedObject(NSProcessInfo.processInfo,key,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
        SEL initializer=@selector(initWithFrame:configuration:);
        ZZReplaceMethod(WKWebView.class,initializer,@"web",^IMP(IMP original){
            return imp_implementationWithBlock(^id(WKWebView *object,CGRect frame,WKWebViewConfiguration *configuration){
                id web=((id(*)(id,SEL,CGRect,id))original)(object,initializer,frame,configuration);[[ZZPicker shared]installWebView:web];return web;
            });
        });
        SEL load=@selector(loadRequest:);
        ZZReplaceMethod(WKWebView.class,load,@"web",^IMP(IMP original){
            return imp_implementationWithBlock(^id(WKWebView *web,NSURLRequest *request){[[ZZPicker shared]installWebView:web];return ((id(*)(id,SEL,id))original)(web,load,request);});
        });
        ZZInstallNetworkHooks();
        dispatch_async(dispatch_get_main_queue(),^{[[ZZPicker shared]install];});
    }
}
