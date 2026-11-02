const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs');
const C=require('../src/compatibility.js');
function api(){assert.ok(fs.existsSync(require('node:path').join(__dirname,'../src/config.js')),'v3 configuration module must exist');return require('../src/config.js');}
const legacy=extra=>({model:'Apple iPhone 14 Pro Max',minIOS:'',maxIOS:'17',autoFavorite:false,channels:['国行'],capacities:['128'],conditions:['95新'],...extra});
test('M01 fresh defaults are auto 15PM with purposes/favorite off and finite budgets',()=>{
 const c=api().readStoredConfig({v3:null,v2:null,v1:null},C.defaultRuleContext()).config;
 assert.equal(c.schemaVersion,3);assert.equal(c.modelId,'iphone-15-pro-max');assert.equal(c.rangeMode,'auto');
 assert.equal(c.requireTrollStore,false);assert.equal(c.requireJailbreak,false);assert.equal(c.autoFavorite,false);
 assert.equal(c.maxProducts,100);assert.equal(c.maxMinutes,15);assert.deepEqual(c.channels,['国行']);assert.deepEqual(c.capacities,[]);
});
test('M02 M04-M08 migration preserves original query, raw bounds, favorites and capacity',()=>{
 const Q=api(),ctx=C.defaultRuleContext();
 for(const favorite of [false,true])for(const bounds of [{minIOS:'',maxIOS:''},{minIOS:' iOS 16.5 ',maxIOS:'17'}]){
  const old=legacy({...bounds,autoFavorite:favorite}),r=Q.readStoredConfig({v3:null,v2:old,v1:null},ctx),c=r.config;
  assert.equal(r.status,'ready');assert.equal(c.model,old.model);assert.equal(c.legacyModelText,old.model);assert.equal(c.modelId,'iphone-14-pro-max');
  assert.equal(c.rangeMode,'manual');assert.equal(c.manualMinIOS,bounds.minIOS);assert.equal(c.manualMaxIOS,bounds.maxIOS);assert.equal(c.preserveLegacyRange,true);
  assert.equal(c.autoFavorite,favorite);assert.deepEqual(c.capacities,['128']);assert.equal(c.requireTrollStore,false);
  assert.deepEqual(Q.readStoredConfig({v3:c,v2:legacy({model:'different'})},ctx).config,c);
 }
});
test('M03 M10 unknown model preserves ordinary text and blocks requested capabilities',()=>{
 const Q=api(),ctx=C.defaultRuleContext(),r=Q.readStoredConfig({v2:legacy({model:'my unknown phone'})},ctx),c=r.config;
 assert.equal(c.modelId,'');assert.equal(c.legacyModelText,'my unknown phone');assert.equal(C.effectiveRange(c,ctx).canStart,true);
 assert.equal(C.effectiveRange(Q.applyConfigEdit(c,{type:'setPurpose',key:'requireTrollStore',value:true},ctx),ctx).canStart,false);
});
test('M09 R28-R31 corruption is explicit; valid older backup never silently wins',()=>{
 const Q=api(),ctx=C.defaultRuleContext();
 for(const bad of [[], 'bad',42,{schemaVersion:99},legacy({autoFavorite:'false'})]){
  const r=Q.readStoredConfig({v3:bad,v2:legacy()},ctx);
  assert.equal(r.status,'recovery');assert.equal(r.config,null);assert.equal(r.backupSource,'v2');assert.deepEqual(r.invalidSlots,['v3']);assert.equal(r.backup.autoFavorite,false);
 }
 const r=Q.readStoredConfig({v2:legacy({minIOS:'17.x'}),v1:null},ctx);assert.equal(r.status,'recovery');assert.equal(r.backup,null);
 const c=Q.freshConfig();for(const patch of [{requireTrollStore:'false'},{requireJailbreak:null},{manualMinIOS:null},{preserveLegacyRange:'false'},{schemaVersion:4},{capacities:{}},{unrecognizedField:true}])assert.equal(Q.validateConfig({...c,...patch},ctx).ok,false);
});
test('M11 M12 explicit edits clear legacy semantics but preserve manual values and capacities',()=>{
 const Q=api(),ctx=C.defaultRuleContext();let c=Q.readStoredConfig({v2:legacy({minIOS:'15.0'})},ctx).config;
 c=Q.applyConfigEdit(c,{type:'setPurpose',key:'requireJailbreak',value:true},ctx);
 c=Q.applyConfigEdit(c,{type:'setPurpose',key:'requireJailbreak',value:false},ctx);
 assert.equal(C.effectiveRange(c,ctx).ranges[0].min,'15.0');
 const selected=Q.applyConfigEdit(c,{type:'selectModel',modelId:c.modelId},ctx);assert.equal(selected.preserveLegacyRange,false);
 c=Q.applyConfigEdit(c,{type:'setRangeMode',mode:'auto'},ctx);c=Q.applyConfigEdit(c,{type:'setRangeMode',mode:'manual'},ctx);
 assert.equal(c.manualMinIOS,'15.0');assert.equal(c.manualMaxIOS,'17');assert.equal(c.preserveLegacyRange,false);
 c=Q.applyConfigEdit(c,{type:'selectModel',modelId:'iphone-15-pro-max'},ctx);assert.deepEqual(c.capacities,['128']);
 assert.equal(Q.validateConfig(c,ctx).ok,true);assert.equal(C.effectiveRange(c,ctx).canStart,false);
});
test('normalized config arrays do not alias drafts and validation never overwrites raw input',()=>{
 const Q=api(),ctx=C.defaultRuleContext(),raw=legacy(),c=Q.validateConfig(raw,ctx).config;
 raw.channels.push('美版');raw.capacities.push('256');assert.deepEqual(c.channels,['国行']);assert.deepEqual(c.capacities,['128']);
 assert.equal(Q.validateConfig(Q.freshConfig(),ctx).config.minIOS,undefined);
});
