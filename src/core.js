(function (root) {
  'use strict';
  var serial = 0;
  var channelChoices = ['国行','美版','港澳台版','韩版','日版','欧版','其他版本'];
  function normalizeChannel(value) {
    if(typeof value!=='string')return null;
    var text=value.trim();
    if(text==='其他版本（不支持检测具体地区）'||text==='其他版本(不支持检测具体地区)')text='其他版本';
    return channelChoices.indexOf(text)>=0?text:null;
  }
  function clone(v) { return JSON.parse(JSON.stringify(v)); }
  function version(v) {
    if (typeof v !== 'string') return null;
    var m = v.trim().match(/^(?:iOS\s*)?(\d{1,2})(?:\.(\d{1,3}))?(?:\.(\d{1,3}))?$/i);
    return m ? [Number(m[1]), Number(m[2] || 0), Number(m[3] || 0)] : null;
  }
  function compareVersions(a, b) {
    a = version(a); b = version(b);
    if (!a || !b) return null;
    for (var i = 0; i < 3; i++) if (a[i] !== b[i]) return a[i] > b[i] ? 1 : -1;
    return 0;
  }
  function model(v) { return typeof v === 'string' ? v.toLowerCase().replace(/^(苹果|apple)\s*/,'').replace(/[\s_-]/g,'') : ''; }
  function normalizeCapacity(v) {
    var m = String(v || '').trim().match(/^(\d+)\s*(G(?:B)?|T(?:B)?)?$/i);
    return m && Number(m[1]) > 0 ? String(Number(m[1]) * (/^t/i.test(m[2] || '') ? 1024 : 1)) : null;
  }
  function normalizeId(v) {
    if (typeof v === 'number' && (!Number.isSafeInteger(v) || v <= 0)) return null;
    var s = typeof v === 'string' ? v : (typeof v === 'number' ? String(v) : '');
    return /^[1-9]\d*$/.test(s) ? s : null;
  }
  function bool(v) {
    if (v === true || v === 1 || v === '1' || v === 'true') return true;
    if (v === false || v === 0 || v === '0' || v === 'false') return false;
    return null;
  }
  var wearTypes = ['划痕', '磕碰', '掉漆/磨损'];
  var batteryTypes = ['未检出更换', '平台更换', '其他已更换'];
  var inspectionGroups = [
    {key:'appearance', label:'外观', name:'外观检测', modes:{any:'不限',wear:'允许常见痕迹，其余全部通过',selected:'排除指定外观'},
     groups:[['外壳',['外壳外观痕迹','脱胶/缝隙','刻字/图','机身弯曲','摄像头/闪光灯外观','卡托']],
             ['屏幕',['屏幕外观痕迹','支架破损','内屏掉漆/划伤','屏幕/其它','屏幕凸点（褶皱）']]]},
    {key:'battery', label:'电池情况', types:batteryTypes},
    {key:'screen', label:'屏幕', name:'屏幕检测', modes:{any:'不限',all:'显示和触控全部通过',selected:'排除指定问题'},
     groups:[['屏幕显示',['亮点/亮斑','泛红/泛黄','色斑','坏点','其它','图文残影']],['屏幕触控',['触控']]]},
    {key:'functions', label:'设备功能', name:'设备功能', modes:{any:'不限',all:'全部通过',selected:'指定功能必须通过'},
     groups:[['按键',['电源键','音量键','其它按键']],['生物识别',['面部识别']],['传感器',['距离感应','光线感应','重力感应','指南针']],
             ['无线',['无线功能']],['声音与振动',['振动','听筒','底部麦克风','扬声器']],['充电',['无线充电','有线充电']],
             ['通话功能',['SIM 卡1','SIM 卡2']],['摄像头',['闪光灯功能','前置摄像头','后置摄像头']],['其它状况',['开机情况','ID 锁','系统情况','激活还原情况']]]},
    {key:'repair', label:'维修浸液', name:'维修浸液', modes:{any:'不限',all:'全部通过',selected:'指定情况'},
     groups:[['维修浸液',['后摄维修情况','零件维修/更换','主板','屏幕','机身','前摄维修情况','浸液痕迹情况']],['拆机情况',['拆机情况']]]}
  ];
  inspectionGroups[0].wearTypes = wearTypes;
  var inspectionOrder = ['repair','screen','functions','battery','appearance'];
  var wearPaths = ['外壳›外壳外观痕迹','屏幕›屏幕外观痕迹'];
  var dismantlePath = '拆机情况›拆机情况';
  var na = /^(不适用|无此功能|无此配置)$/;
  function inspectionDefaults() {
    return {battery:{types:['未检出更换']},screen:{mode:'all'},functions:{mode:'all'},repair:{mode:'all'}};
  }
  function inspectionSelections(value, choices, label, errors) {
    if(value===undefined)return [];
    if(!Array.isArray(value)||value.some(function(x){return choices.indexOf(x)<0;})){
      errors.push(label+'选项无效');return [];
    }
    return choices.filter(function(x){return value.indexOf(x)>=0;});
  }
  function inspectionLimit(value, min, max, label, errors) {
    if(value===undefined||value==='')return '';
    if((typeof value!=='string'&&typeof value!=='number')||!/^\d+$/.test(String(value))||!Number.isSafeInteger(Number(value))||Number(value)<min||Number(value)>max){
      errors.push(label+'格式无效');return '';
    }
    return String(Number(value));
  }
  function validateInspection(input) {
    var errors=[], filters={};
    if(input!==undefined&&(!input||typeof input!=='object'||Array.isArray(input)))errors.push('验机报告筛选格式无效');
    input=input||{};
    inspectionGroups.forEach(function(section){
      var value=input[section.key];
      if(value!==undefined&&(!value||typeof value!=='object'||Array.isArray(value)))errors.push(section.label+'设置无效');
      value=value||{};
      if(section.key==='battery'){
        filters.battery={types:inspectionSelections(value.types,batteryTypes,'电池更换情况',errors),
          minHealth:inspectionLimit(value.minHealth,1,100,'最低电池健康值',errors),
          maxCycles:inspectionLimit(value.maxCycles,0,Number.MAX_SAFE_INTEGER,'最多充电次数',errors)};
        return;
      }
      var mode=value.mode===undefined?'any':value.mode;
      if(typeof mode!=='string'||!Object.prototype.hasOwnProperty.call(section.modes,mode))errors.push(section.label+'筛选方式无效');
      var paths=[];
      section.groups.forEach(function(g){g[1].forEach(function(item){paths.push(g[0]+'›'+item);});});
      var rule={mode:mode,items:inspectionSelections(value.items,paths,section.label,errors)};
      if(section.key==='appearance')rule.wear=inspectionSelections(value.wear,wearTypes,'外观痕迹',errors);
      if(section.key==='repair'){
        if(value.allowBatteryOnly!==undefined&&typeof value.allowBatteryOnly!=='boolean')errors.push('允许仅平台拆机换电必须是开关值');
        rule.allowBatteryOnly=value.allowBatteryOnly===true;
      }
      filters[section.key]=rule;
    });
    return {filters:filters,errors:errors};
  }
  function inspectionSummary(filters) {
    var rules=validateInspection(filters).filters, summary={};
    inspectionGroups.forEach(function(section){
      var r=rules[section.key], parts=[];
      if(section.key==='battery'){
        if(r.types.length)parts.push(r.types.join('／'));
        if(r.minHealth!=='')parts.push('健康值 ≥ '+r.minHealth+'%');
        if(r.maxCycles!=='')parts.push('充电 ≤ '+r.maxCycles+' 次');
      }else if(r.mode==='selected'){
        var count=r.items.length+(r.wear||[]).length;
        if(count)parts.push('已选 '+count+' 项');
        if(r.allowBatteryOnly&&r.items.indexOf(dismantlePath)>=0)parts.push('允许仅平台换电');
      }else if(r.mode!=='any'&&section.modes[r.mode])parts.push(section.modes[r.mode]);
      if(parts.length)summary[section.key]=parts.join(' · ');
    });
    return summary;
  }
  function inspectionLeaf(value) {
    var list=Array.isArray(value)?value:[];
    if(!list.length)return {state:'unknown',texts:[]};
    var texts=[], flags=[];
    list.forEach(function(result){
      var label=result&&typeof result.value==='string'?result.value.trim():'';
      if(!label){flags.push(null);return;}
      if(na.test(label)){flags.push('na');return;}
      texts.push(label);
      flags.push(bool(result.isNormal));
    });
    var unique=flags.filter(function(flag,i){return flags.indexOf(flag)===i;});
    var flag=unique.length===1?unique[0]:null;
    return {state:flag==='na'?'na':flag===true?'pass':flag===false?'fail':'unknown',texts:texts};
  }
  function inspectionData(report) {
    var categories={}, params={};
    (Array.isArray(report.params)?report.params:[]).forEach(function(p){
      if(p&&['电池健康值','充电次数','电池更换情况'].indexOf(p.key)>=0){
        (params[p.key]||(params[p.key]=[])).push(typeof p.value==='string'||typeof p.value==='number'?String(p.value).trim():'');
      }
    });
    (Array.isArray(report.reportItem)?report.reportItem:[]).forEach(function(category){
      if(!category||!inspectionGroups.some(function(s){return s.name===category.name;}))return;
      if(Object.prototype.hasOwnProperty.call(categories,category.name)){categories[category.name]={complete:false,items:{}};return;}
      var items=Object.create(null), duplicate=false;
      function read(n,path){
        if(!n||typeof n.name!=='string'||!n.name.trim()||n.name.indexOf('›')>=0){duplicate=true;return;}
        var next=path.concat(n.name.trim());
        if(Array.isArray(n.children)&&n.children.length){n.children.forEach(function(child){read(child,next);});return;}
        // The captured repair report includes an empty, zero-count battery subsection.
        if(!path.length&&n.name==='电池检测'&&!n.values&&n.normalNum===0&&n.abNormalNum===0)return;
        var key=next.join('›');
        if(items[key]){items[key]={state:'unknown',texts:[]};duplicate=true;}
        else items[key]=inspectionLeaf(n.values);
      }
      (Array.isArray(category.children)?category.children:[]).forEach(function(n){read(n,[]);});
      var applicable=Object.keys(items).filter(function(key){return items[key].state!=='na';});
      var normal=applicable.filter(function(key){return items[key].state==='pass';}).length;
      var abnormal=applicable.filter(function(key){return items[key].state==='fail';}).length;
      categories[category.name]={items:items,complete:!duplicate&&applicable.length>0&&
        normal+abnormal===applicable.length&&category.normalNum===normal&&category.abNormalNum===abnormal};
    });
    return {categories:categories,params:params};
  }
  function batteryType(value) {
    if(/^(未检出|未检测到|未发现|无)电池更换$|^未检出更换$/.test(value))return '未检出更换';
    if(/^平台(?:已)?(?:更换|换新|焕新|换电)/.test(value))return '平台更换';
    if(/^(?:非平台|第三方)?(?:已)?(?:更换|换过)(?!情况)|^检出更换/.test(value))return '其他已更换';
    return null;
  }
  function healthRange(value) {
    var m=value.match(/^(\d{1,3})\s*%(?:\s*[-–—~～至]\s*(\d{1,3})\s*%)?$/);
    if(!m)return null;
    var low=Number(m[1]), high=m[2]?Number(m[2]):low;
    return low>0&&low<=high&&high<=100?low+'-'+high:null;
  }
  function cycleCount(value) {
    var m=value.match(/^(\d+)\s*(?:次)?(?:[（(]全新电池[）)])?$/);
    return m&&Number.isSafeInteger(Number(m[1]))?String(Number(m[1])):null;
  }
  function inspectBattery(params, rule, reject, unknown) {
    function field(key, normalize, evaluate){
      var v=consistent(params[key]||[],normalize).value;
      var decision=v===null?null:evaluate(v);
      if(decision===false)reject.push('电池情况 › '+key+'不符');
      if(decision===null)unknown.push('电池情况 › '+key+'待确认');
    }
    if(rule.types.length)field('电池更换情况',batteryType,function(v){return rule.types.indexOf(v)>=0;});
    if(rule.minHealth!=='')field('电池健康值',healthRange,function(v){
      var range=v.split('-').map(Number), min=Number(rule.minHealth);
      return range[0]>=min?true:range[1]<min?false:null;
    });
    if(rule.maxCycles!=='')field('充电次数',cycleCount,function(v){return Number(v)<=Number(rule.maxCycles);});
  }
  function repairDecision(row, allowBatteryOnly) {
    if(row.state==='unknown')return 'unknown';
    var text=row.texts.join('、');
    if(row.texts.length===1&&text==='平台已拆机换电')return allowBatteryOnly?'pass':'fail';
    if(row.state==='fail')return 'fail';
    if(row.texts.every(function(v){return /^(正常|无|未拆机|无拆机|未检出(?:维修(?:更换)?|更换|浸液(?:痕迹)?|拆机(?:痕迹)?)|无(?:维修|更换|浸液|拆机)(?:记录|痕迹)?)$/.test(v);}))return 'pass';
    if(row.texts.some(function(v){return !/^(?:未|无)/.test(v)&&/维修|更换|浸液|拆机/.test(v);}))return 'fail';
    return 'unknown';
  }
  function wearTokens(row) {
    return row.texts.join('、').replace(/／/g,'/').split(/[、，,；;]+/).map(function(t){return t.trim();});
  }
  function commonWear(token) {
    if(/^(轻微|明显|多处|少量)?(?:掉漆(?:\/磨损)?|磨损)$/.test(token))return '掉漆/磨损';
    if(/^(轻微|明显|多处|少量)?划痕$/.test(token))return '划痕';
    if(/^(轻微|明显|多处|少量)?磕碰$/.test(token))return '磕碰';
    return null;
  }
  function inspectReport(report, filters, reject, unknown) {
    report=report||{categories:{},params:{}};
    inspectionOrder.forEach(function(key){
      var rule=filters[key], section=inspectionGroups.find(function(g){return g.key===key;});
      if(key==='battery'){inspectBattery(report.params,rule,reject,unknown);return;}
      if(rule.mode==='any')return;
      var category=report.categories[section.name], items=category?category.items:{};
      var selected=rule.mode==='selected';
      var paths=selected?rule.items:Object.keys(items);
      var exclusionOnly=key==='appearance'&&selected&&rule.wear.length>0;
      if(exclusionOnly)paths=paths.concat(wearPaths.filter(function(path){return paths.indexOf(path)<0;}));
      paths.forEach(function(path){
        var row=items[path];
        if(row&&row.state==='na')return;
        var label=section.label+' › '+path.replace(/›/g,' › '), result=row?row.state:'unknown';
        if(row&&key==='repair'){
          var allow=selected&&rule.allowBatteryOnly&&path===dismantlePath;
          result=repairDecision(row,allow);
          if(result==='fail'&&row.texts.length===1&&['平台已拆机换电','屏幕外玻璃更换'].indexOf(row.texts[0])>=0)
            label+='（'+row.texts[0]+'）';
        }
        if(row&&key==='appearance'&&wearPaths.indexOf(path)>=0&&result!=='unknown'){
          var tokens=wearTokens(row);
          if(rule.mode==='wear'&&result==='fail'&&tokens.every(commonWear))result='pass';
          if(exclusionOnly&&tokens.some(function(t){return rule.wear.indexOf(commonWear(t))>=0;}))result='fail';
          else if(exclusionOnly&&rule.items.indexOf(path)<0)result='pass';
        }
        if(result==='fail')reject.push(label+'不符');
        if(result==='unknown')unknown.push(label+'待确认');
      });
      if(!selected&&(!category||!category.complete))unknown.push(section.label+' › 报告项目完整性待确认');
    });
  }
  function validateConfig(input) {
    input = input || {};
    var c = { model: String(input.model || '').trim(), minIOS: String(input.minIOS || '').trim(), maxIOS: String(input.maxIOS || '').trim(), channels: input.channels===undefined?['国行']:input.channels, conditions: input.conditions || [], capacities: input.capacities || [], autoFavorite: input.autoFavorite === true, autoConfirmBattery: input.autoConfirmBattery === true, continueAfterHit: input.continueAfterHit === true };
    var inspection = validateInspection(input.reportFilters);
    c.reportFilters = inspection.filters;
    var errors = inspection.errors;
    [['maxProducts',100,2000,'商品数量'],['maxMinutes',15,120,'运行分钟数']].forEach(function(limit){
      var value=input[limit[0]];
      if(value===undefined)value=limit[1];
      else if(typeof value==='string'&&value.trim())value=Number(value);
      if(typeof value!=='number'||!Number.isFinite(value)||!Number.isInteger(value)||value<1||value>limit[2])errors.push(limit[3]+'必须是1至'+limit[2]+'的整数');
      c[limit[0]]=value;
    });
    if (!c.model || c.model.length > 80) errors.push('请填写完整手机型号');
    if (c.minIOS && !version(c.minIOS)) errors.push('最低版本格式错误，例如 17.0.3');
    if (c.maxIOS && !version(c.maxIOS)) errors.push('最高版本格式错误，例如 17.0.3');
    if (c.minIOS && c.maxIOS && compareVersions(c.minIOS,c.maxIOS) === 1) errors.push('最低版本不能大于最高版本');
    if (input.autoFavorite !== undefined && typeof input.autoFavorite !== 'boolean') errors.push('自动收藏必须是开关值');
    if (input.autoConfirmBattery !== undefined && typeof input.autoConfirmBattery !== 'boolean') errors.push('自动确认换新电池提醒必须是开关值');
    if (input.continueAfterHit !== undefined && typeof input.continueAfterHit !== 'boolean') errors.push('命中后继续扫描必须是开关值');
    if (!Array.isArray(c.channels) || c.channels.some(function(x){return channelChoices.indexOf(x)<0;})) errors.push('购买渠道选项无效');
    if (!Array.isArray(c.conditions) || c.conditions.some(function(x){return ['99新','95新','9成新','8成新'].indexOf(x)<0;})) errors.push('成色选项无效');
    if (!Array.isArray(c.capacities) || c.capacities.some(function(x){return !normalizeCapacity(x);})) errors.push('容量选项无效');
    if (!errors.length) c.capacities = c.capacities.map(normalizeCapacity);
    return {ok: !errors.length, errors: errors, config: c};
  }
  function collectedState(envelope) { var d=data(envelope);return d&&!Array.isArray(d)?bool(d.collected):null; }
  function data(envelope) { return envelope && String(envelope.respCode) === '0' && envelope.respData && typeof envelope.respData === 'object' ? envelope.respData : null; }
  function consistent(values, normalize) {
    var result = null, conflict = false;
    values.forEach(function(v){var n=normalize(v);if (!n) conflict=true;else if (result && result!==n) conflict=true;else result=n;});
    return {value: conflict ? null : result, conflict: conflict};
  }
  function normalizeProduct(input) {
    input=input||{};
    var base=data(input.base), more=data(input.more), report=more && more.report || {}, item=input.item||{};
    var ios=[], channels=[], capacities=[], issues=[];
    if(!more || !report || typeof report!=='object' || Array.isArray(report) || !Object.keys(report).length)issues.push('验机报告缺失或请求失败');
    (Array.isArray(report.params) ? report.params : []).forEach(function(p){
      if(!p||typeof p!=='object')return;
      if(p.key==='系统版本') ios.push(p.value);
      if(p.key==='存储容量') capacities.push(p.value);
      if(p.key==='购买渠道') channels.push(p.value);
    });
    var bars=report.reportParam && report.reportParam.paramBars;
    (Array.isArray(bars)?bars:[]).forEach(function(p){if(p&&p.paramName==='购买渠道')channels.push(p.paramValue);});
    var detail=report.reportParam && report.reportParam.paramDetail;
    (Array.isArray(detail)?detail:[]).forEach(function(g){(Array.isArray(g.paramInfo)?g.paramInfo:[]).forEach(function(p){
      if(p.paramName==='系统版本') ios.push(p.paramValue);
      if(p.paramName==='存储容量') capacities.push(p.paramValue);
      if(p.paramName==='购买渠道') channels.push(p.paramValue);
    });});
    var os=consistent(ios,function(v){return version(v)?String(v).replace(/^iOS\s*/i,'').trim():null;});
    // Compare normalized tuples so 17.0 and 17.0.0 agree across report sections.
    if(os.conflict && ios.length && ios.every(function(v){return compareVersions(v,ios[0])===0;})) os={value:String(ios[0]).replace(/^iOS\s*/i,'').trim(),conflict:false};
    var cap=consistent(capacities,normalizeCapacity);
    var channel=consistent(channels,normalizeChannel);
    if(os.conflict) issues.push('系统版本来源冲突或格式异常');
    if(cap.conflict) issues.push('存储容量来源冲突或格式异常');
    if(!base) issues.push('商品基础信息缺失或请求失败');
    var title=base && base.title || item.title || '';
    var m=report.title || '';
    if(!m) {var mt=title.match(/(?:苹果\s*)?(iPhone\s*(?:SE(?:\s*\([^)]*\))?|\d+(?:\s*(?:Pro\s*Max|Pro|Plus|mini|Air|e))?))/i);if(mt)m=mt[1];}
    return {id:normalizeId(input.id)||normalizeId(item.strInfoId)||normalizeId(item.infoId), title:title, model:m,
      modelId:base && base.modelId!=null?String(base.modelId):String(item.pgModelId||''), ios:os.value,channel:channel.value,channelConflict:channel.conflict,capacity:cap.value,
      condition:base && base.infoLv && base.infoLv.level || null,
      functionGrade:report.dtGrade && report.dtGrade.function && report.dtGrade.function.name || null,
      collected:base?bool(base.collected):null,soldOut:base?bool(base.isSoldOut):null,issues:issues,inspection:inspectionData(report)};
  }
  function matchProduct(p, config) {
    var v=validateConfig(config);if(!v.ok)return {status:'unknown',reasons:v.errors};
    var c=v.config,reject=[],unknown=[];
    if(!p.id)unknown.push('商品ID缺失');
    if(!p.model)unknown.push('型号缺失');else if(model(p.model)!==model(c.model))reject.push('型号不符');
    if(p.soldOut===true)reject.push('商品已售出');else if(p.soldOut!==false)unknown.push('销售状态未知');
    if(!version(p.ios))unknown.push('系统版本未知');
    else if((c.minIOS&&compareVersions(p.ios,c.minIOS)<0)||(c.maxIOS&&compareVersions(p.ios,c.maxIOS)>0))reject.push('系统版本超出范围');
    if(c.channels.length){if(!normalizeChannel(p.channel)||p.channelConflict)unknown.push(p.channelConflict?'购买渠道来源冲突或无法识别':'购买渠道未知');else if(c.channels.indexOf(p.channel)<0)reject.push('购买渠道不符');}
    if(c.capacities.length){if(!p.capacity)unknown.push('容量缺失');else if(c.capacities.indexOf(normalizeCapacity(p.capacity))<0)reject.push('容量不符');}
    if(c.conditions.length){if(!p.condition)unknown.push('成色缺失');else if(c.conditions.indexOf(p.condition)<0)reject.push('成色不符');}
    (p.issues||[]).forEach(function(x){unknown.push(x);});
    inspectReport(p.inspection,c.reportFilters,reject,unknown);
    return {status:reject.length?'reject':unknown.length?'unknown':'match', reasons:reject.concat(unknown)};
  }
  function filterOptions(input) {
    var out={conditions:[],capacities:[]},seen={};
    function visit(x){
      if(Array.isArray(x)){x.forEach(visit);return;}
      if(!x||typeof x!=='object')return;
      var group=x.key==='285'?'conditions':x.key==='69'?'capacities':null;
      if(group && typeof x.text==='string' && x.value && typeof x.cmd==='string'){
        var k=group+':'+x.value;if(!seen[k]){out[group].push({label:x.text,key:x.key,value:String(x.value),cmd:x.cmd});seen[k]=true;}
      }
      Object.keys(x).forEach(function(k){if(typeof x[k]==='object')visit(x[k]);});
    }
    visit(input);return out;
  }
  function safeProductURL(url,id) {
    if(typeof url!=='string'||!normalizeId(id))return false;
    var m=url.match(/^https:\/\/m\.zhuanzhuan\.com(\/u\/(?:streamline_detail\/new-goods-detail|bm-consign\/standard\/standard-detail))\?([^#]*)$/);
    if(!m)return false;
    var ids=[];m[2].split('&').forEach(function(x){var p=x.split('=');try{if(decodeURIComponent(p[0])==='infoId')ids.push(decodeURIComponent(p.slice(1).join('=')));}catch(e){ids.push('invalid');}});
    return ids.length===1&&ids[0]===id;
  }
  // Keep unresolved product IDs quarantined across scans; a timeout is not permission to retry them.
  function MutationGate(){this.active=null;this.uncertain={};}
  MutationGate.prototype.pending=function(){return this.active!==null;};
  MutationGate.prototype.begin=function(id,token){if(this.active||this.blocked(id)||!normalizeId(id)||!token||!token.run)return false;this.active={id:id,token:clone(token)};return true;};
  MutationGate.prototype.complete=function(id,token){var a=this.active;if(!a||a.id!==id||!token||a.token.run!==token.run||a.token.step!==token.step)return false;this.active=null;return true;};
  MutationGate.prototype.blocked=function(id){return this.uncertain[id]===true;};
  MutationGate.prototype.settle=function(id,token,collected){var a=this.active;if(!normalizeId(id)||!token||!token.run||!Number.isSafeInteger(token.step)||token.step<0||(a&&(a.id!==id||a.token.run!==token.run||token.step<a.token.step)))return false;if(collected===true)delete this.uncertain[id];else this.uncertain[id]=true;this.active=null;return true;};
  // Page navigation must wait for a real response, not a fixed number of scroll animations.
  function PageWait(token,page,now){this.token=clone(token);this.page=page;this.start=now;this.lastScroll=-Infinity;this.requestSeen=false;}
  PageWait.prototype.requestStarted=function(page,token){if(Number(page)!==this.page||!token||token.run!==this.token.run||token.step!==this.token.step)return false;this.requestSeen=true;return true;};
  PageWait.prototype.poll=function(now,loading){if(now-this.start>=60000)return 'timeout';if(this.requestSeen||loading||now-this.lastScroll<1200)return 'wait';this.lastScroll=now;return 'scroll';};
  function criteriaMatches(selection,options,config) {
    if(!selection||typeof selection!=='object')return false;
    options=options||{capacities:[],conditions:[]};
    function same(key,group,wanted,normalize){
      var actual=[],valid=true;if(!Array.isArray(selection[key]||[]))return false;
      (selection[key]||[]).forEach(function(x){
        if(!x||typeof x!=='object'){valid=false;return;}
        var found=(options[group]||[]).filter(function(o){return String(o.value)===String(x.value)&&o.cmd===x.cmd;})[0];
        if(!found){valid=false;return;}
        var value=normalize(found.label);if(value)actual.push(value);else if(found.label!=='不限')valid=false;
      });
      var a=Array.from(new Set(actual)).sort(),w=Array.from(new Set(wanted.map(normalize))).sort();
      return valid&&JSON.stringify(a)===JSON.stringify(w);
    }
    return same('69','capacities',config.capacities||[],normalizeCapacity)&&same('285','conditions',config.conditions||[],function(x){return x==='9新'?'9成新':x==='8新'?'8成新':x;});
  }
  function filterPlan(selection,options,config) {
    return ['capacities','conditions'].filter(function(field){
      if(!selection||typeof selection!=='object')return true;
      var only=clone(selection),criteria={capacities:[],conditions:[]};criteria[field]=config[field]||[];only[field==='capacities'?'285':'69']=[];
      return !criteriaMatches(only,options,criteria);
    });
  }
  function Run(config,clock) {
    var checked=validateConfig(config);if(!checked.ok)throw new Error(checked.errors.join('；'));
    this.config=checked.config;this.state='idle';this.phase='idle';this.page=1;this.step=0;this.run='';this.results=[];this.counts={};
    this.clock=clock||function(){return typeof root.ZZNow==='function'?root.ZZNow():Date.now();};this.elapsedMs=0;this.activeAt=null;this.budgetExceeded=false;this.limitReason='';
  }
  Run.prototype._tick=function(){if(this.activeAt!==null){var now=this.clock();this.elapsedMs+=Math.max(0,now-this.activeAt);this.activeAt=Math.max(now,this.activeAt);}return this.elapsedMs;};
  Run.prototype._freeze=function(){this._tick();this.activeAt=null;};
  Run.prototype.checkBudget=function(){
    this._tick();
    if(!this.budgetExceeded){if(this.counts.processed>=this.config.maxProducts)this.limitReason='已达到'+this.config.maxProducts+'件商品上限';else if(this.elapsedMs>=this.config.maxMinutes*60000)this.limitReason='已达到'+this.config.maxMinutes+'分钟运行上限';this.budgetExceeded=!!this.limitReason;}
    if(!this.budgetExceeded)return false;
    this.note=this.limitReason+'，请新建任务继续筛选';
    // Let an issued favorite and its independent readback settle before holding the queue.
    if(['favorite','verify'].indexOf(this.phase)>=0||['idle','paused','hit','stopped','finished'].indexOf(this.state)>=0)return false;
    this.pause(this.note);return true;
  };
  Run.prototype._issue=function(type,extra){this._tick();if(this.activeAt===null)this.activeAt=this.clock();this.phase=type;this.state=type;this.step++;this.note='';this.action=Object.assign({type:type,token:{run:this.run,step:this.step}},extra||{});this.intent=clone(this.action);};
  Run.prototype.start=function(){this.elapsedMs=0;this.activeAt=null;this.budgetExceeded=false;this.limitReason='';this.run='run-'+Date.now()+'-'+(++serial);this.page=1;this.step=0;this.results=[];this.queue=[];this.seen={};this.loadedSeen={};this.prefetched={};this.requests={};this.current=null;this.currentProduct=null;this.hit=null;this.recheckRow=null;this.pendingMatch=null;this.favoriteSettlement=null;this.favoriteIssue='';this.filtersConfirmed=false;this.options={conditions:[],capacities:[]};this.counts={loaded:0,processed:0,checked:0,matched:0,unknown:0,rejected:0,already:0,favorited:0,favoriteUnknown:0,favoriteManual:0,favoriteFailed:0};this._issue('search',{keyword:this.config.model,page:1});};
  Run.prototype.next=function(){if(this.checkBudget()||['paused','hit','stopped','finished'].indexOf(this.state)>=0)return null;var a=this.action;this.action=null;return a?clone(a):null;};
  Run.prototype._accept=function(token,phase){return ['paused','hit','stopped','finished'].indexOf(this.state)<0&&token&&token.run===this.run&&token.step===this.step&&(!phase||this.phase===phase);};
  Run.prototype.updateOptions=function(envelope){var d=data(envelope);if(!d)return;var newer=filterOptions(d.filterResponse||[]),self=this;['conditions','capacities'].forEach(function(k){newer[k].forEach(function(x){if(!self.options[k].some(function(o){return o.value===x.value;}))self.options[k].push(x);});});};
  Run.prototype._requestKey=function(token){return token?token.run+':'+token.step:'';};
  Run.prototype.searchStarted=function(page,token){if(!this._accept(token)||Number(page)!==this.page||['search','filters','nextPage'].indexOf(this.phase)<0)return false;(this.requests[page]||(this.requests[page]={}))[this._requestKey(token)]=this.phase;return true;};
  Run.prototype.searchFailed=function(page,token){var pending=this.requests&&this.requests[page],key=this._requestKey(token);if(!token||token.run!==this.run||!pending||!pending[key])return false;var phase=pending[key];delete pending[key];if(Number(page)===this.page&&phase===this.phase&&['search','filters','nextPage'].indexOf(this.phase)>=0&&this.state!=='stopped'){this.pause('搜索请求失败，请检查网络后重试');return true;}return false;};
  Run.prototype._countLoaded=function(infos){var self=this;infos.forEach(function(x){var id=normalizeId(x&&x.strInfoId)||normalizeId(x&&x.infoId);if(id&&!self.loadedSeen[id]){self.loadedSeen[id]=true;self.counts.loaded++;}});};
  Run.prototype.prefetch=function(envelope,page,token,selection){var d=data(envelope);if(!this.filtersConfirmed||!token||token.run!==this.run||['stopped','finished'].indexOf(this.state)>=0||!d||!Array.isArray(d.infos)||page<=this.page||page>100||!criteriaMatches(selection,this.options,this.config))return false;if(!this.prefetched[page]){this.prefetched[page]={envelope:clone(envelope),selection:clone(selection)};this._countLoaded(d.infos);}return true;};
  Run.prototype.search=function(envelope,page,token,selection,filterCommit){
    if(!token||token.run!==this.run||Number(page)!==this.page||['search','filters','nextPage'].indexOf(this.phase)<0||['stopped','finished'].indexOf(this.state)>=0)return false;
    var key=this._requestKey(token),pending=this.requests[page]||{},known=pending[key]===this.phase;
    if(!this._accept(token)&&!known)return false;
    delete pending[key];
    if(this.checkBudget())return false;
    if(this.state==='paused'){this.prefetched[page]={envelope:clone(envelope),selection:clone(selection===undefined?null:selection),filterCommit:filterCommit===true};this.note='已收到页面数据，点击继续处理';return false;}
    var d=data(envelope);if(!d||!Array.isArray(d.infos)){this.pause(envelope&&String(envelope.respCode)==='0'?'搜索响应数据格式异常，请导出诊断':'搜索请求失败，请检查网络或登录状态');return false;}
    this.updateOptions(envelope);
    if(this.phase==='filters'&&filterCommit!==true)return false;
    if(!criteriaMatches(selection,this.options,this.config)){
      if(this.filtersConfirmed){this.pause('列表筛选发生变化，请按原条件重新搜索');return false;}
      if(this.phase==='filters'){
        var missing=filterPlan(selection,this.options,this.config);
        this.intent.applyFields=missing;
        this.pause('筛选确认未通过：'+missing.map(function(field){return field==='capacities'?'容量':'成色';}).join('、')+'与设置不一致；商品尚未加入核验队列，请导出诊断');
        return false;
      }
      if(this.phase!=='filters')this._issue('filters',{page:1,conditions:this.config.conditions,capacities:this.config.capacities,applyFields:filterPlan(selection,this.options,this.config)});
      return this.phase==='filters'&&this.action!==null;
    }
    this.filtersConfirmed=true;var self=this;this._countLoaded(d.infos);
    this.queue=d.infos.filter(function(x){var id=normalizeId(x&&x.strInfoId)||normalizeId(x&&x.infoId);if(!id||self.seen[id])return false;self.seen[id]=true;return true;}).map(function(x){return {id:normalizeId(x.strInfoId)||normalizeId(x.infoId),title:String(x.title||''),price:String(x.price||''),pgModelId:String(x.pgModelId||''),jumpUrl:typeof x.jumpUrl==='string'?x.jumpUrl:''};});
    if(!this.queue.length){this._freeze();this.state='finished';this.phase='finished';this.action=null;this.note='没有更多新商品';return true;}
    this._advance();return true;
  };
  Run.prototype._advance=function(){
    if(this.checkBudget())return;
    this.hit=null;this.favoriteSettlement=null;this.favoriteIssue='';
    if(this.queue.length){this.current=this.queue.shift();this._issue('open',{item:this.current});}
    else if(this.page>=100){this._freeze();this.state='finished';this.phase='finished';this.action=null;this.note='达到单次100页上限';}
    else{this.page++;this.current=null;this._issue('nextPage',{page:this.page});this._consumeCached();}
  };
  Run.prototype._consumeCached=function(){if(this.prefetched[this.page]){var cached=this.prefetched[this.page];delete this.prefetched[this.page];this.search(cached.envelope,this.page,this.intent.token,cached.selection,cached.filterCommit);}};
  Run.prototype._record=function(p,status,reasons){var row={id:this.current.id,title:p.title||this.current.title,model:p.model||'',ios:p.ios||'',channel:p.channel||'',capacity:p.capacity||'',condition:p.condition||'',functionGrade:p.functionGrade||'',status:status,reasons:reasons||[]};if(safeProductURL(this.current.jumpUrl,this.current.id))row.detailPath=this.current.jumpUrl.split('?')[0];this.results.push(row);return row;};
  Run.prototype._hold=function(status,reasons){
    var row=this.recheckRow||this.pendingMatch;
    if(row){
      if(this.recheckRow&&status==='favorited'){
        if(row.status==='favoriteUnknown')this.counts.favoriteUnknown--;
        if(row.status==='favoriteManual')this.counts.favoriteManual--;
      }
      Object.assign(row,{status:status,reasons:reasons});
    }else row=this._record(this.currentProduct,status,reasons);
    var wasRecheck=!!this.recheckRow;
    this.recheckRow=this.pendingMatch=null;
    if(['favorite','verify'].indexOf(this.phase)>=0)this.favoriteSettlement={id:row.id,status:status};
    if(this.config.continueAfterHit&&!wasRecheck&&this.state!=='paused'&&!this.budgetExceeded){
      this._issue('back',{id:this.current.id});
      if(!this.checkBudget())return;
    }
    this._freeze();this.hit=Object.assign({},row,{item:clone(this.current)});
    this.state=this.phase='hit';this.step++;this.action=null;
    this.note='发现符合全部条件的商品，任务已暂停';this.checkBudget();
  };
  Run.prototype.detail=function(p,token){
    if(!this._accept(token,'open')||!this.current||p.id!==this.current.id||this.checkBudget())return false;
    this.currentProduct=p;var match=matchProduct(p,this.config);this.counts.processed++;if(match.status!=='unknown')this.counts.checked++;
    if(match.status==='match'){
      this.counts.matched++;
      if(this.config.autoFavorite&&p.collected===false){this.pendingMatch=this._record(p,'favoritePending',['等待收藏结果']);this._issue('favorite',{id:p.id,allowBatteryConfirmation:this.config.autoConfirmBattery});this.checkBudget();return true;}
      if(p.collected===true){this.counts.already++;this._hold('already',['原有收藏，已保留']);}
      else if(this.config.autoFavorite){this.counts.favoriteUnknown++;this._hold('favoriteUnknown',['收藏状态未知，不自动操作']);}
      else this._hold('match',['符合全部条件']);
    }else{if(match.status==='unknown')this.counts.unknown++;else this.counts.rejected++;this._record(p,match.status,match.reasons);if(!this.checkBudget())this._issue('back',{id:p.id});}
    return true;
  };
  Run.prototype._acceptSettlement=function(token,phase){return this._accept(token,phase)||(this.state==='paused'&&this.phase===phase&&this.intent&&token&&this._requestKey(token)===this._requestKey(this.intent.token));};
  Run.prototype.favoriteNeedsConfirmation=function(token){
    if(!this._acceptSettlement(token,'favorite'))return false;
    this.counts.favoriteManual++;
    this._hold('favoriteManual',['转转要求再次确认，请打开详情手动收藏']);
    return true;
  };
  Run.prototype.favoriteResult=function(envelope,token){
    if(!this._acceptSettlement(token,'favorite'))return false;
    if(envelope&&String(envelope.respCode)==='0'){
      if(this.state==='paused')this.note='收藏响应已返回，点击继续核对状态';
      else this._issue('verify',{id:this.current.id});
    }else{
      this.counts.favoriteFailed++;
      this._hold('favoriteFailed',['收藏接口未返回成功']);
    }
    return true;
  };
  Run.prototype.verified=function(collected,token){
    if(!this._acceptSettlement(token,'verify'))return false;
    this.currentProduct.collected=collected===true?true:collected===false?false:null;
    if(collected===true){
      this.counts.favorited++;this._hold('favorited',['收藏状态已独立确认']);
    }else{
      var status=this.recheckRow?this.recheckRow.status:'favoriteUnknown';
      if(!this.recheckRow)this.counts.favoriteUnknown++;
      var reasons=this.favoriteIssue?[this.favoriteIssue]:[];
      reasons.push(collected===false?'回读显示未收藏，可手动核对':'未能读取收藏状态，可手动核对');
      this._hold(status,reasons);
    }
    return true;
  };
  Run.prototype.recheckFavorite=function(){
    if(!this.hit||['favoriteUnknown','favoriteManual'].indexOf(this.hit.status)<0||this.phase!=='hit'||['hit','paused'].indexOf(this.state)<0)return false;
    this.recheckRow=this.results.filter(function(row){return row.id===this.hit.id&&row.status===this.hit.status;},this).pop();
    if(!this.recheckRow)return false;
    this._issue('verify',{id:this.current.id,item:clone(this.current)});return true;
  };
  Run.prototype.returned=function(token){if(!this._accept(token,'back'))return false;this._advance();return true;};
  Run.prototype.endOfList=function(token){if(!this._accept(token,'nextPage'))return false;this._freeze();this.state=this.phase='finished';this.step++;this.action=null;this.note='列表已确认没有更多商品';return true;};
  Run.prototype.failed=function(reason,token){if(!this._accept(token))return false;if(this.phase==='favorite'){this.favoriteIssue=reason;this._issue('verify',{id:this.current.id});}else if(this.phase==='verify')this.verified(null,token);else this.pause(reason);return true;};
  Run.prototype.pause=function(reason){if(['stopped','finished','idle'].indexOf(this.state)>=0)return;this._freeze();this.note=reason||'已暂停';if(this.state!=='paused'){this.state='paused';this.step++;this.action=null;}};
  Run.prototype.resume=function(){this.checkBudget();if(this.budgetExceeded&&!(this.state==='paused'&&['favorite','verify'].indexOf(this.phase)>=0))return;if(this.state==='hit'||(this.state==='paused'&&this.phase==='hit')){this._issue('back',{id:this.current.id});return;}if(this.state!=='paused')return;var i=this.intent;if(!i)return;var type=(this.phase==='favorite'||this.phase==='verify')?'verify':this.phase;var extra=clone(i);delete extra.type;delete extra.token;if(type==='verify'){extra={id:this.current.id};if(this.recheckRow)extra.item=clone(this.current);}this._issue(type,extra);if(type==='search'||type==='nextPage')this._consumeCached();};
  Run.prototype.beginViewing=function(){if((this.state!=='hit'&&this.state!=='paused')||this.phase!=='hit'||!this.hit)return false;this.pause('查看商品，任务保持暂停');return true;};
  Run.prototype.viewed=function(){if(this.state==='paused'&&this.phase==='hit'){this.checkBudget();if(!this.budgetExceeded)this.note='已返回列表，点击继续处理下一件';}};
  Run.prototype.stop=function(){if(this.state==='stopped')return;this._freeze();if(['favorite','verify'].indexOf(this.phase)>=0&&this.currentProduct){var row=this.recheckRow||this.pendingMatch;if(!this.recheckRow){if(!row)row=this._record(this.currentProduct,'favoriteUnknown',[]);Object.assign(row,{status:'favoriteUnknown',reasons:['任务已结束，已发出的收藏结果待确认']});this.counts.favoriteUnknown++;}this.recheckRow=this.pendingMatch=null;this.stoppedFavorite={id:this.current.id,token:clone(this.intent.token),row:row};}this.state='stopped';this.phase='stopped';this.step++;this.action=null;this.note='已结束，结果与已完成收藏已保留';};
  Run.prototype.settleStopped=function(path,envelope,id,token){var p=this.stoppedFavorite;if(this.state!=='stopped'||!p||p.id!==id||!token||this._requestKey(p.token)!==this._requestKey(token))return false;if(path==='baseInfo'){if(collectedState(envelope)===true){if(p.row.status==='favoriteManual')this.counts.favoriteManual--;else this.counts.favoriteUnknown--;p.row.status='favorited';p.row.reasons=['结束后收到独立收藏状态确认'];if(this.hit&&this.hit.id===id)Object.assign(this.hit,{status:p.row.status,reasons:p.row.reasons});if(this.currentProduct&&this.currentProduct.id===id)this.currentProduct.collected=true;this.counts.favorited++;}this.stoppedFavorite=null;return true;}if(path==='addLoveInfo'){p.row.reasons=['结束后收到收藏响应，状态仍待核验'];return true;}return false;};
  Run.prototype.snapshot=function(){var pending=this.requests&&this.requests[this.page]||{};return clone({state:this.state,phase:this.phase,config:this.config,page:this.page,token:{run:this.run,step:this.step},current:this.current?{id:this.current.id,title:this.current.title}:null,hit:this.hit||null,favoriteSettlement:this.favoriteSettlement||null,candidate:this.currentProduct?Object.assign({},this.currentProduct,{inspection:undefined}):null,counts:this.counts,results:this.results.filter(function(r){return ['match','already','favorited','favoriteUnknown','favoritePending','favoriteManual','favoriteFailed'].indexOf(r.status)>=0;}),allResults:this.results,note:this.note||'',waitingResponse:Object.keys(pending).length>0,options:this.options||{conditions:[],capacities:[]},budgetExceeded:this.budgetExceeded,limitReason:this.limitReason,elapsedMs:this._tick()});};
  function diagnosticSnapshot(snapshot,includeDetails){
    var out={},keys=['state','phase','config','page','counts','note','waitingResponse','options','budgetExceeded','limitReason','elapsedMs'];
    if(includeDetails===true)keys=keys.concat(['current','candidate','hit','results']);
    keys.forEach(function(key){if(snapshot[key]!==undefined)out[key]=clone(snapshot[key]);});
    if(includeDetails===true&&Array.isArray(snapshot.allResults))out.results=clone(snapshot.allResults);
    if(out.hit)delete out.hit.item;
    return out;
  }
  function presentation(s,pending){
    var state=s.state||'idle',phase=s.phase||state,kind=state==='hit'?'hit':state==='paused'?(phase==='hit'?'returned':'paused'):['stopped','finished'].indexOf(state)>=0?'summary':['favorite','verify'].indexOf(state)>=0?'favorite':state==='nextPage'?'loading':['search','filters'].indexOf(state)>=0?'search':state==='idle'?'idle':'running';
    var title={hit:'发现命中 · 已暂停',returned:'任务已暂停，等待继续',paused:'任务已暂停',summary:state==='finished'?'扫描完成':'本次任务已结束',favorite:state==='verify'?'正在核对收藏状态':'命中 · 正在收藏',loading:'正在加载第'+(s.page||1)+'页',search:state==='filters'?'正在应用容量与成色':'正在自动搜索',idle:'选机助手',running:'正在扫描'}[kind];
    var settlement=['favorite','verify'].indexOf(phase)>=0,canResume=['paused','hit'].indexOf(state)>=0&&(!pending||settlement)&&(!s.budgetExceeded||settlement);
    return {kind:kind,title:title,canResume:canResume,canView:!!s.hit&&['hit','returned'].indexOf(kind)>=0,canEnd:['idle','stopped','finished'].indexOf(state)<0,canSettings:['idle','paused','hit','stopped','finished'].indexOf(state)>=0,message:pending&&kind!=='favorite'?'上一笔收藏仍在处理中，可查看结果或结束后续任务':s.note||''};
  }
  var api={inspectionGroups:inspectionGroups,validateInspection:validateInspection,inspectionDefaults:inspectionDefaults,inspectionSummary:inspectionSummary,channelChoices:channelChoices,diagnosticSnapshot:diagnosticSnapshot,presentation:presentation,criteriaMatches:criteriaMatches,PageWait:PageWait,MutationGate:MutationGate,collectedState:collectedState,version:version,compareVersions:compareVersions,normalizeCapacity:normalizeCapacity,normalizeId:normalizeId,validateConfig:validateConfig,normalizeProduct:normalizeProduct,matchProduct:matchProduct,filterOptions:filterOptions,safeProductURL:safeProductURL,Run:Run};
  if(typeof module!=='undefined'&&module.exports)module.exports=api;
  root.ZZCore=api;
})(typeof globalThis!=='undefined'?globalThis:this);
