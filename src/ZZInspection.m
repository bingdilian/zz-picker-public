#import "ZZPicker.h"

@interface ZZInspectionSettingsController : UITableViewController
@property(nonatomic,copy) NSArray<NSDictionary *> *groups;
@property(nonatomic,strong) NSMutableDictionary<NSString *,NSMutableDictionary *> *draft;
@property(nonatomic,copy) void (^onApply)(NSDictionary *);
@end

@implementation ZZInspectionSettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"验机报告筛选";
    self.view.tag=ZZPickerOwnViewTag;
    self.tableView.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"应用筛选" style:UIBarButtonItemStyleDone target:self action:@selector(apply)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier=@"applyInspectionFilters";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return self.groups.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    NSDictionary *group=self.groups[section];
    NSString *summary=[ZZPicker.shared inspectionSummary:self.draft][group[@"key"]];
    return [NSString stringWithFormat:@"%@ · %@",group[@"label"],summary?:@"不限"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    NSString *key=self.groups[section][@"key"], *mode=self.draft[key][@"mode"];
    if([key isEqual:@"battery"])return @"更换情况可多选。健康值与充电次数留空表示不限。";
    if([mode isEqual:@"wear"])return @"允许划痕、磕碰、掉漆或磨损。其余适用项目须通过。";
    if([mode isEqual:@"selected"])return @"只核验已勾选的项目。未选择项目时按不限处理。";
    if([mode isEqual:@"all"]&&[key isEqual:@"repair"])return @"适用项目须通过。有维修、更换、浸液或拆机记录时排除。";
    if([mode isEqual:@"all"])return @"适用项目须通过。报告字段缺失或无法核对时列为待确认。";
    return nil;
}

- (NSArray<NSDictionary *> *)rowsForSection:(NSInteger)section {
    NSDictionary *group=self.groups[section];
    NSString *key=group[@"key"];
    NSDictionary *rule=self.draft[key];
    NSMutableArray *rows=[NSMutableArray new];
    if([key isEqual:@"battery"]){
        for(NSString *type in group[@"types"])
            [rows addObject:@{@"kind":@"choice",@"field":@"types",@"value":type,@"label":type}];
        [rows addObjectsFromArray:@[@{@"kind":@"number",@"field":@"minHealth",@"label":@"最低电池健康值（%）"},
                                    @{@"kind":@"number",@"field":@"maxCycles",@"label":@"最多充电次数"}]];
        return rows;
    }
    [rows addObject:@{@"kind":@"mode",@"label":@"筛选方式"}];
    if(![rule[@"mode"] isEqual:@"selected"])return rows;
    for(NSString *wear in group[@"wearTypes"])
        [rows addObject:@{@"kind":@"choice",@"field":@"wear",@"value":wear,@"label":wear}];
    for(NSArray *subgroup in group[@"groups"]){
        for(NSString *item in subgroup[1]){
            NSString *path=[NSString stringWithFormat:@"%@›%@",subgroup[0],item];
            [rows addObject:@{@"kind":@"choice",@"field":@"items",@"value":path,@"label":item,@"subtitle":subgroup[0]}];
        }
    }
    if([key isEqual:@"repair"]&&[rule[@"items"] containsObject:@"拆机情况›拆机情况"])
        [rows addObject:@{@"kind":@"switch",@"field":@"allowBatteryOnly",@"label":@"允许仅平台拆机换电"}];
    return rows;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return [self rowsForSection:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    NSDictionary *group=self.groups[path.section], *row=[self rowsForSection:path.section][path.row];
    NSString *key=group[@"key"], *kind=row[@"kind"], *field=row[@"field"];
    NSDictionary *rule=self.draft[key];
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text=row[@"label"];
    cell.textLabel.numberOfLines=0;
    cell.detailTextLabel.text=row[@"subtitle"];
    cell.detailTextLabel.numberOfLines=0;
    if([kind isEqual:@"mode"]){
        cell.accessibilityIdentifier=[@"inspectionMode." stringByAppendingString:key];
        cell.detailTextLabel.text=group[@"modes"][rule[@"mode"]];
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }else if([kind isEqual:@"choice"]){
        BOOL selected=[rule[field] containsObject:row[@"value"]];
        cell.accessoryType=selected?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
        if(selected)cell.accessibilityTraits|=UIAccessibilityTraitSelected;
    }else if([kind isEqual:@"number"]){
        UITextField *input=[[UITextField alloc]initWithFrame:CGRectMake(0,0,MIN(96,tableView.bounds.size.width*0.3),40)];
        input.text=rule[field];
        input.placeholder=@"不限";
        input.keyboardType=UIKeyboardTypeNumberPad;
        input.textAlignment=NSTextAlignmentRight;
        input.accessibilityLabel=row[@"label"];
        input.accessibilityIdentifier=field;
        [input addTarget:self action:@selector(numberChanged:) forControlEvents:UIControlEventEditingChanged];
        cell.accessoryView=input;
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }else{
        UISwitch *toggle=[UISwitch new];
        toggle.on=[rule[field] boolValue];
        toggle.accessibilityLabel=row[@"label"];
        [toggle addTarget:self action:@selector(batteryExceptionChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView=toggle;
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)numberChanged:(UITextField *)field {
    self.draft[@"battery"][field.accessibilityIdentifier]=field.text?:@"";
}

- (void)batteryExceptionChanged:(UISwitch *)toggle {
    self.draft[@"repair"][@"allowBatteryOnly"]=@(toggle.on);
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.groups.count-1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    [self.view endEditing:YES];
    NSDictionary *group=self.groups[path.section], *row=[self rowsForSection:path.section][path.row];
    NSMutableDictionary *rule=self.draft[group[@"key"]];
    if([row[@"kind"] isEqual:@"choice"]){
        NSString *field=row[@"field"], *value=row[@"value"];
        NSMutableArray *items=[rule[field] mutableCopy];
        if([items containsObject:value])[items removeObject:value];else [items addObject:value];
        rule[field]=items;
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:path.section] withRowAnimation:UITableViewRowAnimationNone];
    }else if([row[@"kind"] isEqual:@"mode"]){
        UIAlertController *menu=[UIAlertController alertControllerWithTitle:group[@"label"] message:nil preferredStyle:UIAlertControllerStyleAlert];
        menu.view.tag=ZZPickerOwnViewTag;
        for(NSString *mode in @[@"any",@"wear",@"all",@"selected"]){
            NSString *label=group[@"modes"][mode];
            if(!label)continue;
            [menu addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){
                rule[@"mode"]=mode;
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:path.section] withRowAnimation:UITableViewRowAnimationNone];
            }]];
        }
        [menu addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:menu animated:YES completion:nil];
    }
}

- (void)apply {
    [self.view endEditing:YES];
    NSDictionary *checked=[ZZPicker.shared validateInspectionDraft:self.draft];
    NSArray *errors=checked[@"errors"];
    if(!checked[@"filters"]||errors.count){
        UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"检查验机筛选" message:[errors componentsJoinedByString:@"\n"]?:@"筛选条件无法验证" preferredStyle:UIAlertControllerStyleAlert];
        alert.view.tag=ZZPickerOwnViewTag;
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    self.onApply(checked[@"filters"]);
    [self.navigationController popViewControllerAnimated:YES];
}
@end

UIViewController *ZZInspectionSettings(NSDictionary *filters, void (^onApply)(NSDictionary *)) {
    ZZInspectionSettingsController *controller=[[ZZInspectionSettingsController alloc]initWithStyle:UITableViewStyleInsetGrouped];
    controller.groups=ZZPicker.shared.inspectionGroups;
    controller.draft=[NSMutableDictionary new];
    NSDictionary *checked=[ZZPicker.shared validateInspectionDraft:filters][@"filters"];
    for(NSString *key in checked)controller.draft[key]=[checked[key] mutableCopy];
    controller.onApply=onApply;
    return controller;
}

@interface ZZInspectionResultsController : UITableViewController
@property(nonatomic,copy) NSArray<NSDictionary *> *results;
@end

@implementation ZZInspectionResultsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"筛选核验记录";
    self.view.tag=ZZPickerOwnViewTag;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;(void)section;
    return self.results.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;(void)section;
    return self.results.count?@"最近的待确认与排除记录":@"暂无待确认或排除记录";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)tableView;
    NSDictionary *row=self.results[path.row];
    UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text=row[@"title"];
    cell.textLabel.numberOfLines=0;
    NSString *status=[row[@"status"] isEqual:@"reject"]?@"已排除":@"待确认";
    NSArray *reasons=row[@"reasons"];
    cell.detailTextLabel.text=[NSString stringWithFormat:@"%@ · %@",status,reasons.firstObject?:@"原因未知"];
    cell.detailTextLabel.numberOfLines=0;
    cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];
    NSDictionary *row=self.results[path.row];
    UIAlertController *detail=[UIAlertController alertControllerWithTitle:row[@"title"] message:[row[@"reasons"] componentsJoinedByString:@"\n"] preferredStyle:UIAlertControllerStyleAlert];
    detail.view.tag=ZZPickerOwnViewTag;
    [detail addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:detail animated:YES completion:nil];
}
@end

UIViewController *ZZInspectionResults(NSArray<NSDictionary *> *rows) {
    ZZInspectionResultsController *controller=[[ZZInspectionResultsController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    NSMutableArray *results=[NSMutableArray new];
    for(NSDictionary *row in rows.reverseObjectEnumerator){
        if([@[@"reject",@"unknown"] containsObject:row[@"status"]])[results addObject:row];
        if(results.count>=50)break;
    }
    controller.results=results;
    return controller;
}
