#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN
#define ZZPickerOwnViewTag 0x5A5A5001
#define ZZPickerVersion @"1.2.0-beta11"

@interface ZZPicker : NSObject <WKScriptMessageHandler>
+ (instancetype)shared;
@property(nonatomic, readonly) NSDictionary *config;
@property(nonatomic, readonly) NSArray<NSString *> *logs;
@property(nonatomic, readonly, getter=isEnabled) BOOL enabled;
@property(nonatomic, weak, nullable) WKWebView *detailWeb;
@property(nonatomic, weak, nullable) UIViewController *searchController;
@property(nonatomic, strong, nullable) UINavigationController *detailNavigation;
@property(nonatomic, strong, nullable) WKWebViewConfiguration *borrowedConfiguration;
@property(nonatomic, copy, nullable) NSString *borrowedUserAgent;
- (void)install;
- (NSDictionary *)snapshot;
- (NSDictionary *)presentation;
- (nullable NSString *)normalizedCapacity:(NSString *)label;
- (NSArray<NSString *> *)purchaseChannels;
- (nullable NSString *)saveConfigurationDraft:(NSDictionary *)draft;
- (nullable NSString *)startWithConfig:(NSDictionary *)config;
- (nullable NSString *)startWithConfig:(NSDictionary *)config allowUnverified:(BOOL)allow;
- (void)setEnabled:(BOOL)enabled;
- (NSDictionary *)environment;
- (void)pause:(NSString *)reason;
- (void)resume;
- (void)stop;
- (void)showSettings;
- (void)showTask;
- (void)viewMatched;
- (NSArray<NSDictionary *> *)hitHistory;
- (BOOL)viewRecordedProduct:(NSDictionary *)row;
- (void)returnedFromDetails;
- (void)observeFailure:(NSDictionary *)metadata;
- (void)log:(NSString *)message;
- (NSString *)diagnostics;
- (NSString *)diagnosticsWithDetails:(BOOL)includeDetails;
- (void)observeRequest:(NSDictionary *)metadata;
- (nullable NSDictionary *)requestContext:(NSURLRequest *)request;
- (void)observeJSON:(NSDictionary *)json metadata:(NSDictionary *)metadata webView:(nullable WKWebView *)webView;
- (void)installWebView:(WKWebView *)webView;
@end

FOUNDATION_EXPORT void ZZInstallNetworkHooks(void);
@interface ZZFilterDriver : NSObject
- (instancetype)initWithConfig:(NSDictionary *)config fields:(NSArray<NSString *> *)fields;
- (void)step;
@property(nonatomic,readonly) BOOL willCommit;
@property(nonatomic,readonly) BOOL complete;
- (NSDictionary *)diagnostics;
@end
FOUNDATION_EXPORT BOOL ZZActivateText(NSString *label, BOOL prefix, BOOL topOnly);
FOUNDATION_EXPORT NSString *ZZSearchSurface(void);
FOUNDATION_EXPORT NSDictionary *ZZSearchDiagnostics(void);
FOUNDATION_EXPORT void ZZPresentSettings(void);
FOUNDATION_EXPORT void ZZPresentDiagnostics(void);
FOUNDATION_EXPORT void ZZDismissSettings(void (^completion)(void));
FOUNDATION_EXPORT BOOL ZZSettingsVisible(void);
FOUNDATION_EXPORT void ZZShowTaskPanel(void);
FOUNDATION_EXPORT void ZZHideTaskPanel(void);
FOUNDATION_EXPORT WKWebView * _Nullable ZZLoadCollector(NSDictionary *item, BOOL reloadOnly);
FOUNDATION_EXPORT void ZZStopCollector(void);
FOUNDATION_EXPORT void ZZShowMatchedProduct(NSDictionary *item);
void ZZShowRecordedProduct(NSDictionary *item);
NSURL *ZZHitHistoryDirectory(void);
BOOL ZZSaveHitTask(NSURL *directory, NSDictionary *task);
NSArray<NSDictionary *> *ZZReadHitTasks(NSURL *directory);
FOUNDATION_EXPORT BOOL ZZViewerVisible(void);
FOUNDATION_EXPORT UIWindow * _Nullable ZZAppWindow(void);
FOUNDATION_EXPORT UIViewController * _Nullable ZZTopController(void);
FOUNDATION_EXPORT BOOL ZZSubmitSearch(NSString *keyword);
FOUNDATION_EXPORT BOOL ZZOpenNativeProduct(NSDictionary *item);
FOUNDATION_EXPORT BOOL ZZScrollSearchList(void);
FOUNDATION_EXPORT void ZZResetPagination(NSUInteger page);
FOUNDATION_EXPORT BOOL ZZSearchIsLoading(void);
FOUNDATION_EXPORT NSDictionary *ZZFormValues(NSString *text);
FOUNDATION_EXPORT BOOL ZZIsObservedURL(NSURL *url);
NS_ASSUME_NONNULL_END
