#import "ZZPicker.h"
static __weak UINavigationController *ZZSettingsNavigation;
BOOL ZZSettingsVisible(void){return ZZSettingsNavigation.presentingViewController!=nil&&!ZZSettingsNavigation.isBeingDismissed;}
void ZZDismissSettings(void (^completion)(void)) {UINavigationController *navigation=ZZSettingsNavigation;if(navigation.presentingViewController){[navigation dismissViewControllerAnimated:YES completion:^{ZZSettingsNavigation=nil;completion();}];}else completion();}
static UIColor *ZZRed(void){return [UIColor colorWithRed:0.91 green:0.18 blue:0.24 alpha:1];}
static NSString *ZZResultStatus(NSString *status){return @{@"match":@"命中",@"favorited":@"已收藏·已核验",@"already":@"原有收藏·已保留",@"favoriteUnknown":@"收藏待确认",@"favoritePending":@"收藏待确认",@"favoriteManual":@"需手动确认",@"favoriteFailed":@"收藏失败"}[status]?:status;}
@interface ZZHitHistoryController : UITableViewController
@property(nonatomic,copy) NSArray<NSDictionary *> *tasks;
@property(nonatomic,strong) UISegmentedControl *filter;
@end
@implementation ZZHitHistoryController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"命中记录";
    self.view.tag=ZZPickerOwnViewTag;
    self.filter=[[UISegmentedControl alloc]initWithItems:@[@"全部",@"已收藏",@"待处理"]];
    self.filter.selectedSegmentIndex=0;
    self.filter.accessibilityIdentifier=@"hitHistoryFilter";
    [self.filter addTarget:self action:@selector(reloadHistory) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView=self.filter;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadHistory];
}
- (void)reloadHistory {
    NSMutableArray *sections=[NSMutableArray new];
    for(NSDictionary *task in ZZPicker.shared.hitHistory){
        NSMutableArray *rows=[NSMutableArray new];
        for(NSDictionary *row in [task[@"rows"] reverseObjectEnumerator]){
            if(![row isKindOfClass:NSDictionary.class])continue;
            BOOL collected=[@[@"already",@"favorited"]containsObject:row[@"status"]?:@""];
            if(self.filter.selectedSegmentIndex==0||collected==(self.filter.selectedSegmentIndex==1))[rows addObject:row];
        }
        if(rows.count)[sections addObject:@{@"run":task[@"run"],@"model":task[@"model"],@"rows":rows}];
    }
    self.tasks=sections;
    UILabel *empty=[UILabel new];
    empty.text=@"暂无符合条件的命中记录";
    empty.textAlignment=NSTextAlignmentCenter;
    empty.textColor=UIColor.secondaryLabelColor;
    self.tableView.backgroundView=sections.count?nil:empty;
    [self.tableView reloadData];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {(void)tableView;return self.tasks.count;}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;return [self.tasks[section][@"rows"] count];}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    NSDictionary *task=self.tasks[section];
    NSArray *parts=[task[@"run"] componentsSeparatedByString:@"-"];
    NSDate *date=[NSDate dateWithTimeIntervalSince1970:parts.count>1?[parts[1]doubleValue]/1000.0:0];
    return [NSString stringWithFormat:@"%@ · %@",task[@"model"],[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;(void)section;
    return @"收藏状态为扫描时记录。";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;
    NSDictionary *row=self.tasks[path.section][@"rows"][path.row];
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.numberOfLines=0;
    cell.detailTextLabel.numberOfLines=0;
    cell.textLabel.text=row[@"title"];
    cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ · iOS %@ · %@ · %@G · %@",ZZResultStatus(row[@"status"]),row[@"ios"],row[@"channel"],row[@"capacity"],row[@"condition"]];
    if([row[@"reasons"]isKindOfClass:NSArray.class]&&[row[@"reasons"]count])
        cell.detailTextLabel.text=[cell.detailTextLabel.text stringByAppendingFormat:@"\n%@",[row[@"reasons"]componentsJoinedByString:@"；"]];
    cell.accessoryType=row[@"detailPath"]?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    if([ZZPicker.shared viewRecordedProduct:self.tasks[path.section][@"rows"][path.row]])return;
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"暂时无法打开商品" message:@"可以先在转转打开一件商品再返回，或按记录中的标题搜索。" preferredStyle:UIAlertControllerStyleAlert];
    alert.view.tag=ZZPickerOwnViewTag;
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

@interface ZZSettingsController : UITableViewController <UITextFieldDelegate,UIGestureRecognizerDelegate>
@property(nonatomic,strong) NSMutableDictionary *draft;
@property(nonatomic,strong) NSMutableDictionary<NSString *,UITextField *> *fields;
@property(nonatomic,strong) NSArray *capacities;
@property(nonatomic,copy) NSString *surface;
@end
@implementation ZZSettingsController
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"选机设置";self.edgesForExtendedLayout=UIRectEdgeNone;self.view.tag=ZZPickerOwnViewTag;self.tableView.tintColor=ZZRed();self.fields=[NSMutableDictionary new];self.draft=[ZZPicker.shared.config mutableCopy];self.surface=ZZSearchSurface();
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    UITapGestureRecognizer *dismissTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissKeyboard)];dismissTap.name=@"dismissSettingsKeyboard";dismissTap.cancelsTouchesInView=NO;dismissTap.delegate=self;[self.tableView addGestureRecognizer:dismissTap];
    NSMutableOrderedSet *labels=[NSMutableOrderedSet new];for(NSDictionary *option in ZZPicker.shared.snapshot[@"options"][@"capacities"]){NSString *label=option[@"label"];if([ZZPicker.shared normalizedCapacity:label])[labels addObject:label];}
    self.capacities=labels.count?labels.array:@[@"128G",@"256G",@"512G",@"1T"];
    for(NSString *value in self.draft[@"capacities"]){NSString *label=[NSString stringWithFormat:@"%@G",value];BOOL found=NO;for(NSString *existing in self.capacities)if([[ZZPicker.shared normalizedCapacity:existing]isEqual:value])found=YES;if(!found)self.capacities=[self.capacities arrayByAddingObject:label];}
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"说明 / 环境" style:UIBarButtonItemStylePlain target:self action:@selector(about)];
    if(![NSUserDefaults.standardUserDefaults boolForKey:@"com.codex.zzpicker.helpSeen"]){UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0,0,320,150)];UILabel *help=[UILabel new];help.translatesAutoresizingMaskIntoConstraints=NO;help.numberOfLines=0;help.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];help.text=@"首次使用建议关闭自动收藏，先验证搜索与筛选。转转需保持前台；可选择命中后暂停，或保存记录并继续。更多安装、兼容和诊断说明见左上角。";[header addSubview:help];UIButton *ack=[UIButton buttonWithType:UIButtonTypeSystem];ack.translatesAutoresizingMaskIntoConstraints=NO;ack.accessibilityIdentifier=@"acknowledgeHelp";[ack setTitle:@"知道了" forState:UIControlStateNormal];[ack addTarget:self action:@selector(acknowledgeHelp) forControlEvents:UIControlEventTouchUpInside];[header addSubview:ack];[NSLayoutConstraint activateConstraints:@[[help.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],[help.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],[help.topAnchor constraintEqualToAnchor:header.topAnchor constant:8],[help.heightAnchor constraintEqualToConstant:96],[ack.leadingAnchor constraintEqualToAnchor:help.leadingAnchor],[ack.trailingAnchor constraintEqualToAnchor:help.trailingAnchor],[ack.topAnchor constraintEqualToAnchor:help.bottomAnchor],[ack.heightAnchor constraintEqualToConstant:40]]];self.tableView.tableHeaderView=header;}
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updated:) name:@"ZZPickerUpdated" object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Keep the settings list below our bar even when the host app uses transparent navigation.
    UINavigationBar *bar=self.navigationController.navigationBar;UINavigationBarAppearance *appearance=[UINavigationBarAppearance new];[appearance configureWithOpaqueBackground];appearance.backgroundColor=UIColor.systemGroupedBackgroundColor;
    bar.standardAppearance=appearance;bar.scrollEdgeAppearance=appearance;bar.compactAppearance=appearance;bar.compactScrollEdgeAppearance=appearance;bar.translucent=NO;
}
- (void)dealloc {[[NSNotificationCenter defaultCenter]removeObserver:self];}
- (void)dismissKeyboard {[self.view endEditing:YES];}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    (void)gesture;for(UIView *view=touch.view;view;view=view.superview)if([view isKindOfClass:UIControl.class])return NO;return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {[field resignFirstResponder];return YES;}
- (void)close {
    [self dismissKeyboard];NSString *error=[ZZPicker.shared saveConfigurationDraft:self.draft];
    if(!error){ZZDismissSettings(^{[ZZPicker.shared showTask];});return;}
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"设置尚未保存" message:error preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;
    [alert addAction:[UIAlertAction actionWithTitle:@"继续编辑" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"放弃修改" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){(void)action;ZZDismissSettings(^{[ZZPicker.shared showTask];});}]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)about {[self dismissKeyboard];[self.navigationController pushViewController:[(UIViewController *)[NSClassFromString(@"ZZAboutController")alloc]init]animated:YES];}
- (void)acknowledgeHelp {[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"com.codex.zzpicker.helpSeen"];self.tableView.tableHeaderView=nil;}
- (void)updated:(NSNotification *)note {(void)note;for(UITextField *field in self.fields.allValues)if(field.isFirstResponder)return;[self.tableView reloadData];}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {(void)tableView;return 8;}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;if(section==0)return 3;if(section==3)return 2;if(section<3)return 1;if(section==4)return 4;if(section==6)return 4;if(section==5)return 2;return MIN([ZZPicker.shared.snapshot[@"results"]count],50);}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {(void)tableView;return @[[NSString stringWithFormat:@"来自%@ · 新任务",self.surface],@"购买渠道 · 可多选",@"存储容量 · 可多选",@"外观成色 · 可多选",@"插件与收藏",@"扫描限制",@"开始、记录与诊断",@"命中商品 · 仅全部条件符合"][section];}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {(void)tableView;if(section==0)return @"iOS指待售手机，包含上下限；留空不限。";if(section==1)return @"默认国行；全部不选表示不限。限定渠道时，以验机报告为准；渠道未知或冲突不自动收藏。";if(section==2)return @"成色或容量全部不选表示不限；会自动应用转转筛选并核验请求。";if(section==4)return @"停用立即结束任务与采集，保留设置及结果。已发出的收藏不能撤回。自动确认默认关闭，开启自动收藏后才能使用。开启自动确认即允许插件替你接受平台换新电池提醒。打开“命中后继续扫描”可保存商品并扫描下一件。";if(section==5)return @"件数1–2000，分钟1–120。按已处理商品计数，暂停和查看命中详情不计时；到限后暂停，已有收藏先完成核验。";if(section==7)return @"基础诊断不含商品明细；需要排除记录时请在预览中主动开启明细。";return nil;}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;if(indexPath.section>=1&&indexPath.section<=3&&indexPath.row==0){NSUInteger count=indexPath.section==1?ZZPicker.shared.purchaseChannels.count:indexPath.section==2?self.capacities.count:4;CGFloat rows=ceil(count/4.0);return 12+rows*28+MAX(0,rows-1)*6;}if(indexPath.section==4)return 58;return UITableViewAutomaticDimension;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];cell.textLabel.numberOfLines=0;cell.detailTextLabel.numberOfLines=0;cell.selectionStyle=UITableViewCellSelectionStyleNone;
    NSInteger section=path.section,row=path.row;
    if(section==0){NSString *key=@[@"model",@"minIOS",@"maxIOS"][row];cell.textLabel.text=@[@"手机型号",@"最低 iOS",@"最高 iOS"][row];UITextField *field=[[UITextField alloc]initWithFrame:CGRectMake(0,0,MIN(230,tableView.bounds.size.width*0.56),38)];field.text=self.draft[key];field.placeholder=row==0?@"iPhone 15 Pro Max":@"不限";field.accessibilityIdentifier=key;field.textAlignment=NSTextAlignmentRight;field.autocorrectionType=UITextAutocorrectionTypeNo;field.autocapitalizationType=UITextAutocapitalizationTypeNone;field.keyboardType=row==0?UIKeyboardTypeDefault:UIKeyboardTypeNumbersAndPunctuation;[field addTarget:self action:@selector(fieldChanged:) forControlEvents:UIControlEventEditingChanged];cell.accessoryView=field;self.fields[key]=field;}
    else if(section==3&&row==1){
        cell.textLabel.text=@"验机报告筛选";
        NSUInteger count=[ZZPicker.shared inspectionSummary:self.draft[@"reportFilters"]?:@{}].count;
        cell.detailTextLabel.text=count?[NSString stringWithFormat:@"已设置 %lu 类",(unsigned long)count]:@"不限";
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle=UITableViewCellSelectionStyleDefault;
        cell.accessibilityIdentifier=@"inspectionFilters";
    }else if(section>=1&&section<=3){
        NSArray *labels=section==1?ZZPicker.shared.purchaseChannels:section==2?self.capacities:@[@"99新",@"95新",@"9成新",@"8成新"];NSString *key=section==1?@"channels":section==2?@"capacities":@"conditions";
        UIStackView *rows=[UIStackView new];rows.axis=UILayoutConstraintAxisVertical;rows.distribution=UIStackViewDistributionFillEqually;rows.spacing=6;rows.translatesAutoresizingMaskIntoConstraints=NO;[cell.contentView addSubview:rows];[NSLayoutConstraint activateConstraints:@[[rows.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:12],[rows.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-12],[rows.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:6],[rows.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:-6]]];
        for(NSUInteger offset=0;offset<labels.count;offset+=4){UIStackView *line=[UIStackView new];line.axis=UILayoutConstraintAxisHorizontal;line.distribution=UIStackViewDistributionFillEqually;line.spacing=6;[rows addArrangedSubview:line];
            for(NSUInteger i=offset;i<MIN(offset+4,labels.count);i++){NSString *label=labels[i],*value=section==2?([ZZPicker.shared normalizedCapacity:label]?:label):label;UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.accessibilityIdentifier=[NSString stringWithFormat:@"%@|%@",key,value];[b setTitle:label forState:UIControlStateNormal];BOOL selected=[self.draft[key]containsObject:value];b.accessibilityTraits=UIAccessibilityTraitButton|(selected?UIAccessibilityTraitSelected:0);b.titleLabel.font=[UIFont systemFontOfSize:13 weight:selected?UIFontWeightSemibold:UIFontWeightRegular];b.layer.cornerRadius=9;b.backgroundColor=selected?[ZZRed()colorWithAlphaComponent:0.09]:UIColor.secondarySystemGroupedBackgroundColor;b.layer.borderWidth=selected?1:0;b.layer.borderColor=ZZRed().CGColor;[b setTitleColor:selected?ZZRed():UIColor.labelColor forState:UIControlStateNormal];[b addTarget:self action:@selector(toggleChoice:) forControlEvents:UIControlEventTouchUpInside];[line addArrangedSubview:b];}
            while(line.arrangedSubviews.count<4)[line addArrangedSubview:UIView.new];
        }
    }else if(section==4){cell.textLabel.text=@[@"启用插件",@"自动加入收藏",@"命中后继续扫描",@"允许自动确认换新电池提醒"][row];UISwitch *toggle=[UISwitch new];toggle.accessibilityIdentifier=@[@"pluginEnabled",@"autoFavorite",@"continueAfterHit",@"autoConfirmBattery"][row];toggle.on=row==0?ZZPicker.shared.enabled:[self.draft[toggle.accessibilityIdentifier]boolValue];[toggle addTarget:self action:row==0?@selector(enabledChanged:):@selector(scanOptionChanged:) forControlEvents:UIControlEventValueChanged];if(row==3)toggle.enabled=[self.draft[@"autoFavorite"]boolValue];cell.accessoryView=toggle;}
    else if(section==5){NSString *key=row==0?@"maxProducts":@"maxMinutes";cell.textLabel.text=row==0?@"最多处理件数":@"最长运行（分钟）";UITextField *field=[[UITextField alloc]initWithFrame:CGRectMake(0,0,90,38)];field.text=[self.draft[key]?:@(row==0?100:15) description];field.accessibilityIdentifier=key;field.textAlignment=NSTextAlignmentRight;field.keyboardType=UIKeyboardTypeNumberPad;[field addTarget:self action:@selector(fieldChanged:) forControlEvents:UIControlEventEditingChanged];self.fields[key]=field;cell.accessoryView=field;}
    else if(section==6){cell.selectionStyle=UITableViewCellSelectionStyleDefault;if(row==0){cell.textLabel.text=[self.surface isEqual:@"商品列表"]?@"应用条件并重新搜索":@"开始搜索并扫描";cell.textLabel.textAlignment=NSTextAlignmentCenter;cell.textLabel.textColor=UIColor.whiteColor;cell.backgroundColor=ZZRed();}else{cell.textLabel.text=@[@"", @"预览与分享诊断", @"命中记录", @"筛选核验记录"][row];if(row>=2){cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;cell.accessibilityIdentifier=row==2?@"hitHistory":@"inspectionResults";}cell.textLabel.textColor=UIColor.systemBlueColor;}}
    else{NSArray *results=ZZPicker.shared.snapshot[@"results"];NSDictionary *r=results[results.count-1-row];cell.textLabel.text=r[@"title"];cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ · iOS %@ · %@ · %@G · %@\n%@",ZZResultStatus(r[@"status"]),r[@"ios"],[r[@"channel"]length]?r[@"channel"]:@"渠道未知",r[@"capacity"],r[@"condition"],[r[@"reasons"]componentsJoinedByString:@"；"]];}
    if([cell.accessoryView isKindOfClass:UITextField.class]){
        UITextField *field=(id)cell.accessoryView;field.delegate=self;field.returnKeyType=UIReturnKeyDone;
        UIToolbar *toolbar=[[UIToolbar alloc]initWithFrame:CGRectMake(0,0,tableView.bounds.size.width,44)];toolbar.items=@[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard)]];field.inputAccessoryView=toolbar;
    }
    return cell;
}
- (void)fieldChanged:(UITextField *)field {self.draft[field.accessibilityIdentifier]=field.text?:@"";}
- (void)scanOptionChanged:(UISwitch *)toggle {[self dismissKeyboard];self.draft[toggle.accessibilityIdentifier]=@(toggle.on);
    if([toggle.accessibilityIdentifier isEqual:@"autoFavorite"])
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:4]] withRowAnimation:UITableViewRowAnimationNone];
}
- (void)enabledChanged:(UISwitch *)toggle {[self dismissKeyboard];[ZZPicker.shared setEnabled:toggle.on];}
- (void)toggleChoice:(UIButton *)button {NSArray *parts=[button.accessibilityIdentifier componentsSeparatedByString:@"|"];NSString *key=parts[0],*value=parts[1];NSMutableArray *values=[self.draft[key]mutableCopy];if([values containsObject:value])[values removeObject:value];else[values addObject:value];self.draft[key]=values;[self.view endEditing:YES];[self.tableView reloadData];}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    if(path.section==3&&path.row==1){
        [self dismissKeyboard];
        __weak ZZSettingsController *settings=self;
        UIViewController *inspection=ZZInspectionSettings(self.draft[@"reportFilters"]?:@{},^(NSDictionary *filters){
            settings.draft[@"reportFilters"]=filters;
            [settings.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
        });
        [self.navigationController pushViewController:inspection animated:YES];
        return;
    }
    if(path.section!=6)return;[self.view endEditing:YES];
    if(path.row==0){if(ZZPicker.shared.enabled&&![ZZPicker.shared.environment[@"verifiedAppVersion"]boolValue]){NSDictionary *e=ZZPicker.shared.environment;UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"转转版本尚未验证" message:[NSString stringWithFormat:@"当前 %@，适配基线 %@。页面与接口可能不同，建议先关闭自动收藏并进行少量测试。",e[@"appVersion"],e[@"expectedAppVersion"]]preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;[alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];[alert addAction:[UIAlertAction actionWithTitle:@"仅本次测试" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){(void)action;[self startAllowUnverified:YES];}]];[self presentViewController:alert animated:YES completion:nil];}else[self startAllowUnverified:NO];}
    else if(path.row==1)ZZPresentDiagnostics();
    else if(path.row==2)[self.navigationController pushViewController:[[ZZHitHistoryController alloc]initWithStyle:UITableViewStyleInsetGrouped] animated:YES];
    else [self.navigationController pushViewController:ZZInspectionResults(ZZPicker.shared.snapshot[@"allResults"]?:@[]) animated:YES];
}
- (void)startAllowUnverified:(BOOL)allow {NSString *error=[ZZPicker.shared startWithConfig:self.draft allowUnverified:allow];if(error){UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"检查设置" message:error preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;[alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];[self presentViewController:alert animated:YES completion:nil];}}
@end
void ZZPresentSettings(void) {UIViewController *top=ZZTopController();if(!top||ZZSettingsVisible())return;ZZSettingsController *settings=[[ZZSettingsController alloc]initWithStyle:UITableViewStyleInsetGrouped];UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:settings];navigation.view.tag=ZZPickerOwnViewTag;navigation.modalPresentationStyle=UIModalPresentationPageSheet;navigation.modalInPresentation=YES;ZZSettingsNavigation=navigation;[top presentViewController:navigation animated:YES completion:nil];}
