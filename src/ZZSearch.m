#import "ZZPicker.h"
#import "ZZRuntime.h"

UIWindow *ZZAppWindow(void) {
    UIWindow *fallback=nil;
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:UIWindowScene.class]||scene.activationState!=UISceneActivationStateForegroundActive)continue;
        for(UIWindow *w in ((UIWindowScene *)scene).windows){
            if(w.hidden||w.alpha<0.1||w.windowLevel!=UIWindowLevelNormal||!w.rootViewController)continue;
            if(w.isKeyWindow)return w;fallback=w;
        }
    }return fallback;
}
static UIViewController *ZZTop(UIViewController *v) {
    while(v){
        if(v.presentedViewController&&!v.presentedViewController.isBeingDismissed){v=v.presentedViewController;continue;}
        if([v isKindOfClass:UINavigationController.class]){v=((UINavigationController *)v).visibleViewController;continue;}
        if([v isKindOfClass:UITabBarController.class]){v=((UITabBarController *)v).selectedViewController;continue;}
        break;
    }return v;
}
UIViewController *ZZTopController(void){return ZZTop(ZZAppWindow().rootViewController);}
static BOOL ZZVisible(UIView *v) {
    if(!v.window||v.hidden||v.alpha<0.1||v.bounds.size.width<=0||v.bounds.size.height<=0)return NO;
    for(UIView *p=v.superview;p;p=p.superview)if(p.hidden||p.alpha<0.1)return NO;
    return CGRectIntersectsRect([v convertRect:v.bounds toView:v.window],v.window.bounds);
}
static void ZZVisit(UIView *v,void (^block)(UIView *)) {
    if(!v||v.tag==ZZPickerOwnViewTag||v.hidden||v.alpha<0.1)return;
    block(v);if([v isKindOfClass:WKWebView.class])return;
    for(UIView *child in v.subviews)ZZVisit(child,block);
}
static NSString *ZZText(UIView *v) {
    NSMutableArray *parts=[NSMutableArray new];
    ZZVisit(v,^(UIView *x){if([x isKindOfClass:UILabel.class]){NSString *s=((UILabel *)x).text;if(s.length)[parts addObject:s];}if(x.accessibilityIdentifier.length)[parts addObject:x.accessibilityIdentifier];});
    return [[parts componentsJoinedByString:@" "]stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
}
static NSString *ZZCanonicalText(NSString *text) {
    return [[text?:@"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]lowercaseString];
}
static NSArray<NSString *> *ZZViewLabels(UIView *view) {
    NSMutableOrderedSet *labels=[NSMutableOrderedSet new];
    if([view isKindOfClass:UILabel.class]){UILabel *label=(id)view;if(label.text.length)[labels addObject:label.text];if(label.attributedText.string.length)[labels addObject:label.attributedText.string];}
    if([view isKindOfClass:UIButton.class]){UIButton *button=(id)view;if(button.currentTitle.length)[labels addObject:button.currentTitle];if(button.currentAttributedTitle.string.length)[labels addObject:button.currentAttributedTitle.string];}
    if(view.accessibilityLabel.length)[labels addObject:view.accessibilityLabel];return labels.array;
}
static BOOL ZZActivateSearchEntry(void);
static NSMutableArray *ZZActivationHistory;
static NSDictionary *ZZActivationViewState(UIView *view) {
    NSMutableDictionary *state=[@{@"class":NSStringFromClass(view.class),@"attached":@(view.window!=nil),@"frame":NSStringFromCGRect([view convertRect:view.bounds toView:view.window]),@"accessibilitySelected":@((view.accessibilityTraits&UIAccessibilityTraitSelected)!=0)} mutableCopy];
    NSMutableArray *targets=[NSMutableArray new];
    if([view isKindOfClass:UIControl.class]){
        UIControl *control=(id)view;state[@"selected"]=@(control.selected);state[@"enabled"]=@(control.enabled);state[@"highlighted"]=@(control.highlighted);state[@"events"]=@(control.allControlEvents);
        for(id target in control.allTargets){if(targets.count>=16)break;for(NSNumber *event in @[@(UIControlEventTouchUpInside),@(UIControlEventPrimaryActionTriggered)]){NSArray *actions=[control actionsForTarget:target forControlEvent:event.unsignedIntegerValue];if(actions.count)[targets addObject:@{@"class":NSStringFromClass([target class]),@"event":event,@"actions":[actions subarrayWithRange:NSMakeRange(0,MIN(actions.count,8))]}];}}
    }
    state[@"targets"]=targets;NSMutableArray *ancestors=[NSMutableArray new];
    for(UIView *parent=view.superview;parent&&ancestors.count<8;parent=parent.superview){NSMutableDictionary *entry=[@{@"class":NSStringFromClass(parent.class),@"frame":NSStringFromCGRect([parent convertRect:parent.bounds toView:parent.window])}mutableCopy];
        if([parent isKindOfClass:UIControl.class])entry[@"selected"]=@(((UIControl *)parent).selected);
        if([parent isKindOfClass:UICollectionViewCell.class])entry[@"selected"]=@(((UICollectionViewCell *)parent).selected);
        if([parent isKindOfClass:UITableViewCell.class])entry[@"selected"]=@(((UITableViewCell *)parent).selected);
        if([parent isKindOfClass:UICollectionView.class])entry[@"delegate"]=((UICollectionView *)parent).delegate?NSStringFromClass([((UICollectionView *)parent).delegate class]):@"";
        if([parent isKindOfClass:UITableView.class])entry[@"delegate"]=((UITableView *)parent).delegate?NSStringFromClass([((UITableView *)parent).delegate class]):@"";
        [ancestors addObject:entry];
    }state[@"ancestors"]=ancestors;
    NSMutableArray *gestures=[NSMutableArray new];for(UIGestureRecognizer *gesture in view.gestureRecognizers)[gestures addObject:@{@"class":NSStringFromClass(gesture.class),@"state":@(gesture.state),@"enabled":@(gesture.enabled)}];state[@"gestures"]=gestures;return state;
}
static NSArray *ZZActivationStates(NSArray<UIView *> *views) {NSMutableArray *states=[NSMutableArray new];for(UIView *view in views){if(states.count>=8)break;[states addObject:ZZActivationViewState(view)];}return states;}
static void ZZRecordActivation(NSString *label,NSArray<UIView *> *views,NSArray *before,BOOL accepted) {
    NSMutableArray *matches=[NSMutableArray new];for(NSUInteger i=0;i<MIN(views.count,8);i++){NSMutableDictionary *match=[before[i]mutableCopy];match[@"before"]=before[i];match[@"after"]=ZZActivationViewState(views[i]);[matches addObject:match];}
    NSDictionary *entry=@{@"label":label?:@"",@"matchCount":@(views.count),@"matches":matches,@"activationAccepted":accepted?@YES:@NO};if(!ZZActivationHistory)ZZActivationHistory=[NSMutableArray new];if(![ZZActivationHistory.lastObject isEqual:entry]){[ZZActivationHistory addObject:entry];if(ZZActivationHistory.count>16)[ZZActivationHistory removeObjectAtIndex:0];}
}
BOOL ZZSubmitSearch(NSString *keyword) {
    UIView *root=ZZAppWindow();__block UISearchBar *bar=nil;__block UITextField *field=nil;
    ZZVisit(root,^(UIView *v){
        if(!ZZVisible(v))return;
        if([v isKindOfClass:UISearchBar.class])bar=(UISearchBar *)v;
        if([v isKindOfClass:UITextField.class]){
            UITextField *f=(UITextField *)v;NSString *hint=[NSString stringWithFormat:@"%@ %@",f.placeholder?:@"",f.accessibilityLabel?:@""];
            if([hint containsString:@"搜索"]||[hint containsString:@"搜你想要"]||f.returnKeyType==UIReturnKeySearch||[ZZCanonicalText(f.text)isEqual:ZZCanonicalText(keyword)]||[ZZCanonicalText(f.placeholder)isEqual:ZZCanonicalText(keyword)])field=f;
        }
    });
    if(bar&&[bar.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]){
        bar.text=keyword;if([bar.delegate respondsToSelector:@selector(searchBar:textDidChange:)])[bar.delegate searchBar:bar textDidChange:keyword];[bar.delegate searchBarSearchButtonClicked:bar];[bar resignFirstResponder];return YES;
    }
    if(field&&field.enabled&&field.canBecomeFirstResponder){
        [field becomeFirstResponder];field.text=keyword;[field sendActionsForControlEvents:UIControlEventEditingChanged];
        if([field.delegate respondsToSelector:@selector(textFieldShouldReturn:)]){[field.delegate textFieldShouldReturn:field];[field resignFirstResponder];return YES;}
        BOOL hasAction=NO;for(id target in field.allTargets)if([field actionsForTarget:target forControlEvent:UIControlEventEditingDidEndOnExit].count)hasAction=YES;
        if(hasAction){[field sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];[field resignFirstResponder];return YES;}
    }
    ZZActivateSearchEntry();return NO;
}
BOOL ZZOpenNativeProduct(NSDictionary *item) {
    NSMutableArray<UIView *> *matches=[NSMutableArray new],*idMatches=[NSMutableArray new];
    NSString *title=item[@"title"]?:@"",*ident=item[@"id"]?:@"",*price=item[@"price"]?:@"";
    ZZVisit(ZZAppWindow(),^(UIView *v){
        if((![v isKindOfClass:UICollectionViewCell.class]&&![v isKindOfClass:UITableViewCell.class])||!ZZVisible(v))return;
        NSString *text=ZZText(v);
        if(ident.length&&[text containsString:ident])[idMatches addObject:v];
        if(title.length&&[text containsString:title]&&price.length&&[text containsString:price])[matches addObject:v];
    });
    NSArray *selected=idMatches.count?idMatches:matches;if(selected.count!=1)return NO;
    UIView *cell=selected.firstObject,*parent=cell.superview;
    while(parent&&![parent isKindOfClass:UICollectionView.class]&&![parent isKindOfClass:UITableView.class])parent=parent.superview;
    if([parent isKindOfClass:UICollectionView.class]){
        UICollectionView *cv=(UICollectionView *)parent;NSIndexPath *p=[cv indexPathForCell:(UICollectionViewCell *)cell];
        if(p&&[cv.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]){[cv selectItemAtIndexPath:p animated:NO scrollPosition:UICollectionViewScrollPositionNone];[cv.delegate collectionView:cv didSelectItemAtIndexPath:p];return YES;}
    }else if([parent isKindOfClass:UITableView.class]){
        UITableView *tv=(UITableView *)parent;NSIndexPath *p=[tv indexPathForCell:(UITableViewCell *)cell];
        if(p&&[tv.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]){[tv selectRowAtIndexPath:p animated:NO scrollPosition:UITableViewScrollPositionNone];[tv.delegate tableView:tv didSelectRowAtIndexPath:p];return YES;}
    }return NO;
}
static BOOL ZZPageTriggered;
static NSUInteger ZZPageNumber;
static NSDictionary *ZZPageInfo;
static NSMutableArray *ZZPageHistory;
void ZZResetPagination(NSUInteger page) {ZZPageTriggered=NO;ZZPageNumber=page;ZZPageInfo=nil;if(!page)ZZPageHistory=nil;}
static UIScrollView *ZZPagingList(void) {
    __block UIScrollView *best=nil;__block CGFloat area=0;UIWindow *window=ZZAppWindow();
    ZZVisit(window,^(UIView *v){
        if((![v isKindOfClass:UITableView.class]&&![v isKindOfClass:UICollectionView.class])||!ZZVisible(v))return;
        UIScrollView *s=(id)v;CGFloat a=s.bounds.size.width*s.bounds.size.height;
        if(s.scrollEnabled&&s.bounds.size.width>=window.bounds.size.width*0.5&&s.bounds.size.height>=180&&a>area){area=a;best=s;}
    });return best;
}
static void ZZVisitFooterViews(UIView *root,void (^block)(UIView *)) {
    for(UIView *v in root.subviews){
        if(v.tag==ZZPickerOwnViewTag||[v isKindOfClass:UITableViewCell.class]||[v isKindOfClass:UICollectionViewCell.class]||[v isKindOfClass:UIScrollView.class])continue;
        block(v);ZZVisitFooterViews(v,block);
    }
}
static NSNumber *ZZFooterState(UIView *footer,UIScrollView *list) {
    Class cls=NSClassFromString(@"MJRefreshFooter");if(!cls||![footer isKindOfClass:cls])return nil;
    @try{if([footer valueForKey:@"scrollView"]!=list)return nil;id state=[footer valueForKey:@"state"];return [state isKindOfClass:NSNumber.class]?state:nil;}@catch(NSException *exception){(void)exception;return nil;}
}
static NSArray<UIView *> *ZZPagingFooters(UIScrollView *list) {
    NSMutableArray *footers=[NSMutableArray new];ZZVisitFooterViews(list,^(UIView *v){if(ZZFooterState(v,list))[footers addObject:v];});return footers;
}
static NSDictionary *ZZPagingMetrics(UIScrollView *list) {
    if(!list)return @{};NSMutableArray *footers=[NSMutableArray new];
    ZZVisitFooterViews(list,^(UIView *v){NSString *name=NSStringFromClass(v.class);if(footers.count>=12||(![name.lowercaseString containsString:@"footer"]&&![name.lowercaseString containsString:@"refresh"]))return;
        [footers addObject:@{@"class":name,@"frame":NSStringFromCGRect(v.frame),@"hidden":@(v.hidden),@"state":ZZFooterState(v,list)?:NSNull.null}];
    });
    return @{@"class":NSStringFromClass(list.class),@"frame":NSStringFromCGRect([list convertRect:list.bounds toView:list.window]),@"offsetY":@(list.contentOffset.y),@"contentHeight":@(list.contentSize.height),@"viewportHeight":@(list.bounds.size.height),@"bottomY":@(MAX(-list.adjustedContentInset.top,list.contentSize.height-list.bounds.size.height+list.adjustedContentInset.bottom)),@"footers":footers};
}
static BOOL ZZPageRecord(NSString *status,UIScrollView *list,UIView *footer,BOOL accepted) {
    NSMutableDictionary *info=[ZZPagingMetrics(list)mutableCopy];info[@"status"]=status;info[@"page"]=@(ZZPageNumber);
    if(footer)info[@"footer"]=@{@"class":NSStringFromClass(footer.class),@"state":ZZFooterState(footer,list)?:NSNull.null};
    ZZPageInfo=info;if(!ZZPageHistory)ZZPageHistory=[NSMutableArray new];if(![ZZPageHistory.lastObject isEqual:info]){[ZZPageHistory addObject:info];if(ZZPageHistory.count>16)[ZZPageHistory removeObjectAtIndex:0];}return accepted;
}
BOOL ZZSearchIsLoading(void) {
    __block BOOL loading=NO;
    ZZVisit(ZZAppWindow(),^(UIView *v){if([v isKindOfClass:UIActivityIndicatorView.class]&&ZZVisible(v)&&((UIActivityIndicatorView *)v).isAnimating)loading=YES;});
    UIScrollView *list=ZZPagingList();for(UIView *footer in ZZPagingFooters(list)){NSInteger state=ZZFooterState(footer,list).integerValue;if(state==3||state==4)loading=YES;}
    return loading;
}
BOOL ZZScrollSearchList(void) {
    UIScrollView *list=ZZPagingList();if(!list)return ZZPageRecord(@"missingList",nil,nil,NO);
    CGFloat bottom=MAX(-list.adjustedContentInset.top,list.contentSize.height-list.bounds.size.height+list.adjustedContentInset.bottom);
    if(list.contentOffset.y<bottom-2){CGFloat y=MIN(list.contentOffset.y+MAX(200,list.bounds.size.height*0.8),bottom);[list setContentOffset:CGPointMake(list.contentOffset.x,y) animated:YES];return ZZPageRecord(@"scrolling",list,nil,YES);}
    NSArray *footers=ZZPagingFooters(list);if(footers.count>1)return ZZPageRecord(@"ambiguousFooter",list,nil,NO);
    UIView *footer=footers.firstObject;NSInteger state=ZZFooterState(footer,list).integerValue;
    // MJRefresh distinguishes idle, active (3/4), and exhausted (5); never reset exhaustion.
    if(state==5)return ZZPageRecord(@"noMore",list,footer,NO);
    if(state==3||state==4)return ZZPageRecord(@"loading",list,footer,YES);
    if(ZZPageTriggered)return ZZPageRecord(@"waitingResponse",list,footer,YES);
    if(!footer||footer.hidden||!(state==1||state==2))return ZZPageRecord(@"unsupportedFooter",list,footer,NO);
    ZZPageTriggered=YES;
    if(!ZZInvokeRegisteredAction(footer,NSSelectorFromString(@"beginRefreshing"),footer)){ZZPageTriggered=NO;return ZZPageRecord(@"unsupportedFooter",list,footer,NO);}
    return ZZPageRecord(@"triggered",list,footer,YES);
}


static UIControlEvents ZZTapEvent(UIControl *control) {
    for(NSNumber *event in @[@(UIControlEventTouchUpInside),@(UIControlEventPrimaryActionTriggered)])
        for(id target in control.allTargets)if([control actionsForTarget:target forControlEvent:event.unsignedIntegerValue].count)return event.unsignedIntegerValue;
    return 0;
}
static UIView *ZZActionView(UIView *view) {
    // Capacity cells are embedded display content; their outer button owns the selection action.
    Class wrapper=NSClassFromString(@"ZZLabelViewButton");
    for(UIView *v=view;v&&![v isKindOfClass:UIScrollView.class]&&![v isKindOfClass:UIWindow.class];v=v.superview)
        if(wrapper&&[v isKindOfClass:wrapper])return v;
    for(UIView *v=view;v&&![v isKindOfClass:UIWindow.class];v=v.superview){
        if([v isKindOfClass:UIControl.class]&&ZZTapEvent((UIControl *)v))return v;
        if([v isKindOfClass:UITableViewCell.class]||[v isKindOfClass:UICollectionViewCell.class])return v;
        for(UIGestureRecognizer *g in v.gestureRecognizers)if([g isKindOfClass:UITapGestureRecognizer.class]&&g.enabled)return v;
    }return view;
}
static BOOL ZZActivateView(UIView *view) {
    if([view isKindOfClass:UIControl.class]){UIControl *c=(UIControl *)view;UIControlEvents event=ZZTapEvent(c);if(c.enabled&&event){[c sendActionsForControlEvents:event];return YES;}}
    UIView *parent=view.superview;while(parent&&![parent isKindOfClass:UITableView.class]&&![parent isKindOfClass:UICollectionView.class])parent=parent.superview;
    if([view isKindOfClass:UITableViewCell.class]&&[parent isKindOfClass:UITableView.class]){UITableView *table=(UITableView *)parent;NSIndexPath *p=[table indexPathForCell:(id)view];if(p&&[table.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]){[table selectRowAtIndexPath:p animated:NO scrollPosition:UITableViewScrollPositionNone];[table.delegate tableView:table didSelectRowAtIndexPath:p];return YES;}}
    if([view isKindOfClass:UICollectionViewCell.class]&&[parent isKindOfClass:UICollectionView.class]){UICollectionView *cv=(UICollectionView *)parent;NSIndexPath *p=[cv indexPathForCell:(id)view];if(p&&[cv.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]){[cv selectItemAtIndexPath:p animated:NO scrollPosition:UICollectionViewScrollPositionNone];[cv.delegate collectionView:cv didSelectItemAtIndexPath:p];return YES;}}
    if([view accessibilityActivate])return YES;
    // Use only an action actually registered on the uniquely identified semantic entry.
    for(UIGestureRecognizer *gesture in view.gestureRecognizers){
        if(![gesture isKindOfClass:UITapGestureRecognizer.class]||!gesture.enabled)continue;
        @try{for(id entry in [gesture valueForKey:@"_targets"]){
            Ivar targetIvar=class_getInstanceVariable(object_getClass(entry),"_target"),actionIvar=class_getInstanceVariable(object_getClass(entry),"_action");
            if(!targetIvar||!actionIvar||strcmp(ivar_getTypeEncoding(actionIvar),":"))continue;
            id target=object_getIvar(entry,targetIvar);SEL action=NULL;memcpy(&action,(__bridge const void *)entry+ivar_getOffset(actionIvar),sizeof(action));
            if(action&&ZZInvokeRegisteredAction(target,action,gesture))return YES;
        }}@catch(NSException *exception){(void)exception;}
    }return NO;
}
BOOL ZZActivateText(NSString *label,BOOL prefix,BOOL topOnly) {
    NSMutableOrderedSet<UIView *> *matches=[NSMutableOrderedSet new];UIWindow *window=ZZAppWindow();
    ZZVisit(window,^(UIView *v){
        if(!ZZVisible(v))return;
        CGRect frame=[v convertRect:v.bounds toView:window];if(topOnly&&CGRectGetMinY(frame)>window.safeAreaInsets.top+220)return;
        for(NSString *candidate in ZZViewLabels(v)){NSString *text=ZZCanonicalText(candidate),*wanted=ZZCanonicalText(label);
            if(text.length&&wanted.length&&(prefix?[text hasPrefix:wanted]:[text isEqual:wanted]))[matches addObject:ZZActionView(v)];
        }
    });
    NSArray *before=ZZActivationStates(matches.array);BOOL accepted=matches.count==1&&ZZActivateView(matches.firstObject);ZZRecordActivation(label,matches.array,before,accepted);return accepted;
}
static BOOL ZZActivateSearchEntry(void) {
    UIWindow *window=ZZAppWindow();NSMutableOrderedSet<UIView *> *matches=[NSMutableOrderedSet new];
    ZZVisit(window,^(UIView *view){if(!ZZVisible(view))return;CGRect frame=[view convertRect:view.bounds toView:window];if(CGRectGetMidY(frame)>window.safeAreaInsets.top+72||CGRectGetMaxY(frame)<window.safeAreaInsets.top)return;
        for(NSString *label in ZZViewLabels(view)){NSString *text=ZZCanonicalText(label);BOOL query=[text hasPrefix:@"iphone"]||[text hasPrefix:@"ipad"]||[text hasPrefix:@"苹果 iphone"];BOOL prompt=[text hasPrefix:@"搜你想要"]||[text hasPrefix:@"搜索商品"];
            if(query||prompt)[matches addObject:ZZActionView(view)];
        }
    });
    // A standalone 搜索 button may submit a rotating hot term before our keyword is entered.
    NSArray *before=ZZActivationStates(matches.array);BOOL accepted=matches.count==1&&ZZActivateView(matches.firstObject);ZZRecordActivation(@"search-editor-entry",matches.array,before,accepted);return accepted;
}
NSString *ZZSearchSurface(void) {
    __block BOOL list=NO;
    ZZVisit(ZZAppWindow(),^(UIView *v){if(ZZVisible(v)&&[v isKindOfClass:UILabel.class]&&[@[@"容量",@"成色"]containsObject:((UILabel *)v).text])list=YES;});
    return list?@"商品列表":@"首页/搜索入口";
}
NSDictionary *ZZSearchDiagnostics(void) {
    NSMutableArray *entries=[NSMutableArray new];UIWindow *window=ZZAppWindow();
    ZZVisit(window,^(UIView *v){if(entries.count>=100||!ZZVisible(v)||[v convertRect:v.bounds toView:window].origin.y>window.safeAreaInsets.top+440)return;
        if([v isKindOfClass:UITextField.class]){UITextField *f=(id)v;[entries addObject:@{@"class":NSStringFromClass(v.class),@"frame":NSStringFromCGRect([v convertRect:v.bounds toView:window]),@"placeholder":f.placeholder?:@"",@"editable":@(f.enabled&&f.canBecomeFirstResponder)}];}
        else if(v.gestureRecognizers.count||[v isKindOfClass:UIControl.class])[entries addObject:@{@"class":NSStringFromClass(v.class),@"frame":NSStringFromCGRect([v convertRect:v.bounds toView:window]),@"gestures":@(v.gestureRecognizers.count)}];
    });return @{@"surface":ZZSearchSurface(),@"entries":entries,@"activationHistory":[ZZActivationHistory copy]?:@[],@"pagination":ZZPageInfo?:@{},@"paginationHistory":[ZZPageHistory copy]?:@[],@"pagingList":ZZPagingMetrics(ZZPagingList())};
}
@interface ZZFilterDriver ()
@property(nonatomic,copy) NSDictionary *config;
@property(nonatomic,copy) NSArray<NSString *> *fields;
@property(nonatomic) NSUInteger group;
@property(nonatomic) NSUInteger stage;
@property(nonatomic) NSUInteger option;
@property(nonatomic) NSUInteger waits;
@end
@implementation ZZFilterDriver
- (instancetype)initWithConfig:(NSDictionary *)config fields:(NSArray<NSString *> *)fields {if((self=[super init])){_config=[config copy];_fields=[fields copy];}return self;}
- (BOOL)willCommit {return self.group+1==self.fields.count&&self.stage==3;}
- (BOOL)complete {return self.group>=self.fields.count;}
- (NSDictionary *)diagnostics {NSArray *stages=@[@"打开面板",@"重置",@"选择选项",@"确认",@"等待面板关闭"];return @{@"fields":self.fields?:@[],@"field":self.complete?@"":([self.fields[self.group]isEqual:@"capacities"]?@"容量":@"成色"),@"group":@(self.group),@"stage":@(self.stage),@"stageName":self.stage<stages.count?stages[self.stage]:@"未知",@"option":@(self.option),@"complete":@(self.complete)};}
- (void)step {
    if(self.complete)return;
    NSString *key=self.fields[self.group];BOOL capacity=[key isEqual:@"capacities"];NSString *label=capacity?@"容量":@"成色";
    NSArray *values=self.config[key];
    if(self.stage==0){if(ZZActivateText(label,YES,NO))self.stage=1;}
    else if(self.stage==1){if(ZZActivateText(@"重置",NO,NO)){self.stage=2;self.option=0;}}
    else if(self.stage==2){
        if(self.option>=values.count){self.stage=3;return;}
        NSString *value=values[self.option];
        if(capacity){NSInteger gb=value.integerValue;value=gb>=1024&&gb%1024==0?[NSString stringWithFormat:@"%ldT",(long)(gb/1024)]:[NSString stringWithFormat:@"%ldG",(long)gb];}
        if(ZZActivateText(value,NO,NO))self.option++;
    }else if(self.stage==3){if(ZZActivateText(@"确定",NO,NO)){if(self.group+1==self.fields.count){self.group++;self.stage=0;}else{self.stage=4;self.waits=0;}}}
    else if(++self.waits>=2){self.group++;self.stage=0;}
}
@end
