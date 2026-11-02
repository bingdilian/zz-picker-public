(function(root){
  'use strict';
  var raw=typeof module!=='undefined'&&module.exports?require('./compatibility-rules.json'):root.ZZCompatibilityRules;
  function clone(v){return JSON.parse(JSON.stringify(v));}
  function version(v){
    if(typeof v!=='string')return null;
    var m=v.trim().match(/^(?:iOS\s*)?(\d{1,2})(?:\.(\d{1,3}))?(?:\.(\d{1,3}))?$/i);
    return m?[+m[1],+(m[2]||0),+(m[3]||0)]:null;
  }
  function compareVersions(a,b){a=version(a);b=version(b);if(!a||!b)return null;for(var i=0;i<3;i++)if(a[i]!==b[i])return a[i]>b[i]?1:-1;return 0;}
  function object(v){return !!v&&typeof v==='object'&&!Array.isArray(v);}
  function texts(a){return Array.isArray(a)&&a.every(function(s){return typeof s==='string'&&s.length>0;});}
  function unique(a){return new Set(a).size===a.length;}
  function refs(a,ids){return texts(a)&&a.length>0&&a.every(function(s){return ids.indexOf(s)>=0;});}
  function validRanges(a,predicates){return Array.isArray(a)&&a.length>0&&a.every(function(r){return object(r)&&version(r.min)&&version(r.max)&&compareVersions(r.min,r.max)<=0&&texts(r.predicateIds)&&r.predicateIds.every(function(id){return predicates.indexOf(id)>=0;});});}
  function createRuleContext(data){
    var c={ruleVersion:null,catalogAvailable:false,capabilitiesAvailable:false,models:[],tools:[],sources:[],issues:[],knownRCBuilds:[],excludePrerelease:true};
    if(!object(data)||data.schemaVersion!==1||typeof data.ruleVersion!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(data.reviewedAt||'')){c.issues.push('兼容规则暂不可用：数据格式错误');return c;}
    c.ruleVersion=data.ruleVersion;c.reviewedAt=data.reviewedAt;
    var sources=Array.isArray(data.sources)?data.sources:[],sid=sources.map(function(s){return s&&s.id;});
    var sourcesOK=sources.length>0&&unique(sid)&&sources.every(function(s){return object(s)&&typeof s.id==='string'&&typeof s.title==='string'&&/^https:\/\//.test(s.url||'')&&/^\d{4}-\d{2}-\d{2}$/.test(s.reviewedAt||'');});
    if(sourcesOK)c.sources=clone(sources);
    var models=Array.isArray(data.models)?data.models:[],mid=models.map(function(m){return m&&m.id;});
    c.catalogAvailable=!!(sourcesOK&&models.length&&unique(mid)&&models.every(function(m){return object(m)&&/^iphone-[a-z0-9-]+$/.test(m.id||'')&&typeof m.name==='string'&&typeof m.searchText==='string'&&typeof m.chip==='string'&&version(m.minIOS)&&texts(m.capacities)&&m.capacities.length&&m.capacities.every(function(x){return /^[1-9]\d*$/.test(x);})&&refs(m.sourceIds,sid);}));
    if(c.catalogAvailable)c.models=clone(models);else c.issues.push('机型目录暂不可用');
    var tools=Array.isArray(data.tools)?data.tools:[],tid=tools.map(function(t){return t&&t.id;});
    c.capabilitiesAvailable=!!(c.catalogAvailable&&tools.length&&unique(tid)&&data.excludePrerelease===true&&texts(data.knownRCBuilds)&&tools.every(function(t){
      if(!object(t)||typeof t.id!=='string'||['trollstore','jailbreak'].indexOf(t.capability)<0||typeof t.version!=='string'||!refs(t.modelIds,mid)||!refs(t.sourceIds,sid)||!Array.isArray(t.predicates))return false;
      var pid=t.predicates.map(function(p){return p&&p.id;});
      if(!unique(pid)||!t.predicates.every(function(p){return object(p)&&typeof p.id==='string'&&['versionWide','buildRestricted'].indexOf(p.kind)>=0&&version(p.version)&&texts(p.knownBuilds)&&p.knownBuilds.length>0;})||!validRanges(t.ranges,pid))return false;
      return t.capability!=='trollstore'||(Array.isArray(t.installPaths)&&t.installPaths.length>0&&t.installPaths.every(function(p){return object(p)&&typeof p.id==='string'&&typeof p.revision==='string'&&typeof p.requiresComputer==='boolean'&&refs(p.sourceIds,sid)&&validRanges(p.ranges,pid);}));
    })&&['trollstore','jailbreak'].every(function(cap){return tools.some(function(t){return t.capability===cap;});}));
    if(c.capabilitiesAvailable){c.tools=clone(tools);c.knownRCBuilds=clone(data.knownRCBuilds);}else c.issues.push('兼容规则暂不可用');
    return c;
  }
  function defaultRuleContext(){return createRuleContext(raw);}
  function modelKey(s){return typeof s==='string'?s.trim().toLowerCase().replace(/^(?:苹果|apple)\s*/,'').replace(/\s/g,''):'';}
  function resolveModel(text,context){var key=modelKey(text),matches=(context.models||[]).filter(function(m){return modelKey(m.name)===key;});return key&&matches.length===1?matches[0].id:null;}
  function lower(a,b){return !a?b:!b?a:compareVersions(a,b)>=0?a:b;}
  function upper(a,b){return !a?b:!b?a:compareVersions(a,b)<=0?a:b;}
  function intersect(a,b){
    var out=[];a.forEach(function(x){b.forEach(function(y){
      var min=lower(x.min,y.min),max=upper(x.max,y.max);
      if(!min||!max||compareVersions(min,max)<=0)out.push({min:min,max:max,predicateIds:Array.from(new Set((x.predicateIds||[]).concat(y.predicateIds||[]))).sort()});
    });});return merge(out);
  }
  function merge(ranges){
    var out=[];clone(ranges).sort(function(a,b){return !a.min?-1:!b.min?1:compareVersions(a.min,b.min);}).forEach(function(r){
      var p=out[out.length-1];
      if(p&&JSON.stringify(p.predicateIds)===JSON.stringify(r.predicateIds)&&(!p.max||!r.min||compareVersions(r.min,p.max)<=0))p.max=!p.max||!r.max?null:compareVersions(p.max,r.max)>=0?p.max:r.max;
      else out.push(r);
    });return out;
  }
  function capabilityRanges(cap,id,context){
    var ranges=[];(context.tools||[]).forEach(function(t){
      if(t.capability!==cap||t.modelIds.indexOf(id)<0)return;
      var r=t.ranges;
      if(cap==='trollstore'){
        var paths=[];t.installPaths.forEach(function(p){paths=paths.concat(p.ranges);});
        r=intersect(r,paths);
      }
      ranges=ranges.concat(r);
    });return merge(ranges);
  }
  function contains(ranges,value){return !!version(value)&&ranges.some(function(r){return (!r.min||compareVersions(value,r.min)>=0)&&(!r.max||compareVersions(value,r.max)<=0);});}
  function rangeLabel(ranges){return ranges.map(function(r){return r.min&&r.max&&compareVersions(r.min,r.max)===0?r.min:!r.min&&!r.max?'不限':!r.max?r.min+'及以上（最高不限）':!r.min?'不高于'+r.max:r.min+'～'+r.max;}).join(' 或 ');}
  function effectiveRange(c,context){
    context=context||defaultRuleContext();var issues=[],conflicting=[],mode=c.rangeMode,lo=c.manualMinIOS,hi=c.manualMaxIOS;
    function result(status,ranges){return {status:status,ranges:ranges||[],label:ranges&&ranges.length?'iOS '+rangeLabel(ranges):'',issues:issues,capacityConflicts:conflicting,canStart:status==='ready'&&!issues.length};}
    if(['auto','manual'].indexOf(mode)<0){issues.push('请选择自动或手动范围');return result('invalid');}
    if(mode==='manual'){
      if(typeof lo!=='string'||lo&&!version(lo))issues.push('最低版本格式错误，例如17.0.3');
      if(typeof hi!=='string'||hi&&!version(hi))issues.push('最高版本格式错误，例如17.0.3');
      if(lo&&hi&&compareVersions(lo,hi)>0)issues.push('最低版本不能大于最高版本');
      if(issues.length)return result('invalid');
    }
    var required=c.requireTrollStore||c.requireJailbreak,legacy=c.preserveLegacyRange===true&&mode==='manual'&&!required;
    var m=context.models.filter(function(x){return x.id===c.modelId;})[0];
    if(required&&!context.capabilitiesAvailable){issues.push('兼容规则暂不可用，请重新载入本地规则或关闭用途');return result('unavailable');}
    if(!legacy&&!m&&(mode==='auto'||required)){issues.push(context.catalogAvailable?'该机型兼容规则待收录，请选择机型或使用普通手动筛选':'机型目录暂不可用');return result(context.catalogAvailable?'uncovered':'unavailable');}
    var ranges=[{min:legacy||!m?null:m.minIOS,max:null,predicateIds:[]}];
    for(var i=0;i<2;i++){
      var cap=i?'jailbreak':'trollstore',on=i?c.requireJailbreak:c.requireTrollStore;
      if(on){var support=capabilityRanges(cap,c.modelId,context);if(!support.length){issues.push('该机型兼容规则待收录');return result('uncovered');}ranges=intersect(ranges,support);}
    }
    if(mode==='manual')ranges=intersect(ranges,[{min:lo||null,max:hi||null,predicateIds:[]}]);
    if(!ranges.length){issues.push('手动范围与已核对范围无交集');return result('empty');}
    if(!legacy&&m)conflicting=(c.capacities||[]).filter(function(x){return m.capacities.indexOf(x)<0;});
    if(conflicting.length)issues.push('所选容量与当前机型冲突，请主动取消或改选；不会自动改成容量不限');
    return result('ready',ranges);
  }
  function evidenceForConfig(c,context){
    context=context||defaultRuleContext();var tools=context.tools.filter(function(t){return t.modelIds.indexOf(c.modelId)>=0&&((t.capability==='trollstore'&&c.requireTrollStore)||(t.capability==='jailbreak'&&c.requireJailbreak));});
    var ids=[];tools.forEach(function(t){ids=ids.concat(t.sourceIds);(t.installPaths||[]).forEach(function(p){ids=ids.concat(p.sourceIds);});});
    var m=context.models.filter(function(x){return x.id===c.modelId;})[0]||null;if(m)ids=ids.concat(m.sourceIds);
    return clone({effectiveRange:effectiveRange(c,context),ruleVersion:context.ruleVersion,reviewedAt:context.reviewedAt||null,model:m,tools:tools,sources:context.sources.filter(function(s){return ids.indexOf(s.id)>=0;}),limitation:'按待售手机报告标称配置核验；构建未提供时不伪造，发行通道未独立验证，不保证实物系统。'});
  }
  function evaluateCapabilities(p,c,context){
    context=context||defaultRuleContext();var checks=[],evidence=evidenceForConfig(c,context);
    var actual=context.models.filter(function(m){return m.id===p.catalogModelId;})[0];
    // A supplied build is report evidence even when the chosen tool needs no build predicate.
    // Only versionWide metadata supplies a complete version-level list; a restricted subset
    // must not be treated as a whitelist for every other tool.
    var predicates=[];context.tools.forEach(function(t){predicates=predicates.concat(t.predicates);});
    var known=p.build?predicates.filter(function(rule){return rule.knownBuilds.indexOf(p.build)>=0;}):[];
    var wide=predicates.filter(function(rule){return rule.kind==='versionWide'&&compareVersions(rule.version,p.iosNumeric)===0;});
    var buildMismatch=!!p.build&&((known.length>0&&!known.some(function(rule){return compareVersions(rule.version,p.iosNumeric)===0;}))||(wide.length>0&&!wide.some(function(rule){return rule.knownBuilds.indexOf(p.build)>=0;})));
    ['trollstore','jailbreak'].forEach(function(cap){
      var on=cap==='trollstore'?c.requireTrollStore:c.requireJailbreak,state='notRequired',reason='未要求';
      if(on){
        if(p.releaseKind==='beta'||p.releaseKind==='rc'||context.knownRCBuilds.indexOf(p.build)>=0){state='reject';reason='排除Beta/RC预发布系统';}
        else if(!context.capabilitiesAvailable){state='unknown';reason='兼容规则暂不可用';}
        else if(p.modelSource!=='report'||!actual||actual.id!==c.modelId){state='unknown';reason='报告机型依据缺失、冲突或不属于所选机型';}
        else if(!version(p.iosNumeric)||(p.conflicts||[]).length||buildMismatch){state='unknown';reason='报告系统或构建信息缺失、冲突，或所提供构建未核实';}
        else if(compareVersions(p.iosNumeric,actual.minIOS)<0){state='unknown';reason='报告系统低于该机型出厂边界';}
        else{
          var tools=context.tools.filter(function(t){return t.capability===cap&&t.modelIds.indexOf(c.modelId)>=0;}),states=[];
          tools.forEach(function(t){
            var ranges=t.ranges;if(cap==='trollstore'){var paths=[];t.installPaths.forEach(function(path){paths=paths.concat(path.ranges);});ranges=intersect(ranges,paths);}
            var matched=ranges.filter(function(r){return contains([r],p.iosNumeric);});
            if(!matched.length){states.push('reject');return;}
            var verdicts=matched.map(function(r){return r.predicateIds.every(function(id){var pred=t.predicates.filter(function(x){return x.id===id;})[0];return pred&&(p.build?pred.knownBuilds.indexOf(p.build)>=0:pred.kind==='versionWide');})?'pass':'unknown';});
            states.push(verdicts.indexOf('pass')>=0?'pass':'unknown');
          });
          state=states.indexOf('pass')>=0?'pass':!states.length||states.indexOf('unknown')>=0?'unknown':'reject';
          reason=state==='pass'?'符合已收录工具及安装路径':state==='unknown'?'机型规则待收录或必要构建信息未核实':'系统不在已收录支持范围';
        }
      }
      checks.push({key:cap,state:state,reasons:[reason],sourcePaths:(p.iosSources||[]).concat(p.buildSources||[]).map(function(s){return s.path;})});
    });
    return {checks:checks,evidence:evidence};
  }
  var api={createRuleContext:createRuleContext,defaultRuleContext:defaultRuleContext,resolveModel:resolveModel,version:version,compareVersions:compareVersions,effectiveRange:effectiveRange,intersect:intersect,contains:contains,capabilityRanges:capabilityRanges,evaluateCapabilities:evaluateCapabilities,evidenceForConfig:evidenceForConfig};
  if(typeof module!=='undefined'&&module.exports)module.exports=api;
  root.ZZCompatibility=api;
})(typeof globalThis!=='undefined'?globalThis:this);
