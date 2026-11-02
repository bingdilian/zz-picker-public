(function(root){
  'use strict';
  var C=typeof module!=='undefined'&&module.exports?require('./compatibility.js'):root.ZZCompatibility;
  var channelChoices=['国行','美版','港澳台版','韩版','日版','欧版','其他版本'];
  function clone(v){return JSON.parse(JSON.stringify(v));}
  function own(v,k){return Object.prototype.hasOwnProperty.call(v,k);}
  function object(v){return !!v&&typeof v==='object'&&!Array.isArray(v);}
  function normalizeCapacity(v){var m=String(v||'').trim().match(/^(\d+)\s*(G(?:B)?|T(?:B)?)?$/i);return m&&+m[1]>0?String(+m[1]*(/^t/i.test(m[2]||'')?1024:1)):null;}
  function freshConfig(){return {schemaVersion:3,model:'iPhone 15 Pro Max',modelId:'iphone-15-pro-max',legacyModelText:'',requireTrollStore:false,requireJailbreak:false,rangeMode:'auto',manualMinIOS:'',manualMaxIOS:'',preserveLegacyRange:false,channels:['国行'],conditions:[],capacities:[],autoFavorite:false,maxProducts:100,maxMinutes:15};}
  function validateConfig(input,context){
    context=context||C.defaultRuleContext();var errors=[];
    if(!object(input))return {ok:false,errors:['配置必须是对象'],config:null};
    var old=!own(input,'schemaVersion');
    if(!old&&input.schemaVersion!==3)return {ok:false,errors:['配置版本无法识别，请恢复旧配置或使用默认配置'],config:null};
    var c={schemaVersion:3,model:input.model,modelId:old?C.resolveModel(input.model,context)||'':input.modelId,legacyModelText:old?input.model:input.legacyModelText===undefined?'':input.legacyModelText,requireTrollStore:old?false:input.requireTrollStore,requireJailbreak:old?false:input.requireJailbreak,rangeMode:old?'manual':input.rangeMode,manualMinIOS:old?(input.minIOS===undefined?'':input.minIOS):input.manualMinIOS,manualMaxIOS:old?(input.maxIOS===undefined?'':input.maxIOS):input.manualMaxIOS,preserveLegacyRange:old?true:input.preserveLegacyRange,channels:input.channels===undefined?['国行']:input.channels,conditions:input.conditions===undefined?[]:input.conditions,capacities:input.capacities===undefined?[]:input.capacities,autoFavorite:input.autoFavorite===undefined?false:input.autoFavorite};
    if(!old)Object.keys(input).forEach(function(key){if(!own(c,key)&&['maxProducts','maxMinutes'].indexOf(key)<0)errors.push('配置包含无法识别字段：'+key);});
    if(typeof c.model!=='string'||!c.model.trim()||c.model.length>80)errors.push('请填写完整手机型号（最多80字符）');
    if(typeof c.modelId!=='string'||typeof c.legacyModelText!=='string')errors.push('型号标识或原文类型错误');
    ['requireTrollStore','requireJailbreak','preserveLegacyRange','autoFavorite'].forEach(function(key){if(typeof c[key]!=='boolean')errors.push(key+'必须是开关值');});
    if(['auto','manual'].indexOf(c.rangeMode)<0)errors.push('范围模式无效');
    [['manualMinIOS','最低版本'],['manualMaxIOS','最高版本']].forEach(function(row){var value=c[row[0]];if(typeof value!=='string'||value&&!C.version(value))errors.push(row[1]+'格式错误，例如17.0.3');});
    if(c.manualMinIOS&&c.manualMaxIOS&&C.compareVersions(c.manualMinIOS,c.manualMaxIOS)>0)errors.push('最低版本不能大于最高版本');
    [['maxProducts',100,2000,'商品数量'],['maxMinutes',15,120,'运行分钟数']].forEach(function(row){
      var v=input[row[0]];if(v===undefined)v=row[1];else if(typeof v==='string'&&v.trim())v=Number(v);
      if(typeof v!=='number'||!Number.isFinite(v)||!Number.isInteger(v)||v<1||v>row[2])errors.push(row[3]+'必须是1至'+row[2]+'的整数');c[row[0]]=v;
    });
    [['channels',channelChoices,'购买渠道'],['conditions',['99新','95新','9成新','8成新'],'成色']].forEach(function(row){if(!Array.isArray(c[row[0]])||c[row[0]].some(function(v){return row[1].indexOf(v)<0;}))errors.push(row[2]+'选项无效');});
    if(!Array.isArray(c.capacities)||c.capacities.some(function(v){return typeof v!=='string'||!normalizeCapacity(v);}))errors.push('容量选项无效');
    if(errors.length)return {ok:false,errors:errors,config:null};
    c.capacities=c.capacities.map(normalizeCapacity);
    return {ok:true,errors:[],config:clone(c)};
  }
  function readStoredConfig(slots,context){
    context=context||C.defaultRuleContext();slots=slots||{};
    var state={status:'ready',config:null,source:null,issues:[],invalidSlots:[],backup:null,backupSource:null};
    var keys=['v3','v2','v1'];
    for(var i=0;i<keys.length;i++){
      var key=keys[i],raw=slots[key];if(raw===null||raw===undefined)continue;
      var v=key==='v3'&&(!object(raw)||raw.schemaVersion!==3)?{ok:false,errors:['v3配置格式或版本错误']}:validateConfig(raw,context);
      if(v.ok){if(state.status==='ready'){state.config=v.config;state.source=key;}else{state.backup=v.config;state.backupSource=key;}return state;}
      state.status='recovery';state.invalidSlots.push(key);state.issues=state.issues.concat(v.errors.map(function(x){return key+'：'+x;}));
    }
    if(state.status==='ready')state.config=freshConfig();return state;
  }
  function applyConfigEdit(config,event,context){
    context=context||C.defaultRuleContext();var c=clone(config);
    if(event.type==='selectModel'){
      var m=context.models.filter(function(x){return x.id===event.modelId;})[0];if(!m)throw Error('机型未收录');
      c.modelId=m.id;c.model=m.searchText;c.preserveLegacyRange=false;
    }else if(event.type==='setRangeMode'){
      if(['auto','manual'].indexOf(event.mode)<0)throw Error('范围模式无效');c.rangeMode=event.mode;if(event.mode==='auto')c.preserveLegacyRange=false;
    }else if(event.type==='setPurpose'){
      if(['requireTrollStore','requireJailbreak'].indexOf(event.key)<0||typeof event.value!=='boolean')throw Error('用途开关无效');c[event.key]=event.value;
    }else throw Error('编辑操作无效');
    return c;
  }
  var api={freshConfig:freshConfig,validateConfig:validateConfig,readStoredConfig:readStoredConfig,applyConfigEdit:applyConfigEdit,normalizeCapacity:normalizeCapacity,channelChoices:channelChoices};
  if(typeof module!=='undefined'&&module.exports)module.exports=api;root.ZZConfig=api;
})(typeof globalThis!=='undefined'?globalThis:this);
