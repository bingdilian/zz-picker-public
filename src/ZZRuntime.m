#import "ZZRuntime.h"
NSDictionary *ZZSearchSelection(NSString *json) {
    if(![json isKindOfClass:NSString.class]||json.length>131072)return nil;
    id value=[NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    if(![value isKindOfClass:NSDictionary.class])return nil;
    id items=value[@"clickItems"]?:@{};if(![items isKindOfClass:NSDictionary.class])return nil;
    NSMutableDictionary *result=[NSMutableDictionary new];
    for(NSString *key in @[@"69",@"285"]){
        id group=items[key]?:@[];if(![group isKindOfClass:NSArray.class]||[group count]>32)return nil;
        NSMutableArray *rows=[NSMutableArray new];
        for(id row in group){if(![row isKindOfClass:NSDictionary.class]||![row[@"value"]isKindOfClass:NSString.class]||![row[@"cmd"]isKindOfClass:NSString.class])return nil;[rows addObject:@{@"value":row[@"value"],@"cmd":row[@"cmd"]}];}
        result[key]=rows;
    }return result;
}
BOOL ZZInvokeRegisteredAction(id target,SEL action,id sender) {
    if(!target||![target respondsToSelector:action])return NO;
    NSMethodSignature *signature=[target methodSignatureForSelector:action];
    if(!signature||signature.numberOfArguments<2||signature.numberOfArguments>3)return NO;
    if(signature.numberOfArguments==3&&[signature getArgumentTypeAtIndex:2][0]!='@')return NO;
    const char *type=signature.methodReturnType;if(strcmp(type,@encode(void))&&strcmp(type,@encode(BOOL)))return NO;
    @try{
        NSInvocation *call=[NSInvocation invocationWithMethodSignature:signature];call.target=target;call.selector=action;
        if(signature.numberOfArguments==3)[call setArgument:&sender atIndex:2];[call invoke];
        if(!strcmp(type,@encode(BOOL))){BOOL result=NO;[call getReturnValue:&result];return result;}
        return YES;
    }@catch(NSException *exception){(void)exception;return NO;}
}
void ZZReplaceMethod(Class cls,SEL selector,NSString *name,IMP (^factory)(IMP)) {
    if(!cls||!selector||!factory)return;
    const void *key=sel_registerName("zzPickerReplacementRegistryV1");
    @synchronized(cls){
        NSMutableSet *installed=objc_getAssociatedObject(cls,key);
        if(!installed){installed=[NSMutableSet new];objc_setAssociatedObject(cls,key,installed,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
        NSString *tag=[name stringByAppendingFormat:@"/%@",NSStringFromSelector(selector)];
        if([installed containsObject:tag])return;
        Method method=class_getInstanceMethod(cls,selector);if(!method)return;
        IMP replacement=factory(method_getImplementation(method));if(!replacement)return;
        if(!class_addMethod(cls,selector,replacement,method_getTypeEncoding(method)))method_setImplementation(class_getInstanceMethod(cls,selector),replacement);
        [installed addObject:tag];
    }
}

BOOL ZZTrustedBridgeFrame(NSURL *topURL,NSURL *frameURL,NSString *protocol,NSString *host,BOOL mainFrame) {
    NSArray *allowed=@[@"m.zhuanzhuan.com",@"app.zhuanzhuan.com"];
    return mainFrame && [protocol isEqual:@"https"] && [allowed containsObject:host] &&
        [topURL.scheme isEqual:@"https"] && [frameURL.scheme isEqual:@"https"] &&
        [topURL.host isEqual:host] && [frameURL.host isEqual:host] &&
        (!topURL.port || topURL.port.integerValue==443) && (!frameURL.port || frameURL.port.integerValue==443);
}

static char ZZResumeCallbackKey,ZZResumeNotifiedKey;
void ZZOnTaskResume(NSURLSessionTask *task,void (^callback)(void)) {
    if(!task||!callback)return;
    objc_setAssociatedObject(task,&ZZResumeCallbackKey,callback,OBJC_ASSOCIATION_COPY_NONATOMIC);
    ZZReplaceMethod(object_getClass(task),@selector(resume),@"network-start",^IMP(IMP original){
        return imp_implementationWithBlock(^(NSURLSessionTask *object){
            void (^notify)(void)=nil;
            @synchronized(object){
                if(object.state==NSURLSessionTaskStateSuspended&&!objc_getAssociatedObject(object,&ZZResumeNotifiedKey)){
                    notify=objc_getAssociatedObject(object,&ZZResumeCallbackKey);
                    if(notify){objc_setAssociatedObject(object,&ZZResumeNotifiedKey,@YES,OBJC_ASSOCIATION_RETAIN_NONATOMIC);objc_setAssociatedObject(object,&ZZResumeCallbackKey,nil,OBJC_ASSOCIATION_COPY_NONATOMIC);}
                }
            }
            if(notify)notify();
            ((void(*)(id,SEL))original)(object,@selector(resume));
        });
    });
}
