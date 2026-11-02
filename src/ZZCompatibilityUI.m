#import "ZZPicker.h"

static NSString *ZZValue(id value){return [value isKindOfClass:NSString.class]&&[value length]?value:@"未提供";}
static NSDictionary *ZZInfoRow(NSString *label,NSString *value){return @{@"label":label,@"value":value?:@"未提供"};}
@interface ZZInfoController : UITableViewController
@property(nonatomic,copy) NSArray<NSDictionary *> *sections;
@end
@implementation ZZInfoController
- (void)viewDidLoad {[super viewDidLoad];self.view.tag=ZZPickerOwnViewTag;self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=64;}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {(void)tableView;return self.sections.count;}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;return [self.sections[section][@"rows"]count];}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {(void)tableView;return self.sections[section][@"title"];}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;NSDictionary *row=self.sections[path.section][@"rows"][path.row];UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text=row[@"label"];cell.detailTextLabel.text=row[@"value"];cell.textLabel.numberOfLines=0;cell.detailTextLabel.numberOfLines=0;
    cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];cell.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];cell.textLabel.adjustsFontForContentSizeCategory=YES;cell.detailTextLabel.adjustsFontForContentSizeCategory=YES;
    BOOL action=row[@"url"]||row[@"choice"]||row[@"evidence"];cell.selectionStyle=action?UITableViewCellSelectionStyleDefault:UITableViewCellSelectionStyleNone;
    if(action)cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;cell.accessibilityIdentifier=row[@"identifier"]?:row[@"choice"]?:row[@"label"];return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];NSDictionary *row=self.sections[path.section][@"rows"][path.row];
    if(row[@"evidence"])ZZPushCompatibilityEvidence(self.navigationController,row[@"evidence"]);
    NSURL *url=[NSURL URLWithString:row[@"url"]?:@""];if([url.scheme isEqual:@"https"])[UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}
@end

@interface ZZModelPickerController : UITableViewController <UISearchResultsUpdating>
@property(nonatomic,copy) NSDictionary *catalog;
@property(nonatomic,copy) NSString *selectedID;
@property(nonatomic,copy) NSString *legacyText;
@property(nonatomic,copy) void (^didSelect)(NSString *);
@property(nonatomic,strong) UISearchController *search;
@property(nonatomic,copy) NSArray<NSArray *> *groups;
@end
@implementation ZZModelPickerController
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"手机型号";self.view.tag=ZZPickerOwnViewTag;self.tableView.estimatedRowHeight=72;self.tableView.rowHeight=UITableViewAutomaticDimension;
    self.search=[[UISearchController alloc]initWithSearchResultsController:nil];self.search.searchResultsUpdater=self;self.search.obscuresBackgroundDuringPresentation=NO;self.search.searchBar.placeholder=@"搜索已收录机型";self.navigationItem.searchController=self.search;self.navigationItem.hidesSearchBarWhenScrolling=NO;self.definesPresentationContext=YES;[self updateSearchResultsForSearchController:self.search];
}
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query=searchController.searchBar.text.lowercaseString?:@"";NSMutableArray *newer=[NSMutableArray new],*older=[NSMutableArray new];
    for(NSDictionary *model in self.catalog[@"models"])if(!query.length||[model[@"name"]rangeOfString:query options:NSCaseInsensitiveSearch].location!=NSNotFound){if([model[@"id"]hasPrefix:@"iphone-15-"])[newer addObject:model];else[older addObject:model];}
    self.groups=@[newer,older];UILabel *empty=[UILabel new];empty.text=@"本次目录未收录该机型";empty.textAlignment=NSTextAlignmentCenter;empty.numberOfLines=0;empty.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.tableView.backgroundView=newer.count+older.count?nil:empty;[self.tableView reloadData];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {(void)tableView;return self.legacyText.length?3:2;}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;return section==2?1:[self.groups[section]count];}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {(void)tableView;return @[@"iPhone 15系列",@"iPhone 14系列",@"保留原输入"][section];}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];cell.textLabel.numberOfLines=0;cell.detailTextLabel.numberOfLines=0;cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];cell.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];cell.textLabel.adjustsFontForContentSizeCategory=YES;cell.detailTextLabel.adjustsFontForContentSizeCategory=YES;
    if(path.section==2){cell.textLabel.text=self.legacyText;cell.detailTextLabel.text=@"保留原搜索文字；未收录时只可普通手动筛选";cell.accessibilityIdentifier=@"keepLegacyModel";return cell;}
    NSDictionary *m=self.groups[path.section][path.row];cell.textLabel.text=m[@"name"];cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ · iOS %@起 · %@ GB\n资料已核对；真机报告仍需核验",m[@"chip"],m[@"minIOS"],[m[@"capacities"]componentsJoinedByString:@" / "]];cell.accessoryType=[m[@"id"]isEqual:self.selectedID]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;cell.accessibilityIdentifier=m[@"id"];return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path { [tableView deselectRowAtIndexPath:path animated:YES];NSString *value=path.section==2?@"":self.groups[path.section][path.row][@"id"];if(self.didSelect)self.didSelect(value);[self.navigationController popViewControllerAnimated:YES];}
@end

void ZZPushModelPicker(UINavigationController *navigation,NSDictionary *catalog,NSString *selectedID,NSString *legacyText,void (^didSelect)(NSString *)){
    ZZModelPickerController *picker=[[ZZModelPickerController alloc]initWithStyle:UITableViewStyleInsetGrouped];picker.catalog=catalog;picker.selectedID=selectedID;picker.legacyText=legacyText;picker.didSelect=didSelect;[navigation pushViewController:picker animated:YES];
}
void ZZPushCompatibilityEvidence(UINavigationController *navigation,NSDictionary *evidence){
    ZZInfoController *info=[[ZZInfoController alloc]initWithStyle:UITableViewStyleInsetGrouped];info.title=@"支持依据";NSMutableArray *sections=[NSMutableArray new];
    NSDictionary *model=[evidence[@"model"]isKindOfClass:NSDictionary.class]?evidence[@"model"]:@{};
    [sections addObject:@{@"title":@"待售手机与实际范围",@"rows":@[ZZInfoRow(@"机型",ZZValue(model[@"name"])),ZZInfoRow(@"实际候选范围",ZZValue(evidence[@"effectiveRange"][@"label"])),ZZInfoRow(@"核验边界",evidence[@"limitation"]?:@"按报告标称核验，不保证实物系统"),ZZInfoRow(@"规则版本",ZZValue(evidence[@"ruleVersion"])),ZZInfoRow(@"资料核对日期",ZZValue(evidence[@"reviewedAt"]))]}];
    for(NSDictionary *tool in evidence[@"tools"]){
        NSMutableArray *rows=[NSMutableArray new];NSMutableArray *ranges=[NSMutableArray new];for(NSDictionary *r in tool[@"ranges"])[ranges addObject:[r[@"min"]isEqual:r[@"max"]]?r[@"min"]:[NSString stringWithFormat:@"%@～%@",r[@"min"],r[@"max"]]];
        [rows addObject:ZZInfoRow(@"软件范围（仍受机型与手动条件约束）",[ranges componentsJoinedByString:@" 或 "])];
        for(NSDictionary *path in tool[@"installPaths"])[rows addObject:ZZInfoRow(@"安装路径",[NSString stringWithFormat:@"%@ · %@\n%@",path[@"id"],path[@"revision"],[path[@"requiresComputer"]boolValue]?@"需要电脑":@"无需电脑前提"])];
        for(NSDictionary *predicate in tool[@"predicates"])[rows addObject:ZZInfoRow(@"构建前提",[NSString stringWithFormat:@"%@：%@\n已提供但未收录或冲突的构建待确认；Beta/RC排除。",predicate[@"version"],[predicate[@"kind"]isEqual:@"versionWide"]?@"路径覆盖全部正式构建，缺构建号不单独拦截":@"必须提供已收录构建号"])];
        NSString *name=[tool[@"id"]isEqual:@"trollstore"]?@"TrollStore":@"Dopamine";[sections addObject:@{@"title":[NSString stringWithFormat:@"%@ %@",name,tool[@"version"]],@"rows":rows}];
    }
    NSMutableArray *sources=[NSMutableArray new];for(NSDictionary *source in evidence[@"sources"])[sources addObject:@{@"label":source[@"title"],@"value":[NSString stringWithFormat:@"%@核对 · 点按离开插件打开官方来源",source[@"reviewedAt"]],@"url":source[@"url"]}];
    [sections addObject:@{@"title":@"官方来源",@"rows":sources}];info.sections=sections;[navigation pushViewController:info animated:YES];
}

@interface ZZRecoveryController : ZZInfoController
@property(nonatomic,copy) void (^didChoose)(NSString *);
@end
@implementation ZZRecoveryController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];NSString *choice=self.sections[path.section][@"rows"][path.row][@"choice"];if(!choice)return;
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:[choice isEqual:@"useDefaults"]?@"使用默认设置？":@"恢复旧设置？" message:@"确认后先保留损坏设置原文，再保存恢复结果。不会自动搜索或收藏。" preferredStyle:UIAlertControllerStyleAlert];alert.view.tag=ZZPickerOwnViewTag;
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确认恢复" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){(void)action;if(self.didChoose)self.didChoose(choice);}]];[self presentViewController:alert animated:YES completion:nil];
}
@end
void ZZPushConfigRecovery(UINavigationController *navigation,NSDictionary *state,void (^didChoose)(NSString *)){
    ZZRecoveryController *info=[[ZZRecoveryController alloc]initWithStyle:UITableViewStyleInsetGrouped];info.title=@"恢复设置";info.didChoose=didChoose;
    NSMutableArray *actions=[NSMutableArray new],*preview=[NSMutableArray new];NSDictionary *backup=[state[@"backup"]isKindOfClass:NSDictionary.class]?state[@"backup"]:nil;
    if(backup){[preview addObject:ZZInfoRow(@"旧型号",backup[@"model"])];[preview addObject:ZZInfoRow(@"原系统下限 / 上限",[NSString stringWithFormat:@"%@ / %@",[backup[@"manualMinIOS"]length]?backup[@"manualMinIOS"]:@"不限",[backup[@"manualMaxIOS"]length]?backup[@"manualMaxIOS"]:@"不限"])];[preview addObject:ZZInfoRow(@"自动收藏",[backup[@"autoFavorite"]boolValue]?@"原偏好：开启":@"原偏好：关闭")];[preview addObject:ZZInfoRow(@"恢复后的用途",@"巨魔与完整越狱均关闭，其他原条件保持")];[actions addObject:@{@"label":@"恢复旧设置",@"value":@"先确认上述预览",@"choice":@"restoreBackup"}];}
    else{[preview addObject:ZZInfoRow(@"无可用旧备份",@"原损坏数据保留；可以确认使用默认设置")];[actions addObject:ZZInfoRow(@"恢复旧设置不可用",@"没有通过校验的旧备份")];}
    [actions addObject:@{@"label":@"使用默认设置",@"value":@"15 Pro Max、用途与自动收藏关闭；需再次确认",@"choice":@"useDefaults"}];
    info.sections=@[@{@"title":@"设置损坏，任务不会自动开始",@"rows":@[ZZInfoRow(@"检测到的问题",[state[@"issues"]componentsJoinedByString:@"；"])]},@{@"title":@"恢复预览",@"rows":preview},@{@"title":@"选择恢复方式",@"rows":actions}];[navigation pushViewController:info animated:YES];
}

static NSString *ZZVerdict(NSString *state){return @{@"pass":@"符合",@"match":@"符合",@"reject":@"不符合",@"unknown":@"待确认",@"notRequired":@"未要求"}[state]?:@"待确认";}
static NSString *ZZFavoriteState(NSString *status){return @{@"favorited":@"已收藏，独立回读已确认",@"already":@"原有收藏，已保留",@"favoriteUnknown":@"收藏待确认，不自动重试",@"match":@"未记录收藏成功"}[status]?:@"未操作收藏";}
void ZZPushProductChecks(UINavigationController *navigation,NSDictionary *result){
    ZZInfoController *info=[[ZZInfoController alloc]initWithStyle:UITableViewStyleInsetGrouped];info.title=@"商品核验详情";
    NSDictionary *evaluation=[result[@"evaluation"]isKindOfClass:NSDictionary.class]?result[@"evaluation"]:@{};NSDictionary *evidence=evaluation[@"evidence"]?:@{};
    NSString *source=@{@"report":@"验机报告",@"title":@"仅商品标题，未核对硬件",@"conflict":@"报告与商品标题冲突",@"missing":@"未提供"}[result[@"modelSource"]?:@""]?:@"未提供";
    NSMutableArray *fields=[NSMutableArray arrayWithArray:@[ZZInfoRow(@"报告机型",ZZValue(result[@"model"])),ZZInfoRow(@"型号来源",source),ZZInfoRow(@"报告系统原文",ZZValue(result[@"iosRaw"])),ZZInfoRow(@"标称数字版本",ZZValue(result[@"ios"])),ZZInfoRow(@"构建号",ZZValue(result[@"build"])),ZZInfoRow(@"发行通道",[result[@"releaseKind"]isEqual:@"unverified"]?@"未独立验证，按报告标称判断":ZZValue(result[@"releaseKind"])),ZZInfoRow(@"购买渠道",ZZValue(result[@"channel"])),ZZInfoRow(@"容量",[result[@"capacity"]length]?[result[@"capacity"]stringByAppendingString:@" GB"]:@"未提供"),ZZInfoRow(@"外观成色",ZZValue(result[@"condition"]))]];
    NSDictionary *labels=@{@"identity":@"商品身份",@"model":@"型号",@"sale":@"销售状态",@"system":@"系统范围",@"channel":@"购买渠道",@"capacity":@"容量条件",@"condition":@"成色条件",@"report":@"验机报告",@"trollstore":@"巨魔",@"jailbreak":@"完整越狱"};NSMutableArray *checks=[NSMutableArray new];
    for(NSDictionary *check in evaluation[@"checks"])[checks addObject:ZZInfoRow([NSString stringWithFormat:@"%@ · %@",labels[check[@"key"]]?:check[@"key"],ZZVerdict(check[@"state"])],[check[@"reasons"]componentsJoinedByString:@"；"])];
    info.sections=@[@{@"title":@"本次结果",@"rows":@[ZZInfoRow(ZZValue(result[@"title"]),ZZVerdict(evaluation[@"status"])),ZZInfoRow(@"收藏状态",ZZFavoriteState(result[@"status"])),ZZInfoRow(@"规则版本",ZZValue(evaluation[@"ruleVersion"]))]},@{@"title":@"报告字段",@"rows":fields},@{@"title":@"逐项核验（保留全部不符和未知原因）",@"rows":checks},@{@"title":@"判断依据",@"rows":@[@{@"label":@"工具、路径与官方来源",@"value":evidence[@"limitation"]?:@"依据记录未提供",@"evidence":evidence}]}];[navigation pushViewController:info animated:YES];
}

@interface ZZRecordsController : UITableViewController
@property(nonatomic,copy) NSDictionary *taskSnapshot;
@property(nonatomic,copy) NSArray<NSDictionary *> *visibleRecords;
@property(nonatomic,strong) UISegmentedControl *filter;
@end
@implementation ZZRecordsController
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"核验记录";self.view.tag=ZZPickerOwnViewTag;self.tableView.estimatedRowHeight=88;self.tableView.rowHeight=UITableViewAutomaticDimension;
    UIView *header=[[UIView alloc]initWithFrame:CGRectMake(0,0,self.tableView.bounds.size.width,64)];self.filter=[[UISegmentedControl alloc]initWithItems:@[@"全部",@"符合",@"不符合",@"待确认"]];self.filter.frame=CGRectMake(16,10,self.tableView.bounds.size.width-32,44);self.filter.autoresizingMask=UIViewAutoresizingFlexibleWidth;self.filter.selectedSegmentIndex=0;self.filter.accessibilityIdentifier=@"recordFilter";[self.filter addTarget:self action:@selector(refilter) forControlEvents:UIControlEventValueChanged];[header addSubview:self.filter];self.tableView.tableHeaderView=header;[self refilter];
}
- (void)refilter {
    NSArray *all=self.taskSnapshot[@"allResults"]?:@[];NSInteger selected=self.filter.selectedSegmentIndex;
    self.visibleRecords=[all filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary *record,NSDictionary *bindings){(void)bindings;NSString *status=record[@"evaluation"][@"status"]?:record[@"status"];if([@[@"already",@"favorited",@"favoriteUnknown"]containsObject:status])status=@"match";return selected==0||[status isEqual:@[@"",@"match",@"reject",@"unknown"][selected]];}]];[self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;(void)section;return MAX(1,self.visibleRecords.count);}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {(void)tableView;(void)section;return [NSString stringWithFormat:@"打开时快照 · %lu/%lu件 · 规则%@",(unsigned long)self.visibleRecords.count,(unsigned long)[self.taskSnapshot[@"allResults"]count],self.taskSnapshot[@"ruleVersion"]?:@"未提供"];}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];cell.textLabel.numberOfLines=0;cell.detailTextLabel.numberOfLines=0;cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];cell.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];cell.textLabel.adjustsFontForContentSizeCategory=YES;cell.detailTextLabel.adjustsFontForContentSizeCategory=YES;
    if(!self.visibleRecords.count){cell.textLabel.text=@"暂无此类核验记录";cell.selectionStyle=UITableViewCellSelectionStyleNone;return cell;}
    NSDictionary *record=self.visibleRecords[path.row];cell.textLabel.text=ZZValue(record[@"title"]);cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ · iOS %@ · %@\n%@",ZZVerdict(record[@"evaluation"][@"status"]?:record[@"status"]),ZZValue(record[@"ios"]),ZZFavoriteState(record[@"status"]),[record[@"reasons"]componentsJoinedByString:@"；"]];cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;cell.accessibilityIdentifier=[@"result|" stringByAppendingString:record[@"id"]?:@""];return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {[tableView deselectRowAtIndexPath:path animated:YES];if((NSUInteger)path.row<self.visibleRecords.count)ZZPushProductChecks(self.navigationController,self.visibleRecords[path.row]);}
- (void)close {[self dismissViewControllerAnimated:YES completion:^{[ZZPicker.shared showTask];}];}
@end
void ZZPushRunRecords(UINavigationController *navigation,NSDictionary *snapshot){ZZRecordsController *records=[[ZZRecordsController alloc]initWithStyle:UITableViewStyleInsetGrouped];records.taskSnapshot=snapshot;[navigation pushViewController:records animated:YES];}
void ZZPresentRunRecords(void){
    UIViewController *top=ZZTopController();if(!top)return;[ZZPicker.shared pause:@"查看核验记录，任务保持暂停"];ZZHideTaskPanel();
    ZZRecordsController *records=[[ZZRecordsController alloc]initWithStyle:UITableViewStyleInsetGrouped];records.taskSnapshot=ZZPicker.shared.snapshot;records.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:records action:@selector(close)];UINavigationController *navigation=[[UINavigationController alloc]initWithRootViewController:records];navigation.view.tag=ZZPickerOwnViewTag;[top presentViewController:navigation animated:YES completion:nil];
}
