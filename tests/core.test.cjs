const test = require('node:test');
const assert = require('node:assert/strict');
const C = require('../src/core.js');
const f = require('./fixtures/capture.json');
const config = extra => ({model:'iPhone 15 Pro Max',minIOS:'26.0',maxIOS:'26.6.2',conditions:['95新'],capacities:['512G'],autoFavorite:false,...extra});
const product = () => C.normalizeProduct({id:f.id,item:f.item,base:f.base,more:f.more});
const response = items => ({respCode:0,respData:{infos:items}});
const startRun = extra => {const r=new C.Run(config(extra));r.start();const a=r.next();r.search(response([f.item]),1,a.token);return r;};

test('inclusive numeric version bounds, zero padding and 17.0.10 ordering',()=>{
 assert.equal(C.compareVersions('17.0.10','17.0.3'),1);
 assert.equal(C.compareVersions('iOS 17','17.0.0'),0);
 assert.equal(C.matchProduct(product(),config()).status,'match');
 assert.equal(C.matchProduct(product(),config({maxIOS:'26.6.1'})).status,'reject');
});
test('rejects malformed bounds, reverse range, no model and non-boolean favorite flag',()=>{
 for(const x of [{minIOS:'17.x'},{minIOS:'18',maxIOS:'17'},{model:''},{autoFavorite:'false'}]) assert.equal(C.validateConfig(config(x)).ok,false);
 assert.equal(C.validateConfig(config({minIOS:'',maxIOS:''})).ok,true);
});
test('normalizes model without confusing Pro and Pro Max',()=>{
 assert.equal(C.matchProduct(product(),config({model:'苹果 iPhone15ProMax'})).status,'match');
 assert.equal(C.matchProduct(product(),config({model:'iPhone 15 Pro'})).status,'reject');
});
test('capacity units normalize and selected conditions are an OR within a field',()=>{
 assert.equal(C.normalizeCapacity('1TB'),'1024');
 assert.equal(C.normalizeCapacity('512GB'),'512');
 assert.equal(C.matchProduct(product(),config({conditions:['99新','95新'],capacities:['512GB']})).status,'match');
 assert.equal(C.matchProduct(product(),config({capacities:['256G']})).status,'reject');
});
test('capture fields preserve long ID, report version and separate appearance/function',()=>{
 assert.equal(product().id,'2107126446155633664');
 assert.equal(product().ios,'26.6.2');
 assert.equal(product().capacity,'512');
 assert.equal(product().condition,'95新');
 assert.equal(product().functionGrade,'B');
 assert.equal(product().collected,false);
 assert.equal(product().soldOut,false);
});
test('finds fields by label after order change and falls back to reportParam',()=>{
 const x=structuredClone(f);x.more.respData.report.params.reverse();
 assert.equal(C.normalizeProduct({...x}).ios,'26.6.2');
 x.more.respData.report.params=x.more.respData.report.params.filter(p=>p.key!=='系统版本');
 assert.equal(C.normalizeProduct({...x}).ios,'26.6.2');
});
test('conflicting system versions are unknown rather than arbitrarily selected',()=>{
 const x=structuredClone(f);x.more.respData.report.reportParam.paramDetail[0].paramInfo[0].paramValue='iOS 17.0';
 assert.equal(C.matchProduct(C.normalizeProduct({...x}),config()).status,'unknown');
});
test('missing version is unknown even without version bounds',()=>{
 const x=product();x.ios=null;
 assert.equal(C.matchProduct(x,config()).status,'unknown');
 assert.equal(C.matchProduct(x,config({minIOS:'',maxIOS:''})).status,'unknown');
});
test('sold products and wrong known model are rejected despite another missing field',()=>{
 const p=product();p.ios=null;p.soldOut=true;
 assert.equal(C.matchProduct(p,config()).status,'reject');
 p.soldOut=false;p.model='iPhone 15 Pro';
 assert.equal(C.matchProduct(p,config()).status,'reject');
});
test('server errors are not normalized as valid products',()=>{
 const p=C.normalizeProduct({id:f.id,base:{respCode:403,respData:f.base.respData},more:f.more});
 assert.equal(C.matchProduct(p,config()).status,'unknown');
});
test('unsafe numeric IDs are never rounded into product identities',()=>{
 assert.equal(C.normalizeId(2107126446155633664),null);
 assert.equal(C.normalizeId('2107126446155633664'),'2107126446155633664');
});
test('extracts filter options dynamically without tracking payloads',()=>{
 const options=C.filterOptions(f.filterResponse);
 assert.equal(options.capacities.find(x=>x.label==='512G').value,'5170');
 assert.equal(options.conditions.find(x=>x.label==='95新').value,'28077');
});
test('safe detail URL requires one exact product ID on a known HTTPS route',()=>{
 assert.equal(C.safeProductURL(f.item.jumpUrl,f.id),true);
 for(const u of ['https://evil.example/?infoId='+f.id,'javascript:alert(1)','https://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail?infoId=999'])assert.equal(C.safeProductURL(u,f.id),false);
});
test('missing and failed reports never match even with unrestricted optional filters',()=>{
 for(const more of [null,{respCode:403},{respCode:0,respData:{}},{respCode:0,respData:{report:{}}}]){
  const p=C.normalizeProduct({id:f.id,base:f.base,more});
  assert.equal(C.matchProduct(p,config({minIOS:'',maxIOS:'',conditions:[],capacities:[]})).status,'unknown');
 }
});
test('verification accepts only explicit boolean representations and malformed envelopes stay unknown',()=>{
 for(const v of [null,[], 'bad',2,-1,{}])assert.equal(C.collectedState({respCode:0,respData:v}),null);
 for(const v of [2,-1,{},[]])assert.equal(C.collectedState({respCode:0,respData:{collected:v}}),null);
 for(const v of [true,1,'1','true'])assert.equal(C.collectedState({respCode:0,respData:{collected:v}}),true);
 for(const v of [false,0,'0','false'])assert.equal(C.collectedState({respCode:0,respData:{collected:v}}),false);
});
test('pending mutation survives stop/new runs and only its originating completion unlocks',()=>{
 const g=new C.MutationGate(),t={run:'old',step:3};
 assert.equal(g.pending(),false);assert.equal(g.begin(f.id,t),true);assert.equal(g.pending(),true);
 assert.equal(g.begin(f.id,{run:'new',step:1}),false);
 assert.equal(g.complete(f.id,{run:'new',step:3}),false);assert.equal(g.complete('999',t),false);
 assert.equal(g.pending(),true);assert.equal(g.complete(f.id,t),true);assert.equal(g.pending(),false);
 assert.equal(g.begin(f.id,{run:'new',step:1}),true);
});
test('pagination waits through slow requests beyond the former eight-scroll limit',()=>{
 const t={run:'slow',step:3},w=new C.PageWait(t,2,1000);assert.equal(w.poll(1000,false),'scroll');w.requestStarted(2,t);
 for(let now=2200;now<=55000;now+=1200)assert.equal(w.poll(now,false),'wait');assert.equal(w.poll(61000,false),'timeout');
});
test('pagination waits for visible loading, ignores stale requests and stays bounded',()=>{
 const t={run:'a',step:4},w=new C.PageWait(t,2,0);
 assert.equal(w.poll(0,true),'wait');assert.equal(w.poll(15000,true),'wait');
 assert.equal(w.requestStarted(1,t),false);assert.equal(w.requestStarted(2,{run:'a',step:3}),false);
 assert.equal(w.poll(16000,false),'scroll');assert.equal(w.poll(16500,false),'wait');assert.equal(w.poll(17200,false),'scroll');
 assert.equal(w.poll(60000,true),'timeout');
});

test('purchase channels default to mainland while explicit unrestricted and saved criteria survive',()=>{
 const c=C.validateConfig(config()).config;assert.deepEqual(c.channels,['国行']);assert.equal(c.autoFavorite,false);assert.equal(c.manualMinIOS,'26.0');
 assert.deepEqual(C.validateConfig(config({channels:[]})).config.channels,[]);
 assert.deepEqual(C.validateConfig(config({channels:['美版','国行']})).config.channels,['美版','国行']);
 for(const channels of [null,'国行',['未知'],[1]])assert.equal(C.validateConfig(config({channels})).ok,false);
});
test('purchase channel uses report params and paramBars rather than product title',()=>{
 assert.equal(product().channel,'国行');const x=structuredClone(f);
 x.more.respData.report.params=x.more.respData.report.params.filter(p=>p.key!=='购买渠道');
 x.more.respData.report.reportParam.paramBars[0].paramValue='美版';assert.equal(C.normalizeProduct(x).channel,'美版');
 x.more.respData.report.reportParam.paramBars=[];x.more.respData.report.reportParam.paramDetail[0].paramInfo.push({paramName:'购买渠道',paramValue:'港澳台版'});assert.equal(C.normalizeProduct(x).channel,'港澳台版');
 x.more.respData.report.reportParam.paramDetail[0].paramInfo.pop();assert.equal(C.normalizeProduct(x).channel,null);
});
test('channel selection is OR within channels and AND with all other criteria',()=>{
 const p=product();p.channel='港澳台版';assert.equal(C.matchProduct(p,config()).status,'reject');
 assert.equal(C.matchProduct(p,config({channels:['国行','港澳台版']})).status,'match');
 assert.equal(C.matchProduct(p,config({channels:[]})).status,'match');
 p.channel='其他版本';assert.equal(C.matchProduct(p,config({channels:['其他版本']})).status,'match');
 p.channel=null;assert.equal(C.matchProduct(p,config({channels:['其他版本']})).status,'unknown');
});
test('conflicting and unsupported report channels cannot become matches by title inference',()=>{
 const x=structuredClone(f);x.more.respData.report.reportParam.paramBars[0].paramValue='美版';const p=C.normalizeProduct(x);
 assert.equal(p.channel,null);assert.equal(C.matchProduct(p,config()).status,'unknown');
 assert.equal(C.matchProduct(p,config({channels:[]})).status,'match');
 for(const v of ['未知','其他地区',null]){const q=structuredClone(f);q.more.respData.report.params.find(p=>p.key==='购买渠道').value=v;q.more.respData.report.reportParam.paramBars=[];assert.equal(C.matchProduct(C.normalizeProduct(q),config()).status,'unknown');}
 const q=structuredClone(f);q.more.respData.report.params.find(p=>p.key==='购买渠道').value='其他版本（不支持检测具体地区）';q.more.respData.report.reportParam.paramBars=[];assert.equal(C.normalizeProduct(q).channel,'其他版本');
});
test('rejection reasons follow iOS then channel then capacity then appearance',()=>{
 const p=product();p.ios='17.0';p.channel='美版';p.capacity='256';p.condition='8成新';
 assert.deepEqual(C.matchProduct(p,config()).reasons,['系统版本超出范围','购买渠道不符','容量不符','成色不符']);
});
