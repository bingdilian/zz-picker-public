#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
int main(int argc,const char **argv){
    @autoreleasepool {
        if(argc!=2)return 2;
        NSString *root=[NSString stringWithUTF8String:argv[1]];
        JSContext *context=[JSContext new];__block BOOL failed=NO;
        context.exceptionHandler=^(JSContext *ctx,JSValue *error){(void)ctx;fprintf(stderr,"JSCore exception: %s\n",error.toString.UTF8String);failed=YES;};
        NSString *core=[NSString stringWithContentsOfFile:[root stringByAppendingPathComponent:@"src/core.js"]encoding:NSUTF8StringEncoding error:nil];
        if(!core)return 3;[context evaluateScript:core];
        NSDictionary *fixture=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[root stringByAppendingPathComponent:@"tests/fixtures/capture.json"]]options:0 error:nil];
        if(!fixture)return 4;context[@"fixture"]=fixture;
        JSValue *result=[context evaluateScript:@"(function(){var p=ZZCore.normalizeProduct(fixture);var c={model:'iPhone 15 Pro Max',minIOS:'26.0',maxIOS:'26.6.2',conditions:[],capacities:[],autoFavorite:false};if(p.id!=='2107126446155633664'||p.ios!=='26.6.2'||ZZCore.matchProduct(p,c).status!=='match')throw Error('capture mismatch');if(ZZCore.compareVersions('17.0.10','17.0.3')!==1)throw Error('version order');var r=new ZZCore.Run(c);r.start();var a=r.next();r.search({respCode:0,respData:{infos:[fixture.item]}},1,a.token,{});a=r.next();r.detail(p,a.token);if(r.snapshot().state!=='hit'||r.next()!==null)throw Error('manual mode hold');r.resume();if(r.next().type!=='back')throw Error('resume hit');return true;})()"];
        if(failed||!result.toBool)return 1;
        puts("JavaScriptCore capture parsing, version comparison and run integration: PASS");
        return 0;
    }
}
