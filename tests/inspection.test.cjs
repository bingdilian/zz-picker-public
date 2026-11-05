const test = require('node:test');
const assert = require('node:assert/strict');
const C = require('../src/core.js');
const f = require('./fixtures/capture.json');

const row = (name, value, isNormal = 1) => ({name, values: [{value, isNormal}]});
const group = (name, normalNum, abNormalNum, ...children) => ({name, normalNum, abNormalNum, children});
const sample = () => [
 group('外观检测', 1, 1, {name:'外壳',children:[row('外壳外观痕迹','掉漆/磨损、划痕',0),row('机身弯曲','无')]}),
 group('屏幕检测', 1, 1, {name:'屏幕显示',children:[row('坏点','无'),row('亮点/亮斑','有亮斑',0)]}),
 group('设备功能', 1, 0, {name:'生物识别',children:[row('面部识别','正常')]}),
 group('维修浸液', 2, 0, {name:'维修浸液',children:[row('屏幕','未检出维修更换')]},
       {name:'拆机情况',children:[row('拆机情况','平台已拆机换电')]}),
];
function product(items = sample(), params = []) {
 const input = structuredClone(f);
 const report = input.more.respData.report;
 report.reportItem = items;
 report.params.push(...params);
 return C.normalizeProduct(input);
}
const evaluate = (filters, p = product()) => C.matchProduct(p, {model:'iPhone 15 Pro Max', reportFilters:filters});

test('old settings leave inspection unrestricted; specified mode checks only selected paths', () => {
 assert.equal(evaluate(undefined, product([])).status, 'match');
 assert.equal(evaluate({screen:{mode:'selected',items:['屏幕显示›坏点']}}).status, 'match');
 assert.equal(evaluate({screen:{mode:'all'}}).status, 'reject');
 assert.equal(evaluate({screen:{mode:'selected',items:[]}}).status, 'match');
});

test('selected missing field is unknown; all requires complete evidence and skips explicit N/A', () => {
 assert.equal(evaluate({screen:{mode:'selected',items:['屏幕触控›触控']}}).status, 'unknown');
 const items = sample();
 items[2].children[0].children.push(row('指纹识别','不适用',null));
 assert.equal(evaluate({functions:{mode:'all'}},product(items)).status, 'match');
 items[2].normalNum = 2;
 assert.equal(evaluate({functions:{mode:'all'}},product(items)).status, 'unknown');
});

test('repair checks explicit disclosures despite a passing flag and orders reasons before screen', () => {
 const result = evaluate({repair:{mode:'all'},screen:{mode:'all'}});
 assert.equal(result.status, 'reject');
 assert.match(result.reasons[0], /维修浸液.*平台.*换电/);
 assert.match(result.reasons[1], /屏幕/);
 assert.equal(evaluate({repair:{mode:'selected',items:['拆机情况›拆机情况'],allowBatteryOnly:true}}).status, 'match');
 const items = sample();
 items[3].children[0].children[0].values = [{value:'屏幕外玻璃更换',isNormal:1}];
 assert.equal(evaluate({repair:{mode:'selected',items:['维修浸液›屏幕','拆机情况›拆机情况'],allowBatteryOnly:true}},product(items)).status, 'reject');
});

test('platform inspection disclosures pass only with consistent normal flags', () => {
 const repair = {mode:'all'};
 for (const value of ['平台已拆机检测','平台未拆机检测']) {
  const items = sample();
  const section = items[3];
  const dismantle = section.children[1].children;
  dismantle[0] = row('拆机情况',value);
  assert.equal(evaluate({repair},product(items)).status,'match',value);
  section.children[0].children[0] = row('屏幕','更换原厂屏',0);
  section.normalNum = 1;
  section.abNormalNum = 1;
  assert.deepEqual(evaluate({repair},product(items)).reasons,['维修浸液 › 维修浸液 › 屏幕不符']);
  section.children[0].children[0] = row('屏幕','未检出维修更换');
  dismantle[0] = row('拆机情况',value,0);
  assert.equal(evaluate({repair},product(items)).status,'unknown',value);
  dismantle[0] = row('拆机情况',value,null);
  section.normalNum = 2;
  section.abNormalNum = 0;
  assert.equal(evaluate({repair},product(items)).status,'unknown',value);
 }
});

test('detailed diagnostics retain dismantle evidence after favorite settlement', () => {
 const items = sample();
 items[3].children[1].children[0] = row('拆机情况','平台未拆机检测','1');
 const p = {...product(items),collected:false};
 const r = new C.Run({model:'iPhone 15 Pro Max',autoFavorite:true,reportFilters:{repair:{mode:'all'}}});
 r.start();
 r.search({respCode:0,respData:{infos:[f.item]}},1,r.next().token,{});
 r.detail(p,r.next().token);
 const favorite = r.next();
 assert.equal(favorite.type,'favorite');
 r.favoriteResult(f.favorite,favorite.token);
 r.verified(true,r.next().token);
 const snapshot = r.snapshot();
 assert.equal(C.diagnosticSnapshot(snapshot).results,undefined);
 assert.equal(JSON.stringify(C.diagnosticSnapshot(snapshot)).includes('平台未拆机检测'),false);
 const result = C.diagnosticSnapshot(snapshot,true).results[0];
 assert.equal(result.status,'favorited');
 assert.deepEqual(result.dismantleCheck.values,[{value:'平台未拆机检测',isNormal:'1'}]);
 assert.equal(result.dismantleCheck.decision,'pass');
 assert.match(result.dismantleCheck.reason,/平台检测方式/);
});

test('missing dismantle evidence stays pending in all-pass mode and is visible in detailed diagnostics', () => {
 const items = sample();
 items[3].children.pop();
 items[3].normalNum = 1;
 const r = new C.Run({model:'iPhone 15 Pro Max',reportFilters:{repair:{mode:'all'}}});
 r.start();
 r.search({respCode:0,respData:{infos:[f.item]}},1,r.next().token,{});
 r.detail(product(items),r.next().token);
 const snapshot = r.snapshot();
 assert.equal(snapshot.counts.matched,0);
 assert.equal(snapshot.counts.unknown,1);
 const result = C.diagnosticSnapshot(snapshot,true).results[0];
 assert.equal(result.dismantleCheck.decision,'unknown');
 assert.deepEqual(result.dismantleCheck.values,[]);
});

test('the reported no-missing-parts result passes with a normal platform flag', () => {
 const items = sample();
 items[3].children[1].children[0] = row('拆机情况','平台已拆机检测');
 const parts = items[3].children[0].children;
 parts.push(row('零件缺失','未检出缺失',1));
 items[3].normalNum = 3;
 const r = new C.Run({model:'iPhone 15 Pro Max',reportFilters:{repair:{mode:'all'}}});
 r.start();
 r.search({respCode:0,respData:{infos:[f.item]}},1,r.next().token,{});
 r.detail(product(items),r.next().token);
 const snapshot = r.snapshot();
 assert.equal(C.diagnosticSnapshot(snapshot).results,undefined);
 const result = C.diagnosticSnapshot(snapshot,true).results[0];
 assert.equal(result.status,'match');
 assert.deepEqual(result.partsMissingCheck,{
  values:[{value:'未检出缺失',isNormal:1}],decision:'pass'
 });
 for (const [text, flag, expected] of [['未检出缺失',null,'unknown'],['未检出缺失',0,'reject'],['缺失',0,'reject']]) {
  parts[1] = row('零件缺失',text,flag);
  items[3].normalNum = 2;
  items[3].abNormalNum = flag===0?1:0;
  assert.equal(evaluate({repair:{mode:'all'}},product(items)).status,expected);
 }
});

test('allowing common exterior wear does not excuse a simultaneous defect', () => {
 assert.equal(evaluate({appearance:{mode:'wear'}}).status, 'match');
 const items = sample();
 items[0].children[0].children[0].values[0].value = '划痕、脱胶';
 assert.equal(evaluate({appearance:{mode:'wear'}},product(items)).status, 'reject');
});

test('battery alternatives and zero cycles are honored, ambiguous health range stays unknown', () => {
 const p = product(sample(),[{key:'电池更换情况',value:'平台更换全新华严苛品牌电池'},
  {key:'充电次数',value:'0（全新电池）'},{key:'电池健康值',value:'90%-95%'}]);
 assert.equal(evaluate({battery:{types:['未检出更换','平台更换'],maxCycles:'0',minHealth:'90'}},p).status, 'match');
 assert.equal(evaluate({battery:{minHealth:'93'}},p).status, 'unknown');
 assert.equal(evaluate({battery:{types:['未检出更换']}},p).status, 'reject');
});

test('a confirmed exclusion wins over missing inspection data and preserves both explanations', () => {
 const result = evaluate({screen:{mode:'all'},battery:{types:['未检出更换']}});
 assert.equal(result.status, 'reject');
 assert.match(result.reasons[0], /亮点/);
 assert.match(result.reasons[1], /电池.*待确认/);
});
