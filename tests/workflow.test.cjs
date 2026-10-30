const test=require('node:test'),assert=require('node:assert/strict'),C=require('../src/core.js'),f=require('./fixtures/capture.json');
const config=extra=>({model:'iPhone 15 Pro Max',minIOS:'26.0',maxIOS:'26.6.2',conditions:['95新'],capacities:['512'],autoFavorite:false,...extra});
const response=items=>({respCode:0,respData:{infos:items,filterResponse:f.filterResponse}});
function selection(){const o=C.filterOptions(f.filterResponse);return {'69':[o.capacities.find(x=>x.label==='512G')],'285':[o.conditions.find(x=>x.label==='95新')]};}
function started(extra){const r=new C.Run(config(extra));r.start();const a=r.next();r.search(response([f.item]),1,a.token,selection());return r;}
const product=()=>C.normalizeProduct(f);
function hold(r){let a=r.next();r.detail(product(),a.token);if(r.snapshot().state==='favorite'){a=r.next();r.favoriteResult(f.favorite,a.token);a=r.next();r.verified(true,a.token);}return r;}
test('new configuration defaults auto favorite off and preserves explicit choices',()=>{assert.equal(C.validateConfig({model:'iPhone 15 Pro Max'}).config.autoFavorite,false);assert.equal(C.validateConfig(config()).config.autoFavorite,false);assert.equal(C.validateConfig(config({autoFavorite:true})).config.autoFavorite,true);});
test('unfiltered search discovers options but cannot count candidates until native filters are proved',()=>{
 const r=new C.Run(config());r.start();let a=r.next();r.search(response([f.item]),1,a.token,{});a=r.next();assert.equal(a.type,'filters');assert.equal(r.snapshot().counts.loaded,0);
 const partial=selection();partial['285']=[];assert.equal(r.search(response([f.item]),1,a.token,partial),false);assert.equal(r.snapshot().state,'filters');
 assert.equal(r.search(response([f.item]),1,a.token,selection(),true),true);assert.equal(r.next().type,'open');assert.equal(r.snapshot().counts.loaded,1);
});
test('filter proof rejects forged labels, unknown choices and stale capacity',()=>{
 assert.equal(C.criteriaMatches(selection(),C.filterOptions(f.filterResponse),config()),true);
 const x=selection();x['69']=[{value:'unknown',cmd:'fake',text:'512G'}];assert.equal(C.criteriaMatches(x,C.filterOptions(f.filterResponse),config()),false);
 assert.equal(C.criteriaMatches(selection(),C.filterOptions(f.filterResponse),config({capacities:['256']})),false);
});
test('a manual-mode hit holds the queue and only final matches appear in visible results',()=>{
 const r=hold(started());assert.equal(r.snapshot().state,'hit');assert.equal(r.next(),null);assert.equal(r.snapshot().results.length,1);assert.equal(r.snapshot().counts.matched,1);
 r.resume();let a=r.next();assert.equal(a.type,'back');r.returned(a.token);assert.equal(r.next().type,'nextPage');
 const q=started();a=q.next();const p=product();p.capacity='256';q.detail(p,a.token);assert.equal(q.snapshot().results.length,0);assert.equal(q.snapshot().allResults[0].status,'reject');assert.equal(q.snapshot().counts.matched,0);
});
test('auto favorite completes verification before hit hold; original favorites are preserved',()=>{
 const r=hold(started({autoFavorite:true}));assert.equal(r.snapshot().state,'hit');assert.equal(r.snapshot().counts.favorited,1);assert.equal(r.snapshot().hit.status,'favorited');assert.equal(r.next(),null);
 const q=started({autoFavorite:true});let a=q.next();const p=product();p.collected=true;q.detail(p,a.token);assert.equal(q.snapshot().state,'hit');assert.equal(q.snapshot().counts.already,1);assert.equal(q.snapshot().counts.favorited,0);
});
test('favorite failure remains a hit but cannot count as confirmed favorite or auto retry',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.favoriteResult({respCode:403},a.token);assert.equal(r.snapshot().state,'hit');assert.equal(r.snapshot().hit.status,'favoriteUnknown');assert.equal(r.snapshot().counts.favorited,0);assert.equal(r.next(),null);
});
test('viewing and returning from a hit stay paused until explicit resume',()=>{
 const r=hold(started());assert.equal(r.beginViewing(),true);assert.equal(r.snapshot().state,'paused');r.viewed();assert.equal(r.next(),null);assert.match(r.snapshot().note,/返回/);r.resume();assert.equal(r.next().type,'back');
});
test('loaded count deduplicates IDs across pages; loading alone does not inflate it',()=>{
 const r=hold(started());r.resume();let a=r.next();r.returned(a.token);a=r.next();assert.equal(r.snapshot().counts.loaded,1);const item={...f.item,infoId:'999',strInfoId:'999'};
 r.search(response([f.item,item,item]),2,a.token,selection());assert.equal(r.snapshot().counts.loaded,2);assert.equal(r.next().item.id,'999');
});
test('late page while paused is retained but cannot advance until resume',()=>{
 const r=hold(started());r.resume();let a=r.next();r.returned(a.token);a=r.next();r.searchStarted(2,a.token);r.pause('loading');const item={...f.item,infoId:'999',strInfoId:'999'};
 assert.equal(r.search(response([item]),2,a.token,selection()),false);assert.equal(r.snapshot().state,'paused');r.resume();assert.equal(r.next().type,'open');assert.equal(r.snapshot().counts.loaded,2);
});
test('resume adopts the original pending request and accepts its later response without duplicate scroll',()=>{
 const r=hold(started());r.resume();let a=r.next();r.returned(a.token);a=r.next();r.searchStarted(2,a.token);r.pause();r.resume();const resumed=r.next();assert.equal(resumed.type,'nextPage');assert.equal(r.snapshot().waitingResponse,true);
 const item={...f.item,infoId:'999',strInfoId:'999'};assert.equal(r.search(response([item]),2,a.token,selection()),true);assert.equal(r.next().type,'open');
});
test('failed pending search can retry and stopped runs reject stale work',()=>{
 const r=hold(started());r.resume();let a=r.next();r.returned(a.token);a=r.next();r.searchStarted(2,a.token);r.searchFailed(2,a.token);assert.equal(r.snapshot().state,'paused');r.resume();assert.equal(r.snapshot().waitingResponse,false);r.stop();assert.equal(r.search(response([f.item]),2,a.token,selection()),false);assert.equal(r.beginViewing(),false);
});
test('hit snapshot includes safe viewer route and diagnosis preserves exclusions',()=>{
 const r=hold(started());assert.equal(r.snapshot().hit.item.id,f.id);assert.equal(C.safeProductURL(r.snapshot().hit.item.jumpUrl,f.id),true);assert.equal(r.snapshot().phase,'hit');assert.equal(r.snapshot().allResults.length,1);
});
test('presentation separates pending verification, hit and returned controls',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);let ui=C.presentation(r.snapshot(),false);assert.equal(ui.kind,'favorite');assert.equal(ui.canView,false);assert.equal(ui.canResume,false);
 a=r.next();r.favoriteResult(f.favorite,a.token);a=r.next();r.verified(true,a.token);ui=C.presentation(r.snapshot(),false);assert.equal(ui.kind,'hit');assert.equal(ui.canView,true);assert.equal(ui.canResume,true);
 r.beginViewing();r.viewed();ui=C.presentation(r.snapshot(),false);assert.equal(ui.kind,'returned');assert.equal(ui.canResume,true);assert.equal(ui.kind==='running',false);
});
test('end during an outstanding favorite retains its pending result; late verify settles without restarting',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.favoriteResult(f.favorite,a.token);a=r.next();r.stop();
 assert.equal(r.snapshot().results.length,1);assert.equal(r.snapshot().counts.favorited,0);assert.equal(C.presentation(r.snapshot(),true).canResume,false);
 assert.equal(r.settleStopped('baseInfo',{respCode:0,respData:{collected:true}},f.id,a.token),true);assert.equal(r.snapshot().counts.favorited,1);assert.equal(r.next(),null);assert.equal(r.snapshot().state,'stopped');
});
test('snapshot results do not contain full navigation URLs in diagnostic records',()=>{
 const r=hold(started());assert.equal(r.snapshot().allResults[0].item,undefined);assert.equal(r.snapshot().results[0].item,undefined);
});
test('stale and wrong-ID details cannot mutate, and missing reports stay excluded',()=>{
 const r=started({autoFavorite:true});const a=r.next(),p=product();p.id='999';assert.equal(r.detail(p,a.token),false);r.pause();assert.equal(r.detail(product(),a.token),false);r.resume();const current=r.next();const missing=C.normalizeProduct({id:f.id,base:f.base,more:{respCode:403}});r.detail(missing,current.token);assert.equal(r.snapshot().counts.unknown,1);assert.equal(r.snapshot().results.length,0);assert.equal(r.next().type,'back');
});
test('malformed selections are unproved, duplicate pages end, and prefetched data survives holds',()=>{
 assert.equal(C.criteriaMatches({'69':'bad'},C.filterOptions(f.filterResponse),config()),false);
 const r=hold(started());const t=r.snapshot().token,item={...f.item,infoId:'888',strInfoId:'888'};
 assert.equal(r.prefetch(response([item]),2,t,selection()),true);assert.equal(r.snapshot().counts.loaded,2);r.resume();let a=r.next();r.returned(a.token);assert.equal(r.next().item.id,'888');
});
test('paused favorite resumes with verification and never repeats the mutation',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.pause();assert.equal(r.favoriteResult(f.favorite,a.token),true);assert.equal(r.next(),null);r.resume();assert.equal(r.next().type,'verify');
});
test('empty or repeated pages finish and stopped callbacks cannot add results',()=>{
 const r=hold(started());r.resume();let a=r.next();r.returned(a.token);a=r.next();r.search(response([f.item]),2,a.token,selection());assert.equal(r.snapshot().state,'finished');assert.equal(r.snapshot().counts.loaded,1);
 const q=started({autoFavorite:true});a=q.next();q.stop();assert.equal(q.detail(product(),a.token),false);assert.equal(q.snapshot().results.length,0);
});
test('unconfirmed verification remains visible as a hit without successful favorite count',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.favoriteResult(f.favorite,a.token);a=r.next();r.verified(null,a.token);assert.equal(r.snapshot().state,'hit');assert.equal(r.snapshot().results[0].status,'favoriteUnknown');assert.equal(r.snapshot().counts.favoriteUnknown,1);assert.equal(r.snapshot().counts.favorited,0);
});
test('unknown iOS cannot auto favorite even when version bounds are unrestricted',()=>{
 const r=started({autoFavorite:true,minIOS:'',maxIOS:''});const a=r.next(),p=product();p.ios=null;r.detail(p,a.token);assert.equal(r.snapshot().counts.matched,0);assert.equal(r.next().type,'back');
});
test('malformed filter rows are unproved rather than crashing the run',()=>{
 assert.equal(C.criteriaMatches({'69':[null]},C.filterOptions(f.filterResponse),config()),false);
});
test('intermediate matching filter response cannot end the unfinished filter transaction',()=>{
 const r=new C.Run(config());r.start();let a=r.next();r.search(response([f.item]),1,a.token,{});a=r.next();
 assert.equal(r.search(response([f.item]),1,a.token,selection(),false),false);assert.equal(r.snapshot().state,'filters');assert.equal(r.snapshot().counts.loaded,0);
 assert.equal(r.search(response([f.item]),1,a.token,selection(),true),true);assert.equal(r.next().type,'open');
});
test('verification received during end confirmation is settled without continuing the queue',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.favoriteResult(f.favorite,a.token);a=r.next();r.pause('等待结束确认');
 assert.equal(r.verified(true,a.token),true);assert.equal(r.next(),null);r.stop();assert.equal(r.snapshot().counts.favorited,1);assert.equal(r.snapshot().counts.favoriteUnknown,0);assert.equal(r.snapshot().results.length,1);
});
test('paused favorite response may settle failure but success cannot issue new verification until resume',()=>{
 for(const ok of [true,false]){const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.pause();assert.equal(r.favoriteResult({respCode:ok?0:403},a.token),true);assert.equal(r.next(),null);if(ok){assert.equal(r.snapshot().state,'paused');r.resume();assert.equal(r.next().type,'verify');}else assert.equal(r.snapshot().hit.status,'favoriteUnknown');}
});
test('unknown reports are processed but not counted as verified conclusions',()=>{
 const r=started(),a=r.next(),p=product();p.ios=null;r.detail(p,a.token);const c=r.snapshot().counts;assert.equal(c.processed,1);assert.equal(c.checked,0);assert.equal(c.unknown,1);
});
test('a paused response with unproved selection cannot become an unrestricted proof',()=>{
 const r=new C.Run(config({capacities:[],conditions:[]}));r.start();const a=r.next();r.searchStarted(1,a.token);r.pause();r.search(response([f.item]),1,a.token,null);r.resume();assert.equal(r.snapshot().state,'filters');assert.equal(r.snapshot().counts.loaded,0);
});
test('prefetch cannot count an intermediate filter page before final proof',()=>{
 const r=new C.Run(config());r.start();const a=r.next();r.search(response([f.item]),1,a.token,{});assert.equal(r.prefetch(response([f.item]),2,r.snapshot().token,selection()),false);assert.equal(r.snapshot().counts.loaded,0);
});
test('filter transaction only changes unproved fields so final confirmation makes a real change',()=>{
 const r=new C.Run(config());r.start();const a=r.next(),s=selection();s['69']=[];r.search(response([f.item]),1,a.token,s);assert.deepEqual(r.next().applyFields,['capacities']);
 const q=new C.Run(config());q.start();const b=q.next();q.search(response([f.item]),1,b.token,{});assert.deepEqual(q.next().applyFields,['capacities','conditions']);
});
test('a superseded search failure cannot consume the active detail action',()=>{
 const r=new C.Run(config({conditions:[],capacities:[]}));r.start();const a=r.next();r.searchStarted(1,a.token);r.pause();r.resume();const b=r.next();r.searchStarted(1,b.token);r.search(response([f.item]),1,a.token,{});r.next();assert.equal(r.searchFailed(1,b.token),false);assert.equal(r.snapshot().state,'open');
});
test('an old search failure cannot cancel a newer filter transaction',()=>{
 const r=new C.Run(config());r.start();const a=r.next();r.searchStarted(1,a.token);r.pause();r.resume();const b=r.next();r.searchStarted(1,b.token);r.search(response([f.item]),1,a.token,{});assert.equal(r.snapshot().state,'filters');assert.equal(r.searchFailed(1,b.token),false);assert.equal(r.snapshot().state,'filters');
});

test('a final response missing capacity pauses immediately and resumes only that field',()=>{
 const r=new C.Run(config({conditions:['99新']}));r.start();let a=r.next();r.search(response([f.item]),1,a.token,{});a=r.next();
 const actual={'69':[],'285':[{value:'28076',cmd:'params_new6664=1145139'}]};
 r.searchStarted(1,a.token);assert.equal(r.search(response([f.item]),1,a.token,actual,true),false);
 const snapshot=r.snapshot();assert.equal(snapshot.state,'paused');assert.match(snapshot.note,/容量/);assert.equal(snapshot.counts.loaded,0);assert.equal(snapshot.counts.checked,0);assert.equal(r.next(),null);
 r.resume();assert.deepEqual(r.next().applyFields,['capacities']);
});

test('nonselected or unknown channels never issue favorites and records retain the report channel',()=>{
 for(const channel of ['港澳台版',null]){const r=started({autoFavorite:true}),a=r.next(),p=product();p.channel=channel;r.detail(p,a.token);assert.equal(r.next().type,'back');assert.equal(r.snapshot().counts.matched,0);assert.equal(r.snapshot().allResults[0].channel,channel||'');}
 const r=hold(started({channels:['国行']}));assert.equal(r.snapshot().hit.channel,'国行');assert.equal(r.snapshot().results[0].channel,'国行');
});

test('returning from a manually favorited unknown result rechecks without another mutation or duplicate count',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.failed('timeout',a.token);a=r.next();r.verified(null,a.token);
 assert.equal(r.snapshot().counts.favoriteUnknown,1);const old=a.token;
 assert.equal(r.recheckFavorite(),true);a=r.next();assert.equal(a.type,'verify');assert.equal(a.item.id,f.id);assert.equal(a.item.jumpUrl,f.item.jumpUrl);assert.equal(r.verified(true,old),false);
 assert.equal(r.verified(false,a.token),true);assert.equal(r.snapshot().counts.favoriteUnknown,1);assert.equal(r.snapshot().allResults.length,1);
 assert.equal(r.recheckFavorite(),true);a=r.next();assert.equal(r.verified(true,a.token),true);
 assert.equal(r.snapshot().counts.favorited,1);assert.equal(r.snapshot().counts.favoriteUnknown,0);assert.equal(r.snapshot().allResults.length,1);
 assert.equal(r.snapshot().hit.status,'favorited');assert.equal(r.recheckFavorite(),false);assert.equal(r.verified(true,a.token),false);
});

test('stopping during a read-only favorite recheck preserves one uncertain result and accepts late verification',()=>{
 const r=started({autoFavorite:true});let a=r.next();r.detail(product(),a.token);a=r.next();r.failed('timeout',a.token);a=r.next();r.verified(null,a.token);
 r.recheckFavorite();a=r.next();r.stop();assert.equal(r.snapshot().counts.favoriteUnknown,1);assert.equal(r.snapshot().allResults.length,1);
 assert.equal(r.settleStopped('baseInfo',{respCode:0,respData:{collected:true}},f.id,a.token),true);
 assert.equal(r.snapshot().counts.favoriteUnknown,0);assert.equal(r.snapshot().counts.favorited,1);assert.equal(r.snapshot().allResults.length,1);assert.equal(r.snapshot().hit.status,'favorited');assert.equal(r.next(),null);
});
