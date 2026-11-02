#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
int main(int argc,const char **argv){
    @autoreleasepool {
        if(argc!=2)return 2;
        NSString *root=[NSString stringWithUTF8String:argv[1]];
        JSContext *context=[JSContext new];__block BOOL failed=NO;
        context.exceptionHandler=^(JSContext *ctx,JSValue *error){(void)ctx;fprintf(stderr,"JSCore exception: %s\n",error.toString.UTF8String);failed=YES;};
        NSString *core=[NSString stringWithContentsOfFile:[root stringByAppendingPathComponent:@"src/core.js"]encoding:NSUTF8StringEncoding error:nil];
        if(!core)return 3;
        NSString *rules=[NSString stringWithContentsOfFile:[root stringByAppendingPathComponent:@"src/compatibility-rules.json"]encoding:NSUTF8StringEncoding error:nil];
        [context evaluateScript:[NSString stringWithFormat:@"globalThis.ZZCompatibilityRules = %@;",rules]];
        [context evaluateScript:[NSString stringWithContentsOfFile:[root stringByAppendingPathComponent:@"src/compatibility.js"]encoding:NSUTF8StringEncoding error:nil]];
        if(![[context evaluateScript:@"typeof require === 'undefined' && ZZCompatibility.defaultRuleContext().models.length === 4 && ZZCompatibility.defaultRuleContext().ruleVersion === 'compat-2026-10-21.1'"]toBool])return 5;
        [context evaluateScript:[NSString stringWithContentsOfFile:[root stringByAppendingPathComponent:@"src/config.js"]encoding:NSUTF8StringEncoding error:nil]];
        [context evaluateScript:core];
        NSDictionary *fixture=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[root stringByAppendingPathComponent:@"tests/fixtures/capture.json"]]options:0 error:nil];
        if(!fixture)return 4;context[@"fixture"]=fixture;
        JSValue *result=[context evaluateScript:@"(function(){var p=ZZCore.normalizeProduct(fixture);var c={model:'iPhone 15 Pro Max',minIOS:'26.0',maxIOS:'26.6.2',conditions:[],capacities:[],autoFavorite:false};if(p.id!=='2107126446155633664'||p.ios!=='26.6.2'||ZZCore.matchProduct(p,c).status!=='match')throw Error('capture mismatch');if(ZZCore.compareVersions('17.0.10','17.0.3')!==1)throw Error('version order');var r=new ZZCore.Run(c);r.start();var a=r.next();r.search({respCode:0,respData:{infos:[fixture.item]}},1,a.token,{});a=r.next();r.detail(p,a.token);if(r.snapshot().state!=='hit'||r.next()!==null)throw Error('manual mode hold');r.resume();if(r.next().type!=='back')throw Error('resume hit');return true;})()"];
        if(failed||!result.toBool)return 1;
        context[@"compatibilityCases"]=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[root stringByAppendingPathComponent:@"tests/fixtures/compatibility-cases.json"]]options:0 error:nil];
        result=[context evaluateScript:@"(function(){compatibilityCases.forEach(function(row){var ctx=ZZCompatibility.defaultRuleContext();if(row.buildRestricted)ctx.tools[0].predicates[0].kind='buildRestricted';if(ZZCore.matchProduct(ZZCore.normalizeProduct(row.input),row.config,ctx).status!==row.status)throw Error(row.id+' compatibility mismatch');});var row=compatibilityCases.filter(function(x){return x.id==='P03';})[0],input=JSON.parse(JSON.stringify(row.input));input.base.respData.title='iPhone 13 Pro Max';if(ZZCore.matchProduct(ZZCore.normalizeProduct(input),row.config).status!=='unknown')throw Error('outside catalog title conflict');input=JSON.parse(JSON.stringify(row.input));input.more.respData.report.params.forEach(function(p){if(p.key==='系统版本')p.value='16.5';});input.more.respData.report.reportParam.paramDetail[0].paramInfo[0].paramValue='16.5';if(ZZCore.matchProduct(ZZCore.normalizeProduct(input),row.config).status!=='unknown')throw Error('known build conflicts with report version');return true;})()"];
        if(failed||!result.toBool)return 1;
        puts("JavaScriptCore capture parsing, version comparison and run integration: PASS");
        return 0;
    }
}
