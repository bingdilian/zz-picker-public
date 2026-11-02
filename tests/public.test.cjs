const test=require('node:test'),assert=require('node:assert/strict'),C=require('../src/core.js'),f=require('./fixtures/capture.json');
const config=extra=>({model:'iPhone 15 Pro Max',autoFavorite:false,...extra});
const item=id=>({...f.item,strInfoId:id,infoId:id});
const product=id=>({...C.normalizeProduct(f),id});
const response=items=>({respCode:0,respData:{infos:items}});
function run(extra,items=[f.item]){let now=0;const r=new C.Run(config(extra),()=>now);r.start();const a=r.next();r.search(response(items),1,a.token,{});return {r,time:value=>{now=value;}};}

test('scan budgets default safely, normalize text fields and reject invalid explicit values',()=>{
 const defaults=C.validateConfig(config());assert.equal(defaults.config.maxProducts,100);assert.equal(defaults.config.maxMinutes,15);
 for(const [field,max] of [['maxProducts',2000],['maxMinutes',120]]){
  for(const value of [1,max,'1',String(max),' 2 ']){const v=C.validateConfig(config({[field]:value}));assert.equal(v.ok,true);assert.equal(v.config[field],Number(value));}
  for(const value of [0,max+1,-1,1.5,'1.5','', ' ',null,true,false,NaN,Infinity,{},[]])assert.equal(C.validateConfig(config({[field]:value})).ok,false,field+'='+String(value));
 }
});

test('processed unknown products reach the count budget without consuming another candidate',()=>{
 const {r}=run({maxProducts:1},[f.item,item('999')]);let a=r.next(),p=product(f.id);p.ios=null;r.detail(p,a.token);
 const s=r.snapshot();assert.equal(s.counts.loaded,2);assert.equal(s.counts.processed,1);assert.equal(s.counts.checked,0);assert.equal(s.budgetExceeded,true);assert.match(s.limitReason,/1.*件/);assert.match(s.note,/新.*任务/);assert.equal(s.state,'paused');assert.equal(r.next(),null);r.resume();assert.equal(r.next(),null);assert.equal(C.presentation(r.snapshot(),false).canResume,false);
 assert.equal(r.detail(product('999'),a.token),false);assert.equal(r.snapshot().counts.processed,1);
});

test('the final matching product remains viewable after the count budget is reached',()=>{
 const {r}=run({maxProducts:1},[f.item,item('999')]);const a=r.next();r.detail(product(f.id),a.token);
 assert.equal(r.snapshot().state,'hit');assert.equal(r.snapshot().budgetExceeded,true);assert.equal(C.presentation(r.snapshot(),false).canView,true);assert.equal(C.presentation(r.snapshot(),false).canResume,false);
 assert.equal(r.beginViewing(),true);r.viewed();assert.match(r.snapshot().note,/新.*任务/);r.resume();assert.equal(r.next(),null);assert.equal(C.presentation(r.snapshot(),false).canView,true);assert.equal(r.snapshot().counts.processed,1);
});

test('active time excludes manual pauses and viewing holds',()=>{
 const {r,time}=run({maxMinutes:1});time(10000);r.pause();assert.equal(r.snapshot().elapsedMs,10000);time(90000);assert.equal(r.snapshot().elapsedMs,10000);r.resume();time(95000);let a=r.next();r.detail(product(f.id),a.token);assert.equal(r.snapshot().elapsedMs,15000);time(200000);r.beginViewing();r.viewed();assert.equal(r.snapshot().elapsedMs,15000);r.resume();time(245000);assert.equal(r.checkBudget(),true);assert.equal(r.snapshot().elapsedMs,60000);assert.equal(r.snapshot().state,'paused');assert.match(r.snapshot().limitReason,/1.*分钟/);assert.equal(r.checkBudget(),false);
});

test('time budget cancels fast detail callbacks and late search responses before another product',()=>{
 const {r,time}=run({maxMinutes:1});const a=r.next();time(60000);assert.equal(r.detail(product(f.id),a.token),false);assert.equal(r.snapshot().counts.processed,0);assert.equal(r.snapshot().state,'paused');
 let now=0;const q=new C.Run(config({maxMinutes:1}),()=>now);q.start();const search=q.next();now=60000;assert.equal(q.search(response([f.item]),1,search.token,{}),false);assert.equal(q.snapshot().state,'paused');assert.equal(q.next(),null);
});

test('next and returned enforce budget boundaries between rapid callbacks',()=>{
 const {r,time}=run({maxMinutes:1},[f.item,item('999')]);let a=r.next(),p=product(f.id);p.model='iPhone 13';r.detail(p,a.token);a=r.next();time(60000);assert.equal(r.returned(a.token),true);assert.equal(r.next(),null);assert.equal(r.snapshot().counts.processed,1);assert.equal(r.snapshot().state,'paused');
 const q=run({maxMinutes:1});q.time(60000);assert.equal(q.r.next(),null);assert.equal(q.r.snapshot().state,'paused');
});

test('favorite and independent verification settle across a count budget exactly once',()=>{
 const {r}=run({maxProducts:1,autoFavorite:true});let a=r.next();r.detail(product(f.id),a.token);assert.equal(r.snapshot().budgetExceeded,true);assert.equal(r.checkBudget(),false);a=r.next();assert.equal(a.type,'favorite');r.favoriteResult(f.favorite,a.token);a=r.next();assert.equal(a.type,'verify');assert.equal(r.checkBudget(),false);r.verified(true,a.token);
 assert.equal(r.snapshot().state,'hit');assert.equal(r.snapshot().counts.favorited,1);assert.equal(r.verified(true,a.token),false);assert.equal(C.presentation(r.snapshot(),false).canResume,false);r.resume();assert.equal(r.next(),null);
});

test('time expiry during a favorite does not orphan its verification',()=>{
 const {r,time}=run({maxMinutes:1,autoFavorite:true});let a=r.next();r.detail(product(f.id),a.token);a=r.next();time(60000);assert.equal(r.checkBudget(),false);assert.equal(r.snapshot().budgetExceeded,true);assert.equal(r.snapshot().state,'favorite');r.favoriteResult(f.favorite,a.token);a=r.next();assert.equal(a.type,'verify');r.verified(true,a.token);assert.equal(r.snapshot().state,'hit');assert.equal(r.snapshot().counts.favorited,1);assert.equal(C.presentation(r.snapshot(),false).canResume,false);
});

test('manual pause at a budget allows only verification of the pending mutation',()=>{
 for(const phase of ['favorite','verify']){const {r}=run({maxProducts:1,autoFavorite:true});let a=r.next();r.detail(product(f.id),a.token);a=r.next();if(phase==='verify'){r.favoriteResult(f.favorite,a.token);a=r.next();}r.pause();if(phase==='favorite')assert.equal(r.favoriteResult(f.favorite,a.token),true);assert.equal(C.presentation(r.snapshot(),true).canResume,true);r.resume();a=r.next();assert.equal(a.type,'verify');r.verified(true,a.token);assert.equal(r.snapshot().counts.favorited,1);assert.equal(C.presentation(r.snapshot(),false).canResume,false);r.resume();assert.equal(r.next(),null);}
});

test('elapsed time freezes on stop and finish, and a restarted scan has fresh budgets',()=>{
 const {r,time}=run({maxProducts:1});time(5000);r.stop();time(100000);assert.equal(r.snapshot().elapsedMs,5000);r.start();assert.equal(r.snapshot().elapsedMs,0);assert.equal(r.snapshot().budgetExceeded,false);assert.equal(r.snapshot().limitReason,'');
 const a=r.next();time(105000);r.search(response([]),1,a.token,{});time(200000);assert.equal(r.snapshot().state,'finished');assert.equal(r.snapshot().elapsedMs,5000);
});

test('default clock uses native monotonic uptime when provided',()=>{
 let now=0;global.ZZNow=()=>now;try{const r=new C.Run(config({maxMinutes:1}));r.start();now=60000;assert.equal(r.checkBudget(),true);assert.equal(r.snapshot().elapsedMs,60000);}finally{delete global.ZZNow;}
});

test('diagnostic snapshots whitelist public fields and require opt-in for product details',()=>{
 const {r}=run();const a=r.next();r.detail(product(f.id),a.token);const source=r.snapshot();source.headers={Cookie:'secret'};source.rawResponse='secret';const d=C.diagnosticSnapshot(source);
 assert.deepEqual(Object.keys(d).sort(),['state','phase','config','ruleVersion','effectiveRange','page','counts','note','waitingResponse','options','budgetExceeded','limitReason','elapsedMs'].sort());assert.equal(JSON.stringify(d).includes(f.id),false);assert.equal(JSON.stringify(d).includes('secret'),false);
 const detailed=C.diagnosticSnapshot(source,true);assert.equal(detailed.current.id,f.id);assert.equal(detailed.candidate.id,f.id);assert.equal(detailed.results[0].id,f.id);assert.equal(detailed.hit.id,f.id);assert.equal(detailed.hit.item,undefined);assert.equal(detailed.token,undefined);assert.equal(detailed.allResults,undefined);assert.equal(JSON.stringify(detailed).includes(f.item.jumpUrl),false);assert.equal(source.hit.item.jumpUrl,f.item.jumpUrl);detailed.config.model='changed';assert.equal(source.config.model,'iPhone 15 Pro Max');
});

test('search failures distinguish unsuccessful requests from malformed successful payloads',()=>{
 const notes=[];for(const envelope of [{respCode:403,respData:{}},{respCode:0,respData:{}}]){const r=new C.Run(config());r.start();const a=r.next();r.search(envelope,1,a.token,{});assert.equal(r.snapshot().state,'paused');notes.push(r.snapshot().note);}assert.notEqual(notes[0],notes[1]);assert.match(notes[0],/失败/);assert.match(notes[1],/格式|数据|异常/);
});

test('opt-in diagnostics include excluded evaluations as well as hits',()=>{
 const {r}=run();let a=r.next(),p=product(f.id);p.model='iPhone 13';r.detail(p,a.token);
 const source=r.snapshot();assert.equal(source.results.length,0);assert.equal(source.allResults.length,1);
 assert.equal(C.diagnosticSnapshot(source).results,undefined);
 assert.equal(C.diagnosticSnapshot(source,true).results[0].status,'reject');
 assert.equal(C.diagnosticSnapshot(source,true).results[0].id,f.id);
});

test('only the active next-page token can finish a confirmed exhausted list',()=>{
 const {r}=run();assert.equal(typeof r.endOfList,'function');
 let a=r.next();assert.equal(r.endOfList(a.token),false);const p=product(f.id);p.model='iPhone 13';r.detail(p,a.token);a=r.next();r.returned(a.token);a=r.next();assert.equal(a.type,'nextPage');
 assert.equal(r.endOfList({...a.token,step:a.token.step-1}),false);assert.equal(r.endOfList(a.token),true);assert.equal(r.snapshot().state,'finished');assert.equal(r.snapshot().counts.processed,1);assert.equal(r.snapshot().counts.loaded,1);assert.equal(r.next(),null);
 assert.equal(r.search(response([item('999')]),2,a.token,{}),false);
 const paused=run().r;let b=paused.next(),q=product(f.id);q.model='iPhone 13';paused.detail(q,b.token);b=paused.next();paused.returned(b.token);b=paused.next();paused.pause();assert.equal(paused.endOfList(b.token),false);
});


test('candidate public instructions distinguish report policy, local checks and pending device tests',()=>{
 const fs=require('node:fs'),path=require('node:path');
 const read=name=>fs.readFileSync(path.join(__dirname,'../',name),'utf8');
 const compatibility=read('docs/public/compatibility.md'),install=read('docs/public/install.md'),readme=read('README.md');
 assert.match(readme,/2\.0\.0-alpha1/);assert.match(readme,/未正式发布/);
 for(const model of ['iPhone 14 Pro','iPhone 14 Pro Max','iPhone 15 Pro','iPhone 15 Pro Max'])assert.ok(compatibility.includes(model));
 assert.match(compatibility,/D2/);assert.match(compatibility,/17\.0.*缺.*构建号.*标称/);assert.match(compatibility,/Beta.*RC.*排除/);
 assert.match(compatibility,/未收录.*不等于.*不支持/);assert.match(compatibility,/真机.*待验证/);assert.match(compatibility,/rootless.*RootHide.*待验证/);
 assert.match(install,/config\.v3/);assert.match(install,/恢复.*确认|确认.*恢复/);assert.match(install,/5.*件/);assert.match(install,/2.*分钟/);
 assert.doesNotMatch(readme,/尚未提供第二版安装包|新增功能仍处于设计与开发准备阶段/);
});
