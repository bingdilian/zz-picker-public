const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
function engine() {
 assert.ok(fs.existsSync(path.join(__dirname,'../src/compatibility.js')), 'compatibility engine must exist');
 return require('../src/compatibility.js');
}
test('catalog_has_four_distinct_models',()=>{
 const C=engine(),ctx=C.defaultRuleContext();
 assert.equal(ctx.ruleVersion,'compat-2026-10-21.1');
 assert.deepEqual(ctx.models.map(m=>m.id),['iphone-14-pro','iphone-14-pro-max','iphone-15-pro','iphone-15-pro-max']);
 assert.deepEqual(ctx.models.map(m=>m.minIOS),['16.0','16.0','17.0','17.0']);
 assert.deepEqual(ctx.models.map(m=>m.chip),['A16','A16','A17 Pro','A17 Pro']);
 assert.ok(ctx.models[2].capacities.includes('128'));assert.ok(!ctx.models[3].capacities.includes('128'));
 assert.equal(ctx.tools[0].version,'2.1.1');assert.equal(ctx.tools[1].version,'3.0.11');
});
test('invalid_sections_are_unavailable',()=>{
 const C=engine(),raw=require('../src/compatibility-rules.json');
 assert.equal(C.createRuleContext(null).catalogAvailable,false);
 let ctx=C.createRuleContext({...raw,tools:[]});assert.equal(ctx.catalogAvailable,true);assert.equal(ctx.capabilitiesAvailable,false);
 ctx=C.createRuleContext({...raw,models:[{id:'bad'}]});assert.equal(ctx.catalogAvailable,false);
 ctx=C.createRuleContext({...raw,sources:[]});assert.equal(ctx.capabilitiesAvailable,false);
});
test('model_resolution_requires_exact_alias',()=>{
 const C=engine(),ctx=C.defaultRuleContext();
 assert.equal(C.resolveModel('苹果 iPhone15 Pro Max',ctx),'iphone-15-pro-max');
 assert.equal(C.resolveModel('Apple iPhone 15 Pro',ctx),'iphone-15-pro');
 for(const s of ['14PM','SE','15 Pro','iPhone 16 Pro','iPhone 15 Pro Max 512G'])assert.equal(C.resolveModel(s,ctx),null);
});

const config = extra=>({schemaVersion:3,model:'iPhone 14 Pro Max',modelId:'iphone-14-pro-max',rangeMode:'auto',manualMinIOS:'',manualMaxIOS:'',requireTrollStore:true,requireJailbreak:true,preserveLegacyRange:false,capacities:[],...extra});
test('R01-R10 four models and all capability combinations retain exact gaps',()=>{
 const C=engine(),ctx=C.defaultRuleContext();assert.equal(typeof C.effectiveRange,'function');
 for(const m of ctx.models)for(const ts of [false,true])for(const jb of [false,true]){
  const r=C.effectiveRange(config({modelId:m.id,requireTrollStore:ts,requireJailbreak:jb}),ctx);
  assert.equal(r.canStart,true);
  assert.deepEqual(r.ranges.map(r=>[r.min,r.max]),ts?(m.minIOS==='16.0'?[['16.0','16.6.1'],['17.0','17.0']]:[['17.0','17.0']]):[[m.minIOS,jb?'17.3.1':null]]);
 }
 assert.deepEqual(C.effectiveRange(config({rangeMode:'manual',manualMinIOS:'16.5'}),ctx).ranges.map(r=>[r.min,r.max]),[['16.5','16.6.1'],['17.0','17.0']]);
 assert.deepEqual(C.effectiveRange(config({rangeMode:'manual',manualMaxIOS:'16.6.1'}),ctx).ranges.map(r=>[r.min,r.max]),[['16.0','16.6.1']]);
 assert.equal(C.effectiveRange(config({rangeMode:'manual',manualMaxIOS:'17'}),ctx).ranges.length,2);
});
test('R08 R11 R12 invalid and empty inputs clear previous effective ranges',()=>{
 const C=engine(),ctx=C.defaultRuleContext();
 let r=C.effectiveRange(config({rangeMode:'manual',manualMinIOS:'16.7',manualMaxIOS:'16.7.2'}),ctx);assert.equal(r.status,'empty');assert.equal(r.canStart,false);
 for(const input of [{manualMinIOS:'18',manualMaxIOS:'17'},...['17.x','17.0.0.1','-1','17.0 Beta'].map(v=>({manualMinIOS:v}))]){
  r=C.effectiveRange(config({rangeMode:'manual',...input}),ctx);assert.equal(r.status,'invalid');assert.deepEqual(r.ranges,[]);
 }
 assert.equal(C.compareVersions('17.0.10','17.0.3'),1);assert.equal(C.compareVersions('17','17.0.0'),0);
});
test('R15-R18 legacy bounds and unknown models keep ordinary manual path only',()=>{
 const C=engine(),ctx=C.defaultRuleContext();
 assert.equal(C.effectiveRange(config({modelId:'unknown'}),ctx).status,'uncovered');
 const legacy=config({requireTrollStore:false,requireJailbreak:false,rangeMode:'manual',preserveLegacyRange:true,manualMinIOS:'15.0'});
 assert.deepEqual(C.effectiveRange(legacy,ctx).ranges.map(r=>[r.min,r.max]),[['15.0',null]]);
 assert.deepEqual(C.effectiveRange({...legacy,requireTrollStore:true},ctx).ranges.map(r=>[r.min,r.max]),[['16.0','16.6.1'],['17.0','17.0']]);
 assert.equal(C.effectiveRange({...legacy,modelId:''},ctx).canStart,true);
 assert.equal(C.effectiveRange({...legacy,modelId:'',rangeMode:'auto'},ctx).canStart,false);
});
test('R19-R20 capacity conflicts remain selected; legacy migration keeps original criteria',()=>{
 const C=engine(),ctx=C.defaultRuleContext(),c=config({modelId:'iphone-15-pro-max',capacities:['128']});
 const r=C.effectiveRange(c,ctx);assert.equal(r.canStart,false);assert.deepEqual(r.capacityConflicts,['128']);assert.deepEqual(c.capacities,['128']);
 assert.equal(C.effectiveRange({...c,capacities:['256']},ctx).canStart,true);
 assert.equal(C.effectiveRange({...c,requireTrollStore:false,requireJailbreak:false,rangeMode:'manual',preserveLegacyRange:true},ctx).canStart,true);
});
test('R23-R27 rules unavailable differs from uncovered or no intersection',()=>{
 const C=engine(),ctx=C.createRuleContext({...require('../src/compatibility-rules.json'),tools:[]});
 assert.equal(C.effectiveRange(config(),ctx).status,'unavailable');
 const r=C.effectiveRange(config({requireTrollStore:false,requireJailbreak:false}),ctx);
 assert.equal(r.canStart,true);assert.equal(r.ranges[0].max,null);assert.match(r.label,/以上|不限/);
});
for(const row of require('./fixtures/compatibility-cases.json'))test(`${row.id} report compatibility ${row.status}`,()=>{
 const C=engine(),core=require('../src/core.js'),ctx=C.defaultRuleContext();
 if(row.buildRestricted)ctx.tools[0].predicates[0].kind='buildRestricted';
 const p=core.normalizeProduct(row.input),r=core.matchProduct(p,row.config,ctx);
 assert.equal(r.status,row.status,row.id);assert.ok(Array.isArray(r.checks));
 assert.equal(r.ruleVersion,ctx.ruleVersion);
 if(['P04','P19'].includes(row.id)){assert.equal(p.build,null);assert.equal(p.releaseKind,'unverified');assert.match(r.evidence.limitation,/标称/);}
 if(row.id==='P17')assert.equal(r.checks.find(c=>c.key==='channel').state,'unknown');
 if(row.id==='P18')assert.equal(p.modelSource,'title');
 if(row.id==='P07')assert.equal(r.checks.find(c=>c.key==='trollstore').state,'notRequired');
});
test('original report text is retained; legacy numeric-only parsing is not widened',()=>{
 const core=require('../src/core.js'),row=require('./fixtures/compatibility-cases.json').find(r=>r.id==='P21');
 const p=core.normalizeProduct(row.input);
 assert.equal(p.ios,null);assert.equal(p.iosNumeric,'17.0');assert.match(p.iosRaw,/beta/);
 assert.equal(core.matchProduct(p,{model:'iPhone 14 Pro Max',minIOS:'',maxIOS:'',channels:[]}).status,'unknown');
 assert.equal(p.modelId,'synthetic-platform-model');assert.equal(p.catalogModelId,'iphone-14-pro-max');
});


test('explicit title disagreement is detected outside the compatibility catalog',()=>{
 const core=require('../src/core.js'),row=require('./fixtures/compatibility-cases.json').find(r=>r.id==='P03');
 for(const title of ['iPhone 13 Pro Max 256G','iPhone 16 Pro','苹果 iPhone SE']){
  const input=structuredClone(row.input);input.base.respData.title=title;input.item.title=title;
  const p=core.normalizeProduct(input);assert.equal(p.modelSource,'conflict',title);
  const e=core.matchProduct(p,row.config);assert.equal(e.status,'unknown',title);assert.equal(e.checks.find(c=>c.key==='model').state,'unknown');
 }
 const input=structuredClone(row.input);input.base.respData.title='Apple iPhone14 Pro Max 256G';assert.equal(core.matchProduct(core.normalizeProduct(input),row.config).status,'match');
});

test('supplied build metadata must agree with the report even on unrestricted tool ranges',()=>{
 const core=require('../src/core.js'),row=require('./fixtures/compatibility-cases.json').find(r=>r.id==='P03'),ctx=engine().defaultRuleContext();
 function product(ios,build){const input=structuredClone(row.input);for(const p of input.more.respData.report.params){if(p.key==='系统版本')p.value=ios;if(p.key==='构建号')p.value=build;}input.more.respData.report.reportParam.paramDetail[0].paramInfo[0].paramValue=ios;if(build===null)input.more.respData.report.params=input.more.respData.report.params.filter(p=>p.key!=='构建号');return core.normalizeProduct(input);}
 for(const requireTrollStore of [false,true]){
  const c={...row.config,requireTrollStore,requireJailbreak:true};
  for(const p of [product('16.5','21A329'),product('17.0','UNKNOWN999')])assert.equal(core.matchProduct(p,c,ctx).status,'unknown');
  assert.equal(core.matchProduct(product('17.0',null),c,ctx).status,'match');
  assert.equal(core.matchProduct(product('17.0','21A329'),c,ctx).status,'match');
 }
 // No complete16.x list exists: do not invent one or tighten ordinary legacy filtering.
 assert.equal(core.matchProduct(product('16.5','20F66'),row.config,ctx).status,'match');
 assert.equal(core.matchProduct(product('16.5','21A329'),{model:row.config.model,channels:['国行']},ctx).status,'match');
});
