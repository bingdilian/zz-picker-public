#import "ZZPicker.h"
static __weak UINavigationController *ZZSettingsNavigation;
BOOL ZZSettingsVisible(void){return ZZSettingsNavigation.presentingViewController!=nil&&!ZZSettingsNavigation.isBeingDismissed;}
void ZZDismissSettings(void (^completion)(void)){UINavigationController *navigation=ZZSettingsNavigation;if(navigation.presentingViewController){[navigation dismissViewControllerAnimated:YES completion:^{ZZSettingsNavigation=nil;completion();}];}else completion();}
static UIColor *ZZRed(void){return [UIColor colorWithRed:0.91 green:0.18 blue:0.24 alpha:1];}
@interface ZZSettingsController : UITableViewController <UITextFieldDelegate,UIGestureRecognizerDelegate>
@property(nonatomic,strong) NSMutableDictionary *draft;
@property(nonatomic,strong) NSMutableDictionary<NSString *,UITextField *> *fields;
@property(nonatomic,copy) NSArray *capacities;
@property(nonatomic,copy) NSString *surface;
@property(nonatomic,copy) NSDictionary *rangeState;
@end
@implementation ZZSettingsController
- (BOOL)recovering {return [ZZPicker.shared.configLoadState[@"status"]isEqual:@"recovery"];}
- (BOOL)runtimeUnavailable {return ZZPicker.shared.initializationError!=nil;}
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"选机设置";self.edgesForExtendedLayout=UIRectEdgeNone;self.view.tag=ZZPickerOwnViewTag;self.tableView.tintColor=ZZRed();self.fields=[NSMutableDictionary new];self.draft=[ZZPicker.shared.config mutableCopy];self.surface=ZZSearchSurface();self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=58;
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissKeyboard)];tap.name=@"dismissSettingsKeyboard";tap.cancelsTouchesInView=NO;tap.delegate=self;[self.tableView addGestureRecognizer:tap];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(close)];self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"说明 / 环境" style:UIBarButtonItemStylePlain target:self action:@selector(about)];
    [self refreshCapacities];[self updateRangePresentation];
    if(![NSUserDefaults.standardUserDefaults boolForKey:@"com.codex.zzpicker.helpSeen"]){
        UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0,0,MAX(320,self.tableView.bounds.size.width),140)];UILabel *help=[UILabel new];help.translatesAutoresizingMaskIntoConstraints=NO;help.numberOfLines=0;help.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];help.adjustsFontForContentSizeCategory=YES;help.text=@"筛选待售手机的报告。首次测试建议关闭自动收藏；转转保持前台，命中后暂停，查看返回后手动继续。";[header addSubview:help];UIButton *ack=[UIButton buttonWithType:UIButtonTypeSystem];ack.translatesAutoresizingMaskIntoConstraints=NO;ack.accessibilityIdentifier=@"acknowledgeHelp";[ack setTitle:@"知道了" forState:UIControlStateNormal];[ack addTarget:self action:@selector(acknowledgeHelp) forControlEvents:UIControlEventTouchUpInside];[header addSubview:ack];
        [NSLayoutConstraint activateConstraints:@[[help.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],[help.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],[help.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],[ack.leadingAnchor constraintEqualToAnchor:help.leadingAnchor],[ack.trailingAnchor constraintEqualToAnchor:help.trailingAnchor],[ack.topAnchor constraintEqualToAnchor:help.bottomAnchor constant:4],[ack.heightAnchor constraintEqualToConstant:44],[ack.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-6]]];self.tableView.tableHeaderView=header;
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updated:) name:@"ZZPickerUpdated" object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];UINavigationBar *bar=self.navigationController.navigationBar;UINavigationBarAppearance *appearance=[UINavigationBarAppearance new];[appearance configureWithOpaqueBackground];appearance.backgroundColor=UIColor.systemGroupedBackgroundColor;bar.standardAppearance=appearance;bar.scrollEdgeAppearance=appearance;bar.compactAppearance=appearance;bar.compactScrollEdgeAppearance=appearance;bar.translucent=NO;
}
- (void)viewDidLayoutSubviews {[super viewDidLayoutSubviews];UIView *header=self.tableView.tableHeaderView;if(header){CGFloat height=[header systemLayoutSizeFittingSize:CGSizeMake(self.tableView.bounds.size.width,UILayoutFittingCompressedSize.height) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;if(fabs(height-header.frame.size.height)>1){header.frame=CGRectMake(0,0,self.tableView.bounds.size.width,height);self.tableView.tableHeaderView=header;}}}
- (void)dealloc {[[NSNotificationCenter defaultCenter]removeObserver:self];}
- (void)dismissKeyboard {[self.view endEditing:YES];}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {(void)gesture;for(UIView *view=touch.view;view;view=view.superview)if([view isKindOfClass:UIControl.class])return NO;return YES;}
- (BOOL)textFieldShouldReturn:(UITextField *)field {[field resignFirstResponder];return YES;}
- (void)explain:(NSString *)message {UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"检查设置" message:message preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;[alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];[(self.navigationController.topViewController?:self) presentViewController:alert animated:YES completion:nil];}
- (void)close {
    [self dismissKeyboard];if(self.recovering||self.runtimeUnavailable){ZZDismissSettings(^{[ZZPicker.shared showTask];});return;}
    NSString *error=[ZZPicker.shared saveConfigurationDraft:self.draft];if(!error){ZZDismissSettings(^{[ZZPicker.shared showTask];});return;}
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"设置尚未保存" message:error preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;[alert addAction:[UIAlertAction actionWithTitle:@"继续编辑" style:UIAlertActionStyleCancel handler:nil]];[alert addAction:[UIAlertAction actionWithTitle:@"放弃修改" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){(void)a;ZZDismissSettings(^{[ZZPicker.shared showTask];});}]];[self presentViewController:alert animated:YES completion:nil];
}
- (void)about {[self dismissKeyboard];[self.navigationController pushViewController:[(UIViewController *)[NSClassFromString(@"ZZAboutController")alloc]init]animated:YES];}
- (void)acknowledgeHelp {[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"com.codex.zzpicker.helpSeen"];self.tableView.tableHeaderView=nil;}
- (void)updated:(NSNotification *)note {(void)note;for(UITextField *field in self.fields.allValues)if(field.isFirstResponder)return;[self updateRangePresentation];[self.tableView reloadData];}
- (void)refreshCapacities {
    NSArray *models=[ZZPicker.shared compatibilityCatalog][@"models"];NSDictionary *current=nil;for(NSDictionary *m in models)if([m[@"id"]isEqual:self.draft[@"modelId"]])current=m;
    NSMutableOrderedSet *labels=[NSMutableOrderedSet new];for(NSString *v in current[@"capacities"])[labels addObject:[v isEqual:@"1024"]?@"1T":[v stringByAppendingString:@"G"]];
    if(!labels.count)[labels addObjectsFromArray:@[@"128G",@"256G",@"512G",@"1T"]];
    for(NSString *v in self.draft[@"capacities"]){NSString *label=[v isEqual:@"1024"]?@"1T":[v stringByAppendingString:@"G"];[labels addObject:label];}self.capacities=labels.array;
}
- (void)updateRangePresentation {
    self.rangeState=[ZZPicker.shared effectiveRangeForConfig:self.draft];UITableViewCell *range=[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];if([range.accessibilityIdentifier isEqual:@"effectiveRange"]){range.textLabel.text=[self.rangeState[@"label"]length]?self.rangeState[@"label"]:@"实际范围暂不可用";range.detailTextLabel.text=[self rangeNote];range.textLabel.textColor=[self.rangeState[@"canStart"]boolValue]?UIColor.labelColor:UIColor.systemRedColor;}
    UITableViewCell *start=[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:8]];BOOL enabled=[self.rangeState[@"canStart"]boolValue]&&ZZPicker.shared.enabled&&!self.recovering;start.userInteractionEnabled=enabled;start.backgroundColor=enabled?ZZRed():UIColor.secondarySystemGroupedBackgroundColor;start.textLabel.textColor=enabled?UIColor.whiteColor:UIColor.secondaryLabelColor;
}
- (NSString *)rangeNote {
    if([self.rangeState[@"issues"]count])return [self.rangeState[@"issues"]componentsJoinedByString:@"；"];
    if([self.draft[@"requireTrollStore"]boolValue])return @"按报告标称核验；17.0缺构建号不单独拦截，已提供异常构建待确认。安装路径需要电脑。";
    return [self.draft[@"requireJailbreak"]boolValue]?@"仅核验已收录完整越狱工具；未要求巨魔。":@"仅按机型边界与普通条件筛选，不作工具支持承诺。";
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {(void)tableView;return self.recovering||self.runtimeUnavailable?1:10;}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;if(self.recovering||self.runtimeUnavailable)return 1;if(section==0)return 3;if(section==1)return 2;if(section==2)return 5;if(section<=5)return 1;if(section<=8)return 2;return 1;}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {(void)tableView;if(self.runtimeUnavailable)return @"规则运行时不可用";if(self.recovering)return @"设置损坏";return @[@"待售手机 · 型号与资料",@"用途要求 · 同时开启须全部满足",@"系统范围",@"购买渠道 · 可多选",@"存储容量 · 可多选",@"外观成色 · 可多选",@"插件与收藏",@"扫描限制",@"开始与诊断",@"核验记录"][section];}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;if(self.runtimeUnavailable)return @"设置原文保留，不保存或开始任务。可预览诊断后重新安装完整测试包。";if(self.recovering)return @"原数据保留，恢复前不会开始任务。";
    if(section==0)return [NSString stringWithFormat:@"来自%@。%@",self.surface,![@[@"idle",@"stopped",@"finished"]containsObject:ZZPicker.shared.taskSummary[@"state"]]?@"原任务已暂停；修改用于下一次任务，关闭后手动继续原任务。":@"根据待售手机报告筛选，不是当前设备系统。"];
    if(section==2)return @"17等于17.0.0，不代表整个iOS17。手动留空只是不额外收窄，不取消用途限制；自动显示不覆盖手动原值。";
    if(section==3)return @"全部不选表示不限；限定渠道时缺失或冲突不命中。";
    if(section==4)return @"切换机型后冲突容量保留，须主动处理；不会自动变成容量不限。";
    if(section==6)return @"新用户自动收藏关闭，旧偏好保留。停用立即结束任务；已发收藏无法撤回。";
    if(section==7)return @"件数1～2000，分钟1～120；暂停与查看详情不计时。";
    if(section==8)return !ZZPicker.shared.enabled?@"插件已停用，请先启用。":![self.rangeState[@"canStart"]boolValue]?[self rangeNote]:@"关闭会保存合法设置；开始才创建新任务。";return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;if(path.section>=3&&path.section<=5){NSUInteger count=path.section==3?ZZPicker.shared.purchaseChannels.count:path.section==4?self.capacities.count:4;CGFloat rows=ceil(count/4.0);return 12+rows*28+MAX(0,rows-1)*6;}if(path.section==6||path.section==1)return MAX(58,[UIFont preferredFontForTextStyle:UIFontTextStyleBody].lineHeight*2+20);return UITableViewAutomaticDimension;
}
- (UITextField *)field:(NSString *)key numeric:(BOOL)numeric {
    UITextField *field=[[UITextField alloc]initWithFrame:CGRectMake(0,0,MIN(230,self.tableView.bounds.size.width*0.56),40)];field.text=[self.draft[key]description];field.accessibilityIdentifier=key;field.textAlignment=NSTextAlignmentRight;field.autocorrectionType=UITextAutocorrectionTypeNo;field.autocapitalizationType=UITextAutocapitalizationTypeNone;field.keyboardType=numeric?UIKeyboardTypeNumbersAndPunctuation:UIKeyboardTypeDefault;[field addTarget:self action:@selector(fieldChanged:) forControlEvents:UIControlEventEditingChanged];self.fields[key]=field;return field;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];cell.textLabel.numberOfLines=0;cell.detailTextLabel.numberOfLines=0;cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];cell.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];cell.textLabel.adjustsFontForContentSizeCategory=YES;cell.detailTextLabel.adjustsFontForContentSizeCategory=YES;cell.selectionStyle=UITableViewCellSelectionStyleNone;
    NSInteger section=path.section-2,row=path.row;
    if(self.runtimeUnavailable){cell.textLabel.text=@"预览初始化诊断";cell.detailTextLabel.text=ZZPicker.shared.initializationError;cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;cell.selectionStyle=UITableViewCellSelectionStyleDefault;cell.accessibilityIdentifier=@"runtimeUnavailable";return cell;}
    if(self.recovering){cell.textLabel.text=@"恢复损坏的设置";cell.detailTextLabel.text=[ZZPicker.shared.configLoadState[@"issues"]componentsJoinedByString:@"；"];cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;cell.selectionStyle=UITableViewCellSelectionStyleDefault;cell.accessibilityIdentifier=@"recoverConfig";return cell;}
    if(path.section==0){
        if(row==0){cell.textLabel.text=@"手机型号";cell.accessoryView=[self field:@"model" numeric:NO];}
        else{cell.textLabel.text=row==1?@"选择已收录机型":@"查看支持依据";cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;cell.selectionStyle=UITableViewCellSelectionStyleDefault;cell.accessibilityIdentifier=row==1?@"modelPicker":@"compatibilityEvidence";cell.detailTextLabel.text=row==1?([self.draft[@"modelId"]length]?self.draft[@"model"]:[NSString stringWithFormat:@"原型号待确认：%@；普通手动筛选仍可保留",self.draft[@"model"]?:@""]):@"工具版本、安装路径、构建前提和官方来源";}
    }else if(path.section==1){NSString *key=row==0?@"requireTrollStore":@"requireJailbreak";cell.textLabel.text=row==0?@"需要巨魔":@"需要完整越狱";UISwitch *toggle=[UISwitch new];toggle.accessibilityIdentifier=key;toggle.on=[self.draft[key]boolValue];[toggle addTarget:self action:@selector(purposeChanged:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=toggle;}
    else if(path.section==2){
        if(row==0){cell.accessibilityIdentifier=@"effectiveRange";cell.textLabel.text=[self.rangeState[@"label"]length]?self.rangeState[@"label"]:@"实际范围暂不可用";cell.detailTextLabel.text=[self rangeNote];cell.textLabel.textColor=[self.rangeState[@"canStart"]boolValue]?UIColor.labelColor:UIColor.systemRedColor;}
        else if(row==1){cell.textLabel.text=@"范围模式";UISegmentedControl *mode=[[UISegmentedControl alloc]initWithItems:@[@"自动",@"手动"]];mode.frame=CGRectMake(0,0,150,44);mode.accessibilityIdentifier=@"rangeMode";mode.selectedSegmentIndex=[self.draft[@"rangeMode"]isEqual:@"auto"]?0:1;[mode addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=mode;}
        else if(row==4){cell.textLabel.text=@"重新载入本地规则";cell.accessibilityIdentifier=@"reloadRules";cell.selectionStyle=UITableViewCellSelectionStyleDefault;cell.detailTextLabel.text=@"只重载插件内规则，影响下一次任务，不联网";}
        else{NSString *key=row==2?@"manualMinIOS":@"manualMaxIOS";cell.textLabel.text=row==2?@"最低 iOS":@"最高 iOS";UITextField *field=[self field:key numeric:YES];field.placeholder=@"不限";BOOL manual=[self.draft[@"rangeMode"]isEqual:@"manual"];field.enabled=manual;if(!manual){NSArray *ranges=self.rangeState[@"ranges"];id bound=row==2?[ranges firstObject][@"min"]:[ranges lastObject][@"max"];field.text=[bound isKindOfClass:NSString.class]?bound:@"";field.textColor=UIColor.secondaryLabelColor;}cell.accessoryView=field;}
    }
    else if(section>=1&&section<=3){
        NSArray *labels=section==1?ZZPicker.shared.purchaseChannels:section==2?self.capacities:@[@"99新",@"95新",@"9成新",@"8成新"];NSString *key=section==1?@"channels":section==2?@"capacities":@"conditions";
        UIStackView *rows=[UIStackView new];rows.axis=UILayoutConstraintAxisVertical;rows.distribution=UIStackViewDistributionFillEqually;rows.spacing=6;rows.translatesAutoresizingMaskIntoConstraints=NO;[cell.contentView addSubview:rows];[NSLayoutConstraint activateConstraints:@[[rows.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:12],[rows.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-12],[rows.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6],[rows.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-6]]];
        for(NSUInteger offset=0;offset<labels.count;offset+=4){UIStackView *line=[UIStackView new];line.axis=UILayoutConstraintAxisHorizontal;line.distribution=UIStackViewDistributionFillEqually;line.spacing=6;[rows addArrangedSubview:line];
            for(NSUInteger i=offset;i<MIN(offset+4,labels.count);i++){NSString *label=labels[i],*value=section==2?([ZZPicker.shared normalizedCapacity:label]?:label):label;UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.accessibilityIdentifier=[NSString stringWithFormat:@"%@|%@",key,value];[b setTitle:label forState:UIControlStateNormal];BOOL selected=[self.draft[key]containsObject:value];b.accessibilityTraits=UIAccessibilityTraitButton|(selected?UIAccessibilityTraitSelected:0);b.titleLabel.font=[UIFont systemFontOfSize:13 weight:selected?UIFontWeightSemibold:UIFontWeightRegular];b.layer.cornerRadius=9;b.backgroundColor=selected?[ZZRed()colorWithAlphaComponent:0.09]:UIColor.secondarySystemGroupedBackgroundColor;b.layer.borderWidth=selected?1:0;b.layer.borderColor=ZZRed().CGColor;[b setTitleColor:selected?ZZRed():UIColor.labelColor forState:UIControlStateNormal];[b addTarget:self action:@selector(toggleChoice:) forControlEvents:UIControlEventTouchUpInside];if(section==2&&[self.rangeState[@"capacityConflicts"]containsObject:value]){b.accessibilityValue=@"容量冲突，须主动处理";[b setTitle:[label stringByAppendingString:@" !"] forState:UIControlStateNormal];b.layer.borderWidth=2;}[line addArrangedSubview:b];}
            while(line.arrangedSubviews.count<4)[line addArrangedSubview:UIView.new];
        }
    }else if(section==4){cell.textLabel.text=row==0?@"启用插件":@"自动加入收藏";UISwitch *toggle=[UISwitch new];toggle.accessibilityIdentifier=row==0?@"pluginEnabled":@"autoFavorite";toggle.on=row==0?ZZPicker.shared.enabled:[self.draft[@"autoFavorite"]boolValue];[toggle addTarget:self action:row==0?@selector(enabledChanged:):@selector(autoChanged:) forControlEvents:UIControlEventValueChanged];cell.accessoryView=toggle;}
    else if(section==5){NSString *key=row==0?@"maxProducts":@"maxMinutes";cell.textLabel.text=row==0?@"最多处理件数":@"最长运行（分钟）";UITextField *field=[[UITextField alloc]initWithFrame:CGRectMake(0,0,90,38)];field.text=[self.draft[key]?:@(row==0?100:15) description];field.accessibilityIdentifier=key;field.textAlignment=NSTextAlignmentRight;field.keyboardType=UIKeyboardTypeNumberPad;[field addTarget:self action:@selector(fieldChanged:) forControlEvents:UIControlEventEditingChanged];self.fields[key]=field;cell.accessoryView=field;}
    else if(section==6){cell.selectionStyle=UITableViewCellSelectionStyleDefault;if(row==0){cell.textLabel.text=[self.surface isEqual:@"商品列表"]?@"应用条件并重新搜索":@"开始搜索并扫描";cell.textLabel.textAlignment=NSTextAlignmentCenter;cell.textLabel.textColor=UIColor.whiteColor;cell.backgroundColor=ZZRed();}else{cell.textLabel.text=@"预览与分享诊断";cell.textLabel.textColor=UIColor.systemBlueColor;}}
    else{cell.textLabel.text=@"查看全部核验记录";cell.detailTextLabel.text=[NSString stringWithFormat:@"已记录%@件 · 全部 / 符合 / 不符合 / 待确认",ZZPicker.shared.taskSummary[@"recordCount"]?:@0];cell.accessibilityIdentifier=@"allRecords";cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;cell.selectionStyle=UITableViewCellSelectionStyleDefault;}
    if([cell.accessoryView isKindOfClass:UITextField.class]){
        UITextField *field=(id)cell.accessoryView;field.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];field.adjustsFontForContentSizeCategory=YES;CGRect frame=field.frame;frame.size.height=MAX(40,field.font.lineHeight+10);field.frame=frame;field.delegate=self;field.returnKeyType=UIReturnKeyDone;
        UIToolbar *toolbar=[[UIToolbar alloc]initWithFrame:CGRectMake(0,0,tableView.bounds.size.width,44)];toolbar.items=@[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],[[UIBarButtonItem alloc]initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard)]];field.inputAccessoryView=toolbar;
    }
    if(path.section==8&&row==0){cell.accessibilityIdentifier=@"startTask";BOOL enabled=[self.rangeState[@"canStart"]boolValue]&&ZZPicker.shared.enabled;cell.userInteractionEnabled=enabled;cell.backgroundColor=enabled?ZZRed():UIColor.secondarySystemGroupedBackgroundColor;cell.textLabel.textColor=enabled?UIColor.whiteColor:UIColor.secondaryLabelColor;}
    return cell;
}
- (void)fieldChanged:(UITextField *)field {self.draft[field.accessibilityIdentifier]=field.text?:@"";if([field.accessibilityIdentifier isEqual:@"model"]){self.draft[@"modelId"]=[ZZPicker.shared modelIDForText:field.text?:@""];self.draft[@"preserveLegacyRange"]=@NO;}[self updateRangePresentation];if(self.tableView.window)[UIView performWithoutAnimation:^{[self.tableView beginUpdates];[self.tableView endUpdates];}];}
- (void)purposeChanged:(UISwitch *)toggle {self.draft=[[ZZPicker.shared configurationByEditing:self.draft event:@{@"type":@"setPurpose",@"key":toggle.accessibilityIdentifier,@"value":@(toggle.on)}]mutableCopy];[self updateRangePresentation];[self.tableView reloadData];}
- (void)modeChanged:(UISegmentedControl *)mode {[self dismissKeyboard];self.draft=[[ZZPicker.shared configurationByEditing:self.draft event:@{@"type":@"setRangeMode",@"mode":mode.selectedSegmentIndex==0?@"auto":@"manual"}]mutableCopy];[self updateRangePresentation];[self.tableView reloadData];}
- (void)autoChanged:(UISwitch *)toggle {self.draft[@"autoFavorite"]=@(toggle.on);}
- (void)enabledChanged:(UISwitch *)toggle {[self dismissKeyboard];[ZZPicker.shared setEnabled:toggle.on];[self updateRangePresentation];[self.tableView reloadData];}
- (void)toggleChoice:(UIButton *)button {NSArray *parts=[button.accessibilityIdentifier componentsSeparatedByString:@"|"];NSString *key=parts[0],*value=parts[1];NSMutableArray *values=[self.draft[key]mutableCopy]?:[NSMutableArray new];if([values containsObject:value])[values removeObject:value];else[values addObject:value];self.draft[key]=values;[self dismissKeyboard];[self updateRangePresentation];[self.tableView reloadData];}
- (void)recover {
    __weak ZZSettingsController *weakSelf=self;ZZPushConfigRecovery(self.navigationController,ZZPicker.shared.configLoadState,^(NSString *choice){NSString *error=[ZZPicker.shared resolveConfigurationRecovery:choice];if(error){[weakSelf explain:error];return;}weakSelf.draft=[ZZPicker.shared.config mutableCopy];[weakSelf refreshCapacities];[weakSelf updateRangePresentation];[weakSelf.tableView reloadData];[weakSelf.navigationController popViewControllerAnimated:YES];});
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];[self dismissKeyboard];if(self.runtimeUnavailable){ZZPresentDiagnostics();return;}if(self.recovering){[self recover];return;}
    if(path.section==0&&path.row==1){
        __weak ZZSettingsController *weakSelf=self;ZZPushModelPicker(self.navigationController,[ZZPicker.shared compatibilityCatalog],self.draft[@"modelId"]?:@"",self.draft[@"legacyModelText"]?:@"",^(NSString *modelID){ZZSettingsController *strong=weakSelf;if(!strong)return;if(modelID.length)strong.draft=[[ZZPicker.shared configurationByEditing:strong.draft event:@{@"type":@"selectModel",@"modelId":modelID}]mutableCopy];else{strong.draft[@"model"]=strong.draft[@"legacyModelText"]?:@"";strong.draft[@"modelId"]=[ZZPicker.shared modelIDForText:strong.draft[@"model"]];}[strong refreshCapacities];[strong updateRangePresentation];[strong.tableView reloadData];});return;
    }
    if(path.section==0&&path.row==2){ZZPushCompatibilityEvidence(self.navigationController,[ZZPicker.shared compatibilityEvidenceForConfig:self.draft]);return;}
    if(path.section==2&&path.row==4){NSString *error=[ZZPicker.shared reloadCompatibilityRules];[self updateRangePresentation];[self.tableView reloadData];if(error)[self explain:error];return;}
    if(path.section==9){ZZPushRunRecords(self.navigationController,ZZPicker.shared.snapshot);return;}
    if(path.section!=8)return;if(path.row==1){ZZPresentDiagnostics();return;}if(![self.rangeState[@"canStart"]boolValue]||!ZZPicker.shared.enabled){[self explain:[self rangeNote]];return;}
    if(![ZZPicker.shared.environment[@"verifiedAppVersion"]boolValue]){UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"转转版本尚未验证" message:@"当前版本与适配基线不同。先关闭自动收藏做少量测试；本次确认不会更改收藏偏好。" preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;[alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];[alert addAction:[UIAlertAction actionWithTitle:@"仅本次测试" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){(void)a;[self startAllowUnverified:YES];}]];[self presentViewController:alert animated:YES completion:nil];}else[self startAllowUnverified:NO];
}
- (void)startAllowUnverified:(BOOL)allow {
    if(![@[@"idle",@"stopped",@"finished"]containsObject:ZZPicker.shared.taskSummary[@"state"]]){
        UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"结束原任务并开始新任务？" message:@"新任务使用当前设置和规则快照；原结果保留在当前窗口直至替换。未确认前原任务保持暂停。" preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;[alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];[alert addAction:[UIAlertAction actionWithTitle:@"开始新任务" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){(void)a;[self performStartAllowUnverified:allow];}]];[self presentViewController:alert animated:YES completion:nil];return;
    }[self performStartAllowUnverified:allow];
}
- (void)performStartAllowUnverified:(BOOL)allow {NSString *error=[ZZPicker.shared startWithConfig:self.draft allowUnverified:allow];if(error)[self explain:error];}
@end
void ZZPresentSettings(void){UIViewController *top=ZZTopController();if(!top||ZZSettingsVisible())return;ZZSettingsController *settings=[[ZZSettingsController alloc]initWithStyle:UITableViewStyleInsetGrouped];UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:settings];navigation.view.tag=ZZPickerOwnViewTag;navigation.modalPresentationStyle=UIModalPresentationPageSheet;navigation.modalInPresentation=YES;ZZSettingsNavigation=navigation;[top presentViewController:navigation animated:YES completion:nil];}
