#import "ZZConfigurationStore.h"
@interface ZZConfigurationStore ()
@property(nonatomic,strong) NSUserDefaults *defaults;
@end
@implementation ZZConfigurationStore
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults {if((self=[super init]))_defaults=defaults;return self;}
- (NSDictionary *)readSlots {
    NSMutableDictionary *slots=[NSMutableDictionary new];for(NSString *slot in @[@"v3",@"v2",@"v1"])slots[slot]=[self.defaults objectForKey:[@"com.codex.zzpicker.config." stringByAppendingString:slot]]?:NSNull.null;return slots;
}
- (NSString *)commitConfiguration:(NSDictionary *)config backupKeys:(NSArray<NSString *> *)keys {
    if(![NSPropertyListSerialization propertyList:config isValidForFormat:NSPropertyListBinaryFormat_v1_0])return @"设置包含无法保存的值";
    NSString *key=@"com.codex.zzpicker.config.v3";id previous=[self.defaults objectForKey:key];
    @try {
        if(keys.count){
            NSMutableDictionary *values=[NSMutableDictionary new];
            for(NSString *name in keys){if(![@[@"com.codex.zzpicker.config.v3",@"com.codex.zzpicker.config.v2",@"com.codex.zzpicker.config.v1"]containsObject:name])return @"恢复备份键无效";id raw=[self.defaults objectForKey:name];if(raw)values[name]=raw;}
            NSDictionary *backup=@{@"values":values,@"time":@(NSDate.date.timeIntervalSince1970)};
            NSString *backupKey=[@"com.codex.zzpicker.config.v3.recoveryBackup." stringByAppendingString:NSUUID.UUID.UUIDString];
            [self.defaults setObject:backup forKey:backupKey];
            if(![self.defaults synchronize]||![[self.defaults objectForKey:backupKey]isEqual:backup])return @"损坏设置备份失败，原配置未覆盖，请重试";
        }
        [self.defaults setObject:config forKey:key];
        if([self.defaults synchronize]&&[[self.defaults objectForKey:key]isEqual:config])return nil;
    } @catch(NSException *exception){(void)exception;}
    @try {if(previous)[self.defaults setObject:previous forKey:key];else[self.defaults removeObjectForKey:key];[self.defaults synchronize];} @catch(NSException *exception){(void)exception;}
    return @"设置保存或回读失败，请保留当前任务并重试；损坏备份不会删除";
}
@end
