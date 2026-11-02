#import <Foundation/Foundation.h>
#import "ZZConfigurationStore.h"
@interface FailingDefaults : NSUserDefaults
@property(nonatomic,copy) NSString *ignoredPrefix;
@end
@implementation FailingDefaults
- (void)setObject:(id)value forKey:(NSString *)key {if(self.ignoredPrefix&&[key hasPrefix:self.ignoredPrefix])return;[super setObject:value forKey:key];}
@end
int main(int argc,const char **argv){@autoreleasepool{
    NSString *key=@"com.codex.zzpicker.config.v3";
    if(argc==3){NSUserDefaults *child=[[NSUserDefaults alloc]initWithSuiteName:[NSString stringWithUTF8String:argv[2]]];return [[[child dictionaryForKey:key]objectForKey:@"model"]isEqual:@"persisted"]?0:2;}
    NSString *suite=[@"local.zzpicker.config." stringByAppendingString:NSUUID.UUID.UUIDString];
    FailingDefaults *defaults=[[FailingDefaults alloc]initWithSuiteName:suite];ZZConfigurationStore *store=[[ZZConfigurationStore alloc]initWithDefaults:defaults];
    NSDictionary *old=@{@"model":@"old",@"autoFavorite":@YES};[defaults setObject:old forKey:@"com.codex.zzpicker.config.v2"];
    NSCAssert([[store readSlots][@"v2"]isEqual:old],@"old slot lost");
    NSDictionary *next=@{@"schemaVersion":@3,@"model":@"persisted"};
    NSCAssert([store commitConfiguration:next backupKeys:@[]]==nil,@"valid write failed");
    NSCAssert([[defaults objectForKey:@"com.codex.zzpicker.config.v2"]isEqual:old],@"old key overwritten");
    NSTask *child=[NSTask new];child.executableURL=[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[0]]];child.arguments=@[@"read",suite];[child launchAndReturnError:nil];[child waitUntilExit];NSCAssert(child.terminationStatus==0,@"configuration did not survive process restart");
    [defaults setObject:@"damaged" forKey:key];
    NSCAssert([[store readSlots][@"v3"]isEqual:@"damaged"],@"wrong type silently hidden");
    defaults.ignoredPrefix=@"com.codex.zzpicker.config.v3.recoveryBackup.";
    NSCAssert([store commitConfiguration:next backupKeys:@[key]]!=nil,@"failed backup must block overwrite");
    NSCAssert([[defaults objectForKey:key]isEqual:@"damaged"],@"failed backup overwrote damage");
    defaults.ignoredPrefix=nil;
    NSCAssert([store commitConfiguration:next backupKeys:@[key]]==nil,@"recovery write failed");
    NSArray *backupKeys=[[defaults dictionaryRepresentation].allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *name,NSDictionary *bindings){(void)bindings;return [name hasPrefix:@"com.codex.zzpicker.config.v3.recoveryBackup."];}]];
    NSCAssert(backupKeys.count==1,@"raw backup missing");
    NSCAssert([[[defaults objectForKey:backupKeys.firstObject]objectForKey:@"values"][key]isEqual:@"damaged"],@"damaged raw value was not preserved");
    defaults.ignoredPrefix=key;
    NSCAssert([store commitConfiguration:@{@"model":@"will fail"} backupKeys:@[]]!=nil,@"readback failure must return error");
    NSCAssert([[defaults objectForKey:key]isEqual:next],@"failed write lost original config");
    defaults.ignoredPrefix=nil;[defaults removePersistentDomainForName:suite];
    puts("Configuration slots, recovery backup, write failure and process restart: PASS");return 0;
}}
