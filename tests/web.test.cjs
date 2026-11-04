const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const fixture=require('./fixtures/capture.json');
const code=fs.readFileSync(require.resolve('../src/web.js'),'utf8');
const url='https://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail?infoId='+fixture.id;
function environment(options={}){
 const messages=[],callbacks={};let clickCount=0;
 const button={textContent:'收藏',getAttribute:()=>null,getBoundingClientRect:()=>({width:30,height:30,top:740,bottom:770}),click:()=>clickCount++};
 class XHR{constructor(){this.responseType='';this.status=200;this.responseText='';this.listeners={};}open(method,url){this.url=url;}send(){if(options.sendError)throw options.sendError;if(this.onload)this.onload();}addEventListener(k,cb){(this.listeners[k]||(this.listeners[k]=[])).push(cb);}removeEventListener(k,cb){this.listeners[k]=(this.listeners[k]||[]).filter(x=>x!==cb);}emit(k='load'){for(const cb of [...(this.listeners[k]||[])])cb({type:k});}}
 const win={MutationObserver:options.MutationObserver,location:new URL(url),innerHeight:800,webkit:{messageHandlers:{zzPicker:{postMessage:m=>messages.push(JSON.parse(JSON.stringify(m)))}}},fetch:options.fetch||(()=>Promise.resolve(new Response(JSON.stringify(fixture.base),{status:200,headers:{'Content-Type':'application/json'}}))),XMLHttpRequest:XHR,getComputedStyle:()=>({display:'block',visibility:'visible'}),__zzPickerInitialContext:{token:{run:'a',step:1},id:fixture.id,allowFavorite:false}};
 const document={documentElement:{},querySelectorAll:()=>options.buttons||[button]};
 const context=vm.createContext({window:win,document,URL,Promise,JSON,console,setTimeout,clearTimeout});vm.runInContext(code,context);
 return {win,messages,context,button,clicks:()=>clickCount};
}
const settle=()=>new Promise(r=>setTimeout(r,20));
test('fetch observer preserves response and strips sensitive fields',async()=>{
 const e=environment();const response=await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id+'&token=secret');
 assert.equal((await response.json()).respData.title,fixture.base.respData.title);await settle();
 const m=e.messages.find(m=>m.kind==='response');assert.ok(m);assert.equal(m.id,fixture.id);
 assert.equal(m.path,'/zzopen/waresshow/baseInfo');assert.equal(JSON.stringify(m).includes('secret'),false);
 assert.equal(m.data.respData.collected,false);
});
test('captures token when request starts, not when asynchronous response arrives',async()=>{
 let resolve;const e=environment({fetch:()=>new Promise(r=>resolve=r)});
 const p=e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id);
 e.win.ZZWeb.setContext({token:{run:'b',step:9},id:fixture.id});resolve(new Response(JSON.stringify(fixture.base)));await p;await settle();
 assert.equal(e.messages.find(m=>m.kind==='response').token.run,'a');
});
test('does not inspect other domains or unrelated account APIs',async()=>{
 const e=environment();await e.win.fetch('https://evil.example/zzopen/waresshow/baseInfo');await e.win.fetch('https://app.zhuanzhuan.com/zzopen/token');await settle();
 assert.equal(e.messages.filter(m=>m.kind==='response').length,0);
});
test('XHR observation preserves original onload and responseType',()=>{
 const e=environment();const x=new e.win.XMLHttpRequest();let loaded=false;x.onload=()=>loaded=true;
 x.open('GET','https://app.zhuanzhuan.com/zzopen/waresshow/moreInfo?infoId='+fixture.id);x.responseType='json';x.response=fixture.more;x.send();x.emit();
 assert.equal(loaded,true);assert.equal(x.responseType,'json');
 assert.equal(e.messages.find(m=>m.kind==='response').data.respData.report.params[0].key,'系统版本');
});
test('duplicate script injection records a response once',async()=>{
 const e=environment();vm.runInContext(code,e.context);await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id);await settle();
 assert.equal(e.messages.filter(m=>m.kind==='response').length,1);
});
test('favorite requires matching page, explicit permission and current false state',async()=>{
 const e=environment();assert.equal(e.win.ZZWeb.favorite(fixture.id).ok,false);
 await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id);await settle();
 e.win.ZZWeb.setContext({token:{run:'a',step:2},id:fixture.id,allowFavorite:true});
 assert.equal(e.win.ZZWeb.favorite('999').ok,false);
 assert.equal(e.win.ZZWeb.favorite(fixture.id).ok,true);assert.equal(e.clicks(),1);
 assert.equal(e.win.ZZWeb.favorite(fixture.id).ok,false);assert.equal(e.clicks(),1);
});
test('already collected never clicks and ambiguous controls are rejected',async()=>{
 const collected=structuredClone(fixture.base);collected.respData.collected=true;
 const e=environment({fetch:()=>Promise.resolve(new Response(JSON.stringify(collected)))});
 await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id);await settle();e.win.ZZWeb.setContext({token:{run:'a',step:2},id:fixture.id,allowFavorite:true});
 assert.equal(e.win.ZZWeb.favorite(fixture.id).ok,false);assert.equal(e.clicks(),0);
});
test('search response sanitizer retains route and ID without seller identifiers',()=>{
 const e=environment();const x=new e.win.XMLHttpRequest();x.open('POST','https://app.zhuanzhuan.com/zz/transfer/search');x.send('keyword=iPhone%2015%20Pro%20Max&pagenum=2');
 x.responseText=JSON.stringify({respCode:0,respData:{infos:[{...fixture.item,uid:'private-user',metric:'private-metric'}],filterResponse:fixture.filterResponse}});x.emit();
 const m=e.messages.find(m=>m.kind==='response');assert.equal(m.page,2);assert.equal(m.keyword,'iPhone 15 Pro Max');
 assert.equal(m.data.respData.infos[0].uid,undefined);assert.equal(m.data.respData.infos[0].infoId,fixture.id);
});

test('reused and reopened XHR never emits old metadata for new response',()=>{
 const e=environment(),x=new e.win.XMLHttpRequest();x.responseType='json';
 x.open('GET','https://app.zhuanzhuan.com/zzopen/waresshow/moreInfo?infoId='+fixture.id);x.send();x.response=fixture.more;x.emit();
 x.open('GET','https://app.zhuanzhuan.com/zzopen/waresshow/moreInfo?infoId=999');x.send();
 x.open('GET','https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id);x.send();x.response=fixture.base;x.emit();
 const m=e.messages.filter(m=>m.kind==='response');assert.equal(m.length,2);assert.equal(m[1].path,'/zzopen/waresshow/baseInfo');assert.equal(m[1].id,fixture.id);
});
test('favorite rejects unknown paths, HTTP, fragments and duplicate product IDs',async()=>{
 for(const address of ['https://m.zhuanzhuan.com/u/unknown?infoId=','http://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail?infoId=','https://m.zhuanzhuan.com/u/streamline_detail/new-goods-detail?infoId=']){
  const e=environment();await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id);await settle();
  e.win.ZZWeb.setContext({id:fixture.id,allowFavorite:true});e.win.location=new URL(address+fixture.id+(address.startsWith('https://m.zhuanzhuan.com/u/streamline')?'&infoId='+fixture.id:''));
  assert.equal(e.win.ZZWeb.favorite(fixture.id).ok,false);assert.equal(e.clicks(),0);
 }
});
test('missing report stays missing through web sanitizer',()=>{
 const e=environment(),x=new e.win.XMLHttpRequest();x.open('GET','https://app.zhuanzhuan.com/zzopen/waresshow/moreInfo?infoId='+fixture.id);x.send();x.responseText=JSON.stringify({respCode:0,respData:{}});x.emit();
 assert.equal(e.messages.find(m=>m.kind==='response').data.respData.report,undefined);
});

test('malformed successful search does not become a false empty-page finish',()=>{
 const e=environment(),x=new e.win.XMLHttpRequest();x.open('POST','https://app.zhuanzhuan.com/zz/transfer/search');x.send();x.responseText=JSON.stringify({respCode:0,respData:{message:'missing data'}});x.emit();
 const j=e.messages.find(m=>m.kind==='response').data;assert.equal(Array.isArray(j.respData.infos),false);
 const C=require('../src/core.js'),r=new C.Run({model:'iPhone 15 Pro Max'});r.start();const a=r.next();r.search(j,1,a.token);assert.equal(r.snapshot().state,'paused');
});
test('search request-start messages arrive before slow responses and retain request identity',async()=>{
 let resolve;const e=environment({fetch:()=>new Promise(r=>resolve=r)});
 const p=e.win.fetch('https://app.zhuanzhuan.com/zz/transfer/search',{body:'keyword=iPhone%2015%20Pro%20Max&pagenum=2'});
 const started=e.messages.find(m=>m.kind==='request');assert.ok(started);assert.equal(started.page,2);assert.equal(started.token.run,'a');assert.equal(started.data,undefined);
 resolve(new Response(JSON.stringify({respCode:0,respData:{infos:[]}})));await p;await settle();
 assert.equal(e.messages.find(m=>m.kind==='response').page,2);
});
test('XHR search signals its start without waiting for loading to finish',()=>{
 const e=environment(),x=new e.win.XMLHttpRequest();x.open('POST','https://app.zhuanzhuan.com/zz/transfer/search');x.send('pagenum=2&keyword=test');
 const started=e.messages.find(m=>m.kind==='request');assert.ok(started);assert.equal(started.page,2);assert.equal(e.messages.some(m=>m.kind==='response'),false);
});

test('failed synchronous XHR send keeps original exception and does not report a started request',()=>{
 const error=new Error('not sent'),e=environment({sendError:error}),x=new e.win.XMLHttpRequest();x.open('POST','https://app.zhuanzhuan.com/zz/transfer/search');
 assert.throws(()=>x.send('pagenum=2'),value=>value===error);assert.equal(e.messages.some(m=>m.kind==='request'),false);
});
test('search starts carry only public filter selection and fetch failures retain original rejection',async()=>{
 const error=new Error('offline'),e=environment({fetch:()=>Promise.reject(error)});
 const body='pagenum=2&filterModuleServerParamsInput='+encodeURIComponent(JSON.stringify({clickItems:{'69':[{value:'5170',cmd:'params_new6651=1080730',token:'private'}]}}));
 await assert.rejects(e.win.fetch('https://app.zhuanzhuan.com/zz/transfer/search',{body}),value=>value===error);
 const m=e.messages.find(m=>m.kind==='request');assert.equal(m.selection['69'][0].value,'5170');assert.equal(JSON.stringify(m).includes('private'),false);assert.ok(e.messages.some(m=>m.kind==='failure'));
});
test('XHR errors end the observed request without swallowing app listeners',()=>{
 const e=environment(),x=new e.win.XMLHttpRequest();let failed=0;x.addEventListener('error',()=>failed++);
 x.open('POST','https://app.zhuanzhuan.com/zz/transfer/search');x.send('pagenum=2');x.emit('error');
 assert.equal(failed,1);assert.equal(e.messages.filter(m=>m.kind==='failure').length,1);
});
test('unreadable or malformed fetch bodies report failure without changing app response',async()=>{
 for(const payload of [null,'not-json','null']){
  const response=payload===null?{headers:{get:()=>null},clone:()=>({text:()=>Promise.reject(Error('read'))})}:new Response(payload);
  const e=environment({fetch:()=>Promise.resolve(response)});
  assert.equal(await e.win.fetch('https://app.zhuanzhuan.com/zz/transfer/search'),response);await settle();
  assert.equal(e.messages.filter(m=>m.kind==='failure').length,1);
 }
});
test('filter commit marker is captured at request start with its token',async()=>{
 let resolve;const e=environment({fetch:()=>new Promise(r=>resolve=r)});e.win.ZZWeb.setContext({token:{run:'a',step:8},filterCommit:true});const task=e.win.fetch('https://app.zhuanzhuan.com/zz/transfer/search');e.win.ZZWeb.setContext({token:{run:'a',step:9}});resolve(new Response(JSON.stringify({respCode:0,respData:{infos:[]}})));await task;await settle();const m=e.messages.find(x=>x.kind==='response');assert.equal(m.filterCommit,true);assert.equal(m.token.step,8);
});

test('report channel crosses the web bridge through params and paramBars without unrelated fields',()=>{
 const raw=structuredClone(fixture.more);raw.respData.report.params.push({key:'IMEI',value:'private-imei'});raw.respData.report.reportParam.paramBars[0].token='private-token';raw.respData.report.reportParam.paramBars.push({paramName:'卖家',paramValue:'private-seller'});
 const e=environment(),x=new e.win.XMLHttpRequest();x.open('GET','https://app.zhuanzhuan.com/zzopen/waresshow/moreInfo?infoId='+fixture.id);x.responseType='json';x.send();x.response=raw;x.emit();
 const m=e.messages.find(m=>m.kind==='response');assert.equal(m.data.respData.report.params.find(p=>p.key==='购买渠道').value,'国行');assert.deepEqual(m.data.respData.report.reportParam.paramBars,[{paramName:'购买渠道',paramValue:'国行'}]);assert.equal(JSON.stringify(m).includes('private-'),false);
});

test('favorite request-start diagnostics are distinct from a DOM click and exclude unrelated parameters',async()=>{
 const e=environment();await e.win.fetch('https://app.zhuanzhuan.com/zz/transfer/addLoveInfo?infoId='+fixture.id+'&token=private-marker');await settle();
 const start=e.messages.find(m=>m.kind==='request');assert.equal(start.path,'/zz/transfer/addLoveInfo');assert.equal(start.id,fixture.id);assert.equal(JSON.stringify(e.messages).includes('private-marker'),false);
});

test('visible continue-favorite prompt reports its action token without pressing confirm',async()=>{
 let changed,disconnected=false,confirmClicks=0;
 const buttons=[];
 const e=environment({buttons,MutationObserver:class{
  constructor(callback){changed=callback;} observe(){} disconnect(){disconnected=true;}
 }});
 const confirm={...e.button,textContent:'知道了，继续收藏',getBoundingClientRect:()=>({width:100,height:40,top:700,bottom:740}),click:()=>confirmClicks++};
 buttons.push(e.button);
 await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+fixture.id);await settle();
 e.win.ZZWeb.setContext({token:{run:'a',step:2},id:fixture.id,allowFavorite:true});
 assert.equal(e.win.ZZWeb.favorite(fixture.id).ok,true);
 assert.equal(e.messages.some(m=>m.kind==='favoriteConfirmation'),false);
 buttons.push(confirm);
 changed();
 assert.deepEqual(e.messages.find(m=>m.kind==='favoriteConfirmation'),{kind:'favoriteConfirmation',id:fixture.id,token:{run:'a',step:2}});
 assert.equal(confirmClicks,0);assert.equal(disconnected,true);
});

test('battery confirmation requires opt-in, the active product and a visible unambiguous dialog',async()=>{
 let inspect,confirmClicks=0;
 const buttons=[];
 const e=environment({buttons,MutationObserver:class{
  constructor(callback){inspect=callback;} observe(){} disconnect(){}
 }});
 const token={run:'scan',step:2}, id=fixture.id;
 const dialog={getAttribute:()=>null,querySelectorAll:()=>[title,confirm]};
 const title={...e.button,textContent:'平台焕新电池',parentElement:dialog};
 const confirm={...e.button,textContent:'知道了，继续收藏',parentElement:dialog,click:()=>confirmClicks++};
 buttons.push(e.button);
 await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+id);await settle();
 const context={token,id,allowFavorite:true};
 e.win.ZZWeb.setContext(context);
 assert.equal(e.win.ZZWeb.favorite(id).ok,true);
 buttons.push(title,confirm);inspect();
 const approve=()=>e.win.ZZWeb.confirmBatteryFavorite(id,token);
 assert.equal(approve(),false);
 e.win.ZZWeb.setContext({...context,allowBatteryConfirmation:true});
 assert.equal(e.win.ZZWeb.confirmBatteryFavorite(id,{...token,step:1}),false);
 e.win.location=new URL(url.replace(id,'999'));
 assert.equal(approve(),false);
 e.win.location=new URL(url);
 title.textContent='其他收藏提醒';
 assert.equal(approve(),false);
 title.textContent='平台焕新电池';
 buttons.push({...confirm});
 assert.equal(approve(),false);
 buttons.pop();
 assert.equal(approve(),true);
 assert.equal(approve(),false);
 assert.equal(confirmClicks,1);
 assert.equal(e.clicks(),1);
});

test('an already dispatched favorite request suppresses a second click',async()=>{
 const e=environment();
 const id=fixture.id,token={run:'scan',step:2};
 await e.win.fetch('https://app.zhuanzhuan.com/zzopen/waresshow/baseInfo?infoId='+id);await settle();
 e.win.ZZWeb.setContext({id,token,allowFavorite:true,allowBatteryConfirmation:true});
 assert.equal(e.win.ZZWeb.favorite(id).ok,true);
 const request=e.win.fetch('https://app.zhuanzhuan.com/zz/transfer/addLoveInfo?infoId='+id);
 assert.equal(e.win.ZZWeb.confirmBatteryFavorite(id,token),'requestStarted');
 assert.equal(e.clicks(),1);
 await request;
});

test('bridges only inspection fields from report leaves and battery parameters',()=>{
 const e=environment(), x=new e.win.XMLHttpRequest(), more=structuredClone(fixture.more);
 const report=more.respData.report;
 report.params.push({key:'电池健康值',value:'100%',tracking:'private battery metadata'});
 report.reportItem=[{name:'屏幕检测',normalNum:1,abNormalNum:0,metadata:'private report metadata',
  children:[{name:'屏幕触控',children:[{name:'触控',values:[{value:'正常',isNormal:1,photo:'private photo'}]}]}]}];
 x.open('GET','https://app.zhuanzhuan.com/zzopen/waresshow/moreInfo?infoId='+fixture.id);
 x.responseType='json';x.response=more;x.send();x.emit();
 const forwarded=e.messages.find(m=>m.kind==='response').data.respData.report;
 assert.deepEqual(forwarded.params.find(p=>p.key==='电池健康值'),{key:'电池健康值',value:'100%'});
 assert.deepEqual(forwarded.reportItem[0].children[0].children[0].values,[{value:'正常',isNormal:1}]);
 assert.equal(forwarded.reportItem[0].normalNum,1);
 assert.doesNotMatch(JSON.stringify(forwarded),/private/);
});
