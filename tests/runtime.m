#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "ZZRuntime.h"
@interface Base : NSObject
- (NSString *)value;
@end
@implementation Base
- (NSString *)value {return @"base";}
@end
@interface Child : Base @end
@implementation Child
- (NSString *)value {return [[super value]stringByAppendingString:@".child"];}
@end
@interface FakeTask : NSObject
@property(nonatomic) NSURLSessionTaskState state;
@property(nonatomic) NSUInteger resumeCount;
- (void)resume;
@end
@implementation FakeTask
- (void)resume {self.resumeCount++;self.state=NSURLSessionTaskStateRunning;}
@end
static void Hook(Class cls,NSString *suffix){
    ZZReplaceMethod(cls,@selector(value),@"test",^IMP(IMP original){
        return imp_implementationWithBlock(^NSString *(id object){
            return [((NSString *(*)(id,SEL))original)(object,@selector(value))stringByAppendingString:suffix];
        });
    });
}
@interface ActionTarget : NSObject
@property(nonatomic) NSUInteger calls;
- (void)tap:(id)sender;
- (void)unsafe:(NSInteger)value;
@end
@implementation ActionTarget
- (void)tap:(id)sender {(void)sender;self.calls++;}
- (void)unsafe:(NSInteger)value {(void)value;self.calls+=100;}
@end
int main(void){@autoreleasepool {
    Hook(Base.class,@".baseHook");Hook(Child.class,@".childHook");Hook(Child.class,@".duplicate");
    NSCAssert([[Base.new value]isEqual:@"base.baseHook"],@"base interception failed");
    NSCAssert([[Child.new value]isEqual:@"base.baseHook.child.childHook"],@"super calls or duplicate guard failed");
    NSURL *top=[NSURL URLWithString:@"https://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail?infoId=123"];
    NSCAssert(ZZTrustedBridgeFrame(top,top,@"https",@"m.zhuanzhuan.com",YES),@"trusted main frame rejected");
    NSCAssert(!ZZTrustedBridgeFrame(top,top,@"https",@"m.zhuanzhuan.com",NO),@"iframe accepted");
    NSCAssert(!ZZTrustedBridgeFrame(top,top,@"https",@"evil.example",YES),@"foreign security origin accepted");
    NSCAssert(!ZZTrustedBridgeFrame(top,[NSURL URLWithString:@"http://m.zhuanzhuan.com/"],@"http",@"m.zhuanzhuan.com",YES),@"HTTP accepted");
    NSCAssert(!ZZTrustedBridgeFrame(top,[NSURL URLWithString:@"https://app.zhuanzhuan.com/"],@"https",@"app.zhuanzhuan.com",YES),@"mismatched document accepted");
    FakeTask *task=[FakeTask new];task.state=NSURLSessionTaskStateSuspended;__block NSUInteger starts=0;
    ZZOnTaskResume((NSURLSessionTask *)(id)task,^{starts++;});
    NSCAssert(starts==0,@"creating a suspended task must not report network start");
    [task resume];NSCAssert(starts==1&&task.resumeCount==1,@"resume must report start and preserve original");
    task.state=NSURLSessionTaskStateSuspended;[task resume];NSCAssert(starts==1&&task.resumeCount==2,@"resuming again must not report twice");
    FakeTask *cancelled=[FakeTask new];cancelled.state=NSURLSessionTaskStateCanceling;ZZOnTaskResume((NSURLSessionTask *)(id)cancelled,^{starts++;});
    [cancelled resume];NSCAssert(starts==1,@"cancelled task must not report start");
    NSDictionary *selection=ZZSearchSelection(@"{\"clickItems\":{\"69\":[{\"value\":\"5170\",\"cmd\":\"params_new6651=1080730\",\"token\":\"private\"}]}}");
    NSCAssert([selection[@"69"][0][@"value"]isEqual:@"5170"]&&!selection[@"69"][0][@"token"],@"filter selection sanitation failed");
    NSCAssert(ZZSearchSelection(@"broken")==nil&&ZZSearchSelection(@"[]")==nil,@"invalid filter selection accepted");
    ActionTarget *target=[ActionTarget new];NSCAssert(ZZInvokeRegisteredAction(target,@selector(tap:),target)&&target.calls==1,@"registered object action failed");
    NSCAssert(!ZZInvokeRegisteredAction(target,@selector(unsafe:),target)&&target.calls==1,@"unsafe scalar action invoked");
    puts("Runtime hooks, bridge trust and suspended-task resume tests: PASS");return 0;
}}
