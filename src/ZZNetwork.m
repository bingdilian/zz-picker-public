#import "ZZPicker.h"
#import <objc/runtime.h>
#import "ZZRuntime.h"

static char ZZTaskMetadataKey, ZZTaskBufferKey;

NSDictionary *ZZFormValues(NSString *text) {
    NSMutableDictionary *out=[NSMutableDictionary new];
    if(![text isKindOfClass:NSString.class])return out;
    for(NSString *part in [text componentsSeparatedByString:@"&"]){
        NSRange split=[part rangeOfString:@"="];if(split.location==NSNotFound)continue;
        NSString *key=[[part substringToIndex:split.location]stringByRemovingPercentEncoding];
        NSString *value=[[[part substringFromIndex:split.location+1]stringByReplacingOccurrencesOfString:@"+" withString:@" "]stringByRemovingPercentEncoding];
        if(key&&value){if(out[key])out[key]=@"";else out[key]=value;}
    }return out;
}
BOOL ZZIsObservedURL(NSURL *url) {
    if(![url.host isEqual:@"app.zhuanzhuan.com"]||![url.scheme isEqual:@"https"])return NO;
    return [@[@"/zz/transfer/search",@"/zz/v2/zzsearchfilteritem/getFilterItemDTO",@"/zz/v2/zzsearchfilteritem/getStockCount",@"/zzopen/waresshow/baseInfo",@"/zzopen/waresshow/moreInfo",@"/zz/transfer/addLoveInfo"]containsObject:url.path?:@""];
}
static void ZZObserve(NSData *body,NSDictionary *metadata) {
    if(!metadata)return;
    if(body.length==0||body.length>8*1024*1024){[[ZZPicker shared]observeFailure:metadata];return;}
    id json=[NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
    if([json isKindOfClass:NSDictionary.class])[[ZZPicker shared]observeJSON:json metadata:metadata webView:nil];else [[ZZPicker shared]observeFailure:metadata];
}
static void ZZRememberMetadata(NSURLSessionTask *task,NSDictionary *metadata) {
    if(!task||!metadata)return;
    objc_setAssociatedObject(task,&ZZTaskMetadataKey,metadata,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ZZOnTaskResume(task,^{[[ZZPicker shared]observeRequest:metadata];});
}
static void ZZRemember(NSURLSessionTask *task,NSURLRequest *request) {
    ZZRememberMetadata(task,[[ZZPicker shared]requestContext:request]);
}

@interface ZZSessionDelegate : NSObject <NSURLSessionDataDelegate>
@property(nonatomic,strong) id target;
@end
@implementation ZZSessionDelegate
- (BOOL)respondsToSelector:(SEL)s {return [super respondsToSelector:s]||[self.target respondsToSelector:s];}
- (id)forwardingTargetForSelector:(SEL)s {return [self.target respondsToSelector:s]?self.target:[super forwardingTargetForSelector:s];}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data {
    NSDictionary *m=objc_getAssociatedObject(task,&ZZTaskMetadataKey);
    if(m){
        @synchronized(task){
            id stored=objc_getAssociatedObject(task,&ZZTaskBufferKey);
            if(stored!=NSNull.null){
                NSMutableData *buffer=stored?:[NSMutableData new];
                if(buffer.length+data.length<=8*1024*1024){[buffer appendData:data];objc_setAssociatedObject(task,&ZZTaskBufferKey,buffer,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
                else objc_setAssociatedObject(task,&ZZTaskBufferKey,NSNull.null,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    if([self.target respondsToSelector:_cmd])[self.target URLSession:session dataTask:task didReceiveData:data];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSData *body=nil;NSDictionary *m=objc_getAssociatedObject(task,&ZZTaskMetadataKey);
    @synchronized(task){id value=objc_getAssociatedObject(task,&ZZTaskBufferKey);if([value isKindOfClass:NSData.class])body=[value copy];objc_setAssociatedObject(task,&ZZTaskBufferKey,nil,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
    if([self.target respondsToSelector:_cmd])[self.target URLSession:session task:task didCompleteWithError:error];
    if(!error)ZZObserve(body,m);else if(m)[[ZZPicker shared]observeFailure:m];
}
@end

static void ZZInstallForSession(NSURLSession *session) {
    if(!session)return;Class cls=object_getClass(session);
    SEL req=@selector(dataTaskWithRequest:), url=@selector(dataTaskWithURL:);
    SEL reqCompletion=@selector(dataTaskWithRequest:completionHandler:),urlCompletion=@selector(dataTaskWithURL:completionHandler:);
    ZZReplaceMethod(cls,req,@"network",^IMP(IMP original){
        return imp_implementationWithBlock(^id(id object,NSURLRequest *request){
            NSURLSessionTask *task=((id(*)(id,SEL,id))original)(object,req,request);ZZRemember(task,request);return task;
        });
    });
    ZZReplaceMethod(cls,url,@"network",^IMP(IMP original){
        return imp_implementationWithBlock(^id(id object,NSURL *value){
            NSURLSessionTask *task=((id(*)(id,SEL,id))original)(object,url,value);ZZRemember(task,[NSURLRequest requestWithURL:value]);return task;
        });
    });
    ZZReplaceMethod(cls,reqCompletion,@"network",^IMP(IMP original){
        return imp_implementationWithBlock(^id(id object,NSURLRequest *request,void (^handler)(NSData *,NSURLResponse *,NSError *)){
            NSDictionary *m=[[ZZPicker shared]requestContext:request];
            if(!m||!handler)return ((id(*)(id,SEL,id,id))original)(object,reqCompletion,request,handler);
            NSURLSessionTask *task=((id(*)(id,SEL,id,id))original)(object,reqCompletion,request,^(NSData *body,NSURLResponse *response,NSError *error){handler(body,response,error);if(!error)ZZObserve(body,m);else if(m)[[ZZPicker shared]observeFailure:m];});
            ZZRememberMetadata(task,m);return task;
        });
    });
    ZZReplaceMethod(cls,urlCompletion,@"network",^IMP(IMP original){
        return imp_implementationWithBlock(^id(id object,NSURL *value,void (^handler)(NSData *,NSURLResponse *,NSError *)){
            NSDictionary *m=[[ZZPicker shared]requestContext:[NSURLRequest requestWithURL:value]];
            if(!m||!handler)return ((id(*)(id,SEL,id,id))original)(object,urlCompletion,value,handler);
            NSURLSessionTask *task=((id(*)(id,SEL,id,id))original)(object,urlCompletion,value,^(NSData *body,NSURLResponse *response,NSError *error){handler(body,response,error);if(!error)ZZObserve(body,m);else if(m)[[ZZPicker shared]observeFailure:m];});
            ZZRememberMetadata(task,m);return task;
        });
    });
}
static IMP ZZOriginalSessionFactory,ZZOriginalSimpleFactory,ZZOriginalShared;
static id ZZSessionFactory(id object,SEL cmd,NSURLSessionConfiguration *config,id delegate,NSOperationQueue *queue) {
    id actual=delegate;
    if(delegate&&![delegate isKindOfClass:ZZSessionDelegate.class]){ZZSessionDelegate *proxy=[ZZSessionDelegate new];proxy.target=delegate;actual=proxy;}
    NSURLSession *s=((id(*)(id,SEL,id,id,id))ZZOriginalSessionFactory)(object,cmd,config,actual,queue);ZZInstallForSession(s);return s;
}
static id ZZSimpleFactory(id object,SEL cmd,NSURLSessionConfiguration *config) {
    NSURLSession *s=((id(*)(id,SEL,id))ZZOriginalSimpleFactory)(object,cmd,config);ZZInstallForSession(s);return s;
}
static id ZZShared(id object,SEL cmd){NSURLSession *s=((id(*)(id,SEL))ZZOriginalShared)(object,cmd);ZZInstallForSession(s);return s;}
void ZZInstallNetworkHooks(void) {
    ZZOriginalSessionFactory=method_setImplementation(class_getClassMethod(NSURLSession.class,@selector(sessionWithConfiguration:delegate:delegateQueue:)),(IMP)ZZSessionFactory);
    ZZOriginalSimpleFactory=method_setImplementation(class_getClassMethod(NSURLSession.class,@selector(sessionWithConfiguration:)),(IMP)ZZSimpleFactory);
    ZZOriginalShared=method_setImplementation(class_getClassMethod(NSURLSession.class,@selector(sharedSession)),(IMP)ZZShared);
    ZZInstallForSession(NSURLSession.sharedSession);
}
