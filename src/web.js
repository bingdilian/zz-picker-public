(function(w){
 'use strict';
 if(w.__zzPickerBridgeV1)return;
 w.__zzPickerBridgeV1=true;
 var context=w.__zzPickerInitialContext||{},baseCache={},mutation=false,confirmationObserver=null,favoriteAttempt=null,confirmationAttempted=false,favoriteRequestStarted=false;
 var paths=['/zz/transfer/search','/zz/v2/zzsearchfilteritem/getFilterItemDTO','/zzopen/waresshow/baseInfo','/zzopen/waresshow/moreInfo','/zz/transfer/addLoveInfo'];
 function copy(v){return JSON.parse(JSON.stringify(v));}
 function post(m){try{var h=w.webkit&&w.webkit.messageHandlers&&w.webkit.messageHandlers.zzPicker;if(h)h.postMessage(m);}catch(e){/* Page behavior must survive an unavailable native bridge. */}}
 function pick(x,keys){var r={};keys.forEach(function(k){if(x&&Object.prototype.hasOwnProperty.call(x,k))r[k]=x[k];});return r;}
 function filter(x){
  if(Array.isArray(x))return x.map(filter);
  if(!x||typeof x!=='object')return x;
  var r=pick(x,['text','key','value','cmd','style']);if(x.child)r.child=filter(x.child);return r;
 }
 function sanitize(path,j){
  var r={respCode:j&&j.respCode},d=j&&j.respData||{};
  if(String(r.respCode)!=='0')return r;
  if(path==='/zz/transfer/search')r.respData={infos:Array.isArray(d.infos)?d.infos.map(function(x){return pick(x,['infoId','strInfoId','title','price','pgModelId','jumpUrl','status']);}):null,filterResponse:filter(d.filterResponse||[])};
  else if(path.indexOf('getFilterItemDTO')>=0)r.respData={filterResponse:filter(d.filterResponse||[])};
  else if(path.indexOf('/baseInfo')>=0){r.respData=pick(d,['title','modelId','collected','isSoldOut']);r.respData.infoLv=pick(d.infoLv,['level']);}
  else if(path.indexOf('/moreInfo')>=0){
   var report=d.report;
   if(!report||typeof report!=='object'||Array.isArray(report)||!Object.keys(report).length){r.respData={};return r;}
   var detail=report.reportParam&&report.reportParam.paramDetail||[];
   var bars=report.reportParam&&report.reportParam.paramBars||[];
   r.respData={report:{title:report.title,params:(Array.isArray(report.params)?report.params:[]).filter(function(p){return p&&['系统版本','购买渠道','存储容量'].indexOf(p.key)>=0;}).map(function(p){return pick(p,['key','value']);}),reportParam:{paramBars:(Array.isArray(bars)?bars:[]).filter(function(p){return p&&p.paramName==='购买渠道';}).map(function(p){return pick(p,['paramName','paramValue']);}),paramDetail:(Array.isArray(detail)?detail:[]).map(function(g){return {paramInfo:(Array.isArray(g.paramInfo)?g.paramInfo:[]).filter(function(p){return p&&['系统版本','购买渠道','存储容量'].indexOf(p.paramName)>=0;}).map(function(p){return pick(p,['paramName','paramValue']);})};})},dtGrade:{function:pick(report.dtGrade&&report.dtGrade.function,['name'])}}};
  }else r.respData={};
  return r;
 }
 function requestInfo(url,body){
  try{
   var u=new URL(String(url),w.location.href);
   if(u.protocol!=='https:'||u.hostname!=='app.zhuanzhuan.com'||paths.indexOf(u.pathname)<0)return null;
   var params={};String(body||'').split('&').forEach(function(x){var a=x.split('=');try{params[decodeURIComponent(a[0])]=decodeURIComponent(a.slice(1).join('=').replace(/\+/g,' '));}catch(e){}});
   var selection={};try{var raw=JSON.parse(params.filterModuleServerParamsInput||u.searchParams.get('filterModuleServerParamsInput')||'{}'),click=raw.clickItems||{};['69','285'].forEach(function(k){if(!Array.isArray(click[k]||[]))throw Error('selection');selection[k]=(click[k]||[]).map(function(x){return pick(x,['value','cmd']);});});}catch(e){selection=null;}
   return {filterCommit:context.filterCommit===true,selection:selection,path:u.pathname,id:u.searchParams.get('infoId')||'',page:Number(params.pagenum||u.searchParams.get('pagenum')||1),keyword:params.keyword||u.searchParams.get('keyword')||'',token:context.token?copy(context.token):null};
  }catch(e){return null;}
 }
 function failed(info){if(info){var m=copy(info);m.kind='failure';post(m);}}
 function started(info){
  if(info&&info.path==='/zz/transfer/addLoveInfo'&&info.id===context.id&&sameToken(info.token,favoriteAttempt)){
   favoriteRequestStarted=true;
   stopWatchingConfirmation();
  }
  if(info&&(info.path==='/zz/transfer/search'||info.path==='/zz/transfer/addLoveInfo')){var m=copy(info);m.kind='request';post(m);}}
 function observe(info,j){
  if(!info)return;
  if(!j||typeof j!=='object'){failed(info);return;}
  if(info.path.indexOf('/baseInfo')>=0&&String(j.respCode)==='0')baseCache[info.id]=j.respData&&j.respData.collected;
  info.kind='response';info.data=sanitize(info.path,j);post(info);
 }
 if(typeof w.fetch==='function'){
  var fetch=w.fetch;
  w.fetch=function(input,init){
   var info=requestInfo(typeof input==='string'?input:input&&input.url,init&&init.body);
   var promise=fetch.apply(this,arguments);started(info);
   if(!info)return promise;
   return promise.then(function(response){
    try{var length=Number(response.headers&&response.headers.get('content-length')||0);if(length>8*1024*1024){failed(info);return response;}
     response.clone().text().then(function(text){if(text.length>8*1024*1024){failed(info);return;}try{observe(info,JSON.parse(text));}catch(e){failed(info);}}).catch(function(){failed(info);});
    }catch(e){failed(info);}
    return response;
   },function(error){failed(info);throw error;});
  };
 }
 if(w.XMLHttpRequest){
  var open=w.XMLHttpRequest.prototype.open,send=w.XMLHttpRequest.prototype.send;
  w.XMLHttpRequest.prototype.open=function(method,url){if(this.__zzPickerCleanup)this.__zzPickerCleanup();this.__zzPickerURL=url;return open.apply(this,arguments);};
  w.XMLHttpRequest.prototype.send=function(body){
   var info=requestInfo(this.__zzPickerURL,body),xhr=this;
   function cleanup(){['load','error','abort','timeout'].forEach(function(k){xhr.removeEventListener(k,listener);});if(xhr.__zzPickerCleanup===cleanup)xhr.__zzPickerCleanup=null;}
   function listener(event){cleanup();if(event&&event.type!=='load'){failed(info);return;}
    try{if(xhr.responseType==='json')observe(info,xhr.response);else if(!xhr.responseType||xhr.responseType==='text'){var text=xhr.responseText;if(typeof text==='string'&&text.length<=8*1024*1024)observe(info,JSON.parse(text));else failed(info);}}catch(e){failed(info);}
   }
   if(info){this.__zzPickerCleanup=cleanup;['load','error','abort','timeout'].forEach(function(k){xhr.addEventListener(k,listener);});}
   var result;try{result=send.apply(this,arguments);}catch(error){cleanup();throw error;}started(info);return result;
  };
 }
 function stopWatchingConfirmation(){
  if(confirmationObserver){confirmationObserver.disconnect();confirmationObserver=null;}
 }
 var controlSelector='button,[role="button"],a,span,div,[aria-label]';
 function sameToken(a,b){return !!a&&!!b&&a.run===b.run&&a.step===b.step;}
 function matchesFavoritePage(id){
  var u;try{u=new URL(w.location.href);}catch(e){return false;}
  return context.allowFavorite===true&&context.id===id&&u.protocol==='https:'&&u.hostname==='m.zhuanzhuan.com'&&!u.port&&!u.hash&&['/u/streamline_detail/new-goods-detail','/u/bm-consign/standard/standard-detail'].indexOf(u.pathname)>=0&&u.searchParams.getAll('infoId').length===1&&u.searchParams.get('infoId')===id;
 }
 function visible(el){
  var r=el.getBoundingClientRect();
  if(!r.width||!r.height||r.top>=w.innerHeight||r.bottom<=0)return false;
  for(var node=el;node;node=node.parentElement){
   var style=w.getComputedStyle(node);
   if(style.display==='none'||style.visibility==='hidden'||style.opacity==='0'||node.getAttribute('aria-hidden')==='true')return false;
  }
  return true;
 }
 function hasLabel(el,label){
  function clean(text){return (text||'').replace(/[\s，,]/g,'');}
  return clean(el.textContent)===label||clean(el.getAttribute('aria-label'))===label;
 }
 function confirmationControls(){
  var controls=Array.prototype.filter.call(document.querySelectorAll(controlSelector),function(el){
   return hasLabel(el,'知道了继续收藏')&&visible(el);
  });
  return controls.filter(function(el){
   return !controls.some(function(other){return other!==el&&typeof el.contains==='function'&&el.contains(other);});
  });
 }
 function isBatteryPrompt(button){
  // Require the battery heading in the same local container as the confirmation control.
  var node=button.parentElement;
  for(var depth=0;node&&depth<5&&node!==document.body&&node!==document.documentElement;depth++,node=node.parentElement){
   if(Array.prototype.some.call(node.querySelectorAll('h1,h2,h3,span,div,p,[role="heading"],[aria-label]'),function(heading){
    return hasLabel(heading,'平台焕新电池')&&visible(heading);
   }))return true;
  }
  return false;
 }
 function watchConfirmation(id,token){
  function inspect(){
   if(favoriteRequestStarted||!sameToken(token,context.token)||!matchesFavoritePage(id)){stopWatchingConfirmation();return;}
   if(confirmationControls().length){stopWatchingConfirmation();post({kind:'favoriteConfirmation',id:id,token:token});}
  }
  if(w.MutationObserver&&document.documentElement){
   confirmationObserver=new w.MutationObserver(inspect);
   confirmationObserver.observe(document.documentElement,{childList:true,subtree:true,attributes:true,characterData:true});
  }
  inspect();
 }
 w.ZZWeb={
  setContext:function(value){
   var next=value&&typeof value==='object'?copy(value):{};
   if(!next.allowFavorite||next.id!==context.id||!sameToken(next.token,context.token))stopWatchingConfirmation();
   context=next;
  },
  favorite:function(id){
   if(!matchesFavoritePage(id))return {ok:false,reason:'商品或任务不匹配'};
   if(baseCache[id]!==false)return {ok:false,reason:'未确认商品当前未收藏'};
   if(mutation)return {ok:false,reason:'本页已发起收藏，等待确认'};
   var nodes=Array.prototype.slice.call(document.querySelectorAll('button,[role="button"],a,span,div,[aria-label]'));
   var candidates=nodes.filter(function(el){
    var text=(el.textContent||'').trim(),aria=(el.getAttribute('aria-label')||'').trim(),r=el.getBoundingClientRect(),style=w.getComputedStyle(el);
    return (text==='收藏'||aria==='收藏')&&r.width>0&&r.height>0&&r.top>=w.innerHeight*0.5&&r.top<w.innerHeight&&style.display!=='none'&&style.visibility!=='hidden';
   });
   // Nested wrappers can have the same label: click only the deepest visible label.
   candidates=candidates.filter(function(el){return !candidates.some(function(other){return other!==el&&typeof el.contains==='function'&&el.contains(other);});});
   if(candidates.length!==1)return {ok:false,reason:candidates.length?'收藏入口不唯一':'未识别到收藏入口'};
   mutation=true;
   favoriteAttempt=context.token?copy(context.token):null;
   candidates[0].click();
   if(favoriteAttempt)watchConfirmation(id,favoriteAttempt);
   return {ok:true};
  },
  confirmBatteryFavorite:function(id,token){
   if(confirmationAttempted||context.allowBatteryConfirmation!==true||!sameToken(token,favoriteAttempt)||!sameToken(token,context.token)||!matchesFavoritePage(id))return false;
   if(favoriteRequestStarted)return 'requestStarted';
   if(baseCache[id]!==false)return false;
   var buttons=confirmationControls();
   if(buttons.length!==1||!isBatteryPrompt(buttons[0]))return false;
   for(var node=buttons[0];node;node=node.parentElement){
    if(node.disabled||node.getAttribute('aria-disabled')==='true')return false;
   }
   confirmationAttempted=true;
   buttons[0].click();
   return true;
  }
 };
 post({kind:'ready'});
})(window);
