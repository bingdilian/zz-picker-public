#import <Foundation/Foundation.h>
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT void ZZReplaceMethod(Class cls, SEL selector, NSString *name, IMP (^makeReplacement)(IMP original));
FOUNDATION_EXPORT BOOL ZZTrustedBridgeFrame(NSURL * _Nullable topURL, NSURL * _Nullable frameURL, NSString *protocol, NSString *host, BOOL mainFrame);
FOUNDATION_EXPORT void ZZOnTaskResume(NSURLSessionTask *task, void (^callback)(void));
FOUNDATION_EXPORT NSDictionary * _Nullable ZZSearchSelection(NSString * _Nullable json);
FOUNDATION_EXPORT BOOL ZZInvokeRegisteredAction(id target, SEL action, id sender);
NS_ASSUME_NONNULL_END
