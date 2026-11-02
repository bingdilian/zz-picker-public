(function (root) {
  'use strict';
  var compatibility=typeof module!=='undefined'&&module.exports?require('./compatibility.js'):root.ZZCompatibility;
  var configuration=typeof module!=='undefined'&&module.exports?require('./config.js'):root.ZZConfig;
  var serial = 0;
  var channelChoices = configuration.channelChoices;
  function normalizeChannel(value) {
    if(typeof value!=='string')return null;
    var text=value.trim();
    if(text==='其他版本（不支持检测具体地区）'||text==='其他版本(不支持检测具体地区)')text='其他版本';
    return channelChoices.indexOf(text)>=0?text:null;
  }
  function clone(v) { return JSON.parse(JSON.stringify(v)); }
  function version(v) {
    if(compatibility)return compatibility.version(v);
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
  function normalizeCapacity(v) { return configuration.normalizeCapacity(v); }
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
  function validateConfig(input) { return configuration.validateConfig(input,compatibility.defaultRuleContext()); }
  function collectedState(envelope) { var d=data(envelope);return d&&!Array.isArray(d)?bool(d.collected):null; }
  function data(envelope) { return envelope && String(envelope.respCode) === '0' && envelope.respData && typeof envelope.respData === 'object' ? envelope.respData : null; }
  function consistent(values, normalize) {
    var result = null, conflict = false;
    values.forEach(function(v){var n=normalize(v);if (!n) conflict=true;else if (result && result!==n) conflict=true;else result=n;});
    return {value: conflict ? null : result, conflict: conflict};
  }
  function reportValues(report,label){
    var out=[];
    function put(key,value,path){if(key===label)out.push({path:path,value:typeof value==='string'&&value.length<=256?value:null});}
    (Array.isArray(report.params)?report.params:[]).forEach(function(p,i){if(p)put(p.key,p.value,'report.params['+i+'].value');});
    var param=report.reportParam||{};
    (Array.isArray(param.paramBars)?param.paramBars:[]).forEach(function(p,i){if(p)put(p.paramName,p.paramValue,'report.reportParam.paramBars['+i+'].paramValue');});
    (Array.isArray(param.paramDetail)?param.paramDetail:[]).forEach(function(g,i){(g&&Array.isArray(g.paramInfo)?g.paramInfo:[]).forEach(function(p,j){if(p)put(p.paramName,p.paramValue,'report.reportParam.paramDetail['+i+'].paramInfo['+j+'].paramValue');});});
    return out;
  }
  function normalizeProduct(input) {
    input=input||{};
    var base=data(input.base),more=data(input.more),report=more&&more.report||{},item=input.item||{},issues=[];
    if(!report||typeof report!=='object'||Array.isArray(report))report={};
    if(!more||!Object.keys(report).length)issues.push('验机报告缺失或请求失败');
    var iosSources=reportValues(report,'系统版本'),buildSources=reportValues(report,'构建号').concat(reportValues(report,'系统构建号'));
    var ios=iosSources.map(function(p){return p.value;}),channels=reportValues(report,'购买渠道').map(function(p){return p.value;}),capacities=reportValues(report,'存储容量').map(function(p){return p.value;});
    var releaseKind=ios.some(function(v){return /beta|测试版/i.test(v||'');})?'beta':ios.some(function(v){return /(?:^|[^a-z])rc(?:[^a-z]|$)|候选版/i.test(v||'');})?'rc':'unverified';
    var numeric=consistent(ios,function(v){if(version(v))return version(v).join('.');var m=typeof v==='string'&&v.match(/^(?:iOS\s*)?(\d{1,2}(?:\.\d{1,3}){0,2})\s*(?:beta|rc|测试版|候选版)[\s\d.]*$/i);return m&&version(m[1])?version(m[1]).join('.'):null;});
    var build=consistent(buildSources.map(function(x){return x.value;}),function(v){return typeof v==='string'&&/^[A-Za-z0-9]{1,30}$/.test(v.trim())?v.trim().toUpperCase():null;});
    var conflicts=[];if(numeric.conflict)conflicts.push('系统版本来源冲突或格式异常');if(build.conflict)conflicts.push('构建号来源冲突或格式异常');
    var os=consistent(ios,function(v){return version(v)?String(v).replace(/^iOS\s*/i,'').trim():null;});
    // Compare normalized tuples so 17.0 and 17.0.0 agree across report sections.
    if(os.conflict && ios.length && ios.every(function(v){return compareVersions(v,ios[0])===0;})) os={value:String(ios[0]).replace(/^iOS\s*/i,'').trim(),conflict:false};
    var cap=consistent(capacities,normalizeCapacity);
    var channel=consistent(channels,normalizeChannel);
    if(os.conflict) issues.push('系统版本来源冲突或格式异常');
    if(cap.conflict) issues.push('存储容量来源冲突或格式异常');
    if(!base) issues.push('商品基础信息缺失或请求失败');
    var title=String(base && base.title || item.title || '');
    var m=typeof report.title==='string'?report.title:'',modelSource=m?'report':'missing';
    var mt=title.match(/(?:苹果\s*)?(iPhone\s*(?:SE(?:\s*\([^)]*\))?|\d+(?:\s*(?:Pro\s*Max|Pro|Plus|mini|Air|e))?))/i);
    var ctx=compatibility.defaultRuleContext(),reportID=compatibility.resolveModel(m,ctx),titleID=mt?compatibility.resolveModel(mt[1],ctx):null;
    if(m&&mt&&(reportID&&titleID?reportID!==titleID:model(m)!==model(mt[1])))modelSource='conflict';
    if(!m&&mt){m=mt[1];modelSource='title';}
    return {modelSource:modelSource,catalogModelId:reportID,iosSources:iosSources,iosRaw:ios.length?ios[0]:null,iosNumeric:numeric.value?numeric.value.replace(/\.0$/,''):null,build:build.value,buildSources:buildSources,releaseKind:releaseKind,conflicts:conflicts,id:normalizeId(input.id)||normalizeId(item.strInfoId)||normalizeId(item.infoId), title:title, model:m,
      modelId:base && base.modelId!=null?String(base.modelId):String(item.pgModelId||''), ios:os.value,channel:channel.value,channelConflict:channel.conflict,capacity:cap.value,
      condition:base && base.infoLv && base.infoLv.level || null,
      functionGrade:report.dtGrade && report.dtGrade.function && report.dtGrade.function.name || null,
      collected:base?bool(base.collected):null,soldOut:base?bool(base.isSoldOut):null,issues:issues};
  }
  function matchProduct(p, config, context) {
    var v=validateConfig(config);if(!v.ok)return {status:'unknown',reasons:v.errors,checks:[],evidence:{},ruleVersion:null};
    context=context||compatibility.defaultRuleContext();var c=v.config,checks=[];
    var required=c.requireTrollStore||c.requireJailbreak,actual=context.models.filter(function(m){return m.id===p.catalogModelId;})[0];
    var physicalConflict=!!(actual&&version(p.iosNumeric)&&compareVersions(p.iosNumeric,actual.minIOS)<0&&!(c.preserveLegacyRange&&!required));
    function check(key,state,reason,paths){checks.push({key:key,state:state,reasons:reason?[reason]:[],sourcePaths:paths||[]});}
    check('identity',p.id?'pass':'unknown',p.id?'商品ID明确':'商品ID缺失');
    if(required&&p.modelSource!=='report')check('model','unknown','报告机型缺失或与商品标题冲突',['report.title']);
    else check('model',!p.model?'unknown':model(p.model)!==model(c.model)?'reject':'pass',!p.model?'型号缺失':model(p.model)!==model(c.model)?'型号不符':'型号符合',['report.title']);
    check('sale',p.soldOut===true?'reject':p.soldOut===false?'pass':'unknown',p.soldOut===true?'商品已售出':p.soldOut===false?'在售':'销售状态未知');
    var os=required?p.iosNumeric:p.ios;
    if(!version(os)||physicalConflict)check('system','unknown',physicalConflict?'报告系统低于该机型出厂边界':'系统版本未知');
    else if(c.schemaVersion===3){var effective=compatibility.effectiveRange(c,context);check('system',!effective.canStart?'unknown':compatibility.contains(effective.ranges,os)?'pass':'reject',!effective.canStart?effective.issues.join('；'):compatibility.contains(effective.ranges,os)?'系统版本符合':'系统版本超出范围');}
    else check('system',(c.minIOS&&compareVersions(os,c.minIOS)<0)||(c.maxIOS&&compareVersions(os,c.maxIOS)>0)?'reject':'pass','系统版本'+((c.minIOS&&compareVersions(os,c.minIOS)<0)||(c.maxIOS&&compareVersions(os,c.maxIOS)>0)?'超出范围':'符合'));
    if(c.channels.length)check('channel',!normalizeChannel(p.channel)||p.channelConflict?'unknown':c.channels.indexOf(p.channel)<0?'reject':'pass',p.channelConflict?'购买渠道来源冲突或无法识别':!normalizeChannel(p.channel)?'购买渠道未知':c.channels.indexOf(p.channel)<0?'购买渠道不符':'购买渠道符合');
    if(c.capacities.length)check('capacity',!p.capacity?'unknown':c.capacities.indexOf(normalizeCapacity(p.capacity))<0?'reject':'pass',!p.capacity?'容量缺失':c.capacities.indexOf(normalizeCapacity(p.capacity))<0?'容量不符':'容量符合');
    if(c.conditions.length)check('condition',!p.condition?'unknown':c.conditions.indexOf(p.condition)<0?'reject':'pass',!p.condition?'成色缺失':c.conditions.indexOf(p.condition)<0?'成色不符':'成色符合');
    if((p.issues||[]).length)check('report','unknown',p.issues.join('；'));else check('report','pass','验机报告已读取');
    var capability=compatibility.evaluateCapabilities(p,c,context);checks=checks.concat(capability.checks);
    var reject=[],unknown=[];checks.forEach(function(x){if(x.state==='reject')reject=reject.concat(x.reasons);else if(x.state==='unknown')unknown=unknown.concat(x.reasons);});
    return {status:reject.length?'reject':unknown.length?'unknown':'match',reasons:reject.length?reject:unknown,checks:checks,evidence:capability.evidence,ruleVersion:context.ruleVersion};
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
  // One process-wide gate is retained outside individual scans: stopping does not cancel an HTTP mutation.
  function MutationGate(){this.active=null;}
  MutationGate.prototype.pending=function(){return this.active!==null;};
  MutationGate.prototype.begin=function(id,token){if(this.active||!normalizeId(id)||!token||!token.run)return false;this.active={id:id,token:clone(token)};return true;};
  MutationGate.prototype.complete=function(id,token){var a=this.active;if(!a||a.id!==id||!token||a.token.run!==token.run||a.token.step!==token.step)return false;this.active=null;return true;};
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
  function prepareRun(config,context){
    context=clone(context||compatibility.defaultRuleContext());var checked=configuration.validateConfig(config,context);
    var effective=checked.ok?compatibility.effectiveRange(checked.config,context):{status:'invalid',ranges:[],label:'',issues:checked.errors,canStart:false};
    return {ok:checked.ok&&effective.canStart,errors:checked.errors.concat(checked.ok?effective.issues:[]),config:checked.config,effectiveRange:effective,ruleContext:context};
  }
  function freeze(value){if(value&&typeof value==='object'){Object.keys(value).forEach(function(k){freeze(value[k]);});Object.freeze(value);}return value;}
  function Run(config,clock,context) {
    var prepared=prepareRun(config,context);if(!prepared.ok)throw new Error(prepared.errors.join('；'));
    this.config=freeze(prepared.config);this.ruleContext=freeze(prepared.ruleContext);this.effectiveRange=freeze(prepared.effectiveRange);
    this.state='idle';this.phase='idle';this.page=1;this.step=0;this.run='';this.results=[];this.counts={};
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
  Run.prototype.start=function(){this.elapsedMs=0;this.activeAt=null;this.budgetExceeded=false;this.limitReason='';this.run='run-'+Date.now()+'-'+(++serial);this.page=1;this.step=0;this.results=[];this.queue=[];this.seen={};this.loadedSeen={};this.prefetched={};this.requests={};this.current=null;this.currentProduct=null;this.hit=null;this.filtersConfirmed=false;this.options={conditions:[],capacities:[]};this.counts={loaded:0,processed:0,checked:0,matched:0,unknown:0,rejected:0,already:0,favorited:0,favoriteUnknown:0};this._issue('search',{keyword:this.config.model,page:1});};
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
    this.hit=null;
    if(this.queue.length){this.current=this.queue.shift();this._issue('open',{item:this.current});}
    else if(this.page>=100){this._freeze();this.state='finished';this.phase='finished';this.action=null;this.note='达到单次100页上限';}
    else{this.page++;this.current=null;this._issue('nextPage',{page:this.page});this._consumeCached();}
  };
  Run.prototype._consumeCached=function(){if(this.prefetched[this.page]){var cached=this.prefetched[this.page];delete this.prefetched[this.page];this.search(cached.envelope,this.page,this.intent.token,cached.selection,cached.filterCommit);}};
  Run.prototype._record=function(p,status,reasons){
    var row=this.results.filter(function(r){return r.id===p.id;})[0];
    if(!row){row={id:this.current.id,title:p.title||this.current.title,model:p.model||'',ios:p.ios||'',iosRaw:p.iosRaw||null,build:p.build||null,releaseKind:p.releaseKind||'unverified',modelSource:p.modelSource||'missing',channel:p.channel||'',capacity:p.capacity||'',condition:p.condition||'',functionGrade:p.functionGrade||'',evaluation:clone(this.currentEvaluation)};this.results.push(row);}
    row.status=status;row.reasons=reasons||[];return row;
  };
  Run.prototype._hold=function(status,reasons){this._freeze();this.hit=Object.assign({},this._record(this.currentProduct,status,reasons),{item:clone(this.current)});this.state='hit';this.phase='hit';this.step++;this.action=null;this.note='发现符合全部条件的商品，任务已暂停';this.checkBudget();};
  Run.prototype.detail=function(p,token){
    if(!this._accept(token,'open')||!this.current||p.id!==this.current.id||this.checkBudget())return false;
    this.currentProduct=clone(p);var match=matchProduct(p,this.config,this.ruleContext);this.currentEvaluation=match;this._record(p,match.status,match.reasons);this.counts.processed++;if(match.status!=='unknown')this.counts.checked++;
    if(match.status==='match'){
      this.counts.matched++;
      if(this.config.autoFavorite&&p.collected===false){this._issue('favorite',{id:p.id});this.checkBudget();return true;}
      if(p.collected===true){this.counts.already++;this._hold('already',['原有收藏，已保留']);}
      else if(this.config.autoFavorite){this.counts.favoriteUnknown++;this._hold('favoriteUnknown',['收藏状态未知，不自动操作']);}
      else this._hold('match',['符合全部条件']);
    }else{if(match.status==='unknown')this.counts.unknown++;else this.counts.rejected++;this._record(p,match.status,match.reasons);if(!this.checkBudget())this._issue('back',{id:p.id});}
    return true;
  };
  Run.prototype._acceptSettlement=function(token,phase){return this._accept(token,phase)||(this.state==='paused'&&this.phase===phase&&this.intent&&token&&this._requestKey(token)===this._requestKey(this.intent.token));};
  Run.prototype.favoriteResult=function(envelope,token){if(!this._acceptSettlement(token,'favorite'))return false;if(envelope&&String(envelope.respCode)==='0'){if(this.state==='paused')this.note='收藏响应已返回，点击继续核对状态';else this._issue('verify',{id:this.current.id});}else{this.counts.favoriteUnknown++;this._hold('favoriteUnknown',['收藏接口未确认成功']);}return true;};
  Run.prototype.verified=function(collected,token){if(!this._acceptSettlement(token,'verify'))return false;if(collected===true){this.counts.favorited++;this._hold('favorited',['收藏状态已独立确认']);}else{this.counts.favoriteUnknown++;this._hold('favoriteUnknown',['收藏结果待确认，不自动重试']);}return true;};
  Run.prototype.returned=function(token){if(!this._accept(token,'back'))return false;this._advance();return true;};
  Run.prototype.endOfList=function(token){if(!this._accept(token,'nextPage'))return false;this._freeze();this.state=this.phase='finished';this.step++;this.action=null;this.note='列表已确认没有更多商品';return true;};
  Run.prototype.failed=function(reason,token){if(!this._accept(token))return false;if(this.phase==='favorite')this._issue('verify',{id:this.current.id});else if(this.phase==='verify')this.verified(null,token);else this.pause(reason);return true;};
  Run.prototype.pause=function(reason){if(['stopped','finished','idle'].indexOf(this.state)>=0)return;this._freeze();this.note=reason||'已暂停';if(this.state!=='paused'){this.state='paused';this.step++;this.action=null;}};
  Run.prototype.resume=function(){this.checkBudget();if(this.budgetExceeded&&!(this.state==='paused'&&['favorite','verify'].indexOf(this.phase)>=0))return;if(this.state==='hit'||(this.state==='paused'&&this.phase==='hit')){this._issue('back',{id:this.current.id});return;}if(this.state!=='paused')return;var i=this.intent;if(!i)return;var type=(this.phase==='favorite'||this.phase==='verify')?'verify':this.phase;var extra=clone(i);delete extra.type;delete extra.token;if(type==='verify')extra={id:this.current.id};this._issue(type,extra);if(type==='search'||type==='nextPage')this._consumeCached();};
  Run.prototype.beginViewing=function(){if((this.state!=='hit'&&this.state!=='paused')||this.phase!=='hit'||!this.hit)return false;this.pause('查看商品，任务保持暂停');return true;};
  Run.prototype.viewed=function(){if(this.state==='paused'&&this.phase==='hit'){this.checkBudget();if(!this.budgetExceeded)this.note='已返回列表，点击继续处理下一件';}};
  Run.prototype.stop=function(){if(this.state==='stopped')return;this._freeze();if(['favorite','verify'].indexOf(this.phase)>=0&&this.currentProduct){var row=this._record(this.currentProduct,'favoriteUnknown',['任务已结束，已发出的收藏结果待确认']);this.counts.favoriteUnknown++;this.stoppedFavorite={id:this.current.id,token:clone(this.intent.token),row:row};}this.state='stopped';this.phase='stopped';this.step++;this.action=null;this.note='已结束，结果与已完成收藏已保留';};
  Run.prototype.settleStopped=function(path,envelope,id,token){var p=this.stoppedFavorite;if(this.state!=='stopped'||!p||p.id!==id||!token||this._requestKey(p.token)!==this._requestKey(token))return false;if(path==='baseInfo'){if(collectedState(envelope)===true){p.row.status='favorited';p.row.reasons=['结束后收到独立收藏状态确认'];this.counts.favorited++;this.counts.favoriteUnknown--;}this.stoppedFavorite=null;return true;}if(path==='addLoveInfo'){p.row.reasons=['结束后收到收藏响应，状态仍待核验'];return true;}return false;};
  Run.prototype.snapshot=function(includeRecords){var pending=this.requests&&this.requests[this.page]||{};return clone({state:this.state,phase:this.phase,config:this.config,ruleVersion:this.ruleContext.ruleVersion,effectiveRange:this.effectiveRange,page:this.page,token:{run:this.run,step:this.step},current:this.current?{id:this.current.id,title:this.current.title}:null,hit:this.hit||null,candidate:this.currentProduct||null,counts:this.counts,recordCount:this.results.length,results:includeRecords===false?undefined:this.results.filter(function(r){return ['match','already','favorited','favoriteUnknown'].indexOf(r.status)>=0;}),allResults:includeRecords===false?undefined:this.results,note:this.note||'',waitingResponse:Object.keys(pending).length>0,options:this.options||{conditions:[],capacities:[]},budgetExceeded:this.budgetExceeded,limitReason:this.limitReason,elapsedMs:this._tick()});};
  function diagnosticSnapshot(snapshot,includeDetails){
    var out={},keys=['state','phase','config','ruleVersion','effectiveRange','page','counts','note','waitingResponse','options','budgetExceeded','limitReason','elapsedMs'];
    keys.forEach(function(key){if(snapshot[key]!==undefined)out[key]=clone(snapshot[key]);});
    function product(p){
      if(!p||typeof p!=='object')return null;var r={};
      ['id','title','model','ios','iosRaw','iosNumeric','build','releaseKind','modelSource','catalogModelId','channel','capacity','condition','functionGrade','status','reasons'].forEach(function(k){if(p[k]!==undefined)r[k]=clone(p[k]);});
      if(p.evaluation){var e=p.evaluation;r.evaluation={status:e.status,reasons:clone(e.reasons||[]),ruleVersion:e.ruleVersion,checks:clone(e.checks||[]),evidence:clone(e.evidence||{})};}
      return r;
    }
    if(includeDetails===true){['current','candidate','hit'].forEach(function(k){if(snapshot[k]!==undefined)out[k]=product(snapshot[k]);});out.results=(snapshot.allResults||snapshot.results||[]).map(product);}
    return out;
  }
  function presentation(s,pending){
    var state=s.state||'idle',phase=s.phase||state,kind=state==='hit'?'hit':state==='paused'?(phase==='hit'?'returned':'paused'):['stopped','finished'].indexOf(state)>=0?'summary':['favorite','verify'].indexOf(state)>=0?'favorite':state==='nextPage'?'loading':['search','filters'].indexOf(state)>=0?'search':state==='idle'?'idle':'running';
    var title={hit:'发现命中 · 已暂停',returned:'任务已暂停，等待继续',paused:'任务已暂停',summary:state==='finished'?'扫描完成':'本次任务已结束',favorite:state==='verify'?'正在核对收藏状态':'命中 · 正在收藏',loading:'正在加载第'+(s.page||1)+'页',search:state==='filters'?'正在应用容量与成色':'正在自动搜索',idle:'选机助手',running:'正在扫描'}[kind];
    var settlement=['favorite','verify'].indexOf(phase)>=0,canResume=['paused','hit'].indexOf(state)>=0&&(!pending||settlement)&&(!s.budgetExceeded||settlement);
    return {kind:kind,title:title,canResume:canResume,canView:!!s.hit&&['hit','returned'].indexOf(kind)>=0,canEnd:['idle','stopped','finished'].indexOf(state)<0,canSettings:['idle','paused','hit','stopped','finished'].indexOf(state)>=0,message:pending&&kind!=='favorite'?'上一笔收藏仍在处理中，可查看结果或结束后续任务':s.note||''};
  }
  var api={prepareRun:prepareRun,channelChoices:channelChoices,diagnosticSnapshot:diagnosticSnapshot,presentation:presentation,criteriaMatches:criteriaMatches,PageWait:PageWait,MutationGate:MutationGate,collectedState:collectedState,version:version,compareVersions:compareVersions,normalizeCapacity:normalizeCapacity,normalizeId:normalizeId,validateConfig:validateConfig,normalizeProduct:normalizeProduct,matchProduct:matchProduct,filterOptions:filterOptions,safeProductURL:safeProductURL,Run:Run};
  if(typeof module!=='undefined'&&module.exports)module.exports=api;
  root.ZZCore=api;
})(typeof globalThis!=='undefined'?globalThis:this);
