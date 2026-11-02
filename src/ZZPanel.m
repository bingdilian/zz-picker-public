#import "ZZPicker.h"
static UIColor *ZZPanelRed(void){return [UIColor colorWithRed:0.91 green:0.18 blue:0.24 alpha:1];}
static UILabel *ZZLabel(NSString *text,CGFloat size,BOOL bold){UILabel *l=[UILabel new];l.text=text;l.numberOfLines=0;l.font=[[UIFontMetrics defaultMetrics]scaledFontForFont:[UIFont systemFontOfSize:size weight:bold?UIFontWeightSemibold:UIFontWeightRegular]];l.adjustsFontForContentSizeCategory=YES;l.textColor=UIColor.labelColor;return l;}
@interface ZZTaskPanel : UIView
@property(nonatomic,strong) UIView *shade;
@property(nonatomic,strong) UIScrollView *card;
@property(nonatomic,strong) UIStackView *stack;
@property(nonatomic,strong) UIButton *mini;
@property(nonatomic) BOOL collapsed;
@end
static ZZTaskPanel *ZZPanel;
@implementation ZZTaskPanel
- (instancetype)initWithFrame:(CGRect)frame {
    if((self=[super initWithFrame:frame])){self.tag=ZZPickerOwnViewTag;self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;self.shade=[UIView new];self.shade.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.18];[self addSubview:self.shade];self.card=[UIScrollView new];self.card.backgroundColor=UIColor.systemBackgroundColor;self.card.layer.cornerRadius=22;self.card.showsVerticalScrollIndicator=YES;[self addSubview:self.card];self.mini=[UIButton buttonWithType:UIButtonTypeSystem];self.mini.layer.cornerRadius=18;self.mini.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];self.mini.backgroundColor=UIColor.labelColor;[self.mini setTitleColor:UIColor.systemBackgroundColor forState:UIControlStateNormal];[self.mini addTarget:self action:@selector(expand) forControlEvents:UIControlEventTouchUpInside];[self addSubview:self.mini];[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updated:) name:@"ZZPickerUpdated" object:nil];}
    return self;
}
- (void)dealloc {[[NSNotificationCenter defaultCenter]removeObserver:self];}
- (void)updated:(NSNotification *)notification {(void)notification;if(!self.hidden)[self refresh];}
- (UIButton *)button:(NSString *)title action:(SEL)action primary:(BOOL)primary {UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];[b setTitle:title forState:UIControlStateNormal];b.titleLabel.numberOfLines=0;b.titleLabel.textAlignment=NSTextAlignmentCenter;b.titleLabel.font=[[UIFontMetrics defaultMetrics]scaledFontForFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]];[b.heightAnchor constraintGreaterThanOrEqualToConstant:44].active=YES;b.layer.cornerRadius=10;b.backgroundColor=primary?ZZPanelRed():UIColor.secondarySystemBackgroundColor;[b setTitleColor:primary?UIColor.whiteColor:UIColor.labelColor forState:UIControlStateNormal];[b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return b;}
- (void)separator {UIView *line=[UIView new];line.backgroundColor=UIColor.separatorColor;[line.heightAnchor constraintEqualToConstant:0.5].active=YES;[self.stack addArrangedSubview:line];}
- (void)refresh {
    NSDictionary *snap=ZZPicker.shared.taskSummary,*ui=ZZPicker.shared.presentation,*c=snap[@"counts"],*config=snap[@"config"];NSString *kind=ui[@"kind"];
    [self.stack removeFromSuperview];self.stack=[UIStackView new];self.stack.axis=UILayoutConstraintAxisVertical;self.stack.spacing=13;[self.card addSubview:self.stack];
    UIStackView *heading=[UIStackView new];heading.axis=UILayoutConstraintAxisHorizontal;heading.alignment=UIStackViewAlignmentCenter;[heading addArrangedSubview:ZZLabel(ui[@"title"]?:@"选机助手",17,YES)];
    if(![kind isEqual:@"summary"]){UIButton *collapse=[self button:@"收起" action:@selector(collapse) primary:NO];collapse.backgroundColor=UIColor.clearColor;[heading addArrangedSubview:collapse];}
    [self.stack addArrangedSubview:heading];[self.stack addArrangedSubview:ZZLabel(config[@"model"]?:@"",17,YES)];
    NSMutableArray *caps=[NSMutableArray new];for(NSString *v in config[@"capacities"])[caps addObject:[NSString stringWithFormat:@"%@G",v]];
    NSString *range=[NSString stringWithFormat:@"%@\n%@ · %@ · %@\n巨魔：%@ · 完整越狱：%@\n规则：%@",snap[@"effectiveRange"][@"label"]?:@"范围未提供",[config[@"channels"]count]?[config[@"channels"]componentsJoinedByString:@" / "]:@"购买渠道不限",caps.count?[caps componentsJoinedByString:@" / "]:@"容量不限",[config[@"conditions"]count]?[config[@"conditions"]componentsJoinedByString:@" / "]:@"成色不限",[config[@"requireTrollStore"]boolValue]?@"要求":@"未要求",[config[@"requireJailbreak"]boolValue]?@"要求":@"未要求",snap[@"ruleVersion"]?:@"不可用"];
    UILabel *criteria=ZZLabel(range,13,NO);criteria.accessibilityIdentifier=@"taskCriteria";criteria.textColor=UIColor.secondaryLabelColor;[self.stack addArrangedSubview:criteria];[self separator];
    UILabel *budget=ZZLabel([NSString stringWithFormat:@"上限 %@ 件 / %@ 分钟 · 已运行 %.1f 分钟",config[@"maxProducts"]?:@100,config[@"maxMinutes"]?:@15,[snap[@"elapsedMs"]doubleValue]/60000],12,NO);budget.textColor=UIColor.secondaryLabelColor;budget.accessibilityIdentifier=@"taskBudget";[self.stack addArrangedSubview:budget];
    UIStackView *counts=[UIStackView new];counts.axis=UILayoutConstraintAxisHorizontal;counts.distribution=UIStackViewDistributionFillEqually;
    for(NSString *key in @[@"loaded",@"checked",@"matched"]){UIStackView *column=[UIStackView new];column.axis=UILayoutConstraintAxisVertical;column.alignment=UIStackViewAlignmentCenter;NSString *value=[key isEqual:@"checked"]?[NSString stringWithFormat:@"%@/%@",c[key]?:@0,c[@"loaded"]?:@0]:[c[key]?:@0 description];[column addArrangedSubview:ZZLabel(value,23,YES)];UILabel *name=ZZLabel(@{@"loaded":@"商品数",@"checked":@"已核验",@"matched":@"命中"}[key],12,NO);name.textColor=UIColor.secondaryLabelColor;[column addArrangedSubview:name];[counts addArrangedSubview:column];}
    [self.stack addArrangedSubview:counts];if([c[@"unknown"]unsignedIntegerValue])[self.stack addArrangedSubview:ZZLabel([NSString stringWithFormat:@"报告或字段待确认：%@（未计入已核验）",c[@"unknown"]],12,NO)];[self separator];
    if([kind isEqual:@"hit"]||[kind isEqual:@"returned"]||[kind isEqual:@"favorite"]){NSDictionary *p=snap[@"hit"]?:snap[@"candidate"];if([p isKindOfClass:NSDictionary.class]){[self.stack addArrangedSubview:ZZLabel(p[@"title"]?:config[@"model"],15,YES)];NSString *channel=[p[@"channel"]isKindOfClass:NSString.class]&&[p[@"channel"]length]?p[@"channel"]:@"渠道未知";UILabel *details=ZZLabel([NSString stringWithFormat:@"iOS %@ · %@ · %@G · %@",p[@"ios"]?:@"未知",channel,p[@"capacity"]?:@"未知",p[@"condition"]?:@"未知"],13,NO);details.accessibilityIdentifier=@"matchedDetails";[self.stack addArrangedSubview:details];NSString *status=p[@"status"],*text=[kind isEqual:@"favorite"]?@"正在收藏并核对状态，请稍候":@{@"favorited":@"✓ 已收藏 · 状态已核验",@"already":@"原有收藏 · 已保留",@"favoriteUnknown":@"收藏待确认 · 未计入收藏成功",@"match":@"符合全部条件 · 命中已保留"}[status]?:@"命中已保留";UILabel *message=ZZLabel(text,13,NO);message.textColor=[status isEqual:@"favorited"]?UIColor.systemGreenColor:UIColor.secondaryLabelColor;[self.stack addArrangedSubview:message];}}
    if([kind isEqual:@"summary"])[self.stack addArrangedSubview:ZZLabel([NSString stringWithFormat:@"本次新增收藏（已核验）：%@\n原有收藏：%@ · 收藏待确认：%@",c[@"favorited"]?:@0,c[@"already"]?:@0,c[@"favoriteUnknown"]?:@0],13,NO)];
    NSString *message=ui[@"message"];if(!message.length){if([kind isEqual:@"loading"])message=[snap[@"waitingResponse"]boolValue]?@"请求已启动，等待新商品，最长60秒；商品数暂不增加":@"正在加载下一页，商品数以实际返回为准";else if([kind isEqual:@"search"])message=@"自动输入型号，并确认容量与成色筛选";else if([kind isEqual:@"running"])message=@"正在隐藏读取验机报告；iOS → 购买渠道 → 容量 → 成色，全部符合才计入命中";}
    if(message.length){UILabel *note=ZZLabel(message,13,NO);note.textColor=UIColor.secondaryLabelColor;[self.stack addArrangedSubview:note];}
    UIStackView *actions=[UIStackView new];actions.axis=UILayoutConstraintAxisHorizontal;actions.distribution=UIStackViewDistributionFillEqually;actions.spacing=8;
    if([ui[@"canResume"]boolValue])[actions addArrangedSubview:[self button:[snap[@"phase"]isEqual:@"hit"]?@"继续扫描":@"继续任务" action:@selector(resume) primary:![ui[@"canView"]boolValue]]];
    if([ui[@"canView"]boolValue])[actions addArrangedSubview:[self button:@"查看详情" action:@selector(view) primary:YES]];
    if([@[@"running",@"loading",@"search",@"favorite"]containsObject:kind])[actions addArrangedSubview:[self button:@"暂停任务" action:@selector(pause) primary:NO]];
    if(actions.arrangedSubviews.count)[self.stack addArrangedSubview:actions];
    if([ui[@"canEnd"]boolValue]){UIButton *end=[self button:@"结束任务" action:@selector(end) primary:NO];end.backgroundColor=UIColor.clearColor;[end setTitleColor:ZZPanelRed() forState:UIControlStateNormal];[self.stack addArrangedSubview:end];}
    if([snap[@"recordCount"]unsignedIntegerValue])[self.stack addArrangedSubview:[self button:@"核验记录与判定依据" action:@selector(records) primary:NO]];
    if([ui[@"canSettings"]boolValue])[self.stack addArrangedSubview:[self button:[kind isEqual:@"summary"]?@"结果与设置 / 新任务":@"调整设置 / 新任务" action:@selector(settings) primary:NO]];
    if([kind isEqual:@"summary"])[self.stack addArrangedSubview:[self button:@"关闭窗口" action:@selector(hide) primary:NO]];
    [self.mini setTitle:[NSString stringWithFormat:@"%@ · %@/%@ · 展开",[kind isEqual:@"hit"]?@"发现命中":@"选机任务",c[@"processed"]?:@0,c[@"loaded"]?:@0]forState:UIControlStateNormal];
    if([@[@"hit",@"returned",@"paused",@"summary",@"favorite"]containsObject:kind]&&![self.accessibilityIdentifier isEqual:kind])self.collapsed=NO;self.accessibilityIdentifier=kind;[self setNeedsLayout];
}
- (void)layoutSubviews {[super layoutSubviews];self.shade.frame=self.bounds;self.shade.hidden=self.collapsed;self.card.hidden=self.collapsed;self.mini.hidden=!self.collapsed;CGFloat width=MIN(360,self.bounds.size.width-28),available=MAX(150,self.bounds.size.height-self.safeAreaInsets.top-self.safeAreaInsets.bottom-32);self.stack.frame=CGRectMake(18,18,width-36,100);CGSize size=[self.stack systemLayoutSizeFittingSize:CGSizeMake(width-36,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];self.stack.frame=CGRectMake(18,18,width-36,size.height);self.card.contentSize=CGSizeMake(width,size.height+36);CGFloat height=MIN(available,size.height+36);self.card.frame=CGRectMake((self.bounds.size.width-width)/2,self.safeAreaInsets.top+(available-height)/2+16,width,height);self.mini.frame=CGRectMake(MAX(14,self.bounds.size.width-220),self.safeAreaInsets.top+60,206,40);}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {if(self.hidden||self.alpha<=0.01||!self.userInteractionEnabled)return nil;if(self.collapsed){CGPoint p=[self convertPoint:point toView:self.mini];return [self.mini pointInside:p withEvent:event]?[self.mini hitTest:p withEvent:event]:nil;}UIView *hit=[super hitTest:point withEvent:event];return hit==self||hit==self.shade?nil:hit;}
- (void)collapse {self.collapsed=YES;[self setNeedsLayout];}
- (void)expand {self.collapsed=NO;[self refresh];}
- (void)pause {[ZZPicker.shared pause:@"手动暂停，进度已保留"];}
- (void)resume {[ZZPicker.shared resume];}
- (void)view {[ZZPicker.shared viewMatched];}
- (void)records {ZZPresentRunRecords();}
- (void)settings {[ZZPicker.shared showSettings];}
- (void)hide {self.hidden=YES;}
- (void)end {
    ZZPicker *picker=ZZPicker.shared;NSString *before=picker.snapshot[@"state"];BOOL running=![@[@"paused",@"hit"]containsObject:before];[picker pause:@"等待结束确认"];ZZHideTaskPanel();
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"结束本次任务？" message:@"命中结果和已完成收藏会保留。已发出的收藏仍可能完成，后续不会发起新的操作。" preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;
    [alert addAction:[UIAlertAction actionWithTitle:running?@"继续任务":@"返回任务" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){(void)action;if(running)[picker resume];else[picker showTask];}]];
    [alert addAction:[UIAlertAction actionWithTitle:@"结束并保留结果" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){(void)action;[picker stop];}]];[ZZTopController() presentViewController:alert animated:YES completion:nil];
}
@end
void ZZShowTaskPanel(void){UIWindow *window=ZZAppWindow();if(!window)return;if(!ZZPanel)ZZPanel=[[ZZTaskPanel alloc]initWithFrame:window.bounds];if(ZZPanel.superview!=window){[ZZPanel removeFromSuperview];[window addSubview:ZZPanel];}ZZPanel.hidden=NO;[window bringSubviewToFront:ZZPanel];[ZZPanel refresh];}
void ZZHideTaskPanel(void){ZZPanel.hidden=YES;}
