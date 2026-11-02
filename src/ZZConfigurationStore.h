#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ZZConfigurationStore : NSObject
- (instancetype)initWithDefaults:(NSUserDefaults *)defaults;
- (NSDictionary *)readSlots;
- (nullable NSString *)commitConfiguration:(NSDictionary *)config backupKeys:(NSArray<NSString *> *)keys;
@end
NS_ASSUME_NONNULL_END
