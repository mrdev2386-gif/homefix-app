(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[351],{8745:function(e,t,n){"use strict";n.d(t,{BH:function(){return w},L:function(){return u},LL:function(){return A},P0:function(){return m},Pz:function(){return v},Sg:function(){return b},ZR:function(){return C},aH:function(){return y},b$:function(){return T},eu:function(){return x},hl:function(){return S},m9:function(){return U},ne:function(){return M},pd:function(){return L},q4:function(){return g},ru:function(){return _},tV:function(){return c},uI:function(){return I},vZ:function(){return function e(t,n){if(t===n)return!0;let r=Object.keys(t),i=Object.keys(n);for(let s of r){if(!i.includes(s))return!1;let r=t[s],a=n[s];if(D(r)&&D(a)){if(!e(r,a))return!1}else if(r!==a)return!1}for(let e of i)if(!r.includes(e))return!1;return!0}},w1:function(){return k},xO:function(){return O},xb:function(){return R},z$:function(){return E},zd:function(){return P}});var r=n(2601);/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let i=function(e){let t=[],n=0;for(let r=0;r<e.length;r++){let i=e.charCodeAt(r);i<128?t[n++]=i:(i<2048?t[n++]=i>>6|192:((64512&i)==55296&&r+1<e.length&&(64512&e.charCodeAt(r+1))==56320?(i=65536+((1023&i)<<10)+(1023&e.charCodeAt(++r)),t[n++]=i>>18|240,t[n++]=i>>12&63|128):t[n++]=i>>12|224,t[n++]=i>>6&63|128),t[n++]=63&i|128)}return t},s=function(e){let t=[],n=0,r=0;for(;n<e.length;){let i=e[n++];if(i<128)t[r++]=String.fromCharCode(i);else if(i>191&&i<224){let s=e[n++];t[r++]=String.fromCharCode((31&i)<<6|63&s)}else if(i>239&&i<365){let s=e[n++],a=e[n++],o=e[n++],l=((7&i)<<18|(63&s)<<12|(63&a)<<6|63&o)-65536;t[r++]=String.fromCharCode(55296+(l>>10)),t[r++]=String.fromCharCode(56320+(1023&l))}else{let s=e[n++],a=e[n++];t[r++]=String.fromCharCode((15&i)<<12|(63&s)<<6|63&a)}}return t.join("")},a={byteToCharMap_:null,charToByteMap_:null,byteToCharMapWebSafe_:null,charToByteMapWebSafe_:null,ENCODED_VALS_BASE:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",get ENCODED_VALS(){return this.ENCODED_VALS_BASE+"+/="},get ENCODED_VALS_WEBSAFE(){return this.ENCODED_VALS_BASE+"-_."},HAS_NATIVE_SUPPORT:"function"==typeof atob,encodeByteArray(e,t){if(!Array.isArray(e))throw Error("encodeByteArray takes an array as a parameter");this.init_();let n=t?this.byteToCharMapWebSafe_:this.byteToCharMap_,r=[];for(let t=0;t<e.length;t+=3){let i=e[t],s=t+1<e.length,a=s?e[t+1]:0,o=t+2<e.length,l=o?e[t+2]:0,u=i>>2,c=(3&i)<<4|a>>4,h=(15&a)<<2|l>>6,d=63&l;o||(d=64,s||(h=64)),r.push(n[u],n[c],n[h],n[d])}return r.join("")},encodeString(e,t){return this.HAS_NATIVE_SUPPORT&&!t?btoa(e):this.encodeByteArray(i(e),t)},decodeString(e,t){return this.HAS_NATIVE_SUPPORT&&!t?atob(e):s(this.decodeStringToByteArray(e,t))},decodeStringToByteArray(e,t){this.init_();let n=t?this.charToByteMapWebSafe_:this.charToByteMap_,r=[];for(let t=0;t<e.length;){let i=n[e.charAt(t++)],s=t<e.length,a=s?n[e.charAt(t)]:0;++t;let l=t<e.length,u=l?n[e.charAt(t)]:64;++t;let c=t<e.length,h=c?n[e.charAt(t)]:64;if(++t,null==i||null==a||null==u||null==h)throw new o;let d=i<<2|a>>4;if(r.push(d),64!==u){let e=a<<4&240|u>>2;if(r.push(e),64!==h){let e=u<<6&192|h;r.push(e)}}}return r},init_(){if(!this.byteToCharMap_){this.byteToCharMap_={},this.charToByteMap_={},this.byteToCharMapWebSafe_={},this.charToByteMapWebSafe_={};for(let e=0;e<this.ENCODED_VALS.length;e++)this.byteToCharMap_[e]=this.ENCODED_VALS.charAt(e),this.charToByteMap_[this.byteToCharMap_[e]]=e,this.byteToCharMapWebSafe_[e]=this.ENCODED_VALS_WEBSAFE.charAt(e),this.charToByteMapWebSafe_[this.byteToCharMapWebSafe_[e]]=e,e>=this.ENCODED_VALS_BASE.length&&(this.charToByteMap_[this.ENCODED_VALS_WEBSAFE.charAt(e)]=e,this.charToByteMapWebSafe_[this.ENCODED_VALS.charAt(e)]=e)}}};class o extends Error{constructor(){super(...arguments),this.name="DecodeBase64StringError"}}let l=function(e){let t=i(e);return a.encodeByteArray(t,!0)},u=function(e){return l(e).replace(/\./g,"")},c=function(e){try{return a.decodeString(e,!0)}catch(e){console.error("base64Decode failed: ",e)}return null},h=()=>/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */(function(){if("undefined"!=typeof self)return self;if("undefined"!=typeof window)return window;if(void 0!==n.g)return n.g;throw Error("Unable to locate global object.")})().__FIREBASE_DEFAULTS__,d=()=>{if(void 0===r||void 0===r.env)return;let e=r.env.__FIREBASE_DEFAULTS__;if(e)return JSON.parse(e)},f=()=>{let e;if("undefined"==typeof document)return;try{e=document.cookie.match(/__FIREBASE_DEFAULTS__=([^;]+)/)}catch(e){return}let t=e&&c(e[1]);return t&&JSON.parse(t)},p=()=>{try{return h()||d()||f()}catch(e){console.info(`Unable to get __FIREBASE_DEFAULTS__ due to: ${e}`);return}},g=e=>{var t,n;return null===(n=null===(t=p())||void 0===t?void 0:t.emulatorHosts)||void 0===n?void 0:n[e]},m=e=>{let t=g(e);if(!t)return;let n=t.lastIndexOf(":");if(n<=0||n+1===t.length)throw Error(`Invalid host ${t} with no separate hostname and port!`);let r=parseInt(t.substring(n+1),10);return"["===t[0]?[t.substring(1,n-1),r]:[t.substring(0,n),r]},y=()=>{var e;return null===(e=p())||void 0===e?void 0:e.config},v=e=>{var t;return null===(t=p())||void 0===t?void 0:t[`_${e}`]};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class w{constructor(){this.reject=()=>{},this.resolve=()=>{},this.promise=new Promise((e,t)=>{this.resolve=e,this.reject=t})}wrapCallback(e){return(t,n)=>{t?this.reject(t):this.resolve(n),"function"==typeof e&&(this.promise.catch(()=>{}),1===e.length?e(t):e(t,n))}}}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function b(e,t){if(e.uid)throw Error('The "uid" field is no longer supported by mockUserToken. Please use "sub" instead for Firebase Auth User ID.');let n=t||"demo-project",r=e.iat||0,i=e.sub||e.user_id;if(!i)throw Error("mockUserToken must contain 'sub' or 'user_id' field!");let s=Object.assign({iss:`https://securetoken.google.com/${n}`,aud:n,iat:r,exp:r+3600,auth_time:r,sub:i,user_id:i,firebase:{sign_in_provider:"custom",identities:{}}},e);return[u(JSON.stringify({alg:"none",type:"JWT"})),u(JSON.stringify(s)),""].join(".")}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function E(){return"undefined"!=typeof navigator&&"string"==typeof navigator.userAgent?navigator.userAgent:""}function I(){return"undefined"!=typeof window&&!!(window.cordova||window.phonegap||window.PhoneGap)&&/ios|iphone|ipod|ipad|android|blackberry|iemobile/i.test(E())}function _(){let e="object"==typeof chrome?chrome.runtime:"object"==typeof browser?browser.runtime:void 0;return"object"==typeof e&&void 0!==e.id}function T(){return"object"==typeof navigator&&"ReactNative"===navigator.product}function k(){let e=E();return e.indexOf("MSIE ")>=0||e.indexOf("Trident/")>=0}function S(){try{return"object"==typeof indexedDB}catch(e){return!1}}function x(){return new Promise((e,t)=>{try{let n=!0,r="validate-browser-context-for-indexeddb-analytics-module",i=self.indexedDB.open(r);i.onsuccess=()=>{i.result.close(),n||self.indexedDB.deleteDatabase(r),e(!0)},i.onupgradeneeded=()=>{n=!1},i.onerror=()=>{var e;t((null===(e=i.error)||void 0===e?void 0:e.message)||"")}}catch(e){t(e)}})}class C extends Error{constructor(e,t,n){super(t),this.code=e,this.customData=n,this.name="FirebaseError",Object.setPrototypeOf(this,C.prototype),Error.captureStackTrace&&Error.captureStackTrace(this,A.prototype.create)}}class A{constructor(e,t,n){this.service=e,this.serviceName=t,this.errors=n}create(e,...t){let n=t[0]||{},r=`${this.service}/${e}`,i=this.errors[e],s=i?i.replace(N,(e,t)=>{let r=n[t];return null!=r?String(r):`<${t}?>`}):"Error",a=`${this.serviceName}: ${s} (${r}).`,o=new C(r,a,n);return o}}let N=/\{\$([^}]+)}/g;function R(e){for(let t in e)if(Object.prototype.hasOwnProperty.call(e,t))return!1;return!0}function D(e){return null!==e&&"object"==typeof e}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function O(e){let t=[];for(let[n,r]of Object.entries(e))Array.isArray(r)?r.forEach(e=>{t.push(encodeURIComponent(n)+"="+encodeURIComponent(e))}):t.push(encodeURIComponent(n)+"="+encodeURIComponent(r));return t.length?"&"+t.join("&"):""}function P(e){let t={},n=e.replace(/^\?/,"").split("&");return n.forEach(e=>{if(e){let[n,r]=e.split("=");t[decodeURIComponent(n)]=decodeURIComponent(r)}}),t}function L(e){let t=e.indexOf("?");if(!t)return"";let n=e.indexOf("#",t);return e.substring(t,n>0?n:void 0)}function M(e,t){let n=new F(e,t);return n.subscribe.bind(n)}class F{constructor(e,t){this.observers=[],this.unsubscribes=[],this.observerCount=0,this.task=Promise.resolve(),this.finalized=!1,this.onNoObservers=t,this.task.then(()=>{e(this)}).catch(e=>{this.error(e)})}next(e){this.forEachObserver(t=>{t.next(e)})}error(e){this.forEachObserver(t=>{t.error(e)}),this.close(e)}complete(){this.forEachObserver(e=>{e.complete()}),this.close()}subscribe(e,t,n){let r;if(void 0===e&&void 0===t&&void 0===n)throw Error("Missing Observer.");void 0===(r=!function(e,t){if("object"!=typeof e||null===e)return!1;for(let n of t)if(n in e&&"function"==typeof e[n])return!0;return!1}(e,["next","error","complete"])?{next:e,error:t,complete:n}:e).next&&(r.next=V),void 0===r.error&&(r.error=V),void 0===r.complete&&(r.complete=V);let i=this.unsubscribeOne.bind(this,this.observers.length);return this.finalized&&this.task.then(()=>{try{this.finalError?r.error(this.finalError):r.complete()}catch(e){}}),this.observers.push(r),i}unsubscribeOne(e){void 0!==this.observers&&void 0!==this.observers[e]&&(delete this.observers[e],this.observerCount-=1,0===this.observerCount&&void 0!==this.onNoObservers&&this.onNoObservers(this))}forEachObserver(e){if(!this.finalized)for(let t=0;t<this.observers.length;t++)this.sendOne(t,e)}sendOne(e,t){this.task.then(()=>{if(void 0!==this.observers&&void 0!==this.observers[e])try{t(this.observers[e])}catch(e){"undefined"!=typeof console&&console.error&&console.error(e)}})}close(e){this.finalized||(this.finalized=!0,void 0!==e&&(this.finalError=e),this.task.then(()=>{this.observers=void 0,this.onNoObservers=void 0}))}}function V(){}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function U(e){return e&&e._delegate?e._delegate:e}},2601:function(e,t,n){"use strict";var r,i;e.exports=(null==(r=n.g.process)?void 0:r.env)&&"object"==typeof(null==(i=n.g.process)?void 0:i.env)?n.g.process:n(8960)},4796:function(e,t,n){"use strict";n.d(t,{H:function(){return c},a:function(){return h}});var r=n(7437),i=n(2265),s=n(3778),a=n(4033),o=n(2860),l=n(9976);let u=(0,i.createContext)({user:null,loading:!0,isAdmin:!1,signOut:async()=>{}}),c=e=>{let{children:t}=e,[n,c]=(0,i.useState)(null),[h,d]=(0,i.useState)(!1),[f,p]=(0,i.useState)(!0),g=(0,a.useRouter)(),m=(0,a.usePathname)();(0,i.useEffect)(()=>{let e=(0,s.Aj)(o.I8,async e=>{if(e)try{await e.getIdToken(!0);let t=await e.getIdTokenResult();!0===t.claims.admin?(c(e),d(!0)):(console.error("Non-admin user attempted access"),await (0,l.Mx)(),c(null),d(!1))}catch(e){console.error("Auth verification error:",e),c(null),d(!1)}else c(null),d(!1);p(!1)});return()=>e()},[]),(0,i.useEffect)(()=>{if(f)return;let e=["/","/login"].includes(m);n||e?!n||h||e?n&&h&&"/login"===m&&g.push("/admin"):g.push("/login?error=not_admin"):g.push("/login")},[n,h,f,m,g]);let y=async()=>{try{await (0,l.Mx)(),c(null),d(!1),g.push("/login")}catch(e){console.error("Error signing out:",e)}};return f?(0,r.jsxs)("div",{className:"h-screen w-full flex flex-col items-center justify-center bg-[#020617] gap-4",children:[(0,r.jsxs)("div",{className:"relative",children:[(0,r.jsx)("div",{className:"w-12 h-12 border-4 border-indigo-500/20 rounded-full"}),(0,r.jsx)("div",{className:"w-12 h-12 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin absolute top-0 left-0"})]}),(0,r.jsx)("p",{className:"text-indigo-400/80 text-[10px] font-black uppercase tracking-[0.3em] animate-pulse",children:"Verifying Credentials"})]}):(0,r.jsx)(u.Provider,{value:{user:n,loading:f,isAdmin:h,signOut:y},children:t})},h=()=>(0,i.useContext)(u)},5914:function(e,t,n){"use strict";n.d(t,{C:function(){return a}});var r=n(7437);n(2265);var i=n(5653);let s={default:"bg-primary text-primary-foreground hover:bg-primary/80 border-transparent",secondary:"bg-secondary text-secondary-foreground hover:bg-secondary/80 border-transparent",destructive:"bg-destructive text-destructive-foreground hover:bg-destructive/80 border-transparent",outline:"text-foreground border-border",success:"bg-green-100 text-green-800 border-green-200",warning:"bg-yellow-100 text-yellow-800 border-yellow-200",info:"bg-blue-100 text-blue-800 border-blue-200",slate:"bg-slate-100 text-slate-800 border-slate-200"};function a(e){let{className:t,variant:n="default",...a}=e;return(0,r.jsx)("div",{className:(0,i.cn)("inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",s[n],t),...a})}},860:function(e,t,n){"use strict";n.d(t,{z:function(){return u}});var r=n(7437),i=n(2265),s=n(5653),a=n(6794);let o={default:"bg-[#6366F1] text-white hover:bg-[#4F46E5] shadow-lg shadow-[#6366F1]/20 active:scale-[0.98] transition-all duration-200",destructive:"bg-red-600 text-white hover:bg-red-700 shadow-lg shadow-red-600/20 active:scale-[0.98] transition-all duration-200",outline:"border border-[#374151] bg-transparent text-[#E5E7EB] hover:bg-[#1F2937] hover:border-[#6366F1] active:scale-[0.98] transition-all duration-200",secondary:"bg-[#1F2937] text-[#E5E7EB] hover:bg-[#374151] active:scale-[0.98] transition-all duration-200",ghost:"text-[#9CA3AF] hover:bg-[#1F2937] hover:text-[#E5E7EB] active:scale-[0.95] transition-all duration-200",link:"text-[#6366F1] underline-offset-4 hover:underline"},l={default:"h-10 px-4 py-2 rounded-lg",sm:"h-9 rounded-md px-3",lg:"h-11 rounded-lg px-8",icon:"h-10 w-10 rounded-lg"},u=i.forwardRef((e,t)=>{let{className:n,variant:i="default",size:u="default",asChild:c=!1,isLoading:h,children:d,...f}=e;return(0,r.jsxs)("button",{className:(0,s.cn)("inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-[#0B1120] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#6366F1] focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",o[i],l[u],n),ref:t,disabled:h||f.disabled,...f,children:[h&&(0,r.jsx)(a.Z,{className:"mr-2 h-4 w-4 animate-spin"}),d]})});u.displayName="Button"},4793:function(e,t,n){"use strict";n.d(t,{Ol:function(){return o},Zb:function(){return a},aY:function(){return c},ll:function(){return l}});var r=n(7437),i=n(2265),s=n(5653);let a=i.forwardRef((e,t)=>{let{className:n,...i}=e;return(0,r.jsx)("div",{ref:t,className:(0,s.cn)("rounded-xl border bg-[#111827] border-[#1F2937] shadow-lg text-[#E5E7EB]",n),...i})});a.displayName="Card";let o=i.forwardRef((e,t)=>{let{className:n,...i}=e;return(0,r.jsx)("div",{ref:t,className:(0,s.cn)("flex flex-col space-y-1.5 p-6",n),...i})});o.displayName="CardHeader";let l=i.forwardRef((e,t)=>{let{className:n,...i}=e;return(0,r.jsx)("h3",{ref:t,className:(0,s.cn)("text-xl font-semibold leading-none tracking-tight text-[#E5E7EB]",n),...i})});l.displayName="CardTitle";let u=i.forwardRef((e,t)=>{let{className:n,...i}=e;return(0,r.jsx)("p",{ref:t,className:(0,s.cn)("text-sm text-[#9CA3AF]",n),...i})});u.displayName="CardDescription";let c=i.forwardRef((e,t)=>{let{className:n,...i}=e;return(0,r.jsx)("div",{ref:t,className:(0,s.cn)("p-6 pt-0",n),...i})});c.displayName="CardContent";let h=i.forwardRef((e,t)=>{let{className:n,...i}=e;return(0,r.jsx)("div",{ref:t,className:(0,s.cn)("flex items-center p-6 pt-0",n),...i})});h.displayName="CardFooter"},5114:function(e,t,n){"use strict";n.d(t,{Z:function(){return o}});var r=n(7437),i=n(2265),s=n(4919),a=n(4862);function o(e){let{isOpen:t,title:n,message:o,confirmText:l="Confirm",cancelText:u="Cancel",onConfirm:c,onCancel:h,requireInput:d=!1,inputLabel:f,inputPlaceholder:p,inputValidation:g,variant:m="default"}=e,[y,v]=(0,i.useState)(""),[w,b]=(0,i.useState)(null);if(!t)return null;let E=()=>{v(""),b(null),h()};return(0,r.jsx)("div",{className:"fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm",children:(0,r.jsxs)("div",{className:"bg-[#111827] border border-[#1F2937] rounded-xl shadow-2xl max-w-md w-full",children:[(0,r.jsxs)("div",{className:"flex items-center justify-between p-6 border-b border-[#1F2937]",children:[(0,r.jsxs)("div",{className:"flex items-center gap-3",children:["danger"===m&&(0,r.jsx)("div",{className:"w-10 h-10 rounded-full bg-red-500/10 flex items-center justify-center",children:(0,r.jsx)(s.Z,{className:"w-5 h-5 text-red-400"})}),(0,r.jsx)("h2",{className:"text-xl font-bold text-[#E5E7EB]",children:n})]}),(0,r.jsx)("button",{onClick:E,className:"text-[#6B7280] hover:text-[#E5E7EB] transition-colors",children:(0,r.jsx)(a.Z,{className:"w-5 h-5"})})]}),(0,r.jsxs)("div",{className:"p-6",children:[(0,r.jsx)("p",{className:"text-[#9CA3AF] mb-4",children:o}),d&&(0,r.jsxs)("div",{className:"space-y-2",children:[f&&(0,r.jsx)("label",{className:"block text-sm font-medium text-[#9CA3AF]",children:f}),(0,r.jsx)("textarea",{value:y,onChange:e=>{v(e.target.value),b(null)},placeholder:p,rows:3,className:"w-full px-4 py-2 bg-[#1F2937] border border-[#374151] rounded-lg text-[#E5E7EB] placeholder-[#6B7280] focus:outline-none focus:ring-2 focus:ring-[#6366F1] focus:border-transparent resize-none"}),w&&(0,r.jsx)("p",{className:"text-sm text-red-400",children:w})]})]}),(0,r.jsxs)("div",{className:"flex items-center justify-end gap-3 p-6 border-t border-[#1F2937]",children:[(0,r.jsx)("button",{onClick:E,className:"px-4 py-2 bg-[#1F2937] hover:bg-[#374151] text-[#E5E7EB] rounded-lg transition-colors font-medium",children:u}),(0,r.jsx)("button",{onClick:()=>{if(d){let e=null==g?void 0:g(y);if(e){b(e);return}c(y)}else c();v(""),b(null)},className:"px-4 py-2 rounded-lg transition-colors font-medium ".concat("danger"===m?"bg-red-600 hover:bg-red-700 text-white":"bg-[#6366F1] hover:bg-[#4F46E5] text-white"),children:l})]})]})})}},285:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7437);function i(e){let{icon:t,title:n,description:i,action:s}=e;return(0,r.jsxs)("div",{className:"flex flex-col items-center justify-center py-12 px-4",children:[(0,r.jsx)("div",{className:"w-16 h-16 rounded-full bg-[#1F2937] flex items-center justify-center mb-4",children:(0,r.jsx)(t,{className:"w-8 h-8 text-[#6B7280]"})}),(0,r.jsx)("h3",{className:"text-xl font-bold text-[#E5E7EB] mb-2",children:n}),(0,r.jsx)("p",{className:"text-[#6B7280] text-center max-w-md mb-6",children:i}),s&&(0,r.jsx)("button",{onClick:s.onClick,className:"px-4 py-2 bg-[#6366F1] hover:bg-[#4F46E5] text-white rounded-lg transition-colors font-medium",children:s.label})]})}n(2265)},131:function(e,t,n){"use strict";n.d(t,{Z:function(){return a}});var r=n(7437);n(2265);var i=n(4115),s=n(9915);function a(e){let{title:t="Error",message:n,onRetry:a,showRetry:o=!0}=e;return(0,r.jsxs)("div",{className:"flex flex-col items-center justify-center py-12 px-4",children:[(0,r.jsx)("div",{className:"w-16 h-16 rounded-full bg-red-500/10 flex items-center justify-center mb-4",children:(0,r.jsx)(i.Z,{className:"w-8 h-8 text-red-400"})}),(0,r.jsx)("h3",{className:"text-xl font-bold text-[#E5E7EB] mb-2",children:t}),(0,r.jsx)("p",{className:"text-[#6B7280] text-center max-w-md mb-6",children:n}),o&&a&&(0,r.jsxs)("button",{onClick:a,className:"flex items-center gap-2 px-4 py-2 bg-[#6366F1] hover:bg-[#4F46E5] text-white rounded-lg transition-colors font-medium",children:[(0,r.jsx)(s.Z,{className:"w-4 h-4"}),"Try Again"]})]})}},2224:function(e,t,n){"use strict";n.d(t,{I:function(){return a}});var r=n(7437),i=n(2265),s=n(5653);let a=i.forwardRef((e,t)=>{let{className:n,type:i,label:a,leftIcon:o,rightIcon:l,...u}=e;return(0,r.jsxs)("div",{className:"w-full",children:[a&&(0,r.jsx)("label",{className:"text-sm font-medium text-[#E5E7EB] mb-1.5 block",children:a}),(0,r.jsxs)("div",{className:"relative",children:[o&&(0,r.jsx)("div",{className:"absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280]",children:o}),(0,r.jsx)("input",{type:i,className:(0,s.cn)("flex h-10 w-full rounded-lg border border-[#374151] bg-[#1F2937] px-3 py-2 text-sm text-[#E5E7EB] ring-offset-[#0B1120] placeholder:text-[#6B7280] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#6366F1] focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",o&&"pl-10",l&&"pr-10",n),ref:t,...u}),l&&(0,r.jsx)("div",{className:"absolute right-3 top-1/2 -translate-y-1/2 text-[#6B7280]",children:l})]})]})});a.displayName="Input"},6122:function(e,t,n){"use strict";n.d(t,{ZP:function(){return s}});var r=n(7437);n(2265);var i=n(6794);function s(e){let{message:t="Loading...",variant:n="spinner",rows:s=5}=e;return"skeleton"===n?(0,r.jsx)("div",{className:"space-y-4",children:Array.from({length:s}).map((e,t)=>(0,r.jsx)("div",{className:"bg-[#111827] border border-[#1F2937] rounded-lg p-6 animate-pulse",children:(0,r.jsxs)("div",{className:"flex items-center gap-4",children:[(0,r.jsx)("div",{className:"w-12 h-12 bg-[#1F2937] rounded-lg"}),(0,r.jsxs)("div",{className:"flex-1 space-y-3",children:[(0,r.jsx)("div",{className:"h-4 bg-[#1F2937] rounded w-1/4"}),(0,r.jsx)("div",{className:"h-3 bg-[#1F2937] rounded w-3/4"})]}),(0,r.jsx)("div",{className:"w-20 h-8 bg-[#1F2937] rounded"})]})},t))}):(0,r.jsxs)("div",{className:"flex flex-col items-center justify-center py-12 px-4",children:[(0,r.jsx)(i.Z,{className:"w-12 h-12 text-[#6366F1] animate-spin mb-4"}),(0,r.jsx)("p",{className:"text-[#9CA3AF] font-medium",children:t})]})}},7377:function(e,t,n){"use strict";n.d(t,{Z:function(){return a}});var r=n(7437),i=n(4862);let s={sm:"max-w-md",md:"max-w-lg",lg:"max-w-2xl",xl:"max-w-4xl"};function a(e){let{isOpen:t,onClose:n,title:a,children:o,size:l="md"}=e;return t?(0,r.jsx)("div",{className:"fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm",children:(0,r.jsxs)("div",{className:"bg-[#111827] border border-[#1F2937] rounded-xl shadow-2xl w-full ".concat(s[l]," max-h-[90vh] overflow-hidden"),children:[(0,r.jsxs)("div",{className:"flex items-center justify-between p-6 border-b border-[#1F2937]",children:[(0,r.jsx)("h2",{className:"text-xl font-semibold text-[#E5E7EB]",children:a}),(0,r.jsx)("button",{onClick:n,className:"p-2 hover:bg-[#1F2937] rounded-lg transition-colors",children:(0,r.jsx)(i.Z,{size:20,className:"text-[#6B7280]"})})]}),(0,r.jsx)("div",{className:"p-6 overflow-y-auto max-h-[calc(90vh-80px)]",children:o})]})}):null}},6066:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7437);function i(e){let{title:t,description:n,action:i}=e;return(0,r.jsxs)("div",{className:"flex items-center justify-between mb-6",children:[(0,r.jsxs)("div",{children:[(0,r.jsx)("h1",{className:"text-2xl font-bold text-[#E5E7EB]",children:t}),n&&(0,r.jsx)("p",{className:"text-sm text-[#9CA3AF] mt-1",children:n})]}),i&&(0,r.jsx)("div",{children:i})]})}},8330:function(e,t,n){"use strict";n.d(t,{QH:function(){return a.Z},wQ:function(){return g},u_:function(){return m.Z},mr:function(){return p.Z},Rm:function(){return f},OE:function(){return s},iA:function(){return h}});var r=n(7437);let i={success:"badge-success",warning:"badge-warning",error:"badge-error",info:"badge-info",default:"badge-default",purple:"badge-purple"};function s(e){let{status:t,variant:n="default"}=e;return(0,r.jsx)("span",{className:"badge ".concat(i[n]),children:t})}n(2265);var a=n(5114);n(285),n(131),n(6122),n(860),n(4793),n(2224);var o=n(7865);let l=(0,o.Z)("ArrowUpDown",[["path",{d:"m21 16-4 4-4-4",key:"f6ql7i"}],["path",{d:"M17 20V4",key:"1ejh1v"}],["path",{d:"m3 8 4-4 4 4",key:"11wl7u"}],["path",{d:"M7 4v16",key:"1glfcx"}]]),u=(0,o.Z)("ChevronLeft",[["path",{d:"m15 18-6-6 6-6",key:"1wnfg3"}]]),c=(0,o.Z)("ChevronRight",[["path",{d:"m9 18 6-6-6-6",key:"mthhwq"}]]);function h(e){let{columns:t,data:n,loading:i,pagination:s,onSort:a,sortConfig:o,emptyMessage:h="No data found.",className:d}=e;return i?(0,r.jsx)("div",{className:"w-full bg-[#111827] rounded-xl border border-[#1F2937] p-8 space-y-4 ".concat(d||""),children:[1,2,3,4,5].map(e=>(0,r.jsx)("div",{className:"h-12 bg-[#1F2937] rounded-lg animate-pulse"},e))}):(0,r.jsxs)("div",{className:"bg-[#111827] rounded-xl border border-[#1F2937] shadow-lg overflow-hidden ".concat(d||""),children:[(0,r.jsx)("div",{className:"overflow-x-auto",children:(0,r.jsxs)("table",{className:"w-full text-left border-collapse",children:[(0,r.jsx)("thead",{children:(0,r.jsx)("tr",{className:"bg-[#0F172A] border-b border-[#1F2937]",children:t.map(e=>(0,r.jsx)("th",{className:"\n                                        px-4 py-3 text-xs font-semibold text-[#9CA3AF] uppercase tracking-wider whitespace-nowrap\n                                        ".concat(e.sortable?"cursor-pointer hover:bg-[#1F2937] transition-colors group":"","\n                                    "),style:{textAlign:e.align||"left"},onClick:()=>e.sortable&&a&&a(e.key),children:(0,r.jsxs)("div",{className:"flex items-center gap-2 ".concat("right"===e.align?"justify-end":"center"===e.align?"justify-center":"justify-start"),children:[e.label,e.sortable&&(0,r.jsx)(l,{size:14,className:"text-[#6B7280] group-hover:text-[#6366F1]"})]})},e.key))})}),(0,r.jsx)("tbody",{className:"divide-y divide-[#1F2937]",children:n.length>0?n.map((e,n)=>(0,r.jsx)("tr",{className:"hover:bg-[#1F2937]/50 transition-colors",children:t.map(t=>(0,r.jsx)("td",{className:"px-4 py-3 align-middle",style:{textAlign:t.align||"left"},children:t.render?t.render(e,n):(0,r.jsx)("span",{className:"text-sm text-[#E5E7EB]",children:e[t.key]})},"".concat(e.id,"-").concat(t.key)))},e.id||n)):(0,r.jsx)("tr",{children:(0,r.jsx)("td",{colSpan:t.length,className:"px-4 py-16 text-center",children:(0,r.jsx)("p",{className:"text-[#6B7280] text-sm",children:h})})})})]})}),s&&s.totalPages>1&&(0,r.jsxs)("div",{className:"border-t border-[#1F2937] px-6 py-4 flex items-center justify-between bg-[#0F172A]",children:[(0,r.jsxs)("p",{className:"text-sm text-[#9CA3AF]",children:["Page ",s.currentPage," of ",s.totalPages]}),(0,r.jsxs)("div",{className:"flex items-center gap-2",children:[(0,r.jsx)("button",{onClick:()=>s.onPageChange(Math.max(1,s.currentPage-1)),disabled:1===s.currentPage,className:"p-2 rounded-lg hover:bg-[#1F2937] text-[#9CA3AF] disabled:opacity-40 disabled:cursor-not-allowed transition-all border border-[#374151]",children:(0,r.jsx)(u,{size:18})}),(0,r.jsx)("button",{onClick:()=>s.onPageChange(Math.min(s.totalPages,s.currentPage+1)),disabled:s.currentPage===s.totalPages,className:"p-2 rounded-lg hover:bg-[#1F2937] text-[#9CA3AF] disabled:opacity-40 disabled:cursor-not-allowed transition-all border border-[#374151]",children:(0,r.jsx)(c,{size:18})})]})]})]})}n(5914);let d={blue:"bg-blue-500/20 text-blue-400 border-blue-500/30",green:"bg-green-500/20 text-green-400 border-green-500/30",orange:"bg-yellow-500/20 text-yellow-400 border-yellow-500/30",red:"bg-red-500/20 text-red-400 border-red-500/30",purple:"bg-[#6366F1]/20 text-[#6366F1] border-[#6366F1]/30",gray:"bg-gray-500/20 text-gray-400 border-gray-500/30"};function f(e){let{title:t,value:n,icon:i,trend:s,color:a="purple",loading:o}=e;return(0,r.jsx)("div",{className:"admin-card p-6 hover:shadow-[0_0_20px_rgba(99,102,241,0.15)] hover:border-[#6366F1]/30 transition-all duration-300",children:(0,r.jsxs)("div",{className:"flex items-center justify-between",children:[(0,r.jsxs)("div",{className:"flex-1",children:[(0,r.jsx)("p",{className:"text-sm text-[#9CA3AF] mb-1",children:t}),o?(0,r.jsx)("div",{className:"h-8 w-24 bg-[#1F2937] animate-pulse rounded"}):(0,r.jsx)("h3",{className:"text-2xl font-bold text-[#E5E7EB]",children:n}),s&&!o&&(0,r.jsxs)("p",{className:"text-sm mt-2 ".concat(s.isPositive?"text-green-400":"text-red-400"),children:[s.isPositive?"↑":"↓"," ",s.value]})]}),(0,r.jsx)("div",{className:"w-12 h-12 rounded-lg flex items-center justify-center border flex-shrink-0 ".concat(d[a]),children:(0,r.jsx)(i,{size:24})})]})})}var p=n(6066);function g(e){let{columns:t,data:n,loading:i,pagination:s,onSort:a,sortConfig:o,emptyMessage:l,actions:u,title:c}=e;return(0,r.jsxs)("div",{className:"space-y-4",children:[(c||u)&&(0,r.jsxs)("div",{className:"flex items-center justify-between",children:[c&&(0,r.jsx)("h3",{className:"text-lg font-semibold text-[#E5E7EB]",children:c}),u&&(0,r.jsx)("div",{className:"flex items-center gap-2",children:u})]}),(0,r.jsx)(h,{columns:t,data:n,loading:i,pagination:s,onSort:a,sortConfig:o,emptyMessage:l})]})}var m=n(7377)},8572:function(e,t,n){"use strict";n.d(t,{N:function(){return s}});var r=n(2239),i=n(2860);let s={getDashboardStats:async()=>{let e=(0,r.V1)(i.wk,"admin_getDashboardStats"),t=await e();return t.data},approveTechnicianApplication:async(e,t,n)=>{let s=(0,r.V1)(i.wk,"admin_approveTechnicianApplication");return await s({appId:e,approve:t,reason:n})},approveTechnician:async(e,t,n)=>{try{console.log("[ADMIN API] Calling admin_approveTechnician with:",{techId:e,approve:t,reason:n});let s=(0,r.V1)(i.wk,"admin_approveTechnician"),a=await s({techId:e,approve:t,reason:n});return console.log("[ADMIN API] Success:",a.data),a.data}catch(e){throw console.error("[ADMIN API ❌] approveTechnician failed:",e),e}},suspendTechnician:async(e,t)=>{let n=(0,r.V1)(i.wk,"admin_manageUser");return await n({uid:e,action:"block",reason:t})},reactivateTechnician:async e=>{let t=(0,r.V1)(i.wk,"admin_manageUser");return await t({uid:e,action:"unblock"})},toggleTechAvailability:async(e,t)=>{let n=(0,r.V1)(i.wk,"admin_toggleTechAvailability");return await n({uid:e,isAvailable:t})},getAuditLogs:async function(){let e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:50,t=(0,r.V1)(i.wk,"admin_getAuditLogs"),n=await t({limit:e});return n.data},getUsers:async e=>{let t=(0,r.V1)(i.wk,"admin_getUsers"),n=await t(e);return n.data},getUserById:async e=>{let t=(0,r.V1)(i.wk,"admin_getUserById"),n=await t({userId:e});return n.data},updateUser:async(e,t)=>{let n=(0,r.V1)(i.wk,"admin_updateUser");return await n({userId:e,updates:t})},blockUser:async(e,t)=>{let n=(0,r.V1)(i.wk,"admin_blockUser");return await n({userId:e,block:t})},getTechnicians:async e=>{let t=(0,r.V1)(i.wk,"admin_getTechnicians"),n=await t(e);return n.data},getTechnicianById:async e=>{let t=(0,r.V1)(i.wk,"admin_getTechnicianById"),n=await t({techId:e});return n.data},updateTechnician:async(e,t)=>{let n=(0,r.V1)(i.wk,"admin_updateTechnician");return await n({techId:e,updates:t})},manageService:async e=>{let t=(0,r.V1)(i.wk,"admin_manageService");return await t(e)},manageBooking:async function(e,t){let n=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},s=(0,r.V1)(i.wk,"admin_manageBooking");return await s({bookingId:e,action:t,...n})},approveBookingRequest:async e=>{let t=(0,r.V1)(i.wk,"adminApproveBooking");return await t({bookingId:e,action:"approve"})},rejectBookingRequest:async(e,t)=>{let n=(0,r.V1)(i.wk,"adminApproveBooking");return await n({bookingId:e,action:"reject",rejectionReason:t})},approveServiceRequest:async(e,t)=>{let n=(0,r.V1)(i.wk,"adminApproveServiceRequest");return await n({requestId:e,action:"approve",technicianId:t})},rejectServiceRequest:async(e,t)=>{let n=(0,r.V1)(i.wk,"adminApproveServiceRequest");return await n({requestId:e,action:"reject",rejectionReason:t})},markCustomRequestAsReviewed:async e=>{let t=(0,r.V1)(i.wk,"markCustomRequestAsReviewed");return await t({requestId:e})},convertCustomRequest:async e=>{let t=(0,r.V1)(i.wk,"convertCustomRequest");return await t({requestId:e})},rejectCustomRequest:async(e,t)=>{let n=(0,r.V1)(i.wk,"rejectCustomRequest");return await n({requestId:e,adminNotes:t})},approveTechnicianApp:async e=>{let t=(0,r.V1)(i.wk,"approveTechnician");return await t({uid:e})},rejectTechnicianApp:async(e,t)=>{let n=(0,r.V1)(i.wk,"rejectTechnician");return await n({uid:e,reason:t})},manageReview:async(e,t,n)=>{let s=(0,r.V1)(i.wk,"admin_manageReview");return await s({reviewId:e,action:t,reason:n})},manageDispute:async(e,t,n)=>{let s=(0,r.V1)(i.wk,"admin_manageDispute");return await s({disputeId:e,action:t,resolution:n})},generateReport:async function(e){let t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{},n=(0,r.V1)(i.wk,"admin_generateReport"),s=await n({type:e,params:t});return s.data},approveService:async e=>{let t=(0,r.V1)(i.wk,"admin_approveService");return await t({serviceId:e,status:"approved"})},rejectService:async(e,t)=>{let n=(0,r.V1)(i.wk,"admin_rejectService");return await n({serviceId:e,status:"rejected",reason:t})},disableService:async e=>{let t=(0,r.V1)(i.wk,"admin_disableService");return await t({serviceId:e,status:"disabled"})},getAdminLogs:async function(){let e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:100,t=(0,r.V1)(i.wk,"admin_getAdminLogs"),n=await t({limit:e});return n.data},manageCoupon:async(e,t)=>{let n=(0,r.V1)(i.wk,"admin_manageCoupon");return await n({action:e,...t})},sendNotification:async(e,t,n,s)=>{let a=(0,r.V1)(i.wk,"admin_sendNotification");return await a({targetType:e,targetId:t,title:n,body:s})},getSystemHealth:async()=>{let e=(0,r.V1)(i.wk,"admin_getSystemHealth"),t=await e();return t.data}}},9976:function(e,t,n){"use strict";n.d(t,{Mx:function(){return a},qj:function(){return s},sr:function(){return o}});var r=n(3778),i=n(2860);async function s(){let e=new r.hJ;return e.setCustomParameters({prompt:"select_account"}),(0,r.rh)(i.I8,e)}async function a(){return(0,r.w7)(i.I8)}function o(e){let t=(null==e?void 0:e.code)||"";switch(t){case"auth/popup-blocked":return"Popup blocked. Please enable popups and try again.";case"auth/popup-closed-by-user":return"";case"auth/network-request-failed":return"Network error. Please check your connection.";case"auth/too-many-requests":return"Too many attempts. Please try again later.";case"auth/unauthorized-domain":return"This domain is not authorized. Please contact support.";case"auth/user-not-found":case"auth/wrong-password":return"Invalid email or password. Please try again.";default:return(null==e?void 0:e.message)||"Authentication failed. Please try again."}}},2860:function(e,t,n){"use strict";n.d(t,{I8:function(){return l},db:function(){return u},wk:function(){return c}});var r=n(3991);/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */(0,r.KN)("firebase","9.23.0","app");var i=n(3778),s=n(4091),a=n(2239);let o=(0,r.C6)().length?(0,r.Mq)():(0,r.ZF)({apiKey:"AIzaSyADfM4cMfTlz3Cth0QwalYntQv3AoU9daI",authDomain:"homefix-aa42d.firebaseapp.com",projectId:"homefix-aa42d",storageBucket:"homefix-aa42d.firebasestorage.app",messagingSenderId:"663243229047",appId:"1:663243229047:web:generic_web_id"}),l=(0,i.v0)(o),u=(0,s.ad)(o),c=(0,a.$C)(o)},9856:function(e,t,n){"use strict";n.d(t,{B_:function(){return f},Cp:function(){return l},E7:function(){return d},VA:function(){return c},db:function(){return u},k4:function(){return h},ob:function(){return o},pz:function(){return p}});var r=n(2860),i=n(4091),s=n(2239);function a(e,t,n,r){let i=e.data(),s="";return"string"==typeof i.address?s=i.address:i.address&&"object"==typeof i.address?s=i.address.text||i.address.line1||"":(null==t?void 0:t.address)&&(s="string"==typeof t.address?t.address:t.address.text||t.address.line1||""),{id:e.id,customerId:i.customerId,customerName:(null==t?void 0:t.name)||i.customerName||"Unknown Customer",customerPhone:(null==t?void 0:t.phone)||i.customerPhone||"",customerEmail:(null==t?void 0:t.email)||i.customerEmail||"",customerAddress:s,city:i.city||(null==t?void 0:t.city)||"",technicianId:i.technicianId,technicianName:(null==n?void 0:n.name)||i.technicianName,technicianPhone:(null==n?void 0:n.phone)||i.technicianPhone,technicianRating:null==n?void 0:n.rating,technicianExperience:null==n?void 0:n.experience,technicianPhoto:(null==n?void 0:n.photo)||(null==n?void 0:n.profileImage)||i.technicianPhoto,technicianTotalJobs:(null==n?void 0:n.totalJobs)||(null==n?void 0:n.completedJobs)||i.technicianTotalJobs,serviceId:i.serviceId,serviceName:(null==r?void 0:r.name)||i.serviceName||"Unknown Service",serviceDescription:(null==r?void 0:r.description)||i.serviceDescription||"",categoryName:(null==r?void 0:r.category)||i.categoryName||"",servicePrice:i.totalPrice||i.price||0,offerPrice:(null==r?void 0:r.offerPrice)||i.offerPrice,serviceImage:(null==r?void 0:r.image)||i.serviceImage,bookingDate:i.bookingDate||i.scheduledDate,timeSlot:i.timeSlot||i.scheduledTime||"",notes:i.notes||i.customerNotes||"",status:i.status,paymentStatus:i.paymentStatus||"PENDING",paymentMethod:i.paymentMethod,transactionId:i.transactionId,createdAt:i.createdAt,adminApprovedAt:i.adminApprovedAt,technicianAcceptedAt:i.technicianAcceptedAt,serviceStartedAt:i.serviceStartedAt,completedAt:i.completedAt,cancelledAt:i.cancelledAt,rejectionReason:i.rejectionReason}}function o(e,t){return(0,i.cf)((0,i.JU)(r.db,"bookings",e),async e=>{try{if(!e.exists()){t(null);return}let n=e.data(),[s,o,l]=await Promise.all([n.customerId?(0,i.QT)((0,i.JU)(r.db,"users",n.customerId)):Promise.resolve(null),n.technicianId?(0,i.QT)((0,i.JU)(r.db,"technicians",n.technicianId)):Promise.resolve(null),n.serviceId?(0,i.QT)((0,i.JU)(r.db,"services",n.serviceId)):Promise.resolve(null)]),u=(null==s?void 0:s.exists())?s.data():null,c=(null==o?void 0:o.exists())?o.data():null,h=(null==l?void 0:l.exists())?l.data():null,d=a(e,u,c,h);t(d)}catch(e){console.error("Error in booking subscription:",e),t(null)}})}function l(e){let t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:20,n=arguments.length>2?arguments[2]:void 0,s=[(0,i.Xo)("createdAt","desc"),(0,i.b9)(t)];(null==n?void 0:n.status)&&s.push((0,i.ar)("status","==",n.status)),(null==n?void 0:n.paymentStatus)&&s.push((0,i.ar)("paymentStatus","==",n.paymentStatus));let o=(0,i.IO)((0,i.hJ)(r.db,"bookings"),...s);return(0,i.cf)(o,async n=>{try{let s=n.docs,o=[...new Set(s.map(e=>e.data().customerId))],l=[...new Set(s.map(e=>e.data().technicianId).filter(Boolean))],u=[...new Set(s.map(e=>e.data().serviceId))],[c,h,d]=await Promise.all([o.length>0?(0,i.PL)((0,i.IO)((0,i.hJ)(r.db,"users"),(0,i.ar)("__name__","in",o))):Promise.resolve({docs:[]}),l.length>0?(0,i.PL)((0,i.IO)((0,i.hJ)(r.db,"technicians"),(0,i.ar)("__name__","in",l))):Promise.resolve({docs:[]}),u.length>0?(0,i.PL)((0,i.IO)((0,i.hJ)(r.db,"services"),(0,i.ar)("__name__","in",u))):Promise.resolve({docs:[]})]),f=new Map(c.docs.map(e=>[e.id,e.data()])),p=new Map(h.docs.map(e=>[e.id,e.data()])),g=new Map(d.docs.map(e=>[e.id,e.data()])),m=s.map(e=>{let t=e.data(),n=f.get(t.customerId),r=t.technicianId?p.get(t.technicianId):null,i=g.get(t.serviceId);return a(e,n,r,i)});e(m,s.length>=t)}catch(t){console.error("Error in booking subscription:",t),e([],!1)}})}async function u(e){try{let t=await (0,i.PL)((0,i.IO)((0,i.hJ)(r.db,"bookings"),(0,i.ar)("customerId","==",e),(0,i.b9)(1e3)));return t.size}catch(e){return console.error("Error getting customer booking count:",e),0}}async function c(e){let t=(0,s.V1)(r.wk,"approveBookingByAdmin");await t({bookingId:e})}async function h(e,t){let n=(0,s.V1)(r.wk,"rejectBookingByAdmin");await n({bookingId:e,reason:t})}async function d(e){let t=(0,s.V1)(r.wk,"markBookingActive");await t({bookingId:e})}async function f(e){let t=(0,s.V1)(r.wk,"completeBooking");await t({bookingId:e})}async function p(e,t){let n=(0,s.V1)(r.wk,"updateBookingPayment");await n({bookingId:e,paymentStatus:t})}},5653:function(e,t,n){"use strict";n.d(t,{cn:function(){return Z}});let r=e=>{let t=o(e),{conflictingClassGroups:n,conflictingClassGroupModifiers:r}=e;return{getClassGroupId:e=>{let n=e.split("-");return""===n[0]&&1!==n.length&&n.shift(),i(n,t)||a(e)},getConflictingClassGroupIds:(e,t)=>{let i=n[e]||[];return t&&r[e]?[...i,...r[e]]:i}}},i=(e,t)=>{if(0===e.length)return t.classGroupId;let n=e[0],r=t.nextPart.get(n),s=r?i(e.slice(1),r):void 0;if(s)return s;if(0===t.validators.length)return;let a=e.join("-");return t.validators.find(({validator:e})=>e(a))?.classGroupId},s=/^\[(.+)\]$/,a=e=>{if(s.test(e)){let t=s.exec(e)[1],n=t?.substring(0,t.indexOf(":"));if(n)return"arbitrary.."+n}},o=e=>{let{theme:t,prefix:n}=e,r={nextPart:new Map,validators:[]},i=h(Object.entries(e.classGroups),n);return i.forEach(([e,n])=>{l(n,r,e,t)}),r},l=(e,t,n,r)=>{e.forEach(e=>{if("string"==typeof e){let r=""===e?t:u(t,e);r.classGroupId=n;return}if("function"==typeof e){if(c(e)){l(e(r),t,n,r);return}t.validators.push({validator:e,classGroupId:n});return}Object.entries(e).forEach(([e,i])=>{l(i,u(t,e),n,r)})})},u=(e,t)=>{let n=e;return t.split("-").forEach(e=>{n.nextPart.has(e)||n.nextPart.set(e,{nextPart:new Map,validators:[]}),n=n.nextPart.get(e)}),n},c=e=>e.isThemeGetter,h=(e,t)=>t?e.map(([e,n])=>{let r=n.map(e=>"string"==typeof e?t+e:"object"==typeof e?Object.fromEntries(Object.entries(e).map(([e,n])=>[t+e,n])):e);return[e,r]}):e,d=e=>{if(e<1)return{get:()=>void 0,set:()=>{}};let t=0,n=new Map,r=new Map,i=(i,s)=>{n.set(i,s),++t>e&&(t=0,r=n,n=new Map)};return{get(e){let t=n.get(e);return void 0!==t?t:void 0!==(t=r.get(e))?(i(e,t),t):void 0},set(e,t){n.has(e)?n.set(e,t):i(e,t)}}},f=e=>{let{separator:t,experimentalParseClassName:n}=e,r=1===t.length,i=t[0],s=t.length,a=e=>{let n;let a=[],o=0,l=0;for(let u=0;u<e.length;u++){let c=e[u];if(0===o){if(c===i&&(r||e.slice(u,u+s)===t)){a.push(e.slice(l,u)),l=u+s;continue}if("/"===c){n=u;continue}}"["===c?o++:"]"===c&&o--}let u=0===a.length?e:e.substring(l),c=u.startsWith("!"),h=c?u.substring(1):u,d=n&&n>l?n-l:void 0;return{modifiers:a,hasImportantModifier:c,baseClassName:h,maybePostfixModifierPosition:d}};return n?e=>n({className:e,parseClassName:a}):a},p=e=>{if(e.length<=1)return e;let t=[],n=[];return e.forEach(e=>{let r="["===e[0];r?(t.push(...n.sort(),e),n=[]):n.push(e)}),t.push(...n.sort()),t},g=e=>({cache:d(e.cacheSize),parseClassName:f(e),...r(e)}),m=/\s+/,y=(e,t)=>{let{parseClassName:n,getClassGroupId:r,getConflictingClassGroupIds:i}=t,s=[],a=e.trim().split(m),o="";for(let e=a.length-1;e>=0;e-=1){let t=a[e],{modifiers:l,hasImportantModifier:u,baseClassName:c,maybePostfixModifierPosition:h}=n(t),d=!!h,f=r(d?c.substring(0,h):c);if(!f){if(!d||!(f=r(c))){o=t+(o.length>0?" "+o:o);continue}d=!1}let g=p(l).join(":"),m=u?g+"!":g,y=m+f;if(s.includes(y))continue;s.push(y);let v=i(f,d);for(let e=0;e<v.length;++e){let t=v[e];s.push(m+t)}o=t+(o.length>0?" "+o:o)}return o};function v(){let e,t,n=0,r="";for(;n<arguments.length;)(e=arguments[n++])&&(t=w(e))&&(r&&(r+=" "),r+=t);return r}let w=e=>{let t;if("string"==typeof e)return e;let n="";for(let r=0;r<e.length;r++)e[r]&&(t=w(e[r]))&&(n&&(n+=" "),n+=t);return n},b=e=>{let t=t=>t[e]||[];return t.isThemeGetter=!0,t},E=/^\[(?:([a-z-]+):)?(.+)\]$/i,I=/^\d+\/\d+$/,_=new Set(["px","full","screen"]),T=/^(\d+(\.\d+)?)?(xs|sm|md|lg|xl)$/,k=/\d+(%|px|r?em|[sdl]?v([hwib]|min|max)|pt|pc|in|cm|mm|cap|ch|ex|r?lh|cq(w|h|i|b|min|max))|\b(calc|min|max|clamp)\(.+\)|^0$/,S=/^(rgba?|hsla?|hwb|(ok)?(lab|lch)|color-mix)\(.+\)$/,x=/^(inset_)?-?((\d+)?\.?(\d+)[a-z]+|0)_-?((\d+)?\.?(\d+)[a-z]+|0)/,C=/^(url|image|image-set|cross-fade|element|(repeating-)?(linear|radial|conic)-gradient)\(.+\)$/,A=e=>R(e)||_.has(e)||I.test(e),N=e=>$(e,"length",H),R=e=>!!e&&!Number.isNaN(Number(e)),D=e=>$(e,"number",R),O=e=>!!e&&Number.isInteger(Number(e)),P=e=>e.endsWith("%")&&R(e.slice(0,-1)),L=e=>E.test(e),M=e=>T.test(e),F=new Set(["length","size","percentage"]),V=e=>$(e,F,K),U=e=>$(e,"position",K),j=new Set(["image","url"]),B=e=>$(e,j,W),q=e=>$(e,"",G),z=()=>!0,$=(e,t,n)=>{let r=E.exec(e);return!!r&&(r[1]?"string"==typeof t?r[1]===t:t.has(r[1]):n(r[2]))},H=e=>k.test(e)&&!S.test(e),K=()=>!1,G=e=>x.test(e),W=e=>C.test(e),Q=function(e){let t,n,r;let i=function(a){let o=[].reduce((e,t)=>t(e),e());return n=(t=g(o)).cache.get,r=t.cache.set,i=s,s(a)};function s(e){let i=n(e);if(i)return i;let s=y(e,t);return r(e,s),s}return function(){return i(v.apply(null,arguments))}}(()=>{let e=b("colors"),t=b("spacing"),n=b("blur"),r=b("brightness"),i=b("borderColor"),s=b("borderRadius"),a=b("borderSpacing"),o=b("borderWidth"),l=b("contrast"),u=b("grayscale"),c=b("hueRotate"),h=b("invert"),d=b("gap"),f=b("gradientColorStops"),p=b("gradientColorStopPositions"),g=b("inset"),m=b("margin"),y=b("opacity"),v=b("padding"),w=b("saturate"),E=b("scale"),I=b("sepia"),_=b("skew"),T=b("space"),k=b("translate"),S=()=>["auto","contain","none"],x=()=>["auto","hidden","clip","visible","scroll"],C=()=>["auto",L,t],F=()=>[L,t],j=()=>["",A,N],$=()=>["auto",R,L],H=()=>["bottom","center","left","left-bottom","left-top","right","right-bottom","right-top","top"],K=()=>["solid","dashed","dotted","double","none"],G=()=>["normal","multiply","screen","overlay","darken","lighten","color-dodge","color-burn","hard-light","soft-light","difference","exclusion","hue","saturation","color","luminosity"],W=()=>["start","end","center","between","around","evenly","stretch"],Q=()=>["","0",L],Z=()=>["auto","avoid","all","avoid-page","page","left","right","column"],J=()=>[R,L];return{cacheSize:500,separator:":",theme:{colors:[z],spacing:[A,N],blur:["none","",M,L],brightness:J(),borderColor:[e],borderRadius:["none","","full",M,L],borderSpacing:F(),borderWidth:j(),contrast:J(),grayscale:Q(),hueRotate:J(),invert:Q(),gap:F(),gradientColorStops:[e],gradientColorStopPositions:[P,N],inset:C(),margin:C(),opacity:J(),padding:F(),saturate:J(),scale:J(),sepia:Q(),skew:J(),space:F(),translate:F()},classGroups:{aspect:[{aspect:["auto","square","video",L]}],container:["container"],columns:[{columns:[M]}],"break-after":[{"break-after":Z()}],"break-before":[{"break-before":Z()}],"break-inside":[{"break-inside":["auto","avoid","avoid-page","avoid-column"]}],"box-decoration":[{"box-decoration":["slice","clone"]}],box:[{box:["border","content"]}],display:["block","inline-block","inline","flex","inline-flex","table","inline-table","table-caption","table-cell","table-column","table-column-group","table-footer-group","table-header-group","table-row-group","table-row","flow-root","grid","inline-grid","contents","list-item","hidden"],float:[{float:["right","left","none","start","end"]}],clear:[{clear:["left","right","both","none","start","end"]}],isolation:["isolate","isolation-auto"],"object-fit":[{object:["contain","cover","fill","none","scale-down"]}],"object-position":[{object:[...H(),L]}],overflow:[{overflow:x()}],"overflow-x":[{"overflow-x":x()}],"overflow-y":[{"overflow-y":x()}],overscroll:[{overscroll:S()}],"overscroll-x":[{"overscroll-x":S()}],"overscroll-y":[{"overscroll-y":S()}],position:["static","fixed","absolute","relative","sticky"],inset:[{inset:[g]}],"inset-x":[{"inset-x":[g]}],"inset-y":[{"inset-y":[g]}],start:[{start:[g]}],end:[{end:[g]}],top:[{top:[g]}],right:[{right:[g]}],bottom:[{bottom:[g]}],left:[{left:[g]}],visibility:["visible","invisible","collapse"],z:[{z:["auto",O,L]}],basis:[{basis:C()}],"flex-direction":[{flex:["row","row-reverse","col","col-reverse"]}],"flex-wrap":[{flex:["wrap","wrap-reverse","nowrap"]}],flex:[{flex:["1","auto","initial","none",L]}],grow:[{grow:Q()}],shrink:[{shrink:Q()}],order:[{order:["first","last","none",O,L]}],"grid-cols":[{"grid-cols":[z]}],"col-start-end":[{col:["auto",{span:["full",O,L]},L]}],"col-start":[{"col-start":$()}],"col-end":[{"col-end":$()}],"grid-rows":[{"grid-rows":[z]}],"row-start-end":[{row:["auto",{span:[O,L]},L]}],"row-start":[{"row-start":$()}],"row-end":[{"row-end":$()}],"grid-flow":[{"grid-flow":["row","col","dense","row-dense","col-dense"]}],"auto-cols":[{"auto-cols":["auto","min","max","fr",L]}],"auto-rows":[{"auto-rows":["auto","min","max","fr",L]}],gap:[{gap:[d]}],"gap-x":[{"gap-x":[d]}],"gap-y":[{"gap-y":[d]}],"justify-content":[{justify:["normal",...W()]}],"justify-items":[{"justify-items":["start","end","center","stretch"]}],"justify-self":[{"justify-self":["auto","start","end","center","stretch"]}],"align-content":[{content:["normal",...W(),"baseline"]}],"align-items":[{items:["start","end","center","baseline","stretch"]}],"align-self":[{self:["auto","start","end","center","stretch","baseline"]}],"place-content":[{"place-content":[...W(),"baseline"]}],"place-items":[{"place-items":["start","end","center","baseline","stretch"]}],"place-self":[{"place-self":["auto","start","end","center","stretch"]}],p:[{p:[v]}],px:[{px:[v]}],py:[{py:[v]}],ps:[{ps:[v]}],pe:[{pe:[v]}],pt:[{pt:[v]}],pr:[{pr:[v]}],pb:[{pb:[v]}],pl:[{pl:[v]}],m:[{m:[m]}],mx:[{mx:[m]}],my:[{my:[m]}],ms:[{ms:[m]}],me:[{me:[m]}],mt:[{mt:[m]}],mr:[{mr:[m]}],mb:[{mb:[m]}],ml:[{ml:[m]}],"space-x":[{"space-x":[T]}],"space-x-reverse":["space-x-reverse"],"space-y":[{"space-y":[T]}],"space-y-reverse":["space-y-reverse"],w:[{w:["auto","min","max","fit","svw","lvw","dvw",L,t]}],"min-w":[{"min-w":[L,t,"min","max","fit"]}],"max-w":[{"max-w":[L,t,"none","full","min","max","fit","prose",{screen:[M]},M]}],h:[{h:[L,t,"auto","min","max","fit","svh","lvh","dvh"]}],"min-h":[{"min-h":[L,t,"min","max","fit","svh","lvh","dvh"]}],"max-h":[{"max-h":[L,t,"min","max","fit","svh","lvh","dvh"]}],size:[{size:[L,t,"auto","min","max","fit"]}],"font-size":[{text:["base",M,N]}],"font-smoothing":["antialiased","subpixel-antialiased"],"font-style":["italic","not-italic"],"font-weight":[{font:["thin","extralight","light","normal","medium","semibold","bold","extrabold","black",D]}],"font-family":[{font:[z]}],"fvn-normal":["normal-nums"],"fvn-ordinal":["ordinal"],"fvn-slashed-zero":["slashed-zero"],"fvn-figure":["lining-nums","oldstyle-nums"],"fvn-spacing":["proportional-nums","tabular-nums"],"fvn-fraction":["diagonal-fractions","stacked-fractions"],tracking:[{tracking:["tighter","tight","normal","wide","wider","widest",L]}],"line-clamp":[{"line-clamp":["none",R,D]}],leading:[{leading:["none","tight","snug","normal","relaxed","loose",A,L]}],"list-image":[{"list-image":["none",L]}],"list-style-type":[{list:["none","disc","decimal",L]}],"list-style-position":[{list:["inside","outside"]}],"placeholder-color":[{placeholder:[e]}],"placeholder-opacity":[{"placeholder-opacity":[y]}],"text-alignment":[{text:["left","center","right","justify","start","end"]}],"text-color":[{text:[e]}],"text-opacity":[{"text-opacity":[y]}],"text-decoration":["underline","overline","line-through","no-underline"],"text-decoration-style":[{decoration:[...K(),"wavy"]}],"text-decoration-thickness":[{decoration:["auto","from-font",A,N]}],"underline-offset":[{"underline-offset":["auto",A,L]}],"text-decoration-color":[{decoration:[e]}],"text-transform":["uppercase","lowercase","capitalize","normal-case"],"text-overflow":["truncate","text-ellipsis","text-clip"],"text-wrap":[{text:["wrap","nowrap","balance","pretty"]}],indent:[{indent:F()}],"vertical-align":[{align:["baseline","top","middle","bottom","text-top","text-bottom","sub","super",L]}],whitespace:[{whitespace:["normal","nowrap","pre","pre-line","pre-wrap","break-spaces"]}],break:[{break:["normal","words","all","keep"]}],hyphens:[{hyphens:["none","manual","auto"]}],content:[{content:["none",L]}],"bg-attachment":[{bg:["fixed","local","scroll"]}],"bg-clip":[{"bg-clip":["border","padding","content","text"]}],"bg-opacity":[{"bg-opacity":[y]}],"bg-origin":[{"bg-origin":["border","padding","content"]}],"bg-position":[{bg:[...H(),U]}],"bg-repeat":[{bg:["no-repeat",{repeat:["","x","y","round","space"]}]}],"bg-size":[{bg:["auto","cover","contain",V]}],"bg-image":[{bg:["none",{"gradient-to":["t","tr","r","br","b","bl","l","tl"]},B]}],"bg-color":[{bg:[e]}],"gradient-from-pos":[{from:[p]}],"gradient-via-pos":[{via:[p]}],"gradient-to-pos":[{to:[p]}],"gradient-from":[{from:[f]}],"gradient-via":[{via:[f]}],"gradient-to":[{to:[f]}],rounded:[{rounded:[s]}],"rounded-s":[{"rounded-s":[s]}],"rounded-e":[{"rounded-e":[s]}],"rounded-t":[{"rounded-t":[s]}],"rounded-r":[{"rounded-r":[s]}],"rounded-b":[{"rounded-b":[s]}],"rounded-l":[{"rounded-l":[s]}],"rounded-ss":[{"rounded-ss":[s]}],"rounded-se":[{"rounded-se":[s]}],"rounded-ee":[{"rounded-ee":[s]}],"rounded-es":[{"rounded-es":[s]}],"rounded-tl":[{"rounded-tl":[s]}],"rounded-tr":[{"rounded-tr":[s]}],"rounded-br":[{"rounded-br":[s]}],"rounded-bl":[{"rounded-bl":[s]}],"border-w":[{border:[o]}],"border-w-x":[{"border-x":[o]}],"border-w-y":[{"border-y":[o]}],"border-w-s":[{"border-s":[o]}],"border-w-e":[{"border-e":[o]}],"border-w-t":[{"border-t":[o]}],"border-w-r":[{"border-r":[o]}],"border-w-b":[{"border-b":[o]}],"border-w-l":[{"border-l":[o]}],"border-opacity":[{"border-opacity":[y]}],"border-style":[{border:[...K(),"hidden"]}],"divide-x":[{"divide-x":[o]}],"divide-x-reverse":["divide-x-reverse"],"divide-y":[{"divide-y":[o]}],"divide-y-reverse":["divide-y-reverse"],"divide-opacity":[{"divide-opacity":[y]}],"divide-style":[{divide:K()}],"border-color":[{border:[i]}],"border-color-x":[{"border-x":[i]}],"border-color-y":[{"border-y":[i]}],"border-color-s":[{"border-s":[i]}],"border-color-e":[{"border-e":[i]}],"border-color-t":[{"border-t":[i]}],"border-color-r":[{"border-r":[i]}],"border-color-b":[{"border-b":[i]}],"border-color-l":[{"border-l":[i]}],"divide-color":[{divide:[i]}],"outline-style":[{outline:["",...K()]}],"outline-offset":[{"outline-offset":[A,L]}],"outline-w":[{outline:[A,N]}],"outline-color":[{outline:[e]}],"ring-w":[{ring:j()}],"ring-w-inset":["ring-inset"],"ring-color":[{ring:[e]}],"ring-opacity":[{"ring-opacity":[y]}],"ring-offset-w":[{"ring-offset":[A,N]}],"ring-offset-color":[{"ring-offset":[e]}],shadow:[{shadow:["","inner","none",M,q]}],"shadow-color":[{shadow:[z]}],opacity:[{opacity:[y]}],"mix-blend":[{"mix-blend":[...G(),"plus-lighter","plus-darker"]}],"bg-blend":[{"bg-blend":G()}],filter:[{filter:["","none"]}],blur:[{blur:[n]}],brightness:[{brightness:[r]}],contrast:[{contrast:[l]}],"drop-shadow":[{"drop-shadow":["","none",M,L]}],grayscale:[{grayscale:[u]}],"hue-rotate":[{"hue-rotate":[c]}],invert:[{invert:[h]}],saturate:[{saturate:[w]}],sepia:[{sepia:[I]}],"backdrop-filter":[{"backdrop-filter":["","none"]}],"backdrop-blur":[{"backdrop-blur":[n]}],"backdrop-brightness":[{"backdrop-brightness":[r]}],"backdrop-contrast":[{"backdrop-contrast":[l]}],"backdrop-grayscale":[{"backdrop-grayscale":[u]}],"backdrop-hue-rotate":[{"backdrop-hue-rotate":[c]}],"backdrop-invert":[{"backdrop-invert":[h]}],"backdrop-opacity":[{"backdrop-opacity":[y]}],"backdrop-saturate":[{"backdrop-saturate":[w]}],"backdrop-sepia":[{"backdrop-sepia":[I]}],"border-collapse":[{border:["collapse","separate"]}],"border-spacing":[{"border-spacing":[a]}],"border-spacing-x":[{"border-spacing-x":[a]}],"border-spacing-y":[{"border-spacing-y":[a]}],"table-layout":[{table:["auto","fixed"]}],caption:[{caption:["top","bottom"]}],transition:[{transition:["none","all","","colors","opacity","shadow","transform",L]}],duration:[{duration:J()}],ease:[{ease:["linear","in","out","in-out",L]}],delay:[{delay:J()}],animate:[{animate:["none","spin","ping","pulse","bounce",L]}],transform:[{transform:["","gpu","none"]}],scale:[{scale:[E]}],"scale-x":[{"scale-x":[E]}],"scale-y":[{"scale-y":[E]}],rotate:[{rotate:[O,L]}],"translate-x":[{"translate-x":[k]}],"translate-y":[{"translate-y":[k]}],"skew-x":[{"skew-x":[_]}],"skew-y":[{"skew-y":[_]}],"transform-origin":[{origin:["center","top","top-right","right","bottom-right","bottom","bottom-left","left","top-left",L]}],accent:[{accent:["auto",e]}],appearance:[{appearance:["none","auto"]}],cursor:[{cursor:["auto","default","pointer","wait","text","move","help","not-allowed","none","context-menu","progress","cell","crosshair","vertical-text","alias","copy","no-drop","grab","grabbing","all-scroll","col-resize","row-resize","n-resize","e-resize","s-resize","w-resize","ne-resize","nw-resize","se-resize","sw-resize","ew-resize","ns-resize","nesw-resize","nwse-resize","zoom-in","zoom-out",L]}],"caret-color":[{caret:[e]}],"pointer-events":[{"pointer-events":["none","auto"]}],resize:[{resize:["none","y","x",""]}],"scroll-behavior":[{scroll:["auto","smooth"]}],"scroll-m":[{"scroll-m":F()}],"scroll-mx":[{"scroll-mx":F()}],"scroll-my":[{"scroll-my":F()}],"scroll-ms":[{"scroll-ms":F()}],"scroll-me":[{"scroll-me":F()}],"scroll-mt":[{"scroll-mt":F()}],"scroll-mr":[{"scroll-mr":F()}],"scroll-mb":[{"scroll-mb":F()}],"scroll-ml":[{"scroll-ml":F()}],"scroll-p":[{"scroll-p":F()}],"scroll-px":[{"scroll-px":F()}],"scroll-py":[{"scroll-py":F()}],"scroll-ps":[{"scroll-ps":F()}],"scroll-pe":[{"scroll-pe":F()}],"scroll-pt":[{"scroll-pt":F()}],"scroll-pr":[{"scroll-pr":F()}],"scroll-pb":[{"scroll-pb":F()}],"scroll-pl":[{"scroll-pl":F()}],"snap-align":[{snap:["start","end","center","align-none"]}],"snap-stop":[{snap:["normal","always"]}],"snap-type":[{snap:["none","x","y","both"]}],"snap-strictness":[{snap:["mandatory","proximity"]}],touch:[{touch:["auto","none","manipulation"]}],"touch-x":[{"touch-pan":["x","left","right"]}],"touch-y":[{"touch-pan":["y","up","down"]}],"touch-pz":["touch-pinch-zoom"],select:[{select:["none","text","all","auto"]}],"will-change":[{"will-change":["auto","scroll","contents","transform",L]}],fill:[{fill:[e,"none"]}],"stroke-w":[{stroke:[A,N,D]}],stroke:[{stroke:[e,"none"]}],sr:["sr-only","not-sr-only"],"forced-color-adjust":[{"forced-color-adjust":["auto","none"]}]},conflictingClassGroups:{overflow:["overflow-x","overflow-y"],overscroll:["overscroll-x","overscroll-y"],inset:["inset-x","inset-y","start","end","top","right","bottom","left"],"inset-x":["right","left"],"inset-y":["top","bottom"],flex:["basis","grow","shrink"],gap:["gap-x","gap-y"],p:["px","py","ps","pe","pt","pr","pb","pl"],px:["pr","pl"],py:["pt","pb"],m:["mx","my","ms","me","mt","mr","mb","ml"],mx:["mr","ml"],my:["mt","mb"],size:["w","h"],"font-size":["leading"],"fvn-normal":["fvn-ordinal","fvn-slashed-zero","fvn-figure","fvn-spacing","fvn-fraction"],"fvn-ordinal":["fvn-normal"],"fvn-slashed-zero":["fvn-normal"],"fvn-figure":["fvn-normal"],"fvn-spacing":["fvn-normal"],"fvn-fraction":["fvn-normal"],"line-clamp":["display","overflow"],rounded:["rounded-s","rounded-e","rounded-t","rounded-r","rounded-b","rounded-l","rounded-ss","rounded-se","rounded-ee","rounded-es","rounded-tl","rounded-tr","rounded-br","rounded-bl"],"rounded-s":["rounded-ss","rounded-es"],"rounded-e":["rounded-se","rounded-ee"],"rounded-t":["rounded-tl","rounded-tr"],"rounded-r":["rounded-tr","rounded-br"],"rounded-b":["rounded-br","rounded-bl"],"rounded-l":["rounded-tl","rounded-bl"],"border-spacing":["border-spacing-x","border-spacing-y"],"border-w":["border-w-s","border-w-e","border-w-t","border-w-r","border-w-b","border-w-l"],"border-w-x":["border-w-r","border-w-l"],"border-w-y":["border-w-t","border-w-b"],"border-color":["border-color-s","border-color-e","border-color-t","border-color-r","border-color-b","border-color-l"],"border-color-x":["border-color-r","border-color-l"],"border-color-y":["border-color-t","border-color-b"],"scroll-m":["scroll-mx","scroll-my","scroll-ms","scroll-me","scroll-mt","scroll-mr","scroll-mb","scroll-ml"],"scroll-mx":["scroll-mr","scroll-ml"],"scroll-my":["scroll-mt","scroll-mb"],"scroll-p":["scroll-px","scroll-py","scroll-ps","scroll-pe","scroll-pt","scroll-pr","scroll-pb","scroll-pl"],"scroll-px":["scroll-pr","scroll-pl"],"scroll-py":["scroll-pt","scroll-pb"],touch:["touch-x","touch-y","touch-pz"],"touch-x":["touch"],"touch-y":["touch"],"touch-pz":["touch"]},conflictingClassGroupModifiers:{"font-size":["leading"]}}});function Z(){for(var e=arguments.length,t=Array(e),n=0;n<e;n++)t[n]=arguments[n];return Q(function(){for(var e,t,n=0,r="",i=arguments.length;n<i;n++)(e=arguments[n])&&(t=function e(t){var n,r,i="";if("string"==typeof t||"number"==typeof t)i+=t;else if("object"==typeof t){if(Array.isArray(t)){var s=t.length;for(n=0;n<s;n++)t[n]&&(r=e(t[n]))&&(i&&(i+=" "),i+=r)}else for(r in t)t[r]&&(i&&(i+=" "),i+=r)}return i}(e))&&(r&&(r+=" "),r+=t);return r}(t))}},8960:function(e){!function(){var t={229:function(e){var t,n,r,i=e.exports={};function s(){throw Error("setTimeout has not been defined")}function a(){throw Error("clearTimeout has not been defined")}function o(e){if(t===setTimeout)return setTimeout(e,0);if((t===s||!t)&&setTimeout)return t=setTimeout,setTimeout(e,0);try{return t(e,0)}catch(n){try{return t.call(null,e,0)}catch(n){return t.call(this,e,0)}}}!function(){try{t="function"==typeof setTimeout?setTimeout:s}catch(e){t=s}try{n="function"==typeof clearTimeout?clearTimeout:a}catch(e){n=a}}();var l=[],u=!1,c=-1;function h(){u&&r&&(u=!1,r.length?l=r.concat(l):c=-1,l.length&&d())}function d(){if(!u){var e=o(h);u=!0;for(var t=l.length;t;){for(r=l,l=[];++c<t;)r&&r[c].run();c=-1,t=l.length}r=null,u=!1,function(e){if(n===clearTimeout)return clearTimeout(e);if((n===a||!n)&&clearTimeout)return n=clearTimeout,clearTimeout(e);try{n(e)}catch(t){try{return n.call(null,e)}catch(t){return n.call(this,e)}}}(e)}}function f(e,t){this.fun=e,this.array=t}function p(){}i.nextTick=function(e){var t=Array(arguments.length-1);if(arguments.length>1)for(var n=1;n<arguments.length;n++)t[n-1]=arguments[n];l.push(new f(e,t)),1!==l.length||u||o(d)},f.prototype.run=function(){this.fun.apply(null,this.array)},i.title="browser",i.browser=!0,i.env={},i.argv=[],i.version="",i.versions={},i.on=p,i.addListener=p,i.once=p,i.off=p,i.removeListener=p,i.removeAllListeners=p,i.emit=p,i.prependListener=p,i.prependOnceListener=p,i.listeners=function(e){return[]},i.binding=function(e){throw Error("process.binding is not supported")},i.cwd=function(){return"/"},i.chdir=function(e){throw Error("process.chdir is not supported")},i.umask=function(){return 0}}},n={};function r(e){var i=n[e];if(void 0!==i)return i.exports;var s=n[e]={exports:{}},a=!0;try{t[e](s,s.exports,r),a=!1}finally{a&&delete n[e]}return s.exports}r.ab="//";var i=r(229);e.exports=i}()},622:function(e,t,n){"use strict";/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var r=n(2265),i=Symbol.for("react.element"),s=Symbol.for("react.fragment"),a=Object.prototype.hasOwnProperty,o=r.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,l={key:!0,ref:!0,__self:!0,__source:!0};function u(e,t,n){var r,s={},u=null,c=null;for(r in void 0!==n&&(u=""+n),void 0!==t.key&&(u=""+t.key),void 0!==t.ref&&(c=t.ref),t)a.call(t,r)&&!l.hasOwnProperty(r)&&(s[r]=t[r]);if(e&&e.defaultProps)for(r in t=e.defaultProps)void 0===s[r]&&(s[r]=t[r]);return{$$typeof:i,type:e,key:u,ref:c,props:s,_owner:o.current}}t.Fragment=s,t.jsx=u,t.jsxs=u},7437:function(e,t,n){"use strict";e.exports=n(622)},4033:function(e,t,n){e.exports=n(8165)},3991:function(e,t,n){"use strict";let r,i;n.d(t,{Jn:function(){return P},qX:function(){return R},Xd:function(){return N},Mq:function(){return M},C6:function(){return F},ZF:function(){return L},KN:function(){return V}});var s,a=n(5538),o=n(6914),l=n(8745);let u=(e,t)=>t.some(t=>e instanceof t),c=new WeakMap,h=new WeakMap,d=new WeakMap,f=new WeakMap,p=new WeakMap,g={get(e,t,n){if(e instanceof IDBTransaction){if("done"===t)return h.get(e);if("objectStoreNames"===t)return e.objectStoreNames||d.get(e);if("store"===t)return n.objectStoreNames[1]?void 0:n.objectStore(n.objectStoreNames[0])}return m(e[t])},set:(e,t,n)=>(e[t]=n,!0),has:(e,t)=>e instanceof IDBTransaction&&("done"===t||"store"===t)||t in e};function m(e){var t;if(e instanceof IDBRequest)return function(e){let t=new Promise((t,n)=>{let r=()=>{e.removeEventListener("success",i),e.removeEventListener("error",s)},i=()=>{t(m(e.result)),r()},s=()=>{n(e.error),r()};e.addEventListener("success",i),e.addEventListener("error",s)});return t.then(t=>{t instanceof IDBCursor&&c.set(t,e)}).catch(()=>{}),p.set(t,e),t}(e);if(f.has(e))return f.get(e);let n="function"==typeof(t=e)?t!==IDBDatabase.prototype.transaction||"objectStoreNames"in IDBTransaction.prototype?(i||(i=[IDBCursor.prototype.advance,IDBCursor.prototype.continue,IDBCursor.prototype.continuePrimaryKey])).includes(t)?function(...e){return t.apply(y(this),e),m(c.get(this))}:function(...e){return m(t.apply(y(this),e))}:function(e,...n){let r=t.call(y(this),e,...n);return d.set(r,e.sort?e.sort():[e]),m(r)}:(t instanceof IDBTransaction&&function(e){if(h.has(e))return;let t=new Promise((t,n)=>{let r=()=>{e.removeEventListener("complete",i),e.removeEventListener("error",s),e.removeEventListener("abort",s)},i=()=>{t(),r()},s=()=>{n(e.error||new DOMException("AbortError","AbortError")),r()};e.addEventListener("complete",i),e.addEventListener("error",s),e.addEventListener("abort",s)});h.set(e,t)}(t),u(t,r||(r=[IDBDatabase,IDBObjectStore,IDBIndex,IDBCursor,IDBTransaction])))?new Proxy(t,g):t;return n!==e&&(f.set(e,n),p.set(n,e)),n}let y=e=>p.get(e),v=["get","getKey","getAll","getAllKeys","count"],w=["put","add","delete","clear"],b=new Map;function E(e,t){if(!(e instanceof IDBDatabase&&!(t in e)&&"string"==typeof t))return;if(b.get(t))return b.get(t);let n=t.replace(/FromIndex$/,""),r=t!==n,i=w.includes(n);if(!(n in(r?IDBIndex:IDBObjectStore).prototype)||!(i||v.includes(n)))return;let s=async function(e,...t){let s=this.transaction(e,i?"readwrite":"readonly"),a=s.store;return r&&(a=a.index(t.shift())),(await Promise.all([a[n](...t),i&&s.done]))[0]};return b.set(t,s),s}g={...s=g,get:(e,t,n)=>E(e,t)||s.get(e,t,n),has:(e,t)=>!!E(e,t)||s.has(e,t)};/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class I{constructor(e){this.container=e}getPlatformInfoString(){let e=this.container.getProviders();return e.map(e=>{if(!function(e){let t=e.getComponent();return(null==t?void 0:t.type)==="VERSION"}(e))return null;{let t=e.getImmediate();return`${t.library}/${t.version}`}}).filter(e=>e).join(" ")}}let _="@firebase/app",T="0.9.13",k=new o.Yd("@firebase/app"),S="[DEFAULT]",x={[_]:"fire-core","@firebase/app-compat":"fire-core-compat","@firebase/analytics":"fire-analytics","@firebase/analytics-compat":"fire-analytics-compat","@firebase/app-check":"fire-app-check","@firebase/app-check-compat":"fire-app-check-compat","@firebase/auth":"fire-auth","@firebase/auth-compat":"fire-auth-compat","@firebase/database":"fire-rtdb","@firebase/database-compat":"fire-rtdb-compat","@firebase/functions":"fire-fn","@firebase/functions-compat":"fire-fn-compat","@firebase/installations":"fire-iid","@firebase/installations-compat":"fire-iid-compat","@firebase/messaging":"fire-fcm","@firebase/messaging-compat":"fire-fcm-compat","@firebase/performance":"fire-perf","@firebase/performance-compat":"fire-perf-compat","@firebase/remote-config":"fire-rc","@firebase/remote-config-compat":"fire-rc-compat","@firebase/storage":"fire-gcs","@firebase/storage-compat":"fire-gcs-compat","@firebase/firestore":"fire-fst","@firebase/firestore-compat":"fire-fst-compat","fire-js":"fire-js",firebase:"fire-js-all"},C=new Map,A=new Map;function N(e){let t=e.name;if(A.has(t))return k.debug(`There were multiple attempts to register component ${t}.`),!1;for(let n of(A.set(t,e),C.values()))!function(e,t){try{e.container.addComponent(t)}catch(n){k.debug(`Component ${t.name} failed to register with FirebaseApp ${e.name}`,n)}}(n,e);return!0}function R(e,t){let n=e.container.getProvider("heartbeat").getImmediate({optional:!0});return n&&n.triggerHeartbeat(),e.container.getProvider(t)}let D=new l.LL("app","Firebase",{"no-app":"No Firebase App '{$appName}' has been created - call initializeApp() first","bad-app-name":"Illegal App name: '{$appName}","duplicate-app":"Firebase App named '{$appName}' already exists with different options or config","app-deleted":"Firebase App named '{$appName}' already deleted","no-options":"Need to provide options, when not being deployed to hosting via source.","invalid-app-argument":"firebase.{$appName}() takes either no argument or a Firebase App instance.","invalid-log-argument":"First argument to `onLog` must be null or a function.","idb-open":"Error thrown when opening IndexedDB. Original error: {$originalErrorMessage}.","idb-get":"Error thrown when reading from IndexedDB. Original error: {$originalErrorMessage}.","idb-set":"Error thrown when writing to IndexedDB. Original error: {$originalErrorMessage}.","idb-delete":"Error thrown when deleting from IndexedDB. Original error: {$originalErrorMessage}."});/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class O{constructor(e,t,n){this._isDeleted=!1,this._options=Object.assign({},e),this._config=Object.assign({},t),this._name=t.name,this._automaticDataCollectionEnabled=t.automaticDataCollectionEnabled,this._container=n,this.container.addComponent(new a.wA("app",()=>this,"PUBLIC"))}get automaticDataCollectionEnabled(){return this.checkDestroyed(),this._automaticDataCollectionEnabled}set automaticDataCollectionEnabled(e){this.checkDestroyed(),this._automaticDataCollectionEnabled=e}get name(){return this.checkDestroyed(),this._name}get options(){return this.checkDestroyed(),this._options}get config(){return this.checkDestroyed(),this._config}get container(){return this._container}get isDeleted(){return this._isDeleted}set isDeleted(e){this._isDeleted=e}checkDestroyed(){if(this.isDeleted)throw D.create("app-deleted",{appName:this._name})}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let P="9.23.0";function L(e,t={}){let n=e;if("object"!=typeof t){let e=t;t={name:e}}let r=Object.assign({name:S,automaticDataCollectionEnabled:!1},t),i=r.name;if("string"!=typeof i||!i)throw D.create("bad-app-name",{appName:String(i)});if(n||(n=(0,l.aH)()),!n)throw D.create("no-options");let s=C.get(i);if(s){if((0,l.vZ)(n,s.options)&&(0,l.vZ)(r,s.config))return s;throw D.create("duplicate-app",{appName:i})}let o=new a.H0(i);for(let e of A.values())o.addComponent(e);let u=new O(n,r,o);return C.set(i,u),u}function M(e=S){let t=C.get(e);if(!t&&e===S&&(0,l.aH)())return L();if(!t)throw D.create("no-app",{appName:e});return t}function F(){return Array.from(C.values())}function V(e,t,n){var r;let i=null!==(r=x[e])&&void 0!==r?r:e;n&&(i+=`-${n}`);let s=i.match(/\s|\//),o=t.match(/\s|\//);if(s||o){let e=[`Unable to register library "${i}" with version "${t}":`];s&&e.push(`library name "${i}" contains illegal characters (whitespace or "/")`),s&&o&&e.push("and"),o&&e.push(`version name "${t}" contains illegal characters (whitespace or "/")`),k.warn(e.join(" "));return}N(new a.wA(`${i}-version`,()=>({library:i,version:t}),"VERSION"))}let U="firebase-heartbeat-store",j=null;function B(){return j||(j=(function(e,t,{blocked:n,upgrade:r,blocking:i,terminated:s}={}){let a=indexedDB.open(e,1),o=m(a);return r&&a.addEventListener("upgradeneeded",e=>{r(m(a.result),e.oldVersion,e.newVersion,m(a.transaction),e)}),n&&a.addEventListener("blocked",e=>n(e.oldVersion,e.newVersion,e)),o.then(e=>{s&&e.addEventListener("close",()=>s()),i&&e.addEventListener("versionchange",e=>i(e.oldVersion,e.newVersion,e))}).catch(()=>{}),o})("firebase-heartbeat-database",0,{upgrade:(e,t)=>{0===t&&e.createObjectStore(U)}}).catch(e=>{throw D.create("idb-open",{originalErrorMessage:e.message})})),j}async function q(e){try{let t=await B(),n=await t.transaction(U).objectStore(U).get($(e));return n}catch(e){if(e instanceof l.ZR)k.warn(e.message);else{let t=D.create("idb-get",{originalErrorMessage:null==e?void 0:e.message});k.warn(t.message)}}}async function z(e,t){try{let n=await B(),r=n.transaction(U,"readwrite"),i=r.objectStore(U);await i.put(t,$(e)),await r.done}catch(e){if(e instanceof l.ZR)k.warn(e.message);else{let t=D.create("idb-set",{originalErrorMessage:null==e?void 0:e.message});k.warn(t.message)}}}function $(e){return`${e.name}!${e.options.appId}`}class H{constructor(e){this.container=e,this._heartbeatsCache=null;let t=this.container.getProvider("app").getImmediate();this._storage=new G(t),this._heartbeatsCachePromise=this._storage.read().then(e=>(this._heartbeatsCache=e,e))}async triggerHeartbeat(){let e=this.container.getProvider("platform-logger").getImmediate(),t=e.getPlatformInfoString(),n=K();return(null===this._heartbeatsCache&&(this._heartbeatsCache=await this._heartbeatsCachePromise),this._heartbeatsCache.lastSentHeartbeatDate===n||this._heartbeatsCache.heartbeats.some(e=>e.date===n))?void 0:(this._heartbeatsCache.heartbeats.push({date:n,agent:t}),this._heartbeatsCache.heartbeats=this._heartbeatsCache.heartbeats.filter(e=>{let t=new Date(e.date).valueOf(),n=Date.now();return n-t<=2592e6}),this._storage.overwrite(this._heartbeatsCache))}async getHeartbeatsHeader(){if(null===this._heartbeatsCache&&await this._heartbeatsCachePromise,null===this._heartbeatsCache||0===this._heartbeatsCache.heartbeats.length)return"";let e=K(),{heartbeatsToSend:t,unsentEntries:n}=function(e,t=1024){let n=[],r=e.slice();for(let i of e){let e=n.find(e=>e.agent===i.agent);if(e){if(e.dates.push(i.date),W(n)>t){e.dates.pop();break}}else if(n.push({agent:i.agent,dates:[i.date]}),W(n)>t){n.pop();break}r=r.slice(1)}return{heartbeatsToSend:n,unsentEntries:r}}(this._heartbeatsCache.heartbeats),r=(0,l.L)(JSON.stringify({version:2,heartbeats:t}));return this._heartbeatsCache.lastSentHeartbeatDate=e,n.length>0?(this._heartbeatsCache.heartbeats=n,await this._storage.overwrite(this._heartbeatsCache)):(this._heartbeatsCache.heartbeats=[],this._storage.overwrite(this._heartbeatsCache)),r}}function K(){let e=new Date;return e.toISOString().substring(0,10)}class G{constructor(e){this.app=e,this._canUseIndexedDBPromise=this.runIndexedDBEnvironmentCheck()}async runIndexedDBEnvironmentCheck(){return!!(0,l.hl)()&&(0,l.eu)().then(()=>!0).catch(()=>!1)}async read(){let e=await this._canUseIndexedDBPromise;if(!e)return{heartbeats:[]};{let e=await q(this.app);return e||{heartbeats:[]}}}async overwrite(e){var t;let n=await this._canUseIndexedDBPromise;if(n){let n=await this.read();return z(this.app,{lastSentHeartbeatDate:null!==(t=e.lastSentHeartbeatDate)&&void 0!==t?t:n.lastSentHeartbeatDate,heartbeats:e.heartbeats})}}async add(e){var t;let n=await this._canUseIndexedDBPromise;if(n){let n=await this.read();return z(this.app,{lastSentHeartbeatDate:null!==(t=e.lastSentHeartbeatDate)&&void 0!==t?t:n.lastSentHeartbeatDate,heartbeats:[...n.heartbeats,...e.heartbeats]})}}}function W(e){return(0,l.L)(JSON.stringify({version:2,heartbeats:e})).length}N(new a.wA("platform-logger",e=>new I(e),"PRIVATE")),N(new a.wA("heartbeat",e=>new H(e),"PRIVATE")),V(_,T,""),V(_,T,"esm2017"),V("fire-js","")},5538:function(e,t,n){"use strict";n.d(t,{H0:function(){return o},wA:function(){return i}});var r=n(8745);class i{constructor(e,t,n){this.name=e,this.instanceFactory=t,this.type=n,this.multipleInstances=!1,this.serviceProps={},this.instantiationMode="LAZY",this.onInstanceCreated=null}setInstantiationMode(e){return this.instantiationMode=e,this}setMultipleInstances(e){return this.multipleInstances=e,this}setServiceProps(e){return this.serviceProps=e,this}setInstanceCreatedCallback(e){return this.onInstanceCreated=e,this}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let s="[DEFAULT]";/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class a{constructor(e,t){this.name=e,this.container=t,this.component=null,this.instances=new Map,this.instancesDeferred=new Map,this.instancesOptions=new Map,this.onInitCallbacks=new Map}get(e){let t=this.normalizeInstanceIdentifier(e);if(!this.instancesDeferred.has(t)){let e=new r.BH;if(this.instancesDeferred.set(t,e),this.isInitialized(t)||this.shouldAutoInitialize())try{let n=this.getOrInitializeService({instanceIdentifier:t});n&&e.resolve(n)}catch(e){}}return this.instancesDeferred.get(t).promise}getImmediate(e){var t;let n=this.normalizeInstanceIdentifier(null==e?void 0:e.identifier),r=null!==(t=null==e?void 0:e.optional)&&void 0!==t&&t;if(this.isInitialized(n)||this.shouldAutoInitialize())try{return this.getOrInitializeService({instanceIdentifier:n})}catch(e){if(r)return null;throw e}else{if(r)return null;throw Error(`Service ${this.name} is not available`)}}getComponent(){return this.component}setComponent(e){if(e.name!==this.name)throw Error(`Mismatching Component ${e.name} for Provider ${this.name}.`);if(this.component)throw Error(`Component for ${this.name} has already been provided`);if(this.component=e,this.shouldAutoInitialize()){if("EAGER"===e.instantiationMode)try{this.getOrInitializeService({instanceIdentifier:s})}catch(e){}for(let[e,t]of this.instancesDeferred.entries()){let n=this.normalizeInstanceIdentifier(e);try{let e=this.getOrInitializeService({instanceIdentifier:n});t.resolve(e)}catch(e){}}}}clearInstance(e=s){this.instancesDeferred.delete(e),this.instancesOptions.delete(e),this.instances.delete(e)}async delete(){let e=Array.from(this.instances.values());await Promise.all([...e.filter(e=>"INTERNAL"in e).map(e=>e.INTERNAL.delete()),...e.filter(e=>"_delete"in e).map(e=>e._delete())])}isComponentSet(){return null!=this.component}isInitialized(e=s){return this.instances.has(e)}getOptions(e=s){return this.instancesOptions.get(e)||{}}initialize(e={}){let{options:t={}}=e,n=this.normalizeInstanceIdentifier(e.instanceIdentifier);if(this.isInitialized(n))throw Error(`${this.name}(${n}) has already been initialized`);if(!this.isComponentSet())throw Error(`Component ${this.name} has not been registered yet`);let r=this.getOrInitializeService({instanceIdentifier:n,options:t});for(let[e,t]of this.instancesDeferred.entries()){let i=this.normalizeInstanceIdentifier(e);n===i&&t.resolve(r)}return r}onInit(e,t){var n;let r=this.normalizeInstanceIdentifier(t),i=null!==(n=this.onInitCallbacks.get(r))&&void 0!==n?n:new Set;i.add(e),this.onInitCallbacks.set(r,i);let s=this.instances.get(r);return s&&e(s,r),()=>{i.delete(e)}}invokeOnInitCallbacks(e,t){let n=this.onInitCallbacks.get(t);if(n)for(let r of n)try{r(e,t)}catch(e){}}getOrInitializeService({instanceIdentifier:e,options:t={}}){let n=this.instances.get(e);if(!n&&this.component&&(n=this.component.instanceFactory(this.container,{instanceIdentifier:e===s?void 0:e,options:t}),this.instances.set(e,n),this.instancesOptions.set(e,t),this.invokeOnInitCallbacks(n,e),this.component.onInstanceCreated))try{this.component.onInstanceCreated(this.container,e,n)}catch(e){}return n||null}normalizeInstanceIdentifier(e=s){return this.component?this.component.multipleInstances?e:s:e}shouldAutoInitialize(){return!!this.component&&"EXPLICIT"!==this.component.instantiationMode}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class o{constructor(e){this.name=e,this.providers=new Map}addComponent(e){let t=this.getProvider(e.name);if(t.isComponentSet())throw Error(`Component ${e.name} has already been registered with ${this.name}`);t.setComponent(e)}addOrOverwriteComponent(e){let t=this.getProvider(e.name);t.isComponentSet()&&this.providers.delete(e.name),this.addComponent(e)}getProvider(e){if(this.providers.has(e))return this.providers.get(e);let t=new a(e,this);return this.providers.set(e,t),t}getProviders(){return Array.from(this.providers.values())}}},6914:function(e,t,n){"use strict";var r,i;n.d(t,{Yd:function(){return c},in:function(){return r}});/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let s=[];(i=r||(r={}))[i.DEBUG=0]="DEBUG",i[i.VERBOSE=1]="VERBOSE",i[i.INFO=2]="INFO",i[i.WARN=3]="WARN",i[i.ERROR=4]="ERROR",i[i.SILENT=5]="SILENT";let a={debug:r.DEBUG,verbose:r.VERBOSE,info:r.INFO,warn:r.WARN,error:r.ERROR,silent:r.SILENT},o=r.INFO,l={[r.DEBUG]:"log",[r.VERBOSE]:"log",[r.INFO]:"info",[r.WARN]:"warn",[r.ERROR]:"error"},u=(e,t,...n)=>{if(t<e.logLevel)return;let r=new Date().toISOString(),i=l[t];if(i)console[i](`[${r}]  ${e.name}:`,...n);else throw Error(`Attempted to log a message with an invalid logType (value: ${t})`)};class c{constructor(e){this.name=e,this._logLevel=o,this._logHandler=u,this._userLogHandler=null,s.push(this)}get logLevel(){return this._logLevel}set logLevel(e){if(!(e in r))throw TypeError(`Invalid value "${e}" assigned to \`logLevel\``);this._logLevel=e}setLogLevel(e){this._logLevel="string"==typeof e?a[e]:e}get logHandler(){return this._logHandler}set logHandler(e){if("function"!=typeof e)throw TypeError("Value assigned to `logHandler` must be a function");this._logHandler=e}get userLogHandler(){return this._userLogHandler}set userLogHandler(e){this._userLogHandler=e}debug(...e){this._userLogHandler&&this._userLogHandler(this,r.DEBUG,...e),this._logHandler(this,r.DEBUG,...e)}log(...e){this._userLogHandler&&this._userLogHandler(this,r.VERBOSE,...e),this._logHandler(this,r.VERBOSE,...e)}info(...e){this._userLogHandler&&this._userLogHandler(this,r.INFO,...e),this._logHandler(this,r.INFO,...e)}warn(...e){this._userLogHandler&&this._userLogHandler(this,r.WARN,...e),this._logHandler(this,r.WARN,...e)}error(...e){this._userLogHandler&&this._userLogHandler(this,r.ERROR,...e),this._logHandler(this,r.ERROR,...e)}}},3778:function(e,t,n){"use strict";n.d(t,{hJ:function(){return eq},v0:function(){return t6},Aj:function(){return e0},e5:function(){return eY},rh:function(){return tE},w7:function(){return e1}});var r,i=n(8745),s=n(3991);function a(e,t){var n={};for(var r in e)Object.prototype.hasOwnProperty.call(e,r)&&0>t.indexOf(r)&&(n[r]=e[r]);if(null!=e&&"function"==typeof Object.getOwnPropertySymbols)for(var i=0,r=Object.getOwnPropertySymbols(e);i<r.length;i++)0>t.indexOf(r[i])&&Object.prototype.propertyIsEnumerable.call(e,r[i])&&(n[r[i]]=e[r[i]]);return n}"function"==typeof SuppressedError&&SuppressedError;var o=n(6914),l=n(5538);function u(){return{"dependent-sdk-initialized-before-auth":"Another Firebase SDK was initialized and is trying to use Auth before Auth is initialized. Please be sure to call `initializeAuth` or `getAuth` before starting any other Firebase SDK."}}let c=new i.LL("auth","Firebase",u()),h=new o.Yd("@firebase/auth");function d(e,...t){h.logLevel<=o.in.ERROR&&h.error(`Auth (${s.Jn}): ${e}`,...t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function f(e,...t){throw m(e,...t)}function p(e,...t){return m(e,...t)}function g(e,t,n){let r=Object.assign(Object.assign({},u()),{[t]:n}),s=new i.LL("auth","Firebase",r);return s.create(t,{appName:e.name})}function m(e,...t){if("string"!=typeof e){let n=t[0],r=[...t.slice(1)];return r[0]&&(r[0].appName=e.name),e._errorFactory.create(n,...r)}return c.create(e,...t)}function y(e,t,...n){if(!e)throw m(t,...n)}function v(e){let t="INTERNAL ASSERTION FAILED: "+e;throw d(t),Error(t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function w(){var e;return"undefined"!=typeof self&&(null===(e=self.location)||void 0===e?void 0:e.href)||""}function b(){var e;return"undefined"!=typeof self&&(null===(e=self.location)||void 0===e?void 0:e.protocol)||null}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class E{constructor(e,t){this.shortDelay=e,this.longDelay=t,t>e||v("Short delay should be less than long delay!"),this.isMobile=(0,i.uI)()||(0,i.b$)()}get(){return!("undefined"!=typeof navigator&&navigator&&"onLine"in navigator&&"boolean"==typeof navigator.onLine&&("http:"===b()||"https:"===b()||(0,i.ru)()||"connection"in navigator))||navigator.onLine?this.isMobile?this.longDelay:this.shortDelay:Math.min(5e3,this.shortDelay)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function I(e,t){e.emulator||v("Emulator should always be set here");let{url:n}=e.emulator;return t?`${n}${t.startsWith("/")?t.slice(1):t}`:n}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class _{static initialize(e,t,n){this.fetchImpl=e,t&&(this.headersImpl=t),n&&(this.responseImpl=n)}static fetch(){return this.fetchImpl?this.fetchImpl:"undefined"!=typeof self&&"fetch"in self?self.fetch:void v("Could not find fetch implementation, make sure you call FetchProvider.initialize() with an appropriate polyfill")}static headers(){return this.headersImpl?this.headersImpl:"undefined"!=typeof self&&"Headers"in self?self.Headers:void v("Could not find Headers implementation, make sure you call FetchProvider.initialize() with an appropriate polyfill")}static response(){return this.responseImpl?this.responseImpl:"undefined"!=typeof self&&"Response"in self?self.Response:void v("Could not find Response implementation, make sure you call FetchProvider.initialize() with an appropriate polyfill")}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let T={CREDENTIAL_MISMATCH:"custom-token-mismatch",MISSING_CUSTOM_TOKEN:"internal-error",INVALID_IDENTIFIER:"invalid-email",MISSING_CONTINUE_URI:"internal-error",INVALID_PASSWORD:"wrong-password",MISSING_PASSWORD:"missing-password",EMAIL_EXISTS:"email-already-in-use",PASSWORD_LOGIN_DISABLED:"operation-not-allowed",INVALID_IDP_RESPONSE:"invalid-credential",INVALID_PENDING_TOKEN:"invalid-credential",FEDERATED_USER_ID_ALREADY_LINKED:"credential-already-in-use",MISSING_REQ_TYPE:"internal-error",EMAIL_NOT_FOUND:"user-not-found",RESET_PASSWORD_EXCEED_LIMIT:"too-many-requests",EXPIRED_OOB_CODE:"expired-action-code",INVALID_OOB_CODE:"invalid-action-code",MISSING_OOB_CODE:"internal-error",CREDENTIAL_TOO_OLD_LOGIN_AGAIN:"requires-recent-login",INVALID_ID_TOKEN:"invalid-user-token",TOKEN_EXPIRED:"user-token-expired",USER_NOT_FOUND:"user-token-expired",TOO_MANY_ATTEMPTS_TRY_LATER:"too-many-requests",INVALID_CODE:"invalid-verification-code",INVALID_SESSION_INFO:"invalid-verification-id",INVALID_TEMPORARY_PROOF:"invalid-credential",MISSING_SESSION_INFO:"missing-verification-id",SESSION_EXPIRED:"code-expired",MISSING_ANDROID_PACKAGE_NAME:"missing-android-pkg-name",UNAUTHORIZED_DOMAIN:"unauthorized-continue-uri",INVALID_OAUTH_CLIENT_ID:"invalid-oauth-client-id",ADMIN_ONLY_OPERATION:"admin-restricted-operation",INVALID_MFA_PENDING_CREDENTIAL:"invalid-multi-factor-session",MFA_ENROLLMENT_NOT_FOUND:"multi-factor-info-not-found",MISSING_MFA_ENROLLMENT_ID:"missing-multi-factor-info",MISSING_MFA_PENDING_CREDENTIAL:"missing-multi-factor-session",SECOND_FACTOR_EXISTS:"second-factor-already-in-use",SECOND_FACTOR_LIMIT_EXCEEDED:"maximum-second-factor-count-exceeded",BLOCKING_FUNCTION_ERROR_RESPONSE:"internal-error",RECAPTCHA_NOT_ENABLED:"recaptcha-not-enabled",MISSING_RECAPTCHA_TOKEN:"missing-recaptcha-token",INVALID_RECAPTCHA_TOKEN:"invalid-recaptcha-token",INVALID_RECAPTCHA_ACTION:"invalid-recaptcha-action",MISSING_CLIENT_TYPE:"missing-client-type",MISSING_RECAPTCHA_VERSION:"missing-recaptcha-version",INVALID_RECAPTCHA_VERSION:"invalid-recaptcha-version",INVALID_REQ_TYPE:"invalid-req-type"},k=new E(3e4,6e4);function S(e,t){return e.tenantId&&!t.tenantId?Object.assign(Object.assign({},t),{tenantId:e.tenantId}):t}async function x(e,t,n,r,s={}){return C(e,s,async()=>{let s={},a={};r&&("GET"===t?a=r:s={body:JSON.stringify(r)});let o=(0,i.xO)(Object.assign({key:e.config.apiKey},a)).slice(1),l=await e._getAdditionalHeaders();return l["Content-Type"]="application/json",e.languageCode&&(l["X-Firebase-Locale"]=e.languageCode),_.fetch()(N(e,e.config.apiHost,n,o),Object.assign({method:t,headers:l,referrerPolicy:"no-referrer"},s))})}async function C(e,t,n){e._canInitEmulator=!1;let r=Object.assign(Object.assign({},T),t);try{let t=new R(e),i=await Promise.race([n(),t.promise]);t.clearNetworkTimeout();let s=await i.json();if("needConfirmation"in s)throw D(e,"account-exists-with-different-credential",s);if(i.ok&&!("errorMessage"in s))return s;{let t=i.ok?s.errorMessage:s.error.message,[n,a]=t.split(" : ");if("FEDERATED_USER_ID_ALREADY_LINKED"===n)throw D(e,"credential-already-in-use",s);if("EMAIL_EXISTS"===n)throw D(e,"email-already-in-use",s);if("USER_DISABLED"===n)throw D(e,"user-disabled",s);let o=r[n]||n.toLowerCase().replace(/[_\s]+/g,"-");if(a)throw g(e,o,a);f(e,o)}}catch(t){if(t instanceof i.ZR)throw t;f(e,"network-request-failed",{message:String(t)})}}async function A(e,t,n,r,i={}){let s=await x(e,t,n,r,i);return"mfaPendingCredential"in s&&f(e,"multi-factor-auth-required",{_serverResponse:s}),s}function N(e,t,n,r){let i=`${t}${n}?${r}`;return e.config.emulator?I(e.config,i):`${e.config.apiScheme}://${i}`}class R{constructor(e){this.auth=e,this.timer=null,this.promise=new Promise((e,t)=>{this.timer=setTimeout(()=>t(p(this.auth,"network-request-failed")),k.get())})}clearNetworkTimeout(){clearTimeout(this.timer)}}function D(e,t,n){let r={appName:e.name};n.email&&(r.email=n.email),n.phoneNumber&&(r.phoneNumber=n.phoneNumber);let i=p(e,t,r);return i.customData._tokenResponse=n,i}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function O(e,t){return x(e,"POST","/v1/accounts:delete",t)}async function P(e,t){return x(e,"POST","/v1/accounts:lookup",t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function L(e){if(e)try{let t=new Date(Number(e));if(!isNaN(t.getTime()))return t.toUTCString()}catch(e){}}async function M(e,t=!1){let n=(0,i.m9)(e),r=await n.getIdToken(t),s=V(r);y(s&&s.exp&&s.auth_time&&s.iat,n.auth,"internal-error");let a="object"==typeof s.firebase?s.firebase:void 0,o=null==a?void 0:a.sign_in_provider;return{claims:s,token:r,authTime:L(F(s.auth_time)),issuedAtTime:L(F(s.iat)),expirationTime:L(F(s.exp)),signInProvider:o||null,signInSecondFactor:(null==a?void 0:a.sign_in_second_factor)||null}}function F(e){return 1e3*Number(e)}function V(e){let[t,n,r]=e.split(".");if(void 0===t||void 0===n||void 0===r)return d("JWT malformed, contained fewer than 3 sections"),null;try{let e=(0,i.tV)(n);if(!e)return d("Failed to decode base64 JWT payload"),null;return JSON.parse(e)}catch(e){return d("Caught error parsing JWT payload as JSON",null==e?void 0:e.toString()),null}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function U(e,t,n=!1){if(n)return t;try{return await t}catch(t){throw t instanceof i.ZR&&function({code:e}){return"auth/user-disabled"===e||"auth/user-token-expired"===e}(t)&&e.auth.currentUser===e&&await e.auth.signOut(),t}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class j{constructor(e){this.user=e,this.isRunning=!1,this.timerId=null,this.errorBackoff=3e4}_start(){this.isRunning||(this.isRunning=!0,this.schedule())}_stop(){this.isRunning&&(this.isRunning=!1,null!==this.timerId&&clearTimeout(this.timerId))}getInterval(e){var t;if(e){let e=this.errorBackoff;return this.errorBackoff=Math.min(2*this.errorBackoff,96e4),e}{this.errorBackoff=3e4;let e=null!==(t=this.user.stsTokenManager.expirationTime)&&void 0!==t?t:0,n=e-Date.now()-3e5;return Math.max(0,n)}}schedule(e=!1){if(!this.isRunning)return;let t=this.getInterval(e);this.timerId=setTimeout(async()=>{await this.iteration()},t)}async iteration(){try{await this.user.getIdToken(!0)}catch(e){(null==e?void 0:e.code)==="auth/network-request-failed"&&this.schedule(!0);return}this.schedule()}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class B{constructor(e,t){this.createdAt=e,this.lastLoginAt=t,this._initializeTime()}_initializeTime(){this.lastSignInTime=L(this.lastLoginAt),this.creationTime=L(this.createdAt)}_copy(e){this.createdAt=e.createdAt,this.lastLoginAt=e.lastLoginAt,this._initializeTime()}toJSON(){return{createdAt:this.createdAt,lastLoginAt:this.lastLoginAt}}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function q(e){var t;let n=e.auth,r=await e.getIdToken(),i=await U(e,P(n,{idToken:r}));y(null==i?void 0:i.users.length,n,"internal-error");let s=i.users[0];e._notifyReloadListener(s);let o=(null===(t=s.providerUserInfo)||void 0===t?void 0:t.length)?s.providerUserInfo.map(e=>{var{providerId:t}=e,n=a(e,["providerId"]);return{providerId:t,uid:n.rawId||"",displayName:n.displayName||null,email:n.email||null,phoneNumber:n.phoneNumber||null,photoURL:n.photoUrl||null}}):[],l=function(e,t){let n=e.filter(e=>!t.some(t=>t.providerId===e.providerId));return[...n,...t]}(e.providerData,o),u=e.isAnonymous,c=!(e.email&&s.passwordHash)&&!(null==l?void 0:l.length),h={uid:s.localId,displayName:s.displayName||null,photoURL:s.photoUrl||null,email:s.email||null,emailVerified:s.emailVerified||!1,phoneNumber:s.phoneNumber||null,tenantId:s.tenantId||null,providerData:l,metadata:new B(s.createdAt,s.lastLoginAt),isAnonymous:!!u&&c};Object.assign(e,h)}async function z(e){let t=(0,i.m9)(e);await q(t),await t.auth._persistUserIfCurrent(t),t.auth._notifyListenersIfCurrent(t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function $(e,t){let n=await C(e,{},async()=>{let n=(0,i.xO)({grant_type:"refresh_token",refresh_token:t}).slice(1),{tokenApiHost:r,apiKey:s}=e.config,a=N(e,r,"/v1/token",`key=${s}`),o=await e._getAdditionalHeaders();return o["Content-Type"]="application/x-www-form-urlencoded",_.fetch()(a,{method:"POST",headers:o,body:n})});return{accessToken:n.access_token,expiresIn:n.expires_in,refreshToken:n.refresh_token}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class H{constructor(){this.refreshToken=null,this.accessToken=null,this.expirationTime=null}get isExpired(){return!this.expirationTime||Date.now()>this.expirationTime-3e4}updateFromServerResponse(e){y(e.idToken,"internal-error"),y(void 0!==e.idToken,"internal-error"),y(void 0!==e.refreshToken,"internal-error");let t="expiresIn"in e&&void 0!==e.expiresIn?Number(e.expiresIn):function(e){let t=V(e);return y(t,"internal-error"),y(void 0!==t.exp,"internal-error"),y(void 0!==t.iat,"internal-error"),Number(t.exp)-Number(t.iat)}(e.idToken);this.updateTokensAndExpiration(e.idToken,e.refreshToken,t)}async getToken(e,t=!1){return(y(!this.accessToken||this.refreshToken,e,"user-token-expired"),t||!this.accessToken||this.isExpired)?this.refreshToken?(await this.refresh(e,this.refreshToken),this.accessToken):null:this.accessToken}clearRefreshToken(){this.refreshToken=null}async refresh(e,t){let{accessToken:n,refreshToken:r,expiresIn:i}=await $(e,t);this.updateTokensAndExpiration(n,r,Number(i))}updateTokensAndExpiration(e,t,n){this.refreshToken=t||null,this.accessToken=e||null,this.expirationTime=Date.now()+1e3*n}static fromJSON(e,t){let{refreshToken:n,accessToken:r,expirationTime:i}=t,s=new H;return n&&(y("string"==typeof n,"internal-error",{appName:e}),s.refreshToken=n),r&&(y("string"==typeof r,"internal-error",{appName:e}),s.accessToken=r),i&&(y("number"==typeof i,"internal-error",{appName:e}),s.expirationTime=i),s}toJSON(){return{refreshToken:this.refreshToken,accessToken:this.accessToken,expirationTime:this.expirationTime}}_assign(e){this.accessToken=e.accessToken,this.refreshToken=e.refreshToken,this.expirationTime=e.expirationTime}_clone(){return Object.assign(new H,this.toJSON())}_performRefresh(){return v("not implemented")}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function K(e,t){y("string"==typeof e||void 0===e,"internal-error",{appName:t})}class G{constructor(e){var{uid:t,auth:n,stsTokenManager:r}=e,i=a(e,["uid","auth","stsTokenManager"]);this.providerId="firebase",this.proactiveRefresh=new j(this),this.reloadUserInfo=null,this.reloadListener=null,this.uid=t,this.auth=n,this.stsTokenManager=r,this.accessToken=r.accessToken,this.displayName=i.displayName||null,this.email=i.email||null,this.emailVerified=i.emailVerified||!1,this.phoneNumber=i.phoneNumber||null,this.photoURL=i.photoURL||null,this.isAnonymous=i.isAnonymous||!1,this.tenantId=i.tenantId||null,this.providerData=i.providerData?[...i.providerData]:[],this.metadata=new B(i.createdAt||void 0,i.lastLoginAt||void 0)}async getIdToken(e){let t=await U(this,this.stsTokenManager.getToken(this.auth,e));return y(t,this.auth,"internal-error"),this.accessToken!==t&&(this.accessToken=t,await this.auth._persistUserIfCurrent(this),this.auth._notifyListenersIfCurrent(this)),t}getIdTokenResult(e){return M(this,e)}reload(){return z(this)}_assign(e){this!==e&&(y(this.uid===e.uid,this.auth,"internal-error"),this.displayName=e.displayName,this.photoURL=e.photoURL,this.email=e.email,this.emailVerified=e.emailVerified,this.phoneNumber=e.phoneNumber,this.isAnonymous=e.isAnonymous,this.tenantId=e.tenantId,this.providerData=e.providerData.map(e=>Object.assign({},e)),this.metadata._copy(e.metadata),this.stsTokenManager._assign(e.stsTokenManager))}_clone(e){let t=new G(Object.assign(Object.assign({},this),{auth:e,stsTokenManager:this.stsTokenManager._clone()}));return t.metadata._copy(this.metadata),t}_onReload(e){y(!this.reloadListener,this.auth,"internal-error"),this.reloadListener=e,this.reloadUserInfo&&(this._notifyReloadListener(this.reloadUserInfo),this.reloadUserInfo=null)}_notifyReloadListener(e){this.reloadListener?this.reloadListener(e):this.reloadUserInfo=e}_startProactiveRefresh(){this.proactiveRefresh._start()}_stopProactiveRefresh(){this.proactiveRefresh._stop()}async _updateTokensIfNecessary(e,t=!1){let n=!1;e.idToken&&e.idToken!==this.stsTokenManager.accessToken&&(this.stsTokenManager.updateFromServerResponse(e),n=!0),t&&await q(this),await this.auth._persistUserIfCurrent(this),n&&this.auth._notifyListenersIfCurrent(this)}async delete(){let e=await this.getIdToken();return await U(this,O(this.auth,{idToken:e})),this.stsTokenManager.clearRefreshToken(),this.auth.signOut()}toJSON(){return Object.assign(Object.assign({uid:this.uid,email:this.email||void 0,emailVerified:this.emailVerified,displayName:this.displayName||void 0,isAnonymous:this.isAnonymous,photoURL:this.photoURL||void 0,phoneNumber:this.phoneNumber||void 0,tenantId:this.tenantId||void 0,providerData:this.providerData.map(e=>Object.assign({},e)),stsTokenManager:this.stsTokenManager.toJSON(),_redirectEventId:this._redirectEventId},this.metadata.toJSON()),{apiKey:this.auth.config.apiKey,appName:this.auth.name})}get refreshToken(){return this.stsTokenManager.refreshToken||""}static _fromJSON(e,t){var n,r,i,s,a,o,l,u;let c=null!==(n=t.displayName)&&void 0!==n?n:void 0,h=null!==(r=t.email)&&void 0!==r?r:void 0,d=null!==(i=t.phoneNumber)&&void 0!==i?i:void 0,f=null!==(s=t.photoURL)&&void 0!==s?s:void 0,p=null!==(a=t.tenantId)&&void 0!==a?a:void 0,g=null!==(o=t._redirectEventId)&&void 0!==o?o:void 0,m=null!==(l=t.createdAt)&&void 0!==l?l:void 0,v=null!==(u=t.lastLoginAt)&&void 0!==u?u:void 0,{uid:w,emailVerified:b,isAnonymous:E,providerData:I,stsTokenManager:_}=t;y(w&&_,e,"internal-error");let T=H.fromJSON(this.name,_);y("string"==typeof w,e,"internal-error"),K(c,e.name),K(h,e.name),y("boolean"==typeof b,e,"internal-error"),y("boolean"==typeof E,e,"internal-error"),K(d,e.name),K(f,e.name),K(p,e.name),K(g,e.name),K(m,e.name),K(v,e.name);let k=new G({uid:w,auth:e,email:h,emailVerified:b,displayName:c,isAnonymous:E,photoURL:f,phoneNumber:d,tenantId:p,stsTokenManager:T,createdAt:m,lastLoginAt:v});return I&&Array.isArray(I)&&(k.providerData=I.map(e=>Object.assign({},e))),g&&(k._redirectEventId=g),k}static async _fromIdTokenResponse(e,t,n=!1){let r=new H;r.updateFromServerResponse(t);let i=new G({uid:t.localId,auth:e,stsTokenManager:r,isAnonymous:n});return await q(i),i}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let W=new Map;function Q(e){e instanceof Function||v("Expected a class definition");let t=W.get(e);return t?t instanceof e||v("Instance stored in cache mismatched with class"):(t=new e,W.set(e,t)),t}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Z{constructor(){this.type="NONE",this.storage={}}async _isAvailable(){return!0}async _set(e,t){this.storage[e]=t}async _get(e){let t=this.storage[e];return void 0===t?null:t}async _remove(e){delete this.storage[e]}_addListener(e,t){}_removeListener(e,t){}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function J(e,t,n){return`firebase:${e}:${t}:${n}`}Z.type="NONE";class X{constructor(e,t,n){this.persistence=e,this.auth=t,this.userKey=n;let{config:r,name:i}=this.auth;this.fullUserKey=J(this.userKey,r.apiKey,i),this.fullPersistenceKey=J("persistence",r.apiKey,i),this.boundEventHandler=t._onStorageEvent.bind(t),this.persistence._addListener(this.fullUserKey,this.boundEventHandler)}setCurrentUser(e){return this.persistence._set(this.fullUserKey,e.toJSON())}async getCurrentUser(){let e=await this.persistence._get(this.fullUserKey);return e?G._fromJSON(this.auth,e):null}removeCurrentUser(){return this.persistence._remove(this.fullUserKey)}savePersistenceForRedirect(){return this.persistence._set(this.fullPersistenceKey,this.persistence.type)}async setPersistence(e){if(this.persistence===e)return;let t=await this.getCurrentUser();if(await this.removeCurrentUser(),this.persistence=e,t)return this.setCurrentUser(t)}delete(){this.persistence._removeListener(this.fullUserKey,this.boundEventHandler)}static async create(e,t,n="authUser"){if(!t.length)return new X(Q(Z),e,n);let r=(await Promise.all(t.map(async e=>{if(await e._isAvailable())return e}))).filter(e=>e),i=r[0]||Q(Z),s=J(n,e.config.apiKey,e.name),a=null;for(let n of t)try{let t=await n._get(s);if(t){let r=G._fromJSON(e,t);n!==i&&(a=r),i=n;break}}catch(e){}let o=r.filter(e=>e._shouldAllowMigration);return i._shouldAllowMigration&&o.length&&(i=o[0],a&&await i._set(s,a.toJSON()),await Promise.all(t.map(async e=>{if(e!==i)try{await e._remove(s)}catch(e){}}))),new X(i,e,n)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Y(e){let t=e.toLowerCase();if(t.includes("opera/")||t.includes("opr/")||t.includes("opios/"))return"Opera";if(er(t))return"IEMobile";if(t.includes("msie")||t.includes("trident/"))return"IE";{if(t.includes("edge/"))return"Edge";if(ee(t))return"Firefox";if(t.includes("silk/"))return"Silk";if(es(t))return"Blackberry";if(ea(t))return"Webos";if(et(t))return"Safari";if((t.includes("chrome/")||en(t))&&!t.includes("edge/"))return"Chrome";if(ei(t))return"Android";let n=e.match(/([a-zA-Z\d\.]+)\/[a-zA-Z\d\.]*$/);if((null==n?void 0:n.length)===2)return n[1]}return"Other"}function ee(e=(0,i.z$)()){return/firefox\//i.test(e)}function et(e=(0,i.z$)()){let t=e.toLowerCase();return t.includes("safari/")&&!t.includes("chrome/")&&!t.includes("crios/")&&!t.includes("android")}function en(e=(0,i.z$)()){return/crios\//i.test(e)}function er(e=(0,i.z$)()){return/iemobile/i.test(e)}function ei(e=(0,i.z$)()){return/android/i.test(e)}function es(e=(0,i.z$)()){return/blackberry/i.test(e)}function ea(e=(0,i.z$)()){return/webos/i.test(e)}function eo(e=(0,i.z$)()){return/iphone|ipad|ipod/i.test(e)||/macintosh/i.test(e)&&/mobile/i.test(e)}function el(e=(0,i.z$)()){return eo(e)||ei(e)||ea(e)||es(e)||/windows phone/i.test(e)||er(e)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function eu(e,t=[]){let n;switch(e){case"Browser":n=Y((0,i.z$)());break;case"Worker":n=`${Y((0,i.z$)())}-${e}`;break;default:n=e}let r=t.length?t.join(","):"FirebaseCore-web";return`${n}/JsCore/${s.Jn}/${r}`}async function ec(e,t){return x(e,"GET","/v2/recaptchaConfig",S(e,t))}function eh(e){return void 0!==e&&void 0!==e.enterprise}class ed{constructor(e){if(this.siteKey="",this.emailPasswordEnabled=!1,void 0===e.recaptchaKey)throw Error("recaptchaKey undefined");this.siteKey=e.recaptchaKey.split("/")[3],this.emailPasswordEnabled=e.recaptchaEnforcementState.some(e=>"EMAIL_PASSWORD_PROVIDER"===e.provider&&"OFF"!==e.enforcementState)}}function ef(e){return new Promise((t,n)=>{var r,i;let s=document.createElement("script");s.setAttribute("src",e),s.onload=t,s.onerror=e=>{let t=p("internal-error");t.customData=e,n(t)},s.type="text/javascript",s.charset="UTF-8",(null!==(i=null===(r=document.getElementsByTagName("head"))||void 0===r?void 0:r[0])&&void 0!==i?i:document).appendChild(s)})}function ep(e){return`__${e}${Math.floor(1e6*Math.random())}`}class eg{constructor(e){this.type="recaptcha-enterprise",this.auth=ew(e)}async verify(e="verify",t=!1){async function n(e){if(!t){if(null==e.tenantId&&null!=e._agentRecaptchaConfig)return e._agentRecaptchaConfig.siteKey;if(null!=e.tenantId&&void 0!==e._tenantRecaptchaConfigs[e.tenantId])return e._tenantRecaptchaConfigs[e.tenantId].siteKey}return new Promise(async(t,n)=>{ec(e,{clientType:"CLIENT_TYPE_WEB",version:"RECAPTCHA_ENTERPRISE"}).then(r=>{if(void 0===r.recaptchaKey)n(Error("recaptcha Enterprise site key undefined"));else{let n=new ed(r);return null==e.tenantId?e._agentRecaptchaConfig=n:e._tenantRecaptchaConfigs[e.tenantId]=n,t(n.siteKey)}}).catch(e=>{n(e)})})}function r(t,n,r){let i=window.grecaptcha;eh(i)?i.enterprise.ready(()=>{i.enterprise.execute(t,{action:e}).then(e=>{n(e)}).catch(()=>{n("NO_RECAPTCHA")})}):r(Error("No reCAPTCHA enterprise script loaded."))}return new Promise((e,i)=>{n(this.auth).then(n=>{if(!t&&eh(window.grecaptcha))r(n,e,i);else{if("undefined"==typeof window){i(Error("RecaptchaVerifier is only supported in browser"));return}ef("https://www.google.com/recaptcha/enterprise.js?render="+n).then(()=>{r(n,e,i)}).catch(e=>{i(e)})}}).catch(e=>{i(e)})})}}async function em(e,t,n,r=!1){let i;let s=new eg(e);try{i=await s.verify(n)}catch(e){i=await s.verify(n,!0)}let a=Object.assign({},t);return r?Object.assign(a,{captchaResp:i}):Object.assign(a,{captchaResponse:i}),Object.assign(a,{clientType:"CLIENT_TYPE_WEB"}),Object.assign(a,{recaptchaVersion:"RECAPTCHA_ENTERPRISE"}),a}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ey{constructor(e){this.auth=e,this.queue=[]}pushCallback(e,t){let n=t=>new Promise((n,r)=>{try{let r=e(t);n(r)}catch(e){r(e)}});n.onAbort=t,this.queue.push(n);let r=this.queue.length-1;return()=>{this.queue[r]=()=>Promise.resolve()}}async runMiddleware(e){if(this.auth.currentUser===e)return;let t=[];try{for(let n of this.queue)await n(e),n.onAbort&&t.push(n.onAbort)}catch(e){for(let e of(t.reverse(),t))try{e()}catch(e){}throw this.auth._errorFactory.create("login-blocked",{originalMessage:null==e?void 0:e.message})}}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ev{constructor(e,t,n,r){this.app=e,this.heartbeatServiceProvider=t,this.appCheckServiceProvider=n,this.config=r,this.currentUser=null,this.emulatorConfig=null,this.operations=Promise.resolve(),this.authStateSubscription=new eb(this),this.idTokenSubscription=new eb(this),this.beforeStateQueue=new ey(this),this.redirectUser=null,this.isProactiveRefreshEnabled=!1,this._canInitEmulator=!0,this._isInitialized=!1,this._deleted=!1,this._initializationPromise=null,this._popupRedirectResolver=null,this._errorFactory=c,this._agentRecaptchaConfig=null,this._tenantRecaptchaConfigs={},this.lastNotifiedUid=void 0,this.languageCode=null,this.tenantId=null,this.settings={appVerificationDisabledForTesting:!1},this.frameworks=[],this.name=e.name,this.clientVersion=r.sdkClientVersion}_initializeWithPersistence(e,t){return t&&(this._popupRedirectResolver=Q(t)),this._initializationPromise=this.queue(async()=>{var n,r;if(!this._deleted&&(this.persistenceManager=await X.create(this,e),!this._deleted)){if(null===(n=this._popupRedirectResolver)||void 0===n?void 0:n._shouldInitProactively)try{await this._popupRedirectResolver._initialize(this)}catch(e){}await this.initializeCurrentUser(t),this.lastNotifiedUid=(null===(r=this.currentUser)||void 0===r?void 0:r.uid)||null,this._deleted||(this._isInitialized=!0)}}),this._initializationPromise}async _onStorageEvent(){if(this._deleted)return;let e=await this.assertedPersistence.getCurrentUser();if(this.currentUser||e){if(this.currentUser&&e&&this.currentUser.uid===e.uid){this._currentUser._assign(e),await this.currentUser.getIdToken();return}await this._updateCurrentUser(e,!0)}}async initializeCurrentUser(e){var t;let n=await this.assertedPersistence.getCurrentUser(),r=n,i=!1;if(e&&this.config.authDomain){await this.getOrInitRedirectPersistenceManager();let n=null===(t=this.redirectUser)||void 0===t?void 0:t._redirectEventId,s=null==r?void 0:r._redirectEventId,a=await this.tryRedirectSignIn(e);(!n||n===s)&&(null==a?void 0:a.user)&&(r=a.user,i=!0)}if(!r)return this.directlySetCurrentUser(null);if(!r._redirectEventId){if(i)try{await this.beforeStateQueue.runMiddleware(r)}catch(e){r=n,this._popupRedirectResolver._overrideRedirectResult(this,()=>Promise.reject(e))}return r?this.reloadAndSetCurrentUserOrClear(r):this.directlySetCurrentUser(null)}return(y(this._popupRedirectResolver,this,"argument-error"),await this.getOrInitRedirectPersistenceManager(),this.redirectUser&&this.redirectUser._redirectEventId===r._redirectEventId)?this.directlySetCurrentUser(r):this.reloadAndSetCurrentUserOrClear(r)}async tryRedirectSignIn(e){let t=null;try{t=await this._popupRedirectResolver._completeRedirectFn(this,e,!0)}catch(e){await this._setRedirectUser(null)}return t}async reloadAndSetCurrentUserOrClear(e){try{await q(e)}catch(e){if((null==e?void 0:e.code)!=="auth/network-request-failed")return this.directlySetCurrentUser(null)}return this.directlySetCurrentUser(e)}useDeviceLanguage(){this.languageCode=function(){if("undefined"==typeof navigator)return null;let e=navigator;return e.languages&&e.languages[0]||e.language||null}()}async _delete(){this._deleted=!0}async updateCurrentUser(e){let t=e?(0,i.m9)(e):null;return t&&y(t.auth.config.apiKey===this.config.apiKey,this,"invalid-user-token"),this._updateCurrentUser(t&&t._clone(this))}async _updateCurrentUser(e,t=!1){if(!this._deleted)return e&&y(this.tenantId===e.tenantId,this,"tenant-id-mismatch"),t||await this.beforeStateQueue.runMiddleware(e),this.queue(async()=>{await this.directlySetCurrentUser(e),this.notifyAuthListeners()})}async signOut(){return await this.beforeStateQueue.runMiddleware(null),(this.redirectPersistenceManager||this._popupRedirectResolver)&&await this._setRedirectUser(null),this._updateCurrentUser(null,!0)}setPersistence(e){return this.queue(async()=>{await this.assertedPersistence.setPersistence(Q(e))})}async initializeRecaptchaConfig(){let e=await ec(this,{clientType:"CLIENT_TYPE_WEB",version:"RECAPTCHA_ENTERPRISE"}),t=new ed(e);if(null==this.tenantId?this._agentRecaptchaConfig=t:this._tenantRecaptchaConfigs[this.tenantId]=t,t.emailPasswordEnabled){let e=new eg(this);e.verify()}}_getRecaptchaConfig(){return null==this.tenantId?this._agentRecaptchaConfig:this._tenantRecaptchaConfigs[this.tenantId]}_getPersistence(){return this.assertedPersistence.persistence.type}_updateErrorMap(e){this._errorFactory=new i.LL("auth","Firebase",e())}onAuthStateChanged(e,t,n){return this.registerStateListener(this.authStateSubscription,e,t,n)}beforeAuthStateChanged(e,t){return this.beforeStateQueue.pushCallback(e,t)}onIdTokenChanged(e,t,n){return this.registerStateListener(this.idTokenSubscription,e,t,n)}toJSON(){var e;return{apiKey:this.config.apiKey,authDomain:this.config.authDomain,appName:this.name,currentUser:null===(e=this._currentUser)||void 0===e?void 0:e.toJSON()}}async _setRedirectUser(e,t){let n=await this.getOrInitRedirectPersistenceManager(t);return null===e?n.removeCurrentUser():n.setCurrentUser(e)}async getOrInitRedirectPersistenceManager(e){if(!this.redirectPersistenceManager){let t=e&&Q(e)||this._popupRedirectResolver;y(t,this,"argument-error"),this.redirectPersistenceManager=await X.create(this,[Q(t._redirectPersistence)],"redirectUser"),this.redirectUser=await this.redirectPersistenceManager.getCurrentUser()}return this.redirectPersistenceManager}async _redirectUserForId(e){var t,n;return(this._isInitialized&&await this.queue(async()=>{}),(null===(t=this._currentUser)||void 0===t?void 0:t._redirectEventId)===e)?this._currentUser:(null===(n=this.redirectUser)||void 0===n?void 0:n._redirectEventId)===e?this.redirectUser:null}async _persistUserIfCurrent(e){if(e===this.currentUser)return this.queue(async()=>this.directlySetCurrentUser(e))}_notifyListenersIfCurrent(e){e===this.currentUser&&this.notifyAuthListeners()}_key(){return`${this.config.authDomain}:${this.config.apiKey}:${this.name}`}_startProactiveRefresh(){this.isProactiveRefreshEnabled=!0,this.currentUser&&this._currentUser._startProactiveRefresh()}_stopProactiveRefresh(){this.isProactiveRefreshEnabled=!1,this.currentUser&&this._currentUser._stopProactiveRefresh()}get _currentUser(){return this.currentUser}notifyAuthListeners(){var e,t;if(!this._isInitialized)return;this.idTokenSubscription.next(this.currentUser);let n=null!==(t=null===(e=this.currentUser)||void 0===e?void 0:e.uid)&&void 0!==t?t:null;this.lastNotifiedUid!==n&&(this.lastNotifiedUid=n,this.authStateSubscription.next(this.currentUser))}registerStateListener(e,t,n,r){if(this._deleted)return()=>{};let i="function"==typeof t?t:t.next.bind(t),s=this._isInitialized?Promise.resolve():this._initializationPromise;return(y(s,this,"internal-error"),s.then(()=>i(this.currentUser)),"function"==typeof t)?e.addObserver(t,n,r):e.addObserver(t)}async directlySetCurrentUser(e){this.currentUser&&this.currentUser!==e&&this._currentUser._stopProactiveRefresh(),e&&this.isProactiveRefreshEnabled&&e._startProactiveRefresh(),this.currentUser=e,e?await this.assertedPersistence.setCurrentUser(e):await this.assertedPersistence.removeCurrentUser()}queue(e){return this.operations=this.operations.then(e,e),this.operations}get assertedPersistence(){return y(this.persistenceManager,this,"internal-error"),this.persistenceManager}_logFramework(e){!e||this.frameworks.includes(e)||(this.frameworks.push(e),this.frameworks.sort(),this.clientVersion=eu(this.config.clientPlatform,this._getFrameworks()))}_getFrameworks(){return this.frameworks}async _getAdditionalHeaders(){var e;let t={"X-Client-Version":this.clientVersion};this.app.options.appId&&(t["X-Firebase-gmpid"]=this.app.options.appId);let n=await (null===(e=this.heartbeatServiceProvider.getImmediate({optional:!0}))||void 0===e?void 0:e.getHeartbeatsHeader());n&&(t["X-Firebase-Client"]=n);let r=await this._getAppCheckToken();return r&&(t["X-Firebase-AppCheck"]=r),t}async _getAppCheckToken(){var e;let t=await (null===(e=this.appCheckServiceProvider.getImmediate({optional:!0}))||void 0===e?void 0:e.getToken());return(null==t?void 0:t.error)&&function(e,...t){h.logLevel<=o.in.WARN&&h.warn(`Auth (${s.Jn}): ${e}`,...t)}(`Error while retrieving App Check token: ${t.error}`),null==t?void 0:t.token}}function ew(e){return(0,i.m9)(e)}class eb{constructor(e){this.auth=e,this.observer=null,this.addObserver=(0,i.ne)(e=>this.observer=e)}get next(){return y(this.observer,this.auth,"internal-error"),this.observer.next.bind(this.observer)}}function eE(e){let t=e.indexOf(":");return t<0?"":e.substr(0,t+1)}function eI(e){if(!e)return null;let t=Number(e);return isNaN(t)?null:t}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class e_{constructor(e,t){this.providerId=e,this.signInMethod=t}toJSON(){return v("not implemented")}_getIdTokenResponse(e){return v("not implemented")}_linkToIdToken(e,t){return v("not implemented")}_getReauthenticationResolver(e){return v("not implemented")}}async function eT(e,t){return x(e,"POST","/v1/accounts:update",t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function ek(e,t){return A(e,"POST","/v1/accounts:signInWithPassword",S(e,t))}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function eS(e,t){return A(e,"POST","/v1/accounts:signInWithEmailLink",S(e,t))}async function ex(e,t){return A(e,"POST","/v1/accounts:signInWithEmailLink",S(e,t))}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eC extends e_{constructor(e,t,n,r=null){super("password",n),this._email=e,this._password=t,this._tenantId=r}static _fromEmailAndPassword(e,t){return new eC(e,t,"password")}static _fromEmailAndCode(e,t,n=null){return new eC(e,t,"emailLink",n)}toJSON(){return{email:this._email,password:this._password,signInMethod:this.signInMethod,tenantId:this._tenantId}}static fromJSON(e){let t="string"==typeof e?JSON.parse(e):e;if((null==t?void 0:t.email)&&(null==t?void 0:t.password)){if("password"===t.signInMethod)return this._fromEmailAndPassword(t.email,t.password);if("emailLink"===t.signInMethod)return this._fromEmailAndCode(t.email,t.password,t.tenantId)}return null}async _getIdTokenResponse(e){var t;switch(this.signInMethod){case"password":let n={returnSecureToken:!0,email:this._email,password:this._password,clientType:"CLIENT_TYPE_WEB"};if(null===(t=e._getRecaptchaConfig())||void 0===t||!t.emailPasswordEnabled)return ek(e,n).catch(async t=>{if("auth/missing-recaptcha-token"!==t.code)return Promise.reject(t);{console.log("Sign-in with email address and password is protected by reCAPTCHA for this project. Automatically triggering the reCAPTCHA flow and restarting the sign-in flow.");let t=await em(e,n,"signInWithPassword");return ek(e,t)}});{let t=await em(e,n,"signInWithPassword");return ek(e,t)}case"emailLink":return eS(e,{email:this._email,oobCode:this._password});default:f(e,"internal-error")}}async _linkToIdToken(e,t){switch(this.signInMethod){case"password":return eT(e,{idToken:t,returnSecureToken:!0,email:this._email,password:this._password});case"emailLink":return ex(e,{idToken:t,email:this._email,oobCode:this._password});default:f(e,"internal-error")}}_getReauthenticationResolver(e){return this._getIdTokenResponse(e)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function eA(e,t){return A(e,"POST","/v1/accounts:signInWithIdp",S(e,t))}class eN extends e_{constructor(){super(...arguments),this.pendingToken=null}static _fromParams(e){let t=new eN(e.providerId,e.signInMethod);return e.idToken||e.accessToken?(e.idToken&&(t.idToken=e.idToken),e.accessToken&&(t.accessToken=e.accessToken),e.nonce&&!e.pendingToken&&(t.nonce=e.nonce),e.pendingToken&&(t.pendingToken=e.pendingToken)):e.oauthToken&&e.oauthTokenSecret?(t.accessToken=e.oauthToken,t.secret=e.oauthTokenSecret):f("argument-error"),t}toJSON(){return{idToken:this.idToken,accessToken:this.accessToken,secret:this.secret,nonce:this.nonce,pendingToken:this.pendingToken,providerId:this.providerId,signInMethod:this.signInMethod}}static fromJSON(e){let t="string"==typeof e?JSON.parse(e):e,{providerId:n,signInMethod:r}=t,i=a(t,["providerId","signInMethod"]);if(!n||!r)return null;let s=new eN(n,r);return s.idToken=i.idToken||void 0,s.accessToken=i.accessToken||void 0,s.secret=i.secret,s.nonce=i.nonce,s.pendingToken=i.pendingToken||null,s}_getIdTokenResponse(e){let t=this.buildRequest();return eA(e,t)}_linkToIdToken(e,t){let n=this.buildRequest();return n.idToken=t,eA(e,n)}_getReauthenticationResolver(e){let t=this.buildRequest();return t.autoCreate=!1,eA(e,t)}buildRequest(){let e={requestUri:"http://localhost",returnSecureToken:!0};if(this.pendingToken)e.pendingToken=this.pendingToken;else{let t={};this.idToken&&(t.id_token=this.idToken),this.accessToken&&(t.access_token=this.accessToken),this.secret&&(t.oauth_token_secret=this.secret),t.providerId=this.providerId,this.nonce&&!this.pendingToken&&(t.nonce=this.nonce),e.postBody=(0,i.xO)(t)}return e}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function eR(e,t){return x(e,"POST","/v1/accounts:sendVerificationCode",S(e,t))}async function eD(e,t){return A(e,"POST","/v1/accounts:signInWithPhoneNumber",S(e,t))}async function eO(e,t){let n=await A(e,"POST","/v1/accounts:signInWithPhoneNumber",S(e,t));if(n.temporaryProof)throw D(e,"account-exists-with-different-credential",n);return n}let eP={USER_NOT_FOUND:"user-not-found"};async function eL(e,t){let n=Object.assign(Object.assign({},t),{operation:"REAUTH"});return A(e,"POST","/v1/accounts:signInWithPhoneNumber",S(e,n),eP)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eM extends e_{constructor(e){super("phone","phone"),this.params=e}static _fromVerification(e,t){return new eM({verificationId:e,verificationCode:t})}static _fromTokenResponse(e,t){return new eM({phoneNumber:e,temporaryProof:t})}_getIdTokenResponse(e){return eD(e,this._makeVerificationRequest())}_linkToIdToken(e,t){return eO(e,Object.assign({idToken:t},this._makeVerificationRequest()))}_getReauthenticationResolver(e){return eL(e,this._makeVerificationRequest())}_makeVerificationRequest(){let{temporaryProof:e,phoneNumber:t,verificationId:n,verificationCode:r}=this.params;return e&&t?{temporaryProof:e,phoneNumber:t}:{sessionInfo:n,code:r}}toJSON(){let e={providerId:this.providerId};return this.params.phoneNumber&&(e.phoneNumber=this.params.phoneNumber),this.params.temporaryProof&&(e.temporaryProof=this.params.temporaryProof),this.params.verificationCode&&(e.verificationCode=this.params.verificationCode),this.params.verificationId&&(e.verificationId=this.params.verificationId),e}static fromJSON(e){"string"==typeof e&&(e=JSON.parse(e));let{verificationId:t,verificationCode:n,phoneNumber:r,temporaryProof:i}=e;return n||t||r||i?new eM({verificationId:t,verificationCode:n,phoneNumber:r,temporaryProof:i}):null}}class eF{constructor(e){var t,n,r,s,a,o;let l=(0,i.zd)((0,i.pd)(e)),u=null!==(t=l.apiKey)&&void 0!==t?t:null,c=null!==(n=l.oobCode)&&void 0!==n?n:null,h=/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function(e){switch(e){case"recoverEmail":return"RECOVER_EMAIL";case"resetPassword":return"PASSWORD_RESET";case"signIn":return"EMAIL_SIGNIN";case"verifyEmail":return"VERIFY_EMAIL";case"verifyAndChangeEmail":return"VERIFY_AND_CHANGE_EMAIL";case"revertSecondFactorAddition":return"REVERT_SECOND_FACTOR_ADDITION";default:return null}}(null!==(r=l.mode)&&void 0!==r?r:null);y(u&&c&&h,"argument-error"),this.apiKey=u,this.operation=h,this.code=c,this.continueUrl=null!==(s=l.continueUrl)&&void 0!==s?s:null,this.languageCode=null!==(a=l.languageCode)&&void 0!==a?a:null,this.tenantId=null!==(o=l.tenantId)&&void 0!==o?o:null}static parseLink(e){let t=function(e){let t=(0,i.zd)((0,i.pd)(e)).link,n=t?(0,i.zd)((0,i.pd)(t)).deep_link_id:null,r=(0,i.zd)((0,i.pd)(e)).deep_link_id,s=r?(0,i.zd)((0,i.pd)(r)).link:null;return s||r||n||t||e}(e);try{return new eF(t)}catch(e){return null}}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eV{constructor(){this.providerId=eV.PROVIDER_ID}static credential(e,t){return eC._fromEmailAndPassword(e,t)}static credentialWithLink(e,t){let n=eF.parseLink(t);return y(n,"argument-error"),eC._fromEmailAndCode(e,n.code,n.tenantId)}}eV.PROVIDER_ID="password",eV.EMAIL_PASSWORD_SIGN_IN_METHOD="password",eV.EMAIL_LINK_SIGN_IN_METHOD="emailLink";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eU{constructor(e){this.providerId=e,this.defaultLanguageCode=null,this.customParameters={}}setDefaultLanguage(e){this.defaultLanguageCode=e}setCustomParameters(e){return this.customParameters=e,this}getCustomParameters(){return this.customParameters}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ej extends eU{constructor(){super(...arguments),this.scopes=[]}addScope(e){return this.scopes.includes(e)||this.scopes.push(e),this}getScopes(){return[...this.scopes]}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eB extends ej{constructor(){super("facebook.com")}static credential(e){return eN._fromParams({providerId:eB.PROVIDER_ID,signInMethod:eB.FACEBOOK_SIGN_IN_METHOD,accessToken:e})}static credentialFromResult(e){return eB.credentialFromTaggedObject(e)}static credentialFromError(e){return eB.credentialFromTaggedObject(e.customData||{})}static credentialFromTaggedObject({_tokenResponse:e}){if(!e||!("oauthAccessToken"in e)||!e.oauthAccessToken)return null;try{return eB.credential(e.oauthAccessToken)}catch(e){return null}}}eB.FACEBOOK_SIGN_IN_METHOD="facebook.com",eB.PROVIDER_ID="facebook.com";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eq extends ej{constructor(){super("google.com"),this.addScope("profile")}static credential(e,t){return eN._fromParams({providerId:eq.PROVIDER_ID,signInMethod:eq.GOOGLE_SIGN_IN_METHOD,idToken:e,accessToken:t})}static credentialFromResult(e){return eq.credentialFromTaggedObject(e)}static credentialFromError(e){return eq.credentialFromTaggedObject(e.customData||{})}static credentialFromTaggedObject({_tokenResponse:e}){if(!e)return null;let{oauthIdToken:t,oauthAccessToken:n}=e;if(!t&&!n)return null;try{return eq.credential(t,n)}catch(e){return null}}}eq.GOOGLE_SIGN_IN_METHOD="google.com",eq.PROVIDER_ID="google.com";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ez extends ej{constructor(){super("github.com")}static credential(e){return eN._fromParams({providerId:ez.PROVIDER_ID,signInMethod:ez.GITHUB_SIGN_IN_METHOD,accessToken:e})}static credentialFromResult(e){return ez.credentialFromTaggedObject(e)}static credentialFromError(e){return ez.credentialFromTaggedObject(e.customData||{})}static credentialFromTaggedObject({_tokenResponse:e}){if(!e||!("oauthAccessToken"in e)||!e.oauthAccessToken)return null;try{return ez.credential(e.oauthAccessToken)}catch(e){return null}}}ez.GITHUB_SIGN_IN_METHOD="github.com",ez.PROVIDER_ID="github.com";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class e$ extends ej{constructor(){super("twitter.com")}static credential(e,t){return eN._fromParams({providerId:e$.PROVIDER_ID,signInMethod:e$.TWITTER_SIGN_IN_METHOD,oauthToken:e,oauthTokenSecret:t})}static credentialFromResult(e){return e$.credentialFromTaggedObject(e)}static credentialFromError(e){return e$.credentialFromTaggedObject(e.customData||{})}static credentialFromTaggedObject({_tokenResponse:e}){if(!e)return null;let{oauthAccessToken:t,oauthTokenSecret:n}=e;if(!t||!n)return null;try{return e$.credential(t,n)}catch(e){return null}}}e$.TWITTER_SIGN_IN_METHOD="twitter.com",e$.PROVIDER_ID="twitter.com";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eH{constructor(e){this.user=e.user,this.providerId=e.providerId,this._tokenResponse=e._tokenResponse,this.operationType=e.operationType}static async _fromIdTokenResponse(e,t,n,r=!1){let i=await G._fromIdTokenResponse(e,n,r),s=eK(n),a=new eH({user:i,providerId:s,_tokenResponse:n,operationType:t});return a}static async _forOperation(e,t,n){await e._updateTokensIfNecessary(n,!0);let r=eK(n);return new eH({user:e,providerId:r,_tokenResponse:n,operationType:t})}}function eK(e){return e.providerId?e.providerId:"phoneNumber"in e?"phone":null}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class eG extends i.ZR{constructor(e,t,n,r){var i;super(t.code,t.message),this.operationType=n,this.user=r,Object.setPrototypeOf(this,eG.prototype),this.customData={appName:e.name,tenantId:null!==(i=e.tenantId)&&void 0!==i?i:void 0,_serverResponse:t.customData._serverResponse,operationType:n}}static _fromErrorAndOperation(e,t,n,r){return new eG(e,t,n,r)}}function eW(e,t,n,r){let i="reauthenticate"===t?n._getReauthenticationResolver(e):n._getIdTokenResponse(e);return i.catch(n=>{if("auth/multi-factor-auth-required"===n.code)throw eG._fromErrorAndOperation(e,n,t,r);throw n})}async function eQ(e,t,n=!1){let r=await U(e,t._linkToIdToken(e.auth,await e.getIdToken()),n);return eH._forOperation(e,"link",r)}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function eZ(e,t,n=!1){let{auth:r}=e,i="reauthenticate";try{let s=await U(e,eW(r,i,t,e),n);y(s.idToken,r,"internal-error");let a=V(s.idToken);y(a,r,"internal-error");let{sub:o}=a;return y(e.uid===o,r,"user-mismatch"),eH._forOperation(e,i,s)}catch(e){throw(null==e?void 0:e.code)==="auth/user-not-found"&&f(r,"user-mismatch"),e}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function eJ(e,t,n=!1){let r="signIn",i=await eW(e,r,t),s=await eH._fromIdTokenResponse(e,r,i);return n||await e._updateCurrentUser(s.user),s}async function eX(e,t){return eJ(ew(e),t)}function eY(e,t,n){return eX((0,i.m9)(e),eV.credential(t,n))}function e0(e,t,n,r){return(0,i.m9)(e).onAuthStateChanged(t,n,r)}function e1(e){return(0,i.m9)(e).signOut()}new WeakMap;let e2="__sak";/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class e4{constructor(e,t){this.storageRetriever=e,this.type=t}_isAvailable(){try{if(!this.storage)return Promise.resolve(!1);return this.storage.setItem(e2,"1"),this.storage.removeItem(e2),Promise.resolve(!0)}catch(e){return Promise.resolve(!1)}}_set(e,t){return this.storage.setItem(e,JSON.stringify(t)),Promise.resolve()}_get(e){let t=this.storage.getItem(e);return Promise.resolve(t?JSON.parse(t):null)}_remove(e){return this.storage.removeItem(e),Promise.resolve()}get storage(){return this.storageRetriever()}}class e9 extends e4{constructor(){super(()=>window.localStorage,"LOCAL"),this.boundEventHandler=(e,t)=>this.onStorageEvent(e,t),this.listeners={},this.localCache={},this.pollTimer=null,this.safariLocalStorageNotSynced=/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function(){let e=(0,i.z$)();return et(e)||eo(e)}()&&function(){try{return!!(window&&window!==window.top)}catch(e){return!1}}(),this.fallbackToPolling=el(),this._shouldAllowMigration=!0}forAllChangedKeys(e){for(let t of Object.keys(this.listeners)){let n=this.storage.getItem(t),r=this.localCache[t];n!==r&&e(t,r,n)}}onStorageEvent(e,t=!1){if(!e.key){this.forAllChangedKeys((e,t,n)=>{this.notifyListeners(e,n)});return}let n=e.key;if(t?this.detachListener():this.stopPolling(),this.safariLocalStorageNotSynced){let r=this.storage.getItem(n);if(e.newValue!==r)null!==e.newValue?this.storage.setItem(n,e.newValue):this.storage.removeItem(n);else if(this.localCache[n]===e.newValue&&!t)return}let r=()=>{let e=this.storage.getItem(n);(t||this.localCache[n]!==e)&&this.notifyListeners(n,e)},s=this.storage.getItem(n);(0,i.w1)()&&10===document.documentMode&&s!==e.newValue&&e.newValue!==e.oldValue?setTimeout(r,10):r()}notifyListeners(e,t){this.localCache[e]=t;let n=this.listeners[e];if(n)for(let e of Array.from(n))e(t?JSON.parse(t):t)}startPolling(){this.stopPolling(),this.pollTimer=setInterval(()=>{this.forAllChangedKeys((e,t,n)=>{this.onStorageEvent(new StorageEvent("storage",{key:e,oldValue:t,newValue:n}),!0)})},1e3)}stopPolling(){this.pollTimer&&(clearInterval(this.pollTimer),this.pollTimer=null)}attachListener(){window.addEventListener("storage",this.boundEventHandler)}detachListener(){window.removeEventListener("storage",this.boundEventHandler)}_addListener(e,t){0===Object.keys(this.listeners).length&&(this.fallbackToPolling?this.startPolling():this.attachListener()),this.listeners[e]||(this.listeners[e]=new Set,this.localCache[e]=this.storage.getItem(e)),this.listeners[e].add(t)}_removeListener(e,t){this.listeners[e]&&(this.listeners[e].delete(t),0===this.listeners[e].size&&delete this.listeners[e]),0===Object.keys(this.listeners).length&&(this.detachListener(),this.stopPolling())}async _set(e,t){await super._set(e,t),this.localCache[e]=JSON.stringify(t)}async _get(e){let t=await super._get(e);return this.localCache[e]=JSON.stringify(t),t}async _remove(e){await super._remove(e),delete this.localCache[e]}}e9.type="LOCAL";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class e6 extends e4{constructor(){super(()=>window.sessionStorage,"SESSION")}_addListener(e,t){}_removeListener(e,t){}}e6.type="SESSION";/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class e5{constructor(e){this.eventTarget=e,this.handlersMap={},this.boundEventHandler=this.handleEvent.bind(this)}static _getInstance(e){let t=this.receivers.find(t=>t.isListeningto(e));if(t)return t;let n=new e5(e);return this.receivers.push(n),n}isListeningto(e){return this.eventTarget===e}async handleEvent(e){let{eventId:t,eventType:n,data:r}=e.data,i=this.handlersMap[n];if(!(null==i?void 0:i.size))return;e.ports[0].postMessage({status:"ack",eventId:t,eventType:n});let s=Array.from(i).map(async t=>t(e.origin,r)),a=await Promise.all(s.map(async e=>{try{let t=await e;return{fulfilled:!0,value:t}}catch(e){return{fulfilled:!1,reason:e}}}));e.ports[0].postMessage({status:"done",eventId:t,eventType:n,response:a})}_subscribe(e,t){0===Object.keys(this.handlersMap).length&&this.eventTarget.addEventListener("message",this.boundEventHandler),this.handlersMap[e]||(this.handlersMap[e]=new Set),this.handlersMap[e].add(t)}_unsubscribe(e,t){this.handlersMap[e]&&t&&this.handlersMap[e].delete(t),t&&0!==this.handlersMap[e].size||delete this.handlersMap[e],0===Object.keys(this.handlersMap).length&&this.eventTarget.removeEventListener("message",this.boundEventHandler)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function e7(e="",t=10){let n="";for(let e=0;e<t;e++)n+=Math.floor(10*Math.random());return e+n}e5.receivers=[];/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class e3{constructor(e){this.target=e,this.handlers=new Set}removeMessageHandler(e){e.messageChannel&&(e.messageChannel.port1.removeEventListener("message",e.onMessage),e.messageChannel.port1.close()),this.handlers.delete(e)}async _send(e,t,n=50){let r,i;let s="undefined"!=typeof MessageChannel?new MessageChannel:null;if(!s)throw Error("connection_unavailable");return new Promise((a,o)=>{let l=e7("",20);s.port1.start();let u=setTimeout(()=>{o(Error("unsupported_event"))},n);i={messageChannel:s,onMessage(e){if(e.data.eventId===l)switch(e.data.status){case"ack":clearTimeout(u),r=setTimeout(()=>{o(Error("timeout"))},3e3);break;case"done":clearTimeout(r),a(e.data.response);break;default:clearTimeout(u),clearTimeout(r),o(Error("invalid_response"))}}},this.handlers.add(i),s.port1.addEventListener("message",i.onMessage),this.target.postMessage({eventType:e,eventId:l,data:t},[s.port2])}).finally(()=>{i&&this.removeMessageHandler(i)})}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function e8(){return window}/**
 * @license
 * Copyright 2020 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function te(){return void 0!==e8().WorkerGlobalScope&&"function"==typeof e8().importScripts}async function tt(){if(!(null==navigator?void 0:navigator.serviceWorker))return null;try{let e=await navigator.serviceWorker.ready;return e.active}catch(e){return null}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let tn="firebaseLocalStorageDb",tr="firebaseLocalStorage",ti="fbase_key";class ts{constructor(e){this.request=e}toPromise(){return new Promise((e,t)=>{this.request.addEventListener("success",()=>{e(this.request.result)}),this.request.addEventListener("error",()=>{t(this.request.error)})})}}function ta(e,t){return e.transaction([tr],t?"readwrite":"readonly").objectStore(tr)}function to(){let e=indexedDB.open(tn,1);return new Promise((t,n)=>{e.addEventListener("error",()=>{n(e.error)}),e.addEventListener("upgradeneeded",()=>{let t=e.result;try{t.createObjectStore(tr,{keyPath:ti})}catch(e){n(e)}}),e.addEventListener("success",async()=>{let n=e.result;n.objectStoreNames.contains(tr)?t(n):(n.close(),await function(){let e=indexedDB.deleteDatabase(tn);return new ts(e).toPromise()}(),t(await to()))})})}async function tl(e,t,n){let r=ta(e,!0).put({[ti]:t,value:n});return new ts(r).toPromise()}async function tu(e,t){let n=ta(e,!1).get(t),r=await new ts(n).toPromise();return void 0===r?null:r.value}function tc(e,t){let n=ta(e,!0).delete(t);return new ts(n).toPromise()}class th{constructor(){this.type="LOCAL",this._shouldAllowMigration=!0,this.listeners={},this.localCache={},this.pollTimer=null,this.pendingWrites=0,this.receiver=null,this.sender=null,this.serviceWorkerReceiverAvailable=!1,this.activeServiceWorker=null,this._workerInitializationPromise=this.initializeServiceWorkerMessaging().then(()=>{},()=>{})}async _openDb(){return this.db||(this.db=await to()),this.db}async _withRetries(e){let t=0;for(;;)try{let t=await this._openDb();return await e(t)}catch(e){if(t++>3)throw e;this.db&&(this.db.close(),this.db=void 0)}}async initializeServiceWorkerMessaging(){return te()?this.initializeReceiver():this.initializeSender()}async initializeReceiver(){this.receiver=e5._getInstance(te()?self:null),this.receiver._subscribe("keyChanged",async(e,t)=>{let n=await this._poll();return{keyProcessed:n.includes(t.key)}}),this.receiver._subscribe("ping",async(e,t)=>["keyChanged"])}async initializeSender(){var e,t;if(this.activeServiceWorker=await tt(),!this.activeServiceWorker)return;this.sender=new e3(this.activeServiceWorker);let n=await this.sender._send("ping",{},800);n&&(null===(e=n[0])||void 0===e?void 0:e.fulfilled)&&(null===(t=n[0])||void 0===t?void 0:t.value.includes("keyChanged"))&&(this.serviceWorkerReceiverAvailable=!0)}async notifyServiceWorker(e){var t;if(this.sender&&this.activeServiceWorker&&((null===(t=null==navigator?void 0:navigator.serviceWorker)||void 0===t?void 0:t.controller)||null)===this.activeServiceWorker)try{await this.sender._send("keyChanged",{key:e},this.serviceWorkerReceiverAvailable?800:50)}catch(e){}}async _isAvailable(){try{if(!indexedDB)return!1;let e=await to();return await tl(e,e2,"1"),await tc(e,e2),!0}catch(e){}return!1}async _withPendingWrite(e){this.pendingWrites++;try{await e()}finally{this.pendingWrites--}}async _set(e,t){return this._withPendingWrite(async()=>(await this._withRetries(n=>tl(n,e,t)),this.localCache[e]=t,this.notifyServiceWorker(e)))}async _get(e){let t=await this._withRetries(t=>tu(t,e));return this.localCache[e]=t,t}async _remove(e){return this._withPendingWrite(async()=>(await this._withRetries(t=>tc(t,e)),delete this.localCache[e],this.notifyServiceWorker(e)))}async _poll(){let e=await this._withRetries(e=>{let t=ta(e,!1).getAll();return new ts(t).toPromise()});if(!e||0!==this.pendingWrites)return[];let t=[],n=new Set;for(let{fbase_key:r,value:i}of e)n.add(r),JSON.stringify(this.localCache[r])!==JSON.stringify(i)&&(this.notifyListeners(r,i),t.push(r));for(let e of Object.keys(this.localCache))this.localCache[e]&&!n.has(e)&&(this.notifyListeners(e,null),t.push(e));return t}notifyListeners(e,t){this.localCache[e]=t;let n=this.listeners[e];if(n)for(let e of Array.from(n))e(t)}startPolling(){this.stopPolling(),this.pollTimer=setInterval(async()=>this._poll(),800)}stopPolling(){this.pollTimer&&(clearInterval(this.pollTimer),this.pollTimer=null)}_addListener(e,t){0===Object.keys(this.listeners).length&&this.startPolling(),this.listeners[e]||(this.listeners[e]=new Set,this._get(e)),this.listeners[e].add(t)}_removeListener(e,t){this.listeners[e]&&(this.listeners[e].delete(t),0===this.listeners[e].size&&delete this.listeners[e]),0===Object.keys(this.listeners).length&&this.stopPolling()}}async function td(e,t,n){var r,i,s;let a=await n.verify();try{let o;if(y("string"==typeof a,e,"argument-error"),y("recaptcha"===n.type,e,"argument-error"),o="string"==typeof t?{phoneNumber:t}:t,"session"in o){let t=o.session;if("phoneNumber"in o){y("enroll"===t.type,e,"internal-error");let n=await (i={idToken:t.credential,phoneEnrollmentInfo:{phoneNumber:o.phoneNumber,recaptchaToken:a}},x(e,"POST","/v2/accounts/mfaEnrollment:start",S(e,i)));return n.phoneSessionInfo.sessionInfo}{y("signin"===t.type,e,"internal-error");let n=(null===(r=o.multiFactorHint)||void 0===r?void 0:r.uid)||o.multiFactorUid;y(n,e,"missing-multi-factor-info");let i=await (s={mfaPendingCredential:t.credential,mfaEnrollmentId:n,phoneSignInInfo:{recaptchaToken:a}},x(e,"POST","/v2/accounts/mfaSignIn:start",S(e,s)));return i.phoneResponseInfo.sessionInfo}}{let{sessionInfo:t}=await eR(e,{phoneNumber:o.phoneNumber,recaptchaToken:a});return t}}finally{n._reset()}}th.type="LOCAL",ep("rcb"),new E(3e4,6e4);/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class tf{constructor(e){this.providerId=tf.PROVIDER_ID,this.auth=ew(e)}verifyPhoneNumber(e,t){return td(this.auth,e,(0,i.m9)(t))}static credential(e,t){return eM._fromVerification(e,t)}static credentialFromResult(e){return tf.credentialFromTaggedObject(e)}static credentialFromError(e){return tf.credentialFromTaggedObject(e.customData||{})}static credentialFromTaggedObject({_tokenResponse:e}){if(!e)return null;let{phoneNumber:t,temporaryProof:n}=e;return t&&n?eM._fromTokenResponse(t,n):null}}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function tp(e,t){return t?Q(t):(y(e._popupRedirectResolver,e,"argument-error"),e._popupRedirectResolver)}tf.PROVIDER_ID="phone",tf.PHONE_SIGN_IN_METHOD="phone";/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class tg extends e_{constructor(e){super("custom","custom"),this.params=e}_getIdTokenResponse(e){return eA(e,this._buildIdpRequest())}_linkToIdToken(e,t){return eA(e,this._buildIdpRequest(t))}_getReauthenticationResolver(e){return eA(e,this._buildIdpRequest())}_buildIdpRequest(e){let t={requestUri:this.params.requestUri,sessionId:this.params.sessionId,postBody:this.params.postBody,tenantId:this.params.tenantId,pendingToken:this.params.pendingToken,returnSecureToken:!0,returnIdpCredential:!0};return e&&(t.idToken=e),t}}function tm(e){return eJ(e.auth,new tg(e),e.bypassAuthState)}function ty(e){let{auth:t,user:n}=e;return y(n,t,"internal-error"),eZ(n,new tg(e),e.bypassAuthState)}async function tv(e){let{auth:t,user:n}=e;return y(n,t,"internal-error"),eQ(n,new tg(e),e.bypassAuthState)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class tw{constructor(e,t,n,r,i=!1){this.auth=e,this.resolver=n,this.user=r,this.bypassAuthState=i,this.pendingPromise=null,this.eventManager=null,this.filter=Array.isArray(t)?t:[t]}execute(){return new Promise(async(e,t)=>{this.pendingPromise={resolve:e,reject:t};try{this.eventManager=await this.resolver._initialize(this.auth),await this.onExecution(),this.eventManager.registerConsumer(this)}catch(e){this.reject(e)}})}async onAuthEvent(e){let{urlResponse:t,sessionId:n,postBody:r,tenantId:i,error:s,type:a}=e;if(s){this.reject(s);return}let o={auth:this.auth,requestUri:t,sessionId:n,tenantId:i||void 0,postBody:r||void 0,user:this.user,bypassAuthState:this.bypassAuthState};try{this.resolve(await this.getIdpTask(a)(o))}catch(e){this.reject(e)}}onError(e){this.reject(e)}getIdpTask(e){switch(e){case"signInViaPopup":case"signInViaRedirect":return tm;case"linkViaPopup":case"linkViaRedirect":return tv;case"reauthViaPopup":case"reauthViaRedirect":return ty;default:f(this.auth,"internal-error")}}resolve(e){this.pendingPromise||v("Pending promise was never set"),this.pendingPromise.resolve(e),this.unregisterAndCleanUp()}reject(e){this.pendingPromise||v("Pending promise was never set"),this.pendingPromise.reject(e),this.unregisterAndCleanUp()}unregisterAndCleanUp(){this.eventManager&&this.eventManager.unregisterConsumer(this),this.pendingPromise=null,this.cleanUp()}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let tb=new E(2e3,1e4);async function tE(e,t,n){let r=ew(e);!function(e,t,n){if(!(t instanceof n))throw n.name!==t.constructor.name&&f(e,"argument-error"),g(e,"argument-error",`Type of ${t.constructor.name} does not match expected instance.Did you pass a reference from a different Auth SDK?`)}(e,t,eU);let i=tp(r,n),s=new tI(r,"signInViaPopup",t,i);return s.executeNotNull()}class tI extends tw{constructor(e,t,n,r,i){super(e,t,r,i),this.provider=n,this.authWindow=null,this.pollId=null,tI.currentPopupAction&&tI.currentPopupAction.cancel(),tI.currentPopupAction=this}async executeNotNull(){let e=await this.execute();return y(e,this.auth,"internal-error"),e}async onExecution(){1===this.filter.length||v("Popup operations only handle one event");let e=e7();this.authWindow=await this.resolver._openPopup(this.auth,this.provider,this.filter[0],e),this.authWindow.associatedEvent=e,this.resolver._originValidation(this.auth).catch(e=>{this.reject(e)}),this.resolver._isIframeWebStorageSupported(this.auth,e=>{e||this.reject(p(this.auth,"web-storage-unsupported"))}),this.pollUserCancellation()}get eventId(){var e;return(null===(e=this.authWindow)||void 0===e?void 0:e.associatedEvent)||null}cancel(){this.reject(p(this.auth,"cancelled-popup-request"))}cleanUp(){this.authWindow&&this.authWindow.close(),this.pollId&&window.clearTimeout(this.pollId),this.authWindow=null,this.pollId=null,tI.currentPopupAction=null}pollUserCancellation(){let e=()=>{var t,n;if(null===(n=null===(t=this.authWindow)||void 0===t?void 0:t.window)||void 0===n?void 0:n.closed){this.pollId=window.setTimeout(()=>{this.pollId=null,this.reject(p(this.auth,"popup-closed-by-user"))},8e3);return}this.pollId=window.setTimeout(e,tb.get())};e()}}tI.currentPopupAction=null;let t_=new Map;class tT extends tw{constructor(e,t,n=!1){super(e,["signInViaRedirect","linkViaRedirect","reauthViaRedirect","unknown"],t,void 0,n),this.eventId=null}async execute(){let e=t_.get(this.auth._key());if(!e){try{let t=await tk(this.resolver,this.auth),n=t?await super.execute():null;e=()=>Promise.resolve(n)}catch(t){e=()=>Promise.reject(t)}t_.set(this.auth._key(),e)}return this.bypassAuthState||t_.set(this.auth._key(),()=>Promise.resolve(null)),e()}async onAuthEvent(e){if("signInViaRedirect"===e.type)return super.onAuthEvent(e);if("unknown"===e.type){this.resolve(null);return}if(e.eventId){let t=await this.auth._redirectUserForId(e.eventId);if(t)return this.user=t,super.onAuthEvent(e);this.resolve(null)}}async onExecution(){}cleanUp(){}}async function tk(e,t){let n=J("pendingRedirect",t.config.apiKey,t.name),r=Q(e._redirectPersistence);if(!await r._isAvailable())return!1;let i=await r._get(n)==="true";return await r._remove(n),i}function tS(e,t){t_.set(e._key(),t)}async function tx(e,t,n=!1){let r=ew(e),i=tp(r,t),s=new tT(r,i,n),a=await s.execute();return a&&!n&&(delete a.user._redirectEventId,await r._persistUserIfCurrent(a.user),await r._setRedirectUser(null,t)),a}class tC{constructor(e){this.auth=e,this.cachedEventUids=new Set,this.consumers=new Set,this.queuedRedirectEvent=null,this.hasHandledPotentialRedirect=!1,this.lastProcessedEventTime=Date.now()}registerConsumer(e){this.consumers.add(e),this.queuedRedirectEvent&&this.isEventForConsumer(this.queuedRedirectEvent,e)&&(this.sendToConsumer(this.queuedRedirectEvent,e),this.saveEventToCache(this.queuedRedirectEvent),this.queuedRedirectEvent=null)}unregisterConsumer(e){this.consumers.delete(e)}onEvent(e){if(this.hasEventBeenHandled(e))return!1;let t=!1;return this.consumers.forEach(n=>{this.isEventForConsumer(e,n)&&(t=!0,this.sendToConsumer(e,n),this.saveEventToCache(e))}),this.hasHandledPotentialRedirect||!function(e){switch(e.type){case"signInViaRedirect":case"linkViaRedirect":case"reauthViaRedirect":return!0;case"unknown":return tN(e);default:return!1}}(e)||(this.hasHandledPotentialRedirect=!0,t||(this.queuedRedirectEvent=e,t=!0)),t}sendToConsumer(e,t){var n;if(e.error&&!tN(e)){let r=(null===(n=e.error.code)||void 0===n?void 0:n.split("auth/")[1])||"internal-error";t.onError(p(this.auth,r))}else t.onAuthEvent(e)}isEventForConsumer(e,t){let n=null===t.eventId||!!e.eventId&&e.eventId===t.eventId;return t.filter.includes(e.type)&&n}hasEventBeenHandled(e){return Date.now()-this.lastProcessedEventTime>=6e5&&this.cachedEventUids.clear(),this.cachedEventUids.has(tA(e))}saveEventToCache(e){this.cachedEventUids.add(tA(e)),this.lastProcessedEventTime=Date.now()}}function tA(e){return[e.type,e.eventId,e.sessionId,e.tenantId].filter(e=>e).join("-")}function tN({type:e,error:t}){return"unknown"===e&&(null==t?void 0:t.code)==="auth/no-auth-event"}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function tR(e,t={}){return x(e,"GET","/v1/projects",t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let tD=/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/,tO=/^https?/;async function tP(e){if(e.config.emulator)return;let{authorizedDomains:t}=await tR(e);for(let e of t)try{if(function(e){let t=w(),{protocol:n,hostname:r}=new URL(t);if(e.startsWith("chrome-extension://")){let i=new URL(e);return""===i.hostname&&""===r?"chrome-extension:"===n&&e.replace("chrome-extension://","")===t.replace("chrome-extension://",""):"chrome-extension:"===n&&i.hostname===r}if(!tO.test(n))return!1;if(tD.test(e))return r===e;let i=e.replace(/\./g,"\\."),s=RegExp("^(.+\\."+i+"|"+i+")$","i");return s.test(r)}(e))return}catch(e){}f(e,"unauthorized-domain")}/**
 * @license
 * Copyright 2020 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let tL=new E(3e4,6e4);function tM(){let e=e8().___jsl;if(null==e?void 0:e.H){for(let t of Object.keys(e.H))if(e.H[t].r=e.H[t].r||[],e.H[t].L=e.H[t].L||[],e.H[t].r=[...e.H[t].L],e.CP)for(let t=0;t<e.CP.length;t++)e.CP[t]=null}}let tF=null,tV=new E(5e3,15e3),tU={style:{position:"absolute",top:"-100px",width:"1px",height:"1px"},"aria-hidden":"true",tabindex:"-1"},tj=new Map([["identitytoolkit.googleapis.com","p"],["staging-identitytoolkit.sandbox.googleapis.com","s"],["test-identitytoolkit.sandbox.googleapis.com","t"]]);async function tB(e){let t=await (tF=tF||new Promise((t,n)=>{var r,i,s;function a(){tM(),gapi.load("gapi.iframes",{callback:()=>{t(gapi.iframes.getContext())},ontimeout:()=>{tM(),n(p(e,"network-request-failed"))},timeout:tL.get()})}if(null===(i=null===(r=e8().gapi)||void 0===r?void 0:r.iframes)||void 0===i?void 0:i.Iframe)t(gapi.iframes.getContext());else if(null===(s=e8().gapi)||void 0===s?void 0:s.load)a();else{let t=ep("iframefcb");return e8()[t]=()=>{gapi.load?a():n(p(e,"network-request-failed"))},ef(`https://apis.google.com/js/api.js?onload=${t}`).catch(e=>n(e))}}).catch(e=>{throw tF=null,e})),n=e8().gapi;return y(n,e,"internal-error"),t.open({where:document.body,url:function(e){let t=e.config;y(t.authDomain,e,"auth-domain-config-required");let n=t.emulator?I(t,"emulator/auth/iframe"):`https://${e.config.authDomain}/__/auth/iframe`,r={apiKey:t.apiKey,appName:e.name,v:s.Jn},a=tj.get(e.config.apiHost);a&&(r.eid=a);let o=e._getFrameworks();return o.length&&(r.fw=o.join(",")),`${n}?${(0,i.xO)(r).slice(1)}`}(e),messageHandlersFilter:n.iframes.CROSS_ORIGIN_IFRAMES_FILTER,attributes:tU,dontclear:!0},t=>new Promise(async(n,r)=>{await t.restyle({setHideOnLeave:!1});let i=p(e,"network-request-failed"),s=e8().setTimeout(()=>{r(i)},tV.get());function a(){e8().clearTimeout(s),n(t)}t.ping(a).then(a,()=>{r(i)})}))}/**
 * @license
 * Copyright 2020 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let tq={location:"yes",resizable:"yes",statusbar:"yes",toolbar:"no"};class tz{constructor(e){this.window=e,this.associatedEvent=null}close(){if(this.window)try{this.window.close()}catch(e){}}}let t$=encodeURIComponent("fac");async function tH(e,t,n,r,a,o){y(e.config.authDomain,e,"auth-domain-config-required"),y(e.config.apiKey,e,"invalid-api-key");let l={apiKey:e.config.apiKey,appName:e.name,authType:n,redirectUrl:r,v:s.Jn,eventId:a};if(t instanceof eU)for(let[n,r]of(t.setDefaultLanguage(e.languageCode),l.providerId=t.providerId||"",(0,i.xb)(t.getCustomParameters())||(l.customParameters=JSON.stringify(t.getCustomParameters())),Object.entries(o||{})))l[n]=r;if(t instanceof ej){let e=t.getScopes().filter(e=>""!==e);e.length>0&&(l.scopes=e.join(","))}for(let t of(e.tenantId&&(l.tid=e.tenantId),Object.keys(l)))void 0===l[t]&&delete l[t];let u=await e._getAppCheckToken(),c=u?`#${t$}=${encodeURIComponent(u)}`:"";return`${function({config:e}){return e.emulator?I(e,"emulator/auth/handler"):`https://${e.authDomain}/__/auth/handler`}(e)}?${(0,i.xO)(l).slice(1)}${c}`}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let tK="webStorageSupport",tG=class{constructor(){this.eventManagers={},this.iframes={},this.originValidationPromises={},this._redirectPersistence=e6,this._completeRedirectFn=tx,this._overrideRedirectResult=tS}async _openPopup(e,t,n,r){var s;(null===(s=this.eventManagers[e._key()])||void 0===s?void 0:s.manager)||v("_initialize() not called before _openPopup()");let a=await tH(e,t,n,w(),r);return function(e,t,n,r=500,s=600){let a=Math.max((window.screen.availHeight-s)/2,0).toString(),o=Math.max((window.screen.availWidth-r)/2,0).toString(),l="",u=Object.assign(Object.assign({},tq),{width:r.toString(),height:s.toString(),top:a,left:o}),c=(0,i.z$)().toLowerCase();n&&(l=en(c)?"_blank":n),ee(c)&&(t=t||"http://localhost",u.scrollbars="yes");let h=Object.entries(u).reduce((e,[t,n])=>`${e}${t}=${n},`,"");if(function(e=(0,i.z$)()){var t;return eo(e)&&!!(null===(t=window.navigator)||void 0===t?void 0:t.standalone)}(c)&&"_self"!==l)return function(e,t){let n=document.createElement("a");n.href=e,n.target=t;let r=document.createEvent("MouseEvent");r.initMouseEvent("click",!0,!0,window,1,0,0,0,0,!1,!1,!1,!1,1,null),n.dispatchEvent(r)}(t||"",l),new tz(null);let d=window.open(t||"",l,h);y(d,e,"popup-blocked");try{d.focus()}catch(e){}return new tz(d)}(e,a,e7())}async _openRedirect(e,t,n,r){await this._originValidation(e);let i=await tH(e,t,n,w(),r);return e8().location.href=i,new Promise(()=>{})}_initialize(e){let t=e._key();if(this.eventManagers[t]){let{manager:e,promise:n}=this.eventManagers[t];return e?Promise.resolve(e):(n||v("If manager is not set, promise should be"),n)}let n=this.initAndGetManager(e);return this.eventManagers[t]={promise:n},n.catch(()=>{delete this.eventManagers[t]}),n}async initAndGetManager(e){let t=await tB(e),n=new tC(e);return t.register("authEvent",t=>{y(null==t?void 0:t.authEvent,e,"invalid-auth-event");let r=n.onEvent(t.authEvent);return{status:r?"ACK":"ERROR"}},gapi.iframes.CROSS_ORIGIN_IFRAMES_FILTER),this.eventManagers[e._key()]={manager:n},this.iframes[e._key()]=t,n}_isIframeWebStorageSupported(e,t){let n=this.iframes[e._key()];n.send(tK,{type:tK},n=>{var r;let i=null===(r=null==n?void 0:n[0])||void 0===r?void 0:r[tK];void 0!==i&&t(!!i),f(e,"internal-error")},gapi.iframes.CROSS_ORIGIN_IFRAMES_FILTER)}_originValidation(e){let t=e._key();return this.originValidationPromises[t]||(this.originValidationPromises[t]=tP(e)),this.originValidationPromises[t]}get _shouldInitProactively(){return el()||et()||eo()}};class tW{constructor(e){this.factorId=e}_process(e,t,n){switch(t.type){case"enroll":return this._finalizeEnroll(e,t.credential,n);case"signin":return this._finalizeSignIn(e,t.credential);default:return v("unexpected MultiFactorSessionType")}}}class tQ extends tW{constructor(e){super("phone"),this.credential=e}static _fromCredential(e){return new tQ(e)}_finalizeEnroll(e,t,n){return x(e,"POST","/v2/accounts/mfaEnrollment:finalize",S(e,{idToken:t,displayName:n,phoneVerificationInfo:this.credential._makeVerificationRequest()}))}_finalizeSignIn(e,t){return x(e,"POST","/v2/accounts/mfaSignIn:finalize",S(e,{mfaPendingCredential:t,phoneVerificationInfo:this.credential._makeVerificationRequest()}))}}class tZ extends tW{constructor(e,t,n){super("totp"),this.otp=e,this.enrollmentId=t,this.secret=n}static _fromSecret(e,t){return new tZ(t,void 0,e)}static _fromEnrollmentId(e,t){return new tZ(t,e)}async _finalizeEnroll(e,t,n){return y(void 0!==this.secret,e,"argument-error"),x(e,"POST","/v2/accounts/mfaEnrollment:finalize",S(e,{idToken:t,displayName:n,totpVerificationInfo:this.secret._makeTotpVerificationInfo(this.otp)}))}async _finalizeSignIn(e,t){y(void 0!==this.enrollmentId&&void 0!==this.otp,e,"argument-error");let n={verificationCode:this.otp};return x(e,"POST","/v2/accounts/mfaSignIn:finalize",S(e,{mfaPendingCredential:t,mfaEnrollmentId:this.enrollmentId,totpVerificationInfo:n}))}}class tJ{constructor(e,t,n,r,i,s,a){this.sessionInfo=s,this.auth=a,this.secretKey=e,this.hashingAlgorithm=t,this.codeLength=n,this.codeIntervalSeconds=r,this.enrollmentCompletionDeadline=i}static _fromStartTotpMfaEnrollmentResponse(e,t){return new tJ(e.totpSessionInfo.sharedSecretKey,e.totpSessionInfo.hashingAlgorithm,e.totpSessionInfo.verificationCodeLength,e.totpSessionInfo.periodSec,new Date(e.totpSessionInfo.finalizeEnrollmentTime).toUTCString(),e.totpSessionInfo.sessionInfo,t)}_makeTotpVerificationInfo(e){return{sessionInfo:this.sessionInfo,verificationCode:e}}generateQrCodeUrl(e,t){var n;let r=!1;return(tX(e)||tX(t))&&(r=!0),r&&(tX(e)&&(e=(null===(n=this.auth.currentUser)||void 0===n?void 0:n.email)||"unknownuser"),tX(t)&&(t=this.auth.name)),`otpauth://totp/${t}:${e}?secret=${this.secretKey}&issuer=${t}&algorithm=${this.hashingAlgorithm}&digits=${this.codeLength}`}}function tX(e){return void 0===e||(null==e?void 0:e.length)===0}var tY="@firebase/auth",t0="0.23.2";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class t1{constructor(e){this.auth=e,this.internalListeners=new Map}getUid(){var e;return this.assertAuthConfigured(),(null===(e=this.auth.currentUser)||void 0===e?void 0:e.uid)||null}async getToken(e){if(this.assertAuthConfigured(),await this.auth._initializationPromise,!this.auth.currentUser)return null;let t=await this.auth.currentUser.getIdToken(e);return{accessToken:t}}addAuthTokenListener(e){if(this.assertAuthConfigured(),this.internalListeners.has(e))return;let t=this.auth.onIdTokenChanged(t=>{e((null==t?void 0:t.stsTokenManager.accessToken)||null)});this.internalListeners.set(e,t),this.updateProactiveRefresh()}removeAuthTokenListener(e){this.assertAuthConfigured();let t=this.internalListeners.get(e);t&&(this.internalListeners.delete(e),t(),this.updateProactiveRefresh())}assertAuthConfigured(){y(this.auth._initializationPromise,"dependent-sdk-initialized-before-auth")}updateProactiveRefresh(){this.internalListeners.size>0?this.auth._startProactiveRefresh():this.auth._stopProactiveRefresh()}}let t2=(0,i.Pz)("authIdTokenMaxAge")||300,t4=null,t9=e=>async t=>{let n=t&&await t.getIdTokenResult(),r=n&&(new Date().getTime()-Date.parse(n.issuedAtTime))/1e3;if(r&&r>t2)return;let i=null==n?void 0:n.token;t4!==i&&(t4=i,await fetch(e,{method:i?"POST":"DELETE",headers:i?{Authorization:`Bearer ${i}`}:{}}))};function t6(e=(0,s.Mq)()){let t=(0,s.qX)(e,"auth");if(t.isInitialized())return t.getImmediate();let n=/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function(e,t){let n=(0,s.qX)(e,"auth");if(n.isInitialized()){let e=n.getImmediate(),r=n.getOptions();if((0,i.vZ)(r,null!=t?t:{}))return e;f(e,"already-initialized")}let r=n.initialize({options:t});return r}(e,{popupRedirectResolver:tG,persistence:[th,e9,e6]}),r=(0,i.Pz)("authTokenSyncURL");if(r){let e=t9(r);(0,i.m9)(n).beforeAuthStateChanged(e,()=>e(n.currentUser)),(0,i.m9)(n).onIdTokenChanged(t=>e(t),void 0,void 0)}let a=(0,i.q4)("auth");return a&&function(e,t,n){let r=ew(e);y(r._canInitEmulator,r,"emulator-config-failed"),y(/^https?:\/\//.test(t),r,"invalid-emulator-scheme");let i=!!(null==n?void 0:n.disableWarnings),s=eE(t),{host:a,port:o}=function(e){let t=eE(e),n=/(\/\/)?([^?#/]+)/.exec(e.substr(t.length));if(!n)return{host:"",port:null};let r=n[2].split("@").pop()||"",i=/^(\[[^\]]+\])(:|$)/.exec(r);if(i){let e=i[1];return{host:e,port:eI(r.substr(e.length+1))}}{let[e,t]=r.split(":");return{host:e,port:eI(t)}}}(t),l=null===o?"":`:${o}`;r.config.emulator={url:`${s}//${a}${l}/`},r.settings.appVerificationDisabledForTesting=!0,r.emulatorConfig=Object.freeze({host:a,port:o,protocol:s.replace(":",""),options:Object.freeze({disableWarnings:i})}),i||function(){function e(){let e=document.createElement("p"),t=e.style;e.innerText="Running in emulator mode. Do not use with production credentials.",t.position="fixed",t.width="100%",t.backgroundColor="#ffffff",t.border=".1em solid #000000",t.color="#b50000",t.bottom="0px",t.left="0px",t.margin="0px",t.zIndex="10000",t.textAlign="center",e.classList.add("firebase-emulator-warning"),document.body.appendChild(e)}"undefined"!=typeof console&&"function"==typeof console.info&&console.info("WARNING: You are using the Auth Emulator, which is intended for local testing only.  Do not use with production credentials."),"undefined"!=typeof window&&"undefined"!=typeof document&&("loading"===document.readyState?window.addEventListener("DOMContentLoaded",e):e())}()}(n,`http://${a}`),n}r="Browser",(0,s.Xd)(new l.wA("auth",(e,{options:t})=>{let n=e.getProvider("app").getImmediate(),i=e.getProvider("heartbeat"),s=e.getProvider("app-check-internal"),{apiKey:a,authDomain:o}=n.options;y(a&&!a.includes(":"),"invalid-api-key",{appName:n.name});let l={apiKey:a,authDomain:o,clientPlatform:r,apiHost:"identitytoolkit.googleapis.com",tokenApiHost:"securetoken.googleapis.com",apiScheme:"https",sdkClientVersion:eu(r)},u=new ev(n,i,s,l);return function(e,t){let n=(null==t?void 0:t.persistence)||[],r=(Array.isArray(n)?n:[n]).map(Q);(null==t?void 0:t.errorMap)&&e._updateErrorMap(t.errorMap),e._initializeWithPersistence(r,null==t?void 0:t.popupRedirectResolver)}(u,t),u},"PUBLIC").setInstantiationMode("EXPLICIT").setInstanceCreatedCallback((e,t,n)=>{let r=e.getProvider("auth-internal");r.initialize()})),(0,s.Xd)(new l.wA("auth-internal",e=>{let t=ew(e.getProvider("auth").getImmediate());return new t1(t)},"PRIVATE").setInstantiationMode("EXPLICIT")),(0,s.KN)(tY,t0,/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function(e){switch(e){case"Node":return"node";case"ReactNative":return"rn";case"Worker":return"webworker";case"Cordova":return"cordova";default:return}}(r)),(0,s.KN)(tY,t0,"esm2017")},4091:function(e,t,n){"use strict";n.d(t,{EK:function(){return rd},hJ:function(){return o1},oe:function(){return lQ},JU:function(){return o2},Yp:function(){return lY},QT:function(){return lH},PL:function(){return lG},ad:function(){return o5},b9:function(){return lO},cf:function(){return lZ},Xo:function(){return lR},IO:function(){return lS},TQ:function(){return lL},r7:function(){return lW},ar:function(){return lC}});var r,i,s,a,o,l,u,c=n(3991),h=n(5538),d=n(6914),f=n(8745),p="undefined"!=typeof globalThis?globalThis:"undefined"!=typeof window?window:"undefined"!=typeof global?global:"undefined"!=typeof self?self:{},g={},m=m||{},y=p||self;function v(e){var t=typeof e;return"array"==(t="object"!=t?t:e?Array.isArray(e)?"array":t:"null")||"object"==t&&"number"==typeof e.length}function w(e){var t=typeof e;return"object"==t&&null!=e||"function"==t}function b(e,t,n){return e.call.apply(e.bind,arguments)}function E(e,t,n){if(!e)throw Error();if(2<arguments.length){var r=Array.prototype.slice.call(arguments,2);return function(){var n=Array.prototype.slice.call(arguments);return Array.prototype.unshift.apply(n,r),e.apply(t,n)}}return function(){return e.apply(t,arguments)}}function I(e,t,n){return(I=Function.prototype.bind&&-1!=Function.prototype.bind.toString().indexOf("native code")?b:E).apply(null,arguments)}function _(e,t){var n=Array.prototype.slice.call(arguments,1);return function(){var t=n.slice();return t.push.apply(t,arguments),e.apply(this,t)}}function T(e,t){function n(){}n.prototype=t.prototype,e.$=t.prototype,e.prototype=new n,e.prototype.constructor=e,e.ac=function(e,n,r){for(var i=Array(arguments.length-2),s=2;s<arguments.length;s++)i[s-2]=arguments[s];return t.prototype[n].apply(e,i)}}function k(){this.s=this.s,this.o=this.o}k.prototype.s=!1,k.prototype.sa=function(){this.s||(this.s=!0,this.N())},k.prototype.N=function(){if(this.o)for(;this.o.length;)this.o.shift()()};let S=Array.prototype.indexOf?function(e,t){return Array.prototype.indexOf.call(e,t,void 0)}:function(e,t){if("string"==typeof e)return"string"!=typeof t||1!=t.length?-1:e.indexOf(t,0);for(let n=0;n<e.length;n++)if(n in e&&e[n]===t)return n;return -1};function x(e){let t=e.length;if(0<t){let n=Array(t);for(let r=0;r<t;r++)n[r]=e[r];return n}return[]}function C(e,t){for(let t=1;t<arguments.length;t++){let n=arguments[t];if(v(n)){let t=e.length||0,r=n.length||0;e.length=t+r;for(let i=0;i<r;i++)e[t+i]=n[i]}else e.push(n)}}function A(e,t){this.type=e,this.g=this.target=t,this.defaultPrevented=!1}A.prototype.h=function(){this.defaultPrevented=!0};var N=function(){if(!y.addEventListener||!Object.defineProperty)return!1;var e=!1,t=Object.defineProperty({},"passive",{get:function(){e=!0}});try{y.addEventListener("test",()=>{},t),y.removeEventListener("test",()=>{},t)}catch(e){}return e}();function R(e){return/^[\s\xa0]*$/.test(e)}function D(){var e=y.navigator;return e&&(e=e.userAgent)?e:""}function O(e){return -1!=D().indexOf(e)}function P(e){return P[" "](e),e}P[" "]=function(){};var L=O("Opera"),M=O("Trident")||O("MSIE"),F=O("Edge"),V=F||M,U=O("Gecko")&&!(-1!=D().toLowerCase().indexOf("webkit")&&!O("Edge"))&&!(O("Trident")||O("MSIE"))&&!O("Edge"),j=-1!=D().toLowerCase().indexOf("webkit")&&!O("Edge");function B(){var e=y.document;return e?e.documentMode:void 0}e:{var q,z="",$=(q=D(),U?/rv:([^\);]+)(\)|;)/.exec(q):F?/Edge\/([\d\.]+)/.exec(q):M?/\b(?:MSIE|rv)[: ]([^\);]+)(\)|;)/.exec(q):j?/WebKit\/(\S+)/.exec(q):L?/(?:Version)[ \/]?(\S+)/.exec(q):void 0);if($&&(z=$?$[1]:""),M){var H=B();if(null!=H&&H>parseFloat(z)){i=String(H);break e}}i=z}var K=y.document&&M&&(B()||parseInt(i,10))||void 0;function G(e,t){if(A.call(this,e?e.type:""),this.relatedTarget=this.g=this.target=null,this.button=this.screenY=this.screenX=this.clientY=this.clientX=0,this.key="",this.metaKey=this.shiftKey=this.altKey=this.ctrlKey=!1,this.state=null,this.pointerId=0,this.pointerType="",this.i=null,e){var n=this.type=e.type,r=e.changedTouches&&e.changedTouches.length?e.changedTouches[0]:null;if(this.target=e.target||e.srcElement,this.g=t,t=e.relatedTarget){if(U){e:{try{P(t.nodeName);var i=!0;break e}catch(e){}i=!1}i||(t=null)}}else"mouseover"==n?t=e.fromElement:"mouseout"==n&&(t=e.toElement);this.relatedTarget=t,r?(this.clientX=void 0!==r.clientX?r.clientX:r.pageX,this.clientY=void 0!==r.clientY?r.clientY:r.pageY,this.screenX=r.screenX||0,this.screenY=r.screenY||0):(this.clientX=void 0!==e.clientX?e.clientX:e.pageX,this.clientY=void 0!==e.clientY?e.clientY:e.pageY,this.screenX=e.screenX||0,this.screenY=e.screenY||0),this.button=e.button,this.key=e.key||"",this.ctrlKey=e.ctrlKey,this.altKey=e.altKey,this.shiftKey=e.shiftKey,this.metaKey=e.metaKey,this.pointerId=e.pointerId||0,this.pointerType="string"==typeof e.pointerType?e.pointerType:W[e.pointerType]||"",this.state=e.state,this.i=e,e.defaultPrevented&&G.$.h.call(this)}}T(G,A);var W={2:"touch",3:"pen",4:"mouse"};G.prototype.h=function(){G.$.h.call(this);var e=this.i;e.preventDefault?e.preventDefault():e.returnValue=!1};var Q="closure_listenable_"+(1e6*Math.random()|0),Z=0;function J(e,t,n,r,i){this.listener=e,this.proxy=null,this.src=t,this.type=n,this.capture=!!r,this.la=i,this.key=++Z,this.fa=this.ia=!1}function X(e){e.fa=!0,e.listener=null,e.proxy=null,e.src=null,e.la=null}function Y(e,t,n){for(let r in e)t.call(n,e[r],r,e)}function ee(e){let t={};for(let n in e)t[n]=e[n];return t}let et="constructor hasOwnProperty isPrototypeOf propertyIsEnumerable toLocaleString toString valueOf".split(" ");function en(e,t){let n,r;for(let t=1;t<arguments.length;t++){for(n in r=arguments[t])e[n]=r[n];for(let t=0;t<et.length;t++)n=et[t],Object.prototype.hasOwnProperty.call(r,n)&&(e[n]=r[n])}}function er(e){this.src=e,this.g={},this.h=0}function ei(e,t){var n=t.type;if(n in e.g){var r,i=e.g[n],s=S(i,t);(r=0<=s)&&Array.prototype.splice.call(i,s,1),r&&(X(t),0==e.g[n].length&&(delete e.g[n],e.h--))}}function es(e,t,n,r){for(var i=0;i<e.length;++i){var s=e[i];if(!s.fa&&s.listener==t&&!!n==s.capture&&s.la==r)return i}return -1}er.prototype.add=function(e,t,n,r,i){var s=e.toString();(e=this.g[s])||(e=this.g[s]=[],this.h++);var a=es(e,t,r,i);return -1<a?(t=e[a],n||(t.ia=!1)):((t=new J(t,this.src,s,!!r,i)).ia=n,e.push(t)),t};var ea="closure_lm_"+(1e6*Math.random()|0),eo={};function el(e,t,n,r,i,s){if(!t)throw Error("Invalid event type");var a=w(i)?!!i.capture:!!i,o=ed(e);if(o||(e[ea]=o=new er(e)),(n=o.add(t,n,r,a,s)).proxy)return n;if(r=function e(t){return eh.call(e.src,e.listener,t)},n.proxy=r,r.src=e,r.listener=n,e.addEventListener)N||(i=a),void 0===i&&(i=!1),e.addEventListener(t.toString(),r,i);else if(e.attachEvent)e.attachEvent(ec(t.toString()),r);else if(e.addListener&&e.removeListener)e.addListener(r);else throw Error("addEventListener and attachEvent are unavailable.");return n}function eu(e){if("number"!=typeof e&&e&&!e.fa){var t=e.src;if(t&&t[Q])ei(t.i,e);else{var n=e.type,r=e.proxy;t.removeEventListener?t.removeEventListener(n,r,e.capture):t.detachEvent?t.detachEvent(ec(n),r):t.addListener&&t.removeListener&&t.removeListener(r),(n=ed(t))?(ei(n,e),0==n.h&&(n.src=null,t[ea]=null)):X(e)}}}function ec(e){return e in eo?eo[e]:eo[e]="on"+e}function eh(e,t){if(e.fa)e=!0;else{t=new G(t,this);var n=e.listener,r=e.la||e.src;e.ia&&eu(e),e=n.call(r,t)}return e}function ed(e){return(e=e[ea])instanceof er?e:null}var ef="__closure_events_fn_"+(1e9*Math.random()>>>0);function ep(e){return"function"==typeof e?e:(e[ef]||(e[ef]=function(t){return e.handleEvent(t)}),e[ef])}function eg(){k.call(this),this.i=new er(this),this.S=this,this.J=null}function em(e,t){var n,r=e.J;if(r)for(n=[];r;r=r.J)n.push(r);if(e=e.S,r=t.type||t,"string"==typeof t)t=new A(t,e);else if(t instanceof A)t.target=t.target||e;else{var i=t;en(t=new A(r,e),i)}if(i=!0,n)for(var s=n.length-1;0<=s;s--){var a=t.g=n[s];i=ey(a,r,!0,t)&&i}if(i=ey(a=t.g=e,r,!0,t)&&i,i=ey(a,r,!1,t)&&i,n)for(s=0;s<n.length;s++)i=ey(a=t.g=n[s],r,!1,t)&&i}function ey(e,t,n,r){if(!(t=e.i.g[String(t)]))return!0;t=t.concat();for(var i=!0,s=0;s<t.length;++s){var a=t[s];if(a&&!a.fa&&a.capture==n){var o=a.listener,l=a.la||a.src;a.ia&&ei(e.i,a),i=!1!==o.call(l,r)&&i}}return i&&!r.defaultPrevented}T(eg,k),eg.prototype[Q]=!0,eg.prototype.removeEventListener=function(e,t,n,r){!function e(t,n,r,i,s){if(Array.isArray(n))for(var a=0;a<n.length;a++)e(t,n[a],r,i,s);else(i=w(i)?!!i.capture:!!i,r=ep(r),t&&t[Q])?(t=t.i,(n=String(n).toString())in t.g&&-1<(r=es(a=t.g[n],r,i,s))&&(X(a[r]),Array.prototype.splice.call(a,r,1),0==a.length&&(delete t.g[n],t.h--))):t&&(t=ed(t))&&(n=t.g[n.toString()],t=-1,n&&(t=es(n,r,i,s)),(r=-1<t?n[t]:null)&&eu(r))}(this,e,t,n,r)},eg.prototype.N=function(){if(eg.$.N.call(this),this.i){var e,t=this.i;for(e in t.g){for(var n=t.g[e],r=0;r<n.length;r++)X(n[r]);delete t.g[e],t.h--}}this.J=null},eg.prototype.O=function(e,t,n,r){return this.i.add(String(e),t,!1,n,r)},eg.prototype.P=function(e,t,n,r){return this.i.add(String(e),t,!0,n,r)};var ev=y.JSON.stringify,ew=new class{constructor(e,t){this.i=e,this.j=t,this.h=0,this.g=null}get(){let e;return 0<this.h?(this.h--,e=this.g,this.g=e.next,e.next=null):e=this.i(),e}}(()=>new eb,e=>e.reset());class eb{constructor(){this.next=this.g=this.h=null}set(e,t){this.h=e,this.g=t,this.next=null}reset(){this.next=this.g=this.h=null}}let eE,eI=!1,e_=new class{constructor(){this.h=this.g=null}add(e,t){let n=ew.get();n.set(e,t),this.h?this.h.next=n:this.g=n,this.h=n}},eT=()=>{let e=y.Promise.resolve(void 0);eE=()=>{e.then(ek)}};var ek=()=>{let e;for(var t;e=null,e_.g&&(e=e_.g,e_.g=e_.g.next,e_.g||(e_.h=null),e.next=null),t=e;){try{t.h.call(t.g)}catch(e){!function(e){y.setTimeout(()=>{throw e},0)}(e)}ew.j(t),100>ew.h&&(ew.h++,t.next=ew.g,ew.g=t)}eI=!1};function eS(e,t){eg.call(this),this.h=e||1,this.g=t||y,this.j=I(this.qb,this),this.l=Date.now()}function ex(e){e.ga=!1,e.T&&(e.g.clearTimeout(e.T),e.T=null)}function eC(e,t,n){if("function"==typeof e)n&&(e=I(e,n));else if(e&&"function"==typeof e.handleEvent)e=I(e.handleEvent,e);else throw Error("Invalid listener argument");return 2147483647<Number(t)?-1:y.setTimeout(e,t||0)}T(eS,eg),(u=eS.prototype).ga=!1,u.T=null,u.qb=function(){if(this.ga){var e=Date.now()-this.l;0<e&&e<.8*this.h?this.T=this.g.setTimeout(this.j,this.h-e):(this.T&&(this.g.clearTimeout(this.T),this.T=null),em(this,"tick"),this.ga&&(ex(this),this.start()))}},u.start=function(){this.ga=!0,this.T||(this.T=this.g.setTimeout(this.j,this.h),this.l=Date.now())},u.N=function(){eS.$.N.call(this),ex(this),delete this.g};class eA extends k{constructor(e,t){super(),this.m=e,this.j=t,this.h=null,this.i=!1,this.g=null}l(e){this.h=arguments,this.g?this.i=!0:function e(t){t.g=eC(()=>{t.g=null,t.i&&(t.i=!1,e(t))},t.j);let n=t.h;t.h=null,t.m.apply(null,n)}(this)}N(){super.N(),this.g&&(y.clearTimeout(this.g),this.g=null,this.i=!1,this.h=null)}}function eN(e){k.call(this),this.h=e,this.g={}}T(eN,k);var eR=[];function eD(e,t,n,r){Array.isArray(n)||(n&&(eR[0]=n.toString()),n=eR);for(var i=0;i<n.length;i++){var s=function e(t,n,r,i,s){if(i&&i.once)return function e(t,n,r,i,s){if(Array.isArray(n)){for(var a=0;a<n.length;a++)e(t,n[a],r,i,s);return null}return r=ep(r),t&&t[Q]?t.P(n,r,w(i)?!!i.capture:!!i,s):el(t,n,r,!0,i,s)}(t,n,r,i,s);if(Array.isArray(n)){for(var a=0;a<n.length;a++)e(t,n[a],r,i,s);return null}return r=ep(r),t&&t[Q]?t.O(n,r,w(i)?!!i.capture:!!i,s):el(t,n,r,!1,i,s)}(t,n[i],r||e.handleEvent,!1,e.h||e);if(!s)break;e.g[s.key]=s}}function eO(e){Y(e.g,function(e,t){this.g.hasOwnProperty(t)&&eu(e)},e),e.g={}}function eP(){this.g=!0}function eL(e,t,n,r){e.info(function(){return"XMLHTTP TEXT ("+t+"): "+function(e,t){if(!e.g)return t;if(!t)return null;try{var n=JSON.parse(t);if(n){for(e=0;e<n.length;e++)if(Array.isArray(n[e])){var r=n[e];if(!(2>r.length)){var i=r[1];if(Array.isArray(i)&&!(1>i.length)){var s=i[0];if("noop"!=s&&"stop"!=s&&"close"!=s)for(var a=1;a<i.length;a++)i[a]=""}}}}return ev(n)}catch(e){return t}}(e,n)+(r?" "+r:"")})}eN.prototype.N=function(){eN.$.N.call(this),eO(this)},eN.prototype.handleEvent=function(){throw Error("EventHandler.handleEvent not implemented")},eP.prototype.Ea=function(){this.g=!1},eP.prototype.info=function(){};var eM={},eF=null;function eV(){return eF=eF||new eg}function eU(e){A.call(this,eM.Ta,e)}function ej(e){let t=eV();em(t,new eU(t))}function eB(e,t){A.call(this,eM.STAT_EVENT,e),this.stat=t}function eq(e){let t=eV();em(t,new eB(t,e))}function ez(e,t){A.call(this,eM.Ua,e),this.size=t}function e$(e,t){if("function"!=typeof e)throw Error("Fn must not be null and must be a function");return y.setTimeout(function(){e()},t)}eM.Ta="serverreachability",T(eU,A),eM.STAT_EVENT="statevent",T(eB,A),eM.Ua="timingevent",T(ez,A);var eH={NO_ERROR:0,rb:1,Eb:2,Db:3,yb:4,Cb:5,Fb:6,Qa:7,TIMEOUT:8,Ib:9},eK={wb:"complete",Sb:"success",Ra:"error",Qa:"abort",Kb:"ready",Lb:"readystatechange",TIMEOUT:"timeout",Gb:"incrementaldata",Jb:"progress",zb:"downloadprogress",$b:"uploadprogress"};function eG(){}function eW(e){return e.h||(e.h=e.i())}function eQ(){}eG.prototype.h=null;var eZ={OPEN:"a",vb:"b",Ra:"c",Hb:"d"};function eJ(){A.call(this,"d")}function eX(){A.call(this,"c")}function eY(){}function e0(e,t,n,r){this.l=e,this.j=t,this.m=n,this.W=r||1,this.U=new eN(this),this.P=e2,e=V?125:void 0,this.V=new eS(e),this.I=null,this.i=!1,this.s=this.A=this.v=this.L=this.G=this.Y=this.B=null,this.F=[],this.g=null,this.C=0,this.o=this.u=null,this.ca=-1,this.J=!1,this.O=0,this.M=null,this.ba=this.K=this.aa=this.S=!1,this.h=new e1}function e1(){this.i=null,this.g="",this.h=!1}T(eJ,A),T(eX,A),T(eY,eG),eY.prototype.g=function(){return new XMLHttpRequest},eY.prototype.i=function(){return{}},a=new eY;var e2=45e3,e4={},e9={};function e6(e,t,n){e.L=1,e.v=tf(tl(t)),e.s=n,e.S=!0,e5(e,null)}function e5(e,t){e.G=Date.now(),e8(e),e.A=tl(e.v);var n=e.A,r=e.W;Array.isArray(r)||(r=[String(r)]),tS(n.i,"t",r),e.C=0,n=e.l.J,e.h=new e1,e.g=ng(e.l,n?t:null,!e.s),0<e.O&&(e.M=new eA(I(e.Pa,e,e.g),e.O)),eD(e.U,e.g,"readystatechange",e.nb),t=e.I?ee(e.I):{},e.s?(e.u||(e.u="POST"),t["Content-Type"]="application/x-www-form-urlencoded",e.g.ha(e.A,e.u,e.s,t)):(e.u="GET",e.g.ha(e.A,e.u,null,t)),ej(),function(e,t,n,r,i,s){e.info(function(){if(e.g){if(s)for(var a="",o=s.split("&"),l=0;l<o.length;l++){var u=o[l].split("=");if(1<u.length){var c=u[0];u=u[1];var h=c.split("_");a=2<=h.length&&"type"==h[1]?a+(c+"=")+u+"&":a+(c+"=redacted&")}}else a=null}else a=s;return"XMLHTTP REQ ("+r+") [attempt "+i+"]: "+t+"\n"+n+"\n"+a})}(e.j,e.u,e.A,e.m,e.W,e.s)}function e7(e){return!!e.g&&"GET"==e.u&&2!=e.L&&e.l.Ha}function e3(e,t,n){let r=!0,i;for(;!e.J&&e.C<n.length;)if((i=function(e,t){var n=e.C,r=t.indexOf("\n",n);return -1==r?e9:isNaN(n=Number(t.substring(n,r)))?e4:(r+=1)+n>t.length?e9:(t=t.slice(r,r+n),e.C=r+n,t)}(e,n))==e9){4==t&&(e.o=4,eq(14),r=!1),eL(e.j,e.m,null,"[Incomplete Response]");break}else if(i==e4){e.o=4,eq(15),eL(e.j,e.m,n,"[Invalid Chunk]"),r=!1;break}else eL(e.j,e.m,i,null),ti(e,i);e7(e)&&i!=e9&&i!=e4&&(e.h.g="",e.C=0),4!=t||0!=n.length||e.h.h||(e.o=1,eq(16),r=!1),e.i=e.i&&r,r?0<n.length&&!e.ba&&(e.ba=!0,(t=e.l).g==e&&t.ca&&!t.M&&(t.l.info("Great, no buffering proxy detected. Bytes received: "+n.length),no(t),t.M=!0,eq(11))):(eL(e.j,e.m,n,"[Invalid Chunked Response]"),tr(e),tn(e))}function e8(e){e.Y=Date.now()+e.P,te(e,e.P)}function te(e,t){if(null!=e.B)throw Error("WatchDog timer not null");e.B=e$(I(e.lb,e),t)}function tt(e){e.B&&(y.clearTimeout(e.B),e.B=null)}function tn(e){0==e.l.H||e.J||nc(e.l,e)}function tr(e){tt(e);var t=e.M;t&&"function"==typeof t.sa&&t.sa(),e.M=null,ex(e.V),eO(e.U),e.g&&(t=e.g,e.g=null,t.abort(),t.sa())}function ti(e,t){try{var n=e.l;if(0!=n.H&&(n.g==e||tO(n.i,e))){if(!e.K&&tO(n.i,e)&&3==n.H){try{var r=n.Ja.g.parse(t)}catch(e){r=null}if(Array.isArray(r)&&3==r.length){var i=r;if(0==i[0]){e:if(!n.u){if(n.g){if(n.g.G+3e3<e.G)nu(n),t8(n);else break e}na(n),eq(18)}}else n.Fa=i[1],0<n.Fa-n.V&&37500>i[2]&&n.G&&0==n.A&&!n.v&&(n.v=e$(I(n.ib,n),6e3));if(1>=tD(n.i)&&n.oa){try{n.oa()}catch(e){}n.oa=void 0}}else nd(n,11)}else if((e.K||n.g==e)&&nu(n),!R(t))for(i=n.Ja.g.parse(t),t=0;t<i.length;t++){let o=i[t];if(n.V=o[0],o=o[1],2==n.H){if("c"==o[0]){n.K=o[1],n.pa=o[2];let t=o[3];null!=t&&(n.ra=t,n.l.info("VER="+n.ra));let i=o[4];null!=i&&(n.Ga=i,n.l.info("SVER="+n.Ga));let l=o[5];null!=l&&"number"==typeof l&&0<l&&(r=1.5*l,n.L=r,n.l.info("backChannelRequestTimeoutMs_="+r)),r=n;let u=e.g;if(u){let e=u.g?u.g.getResponseHeader("X-Client-Wire-Protocol"):null;if(e){var s=r.i;s.g||-1==e.indexOf("spdy")&&-1==e.indexOf("quic")&&-1==e.indexOf("h2")||(s.j=s.l,s.g=new Set,s.h&&(tP(s,s.h),s.h=null))}if(r.F){let e=u.g?u.g.getResponseHeader("X-HTTP-Session-Id"):null;e&&(r.Da=e,td(r.I,r.F,e))}}if(n.H=3,n.h&&n.h.Ba(),n.ca&&(n.S=Date.now()-e.G,n.l.info("Handshake RTT: "+n.S+"ms")),(r=n).wa=np(r,r.J?r.pa:null,r.Y),e.K){tL(r.i,e);var a=r.L;a&&e.setTimeout(a),e.B&&(tt(e),e8(e)),r.g=e}else ns(r);0<n.j.length&&nt(n)}else"stop"!=o[0]&&"close"!=o[0]||nd(n,7)}else 3==n.H&&("stop"==o[0]||"close"==o[0]?"stop"==o[0]?nd(n,7):t3(n):"noop"!=o[0]&&n.h&&n.h.Aa(o),n.A=0)}}ej(4)}catch(e){}}function ts(e,t){if(e.forEach&&"function"==typeof e.forEach)e.forEach(t,void 0);else if(v(e)||"string"==typeof e)Array.prototype.forEach.call(e,t,void 0);else for(var n=function(e){if(e.ta&&"function"==typeof e.ta)return e.ta();if(!e.Z||"function"!=typeof e.Z){if("undefined"!=typeof Map&&e instanceof Map)return Array.from(e.keys());if(!("undefined"!=typeof Set&&e instanceof Set)){if(v(e)||"string"==typeof e){var t=[];e=e.length;for(var n=0;n<e;n++)t.push(n);return t}for(let r in t=[],n=0,e)t[n++]=r;return t}}}(e),r=function(e){if(e.Z&&"function"==typeof e.Z)return e.Z();if("undefined"!=typeof Map&&e instanceof Map||"undefined"!=typeof Set&&e instanceof Set)return Array.from(e.values());if("string"==typeof e)return e.split("");if(v(e)){for(var t=[],n=e.length,r=0;r<n;r++)t.push(e[r]);return t}for(r in t=[],n=0,e)t[n++]=e[r];return t}(e),i=r.length,s=0;s<i;s++)t.call(void 0,r[s],n&&n[s],e)}(u=e0.prototype).setTimeout=function(e){this.P=e},u.nb=function(e){e=e.target;let t=this.M;t&&3==t2(e)?t.l():this.Pa(e)},u.Pa=function(e){try{if(e==this.g)e:{let c=t2(this.g);var t=this.g.Ia();let h=this.g.da();if(!(3>c)&&(3!=c||V||this.g&&(this.h.h||this.g.ja()||t4(this.g)))){this.J||4!=c||7==t||(8==t||0>=h?ej(3):ej(2)),tt(this);var n=this.g.da();this.ca=n;t:if(e7(this)){var r=t4(this.g);e="";var i=r.length,s=4==t2(this.g);if(!this.h.i){if("undefined"==typeof TextDecoder){tr(this),tn(this);var a="";break t}this.h.i=new y.TextDecoder}for(t=0;t<i;t++)this.h.h=!0,e+=this.h.i.decode(r[t],{stream:s&&t==i-1});r.splice(0,i),this.h.g+=e,this.C=0,a=this.h.g}else a=this.g.ja();if(this.i=200==n,function(e,t,n,r,i,s,a){e.info(function(){return"XMLHTTP RESP ("+r+") [ attempt "+i+"]: "+t+"\n"+n+"\n"+s+" "+a})}(this.j,this.u,this.A,this.m,this.W,c,n),this.i){if(this.aa&&!this.K){t:{if(this.g){var o,l=this.g;if((o=l.g?l.g.getResponseHeader("X-HTTP-Initial-Response"):null)&&!R(o)){var u=o;break t}}u=null}if(n=u)eL(this.j,this.m,n,"Initial handshake response via X-HTTP-Initial-Response"),this.K=!0,ti(this,n);else{this.i=!1,this.o=3,eq(12),tr(this),tn(this);break e}}this.S?(e3(this,c,a),V&&this.i&&3==c&&(eD(this.U,this.V,"tick",this.mb),this.V.start())):(eL(this.j,this.m,a,null),ti(this,a)),4==c&&tr(this),this.i&&!this.J&&(4==c?nc(this.l,this):(this.i=!1,e8(this)))}else(function(e){let t={};e=(e.g&&2<=t2(e)&&e.g.getAllResponseHeaders()||"").split("\r\n");for(let r=0;r<e.length;r++){if(R(e[r]))continue;var n=function(e){var t=1;e=e.split(":");let n=[];for(;0<t&&e.length;)n.push(e.shift()),t--;return e.length&&n.push(e.join(":")),n}(e[r]);let i=n[0];if("string"!=typeof(n=n[1]))continue;n=n.trim();let s=t[i]||[];t[i]=s,s.push(n)}!function(e,t){for(let n in e)t.call(void 0,e[n],n,e)}(t,function(e){return e.join(", ")})})(this.g),400==n&&0<a.indexOf("Unknown SID")?(this.o=3,eq(12)):(this.o=0,eq(13)),tr(this),tn(this)}}}catch(e){}finally{}},u.mb=function(){if(this.g){var e=t2(this.g),t=this.g.ja();this.C<t.length&&(tt(this),e3(this,e,t),this.i&&4!=e&&e8(this))}},u.cancel=function(){this.J=!0,tr(this)},u.lb=function(){this.B=null;let e=Date.now();0<=e-this.Y?(function(e,t){e.info(function(){return"TIMEOUT: "+t})}(this.j,this.A),2!=this.L&&(ej(),eq(17)),tr(this),this.o=2,tn(this)):te(this,this.Y-e)};var ta=RegExp("^(?:([^:/?#.]+):)?(?://(?:([^\\\\/?#]*)@)?([^\\\\/?#]*?)(?::([0-9]+))?(?=[\\\\/?#]|$))?([^?#]+)?(?:\\?([^#]*))?(?:#([\\s\\S]*))?$");function to(e){if(this.g=this.s=this.j="",this.m=null,this.o=this.l="",this.h=!1,e instanceof to){this.h=e.h,tu(this,e.j),this.s=e.s,this.g=e.g,tc(this,e.m),this.l=e.l;var t=e.i,n=new tI;n.i=t.i,t.g&&(n.g=new Map(t.g),n.h=t.h),th(this,n),this.o=e.o}else e&&(t=String(e).match(ta))?(this.h=!1,tu(this,t[1]||"",!0),this.s=tp(t[2]||""),this.g=tp(t[3]||"",!0),tc(this,t[4]),this.l=tp(t[5]||"",!0),th(this,t[6]||"",!0),this.o=tp(t[7]||"")):(this.h=!1,this.i=new tI(null,this.h))}function tl(e){return new to(e)}function tu(e,t,n){e.j=n?tp(t,!0):t,e.j&&(e.j=e.j.replace(/:$/,""))}function tc(e,t){if(t){if(isNaN(t=Number(t))||0>t)throw Error("Bad port number "+t);e.m=t}else e.m=null}function th(e,t,n){var r,i;t instanceof tI?(e.i=t,r=e.i,(i=e.h)&&!r.j&&(t_(r),r.i=null,r.g.forEach(function(e,t){var n=t.toLowerCase();t!=n&&(tT(this,t),tS(this,n,e))},r)),r.j=i):(n||(t=tg(t,tb)),e.i=new tI(t,e.h))}function td(e,t,n){e.i.set(t,n)}function tf(e){return td(e,"zx",Math.floor(2147483648*Math.random()).toString(36)+Math.abs(Math.floor(2147483648*Math.random())^Date.now()).toString(36)),e}function tp(e,t){return e?t?decodeURI(e.replace(/%25/g,"%2525")):decodeURIComponent(e):""}function tg(e,t,n){return"string"==typeof e?(e=encodeURI(e).replace(t,tm),n&&(e=e.replace(/%25([0-9a-fA-F]{2})/g,"%$1")),e):null}function tm(e){return"%"+((e=e.charCodeAt(0))>>4&15).toString(16)+(15&e).toString(16)}to.prototype.toString=function(){var e=[],t=this.j;t&&e.push(tg(t,ty,!0),":");var n=this.g;return(n||"file"==t)&&(e.push("//"),(t=this.s)&&e.push(tg(t,ty,!0),"@"),e.push(encodeURIComponent(String(n)).replace(/%25([0-9a-fA-F]{2})/g,"%$1")),null!=(n=this.m)&&e.push(":",String(n))),(n=this.l)&&(this.g&&"/"!=n.charAt(0)&&e.push("/"),e.push(tg(n,"/"==n.charAt(0)?tw:tv,!0))),(n=this.i.toString())&&e.push("?",n),(n=this.o)&&e.push("#",tg(n,tE)),e.join("")};var ty=/[#\/\?@]/g,tv=/[#\?:]/g,tw=/[#\?]/g,tb=/[#\?@]/g,tE=/#/g;function tI(e,t){this.h=this.g=null,this.i=e||null,this.j=!!t}function t_(e){e.g||(e.g=new Map,e.h=0,e.i&&function(e,t){if(e){e=e.split("&");for(var n=0;n<e.length;n++){var r=e[n].indexOf("="),i=null;if(0<=r){var s=e[n].substring(0,r);i=e[n].substring(r+1)}else s=e[n];t(s,i?decodeURIComponent(i.replace(/\+/g," ")):"")}}}(e.i,function(t,n){e.add(decodeURIComponent(t.replace(/\+/g," ")),n)}))}function tT(e,t){t_(e),t=tx(e,t),e.g.has(t)&&(e.i=null,e.h-=e.g.get(t).length,e.g.delete(t))}function tk(e,t){return t_(e),t=tx(e,t),e.g.has(t)}function tS(e,t,n){tT(e,t),0<n.length&&(e.i=null,e.g.set(tx(e,t),x(n)),e.h+=n.length)}function tx(e,t){return t=String(t),e.j&&(t=t.toLowerCase()),t}(u=tI.prototype).add=function(e,t){t_(this),this.i=null,e=tx(this,e);var n=this.g.get(e);return n||this.g.set(e,n=[]),n.push(t),this.h+=1,this},u.forEach=function(e,t){t_(this),this.g.forEach(function(n,r){n.forEach(function(n){e.call(t,n,r,this)},this)},this)},u.ta=function(){t_(this);let e=Array.from(this.g.values()),t=Array.from(this.g.keys()),n=[];for(let r=0;r<t.length;r++){let i=e[r];for(let e=0;e<i.length;e++)n.push(t[r])}return n},u.Z=function(e){t_(this);let t=[];if("string"==typeof e)tk(this,e)&&(t=t.concat(this.g.get(tx(this,e))));else{e=Array.from(this.g.values());for(let n=0;n<e.length;n++)t=t.concat(e[n])}return t},u.set=function(e,t){return t_(this),this.i=null,tk(this,e=tx(this,e))&&(this.h-=this.g.get(e).length),this.g.set(e,[t]),this.h+=1,this},u.get=function(e,t){return e&&0<(e=this.Z(e)).length?String(e[0]):t},u.toString=function(){if(this.i)return this.i;if(!this.g)return"";let e=[],t=Array.from(this.g.keys());for(var n=0;n<t.length;n++){var r=t[n];let s=encodeURIComponent(String(r)),a=this.Z(r);for(r=0;r<a.length;r++){var i=s;""!==a[r]&&(i+="="+encodeURIComponent(String(a[r]))),e.push(i)}}return this.i=e.join("&")};var tC=class{constructor(e,t){this.g=e,this.map=t}};function tA(e){this.l=e||tN,e=y.PerformanceNavigationTiming?0<(e=y.performance.getEntriesByType("navigation")).length&&("hq"==e[0].nextHopProtocol||"h2"==e[0].nextHopProtocol):!!(y.g&&y.g.Ka&&y.g.Ka()&&y.g.Ka().ec),this.j=e?this.l:1,this.g=null,1<this.j&&(this.g=new Set),this.h=null,this.i=[]}var tN=10;function tR(e){return!!e.h||!!e.g&&e.g.size>=e.j}function tD(e){return e.h?1:e.g?e.g.size:0}function tO(e,t){return e.h?e.h==t:!!e.g&&e.g.has(t)}function tP(e,t){e.g?e.g.add(t):e.h=t}function tL(e,t){e.h&&e.h==t?e.h=null:e.g&&e.g.has(t)&&e.g.delete(t)}function tM(e){if(null!=e.h)return e.i.concat(e.h.F);if(null!=e.g&&0!==e.g.size){let t=e.i;for(let n of e.g.values())t=t.concat(n.F);return t}return x(e.i)}tA.prototype.cancel=function(){if(this.i=tM(this),this.h)this.h.cancel(),this.h=null;else if(this.g&&0!==this.g.size){for(let e of this.g.values())e.cancel();this.g.clear()}};var tF=class{stringify(e){return y.JSON.stringify(e,void 0)}parse(e){return y.JSON.parse(e,void 0)}};function tV(){this.g=new tF}function tU(e,t,n,r,i){try{t.onload=null,t.onerror=null,t.onabort=null,t.ontimeout=null,i(r)}catch(e){}}function tj(e){this.l=e.fc||null,this.j=e.ob||!1}function tB(e,t){eg.call(this),this.F=e,this.u=t,this.m=void 0,this.readyState=tq,this.status=0,this.responseType=this.responseText=this.response=this.statusText="",this.onreadystatechange=null,this.v=new Headers,this.h=null,this.C="GET",this.B="",this.g=!1,this.A=this.j=this.l=null}T(tj,eG),tj.prototype.g=function(){return new tB(this.l,this.j)},tj.prototype.i=(r={},function(){return r}),T(tB,eg);var tq=0;function tz(e){e.j.read().then(e.Xa.bind(e)).catch(e.ka.bind(e))}function t$(e){e.readyState=4,e.l=null,e.j=null,e.A=null,tH(e)}function tH(e){e.onreadystatechange&&e.onreadystatechange.call(e)}(u=tB.prototype).open=function(e,t){if(this.readyState!=tq)throw this.abort(),Error("Error reopening a connection");this.C=e,this.B=t,this.readyState=1,tH(this)},u.send=function(e){if(1!=this.readyState)throw this.abort(),Error("need to call open() first. ");this.g=!0;let t={headers:this.v,method:this.C,credentials:this.m,cache:void 0};e&&(t.body=e),(this.F||y).fetch(new Request(this.B,t)).then(this.$a.bind(this),this.ka.bind(this))},u.abort=function(){this.response=this.responseText="",this.v=new Headers,this.status=0,this.j&&this.j.cancel("Request was aborted.").catch(()=>{}),1<=this.readyState&&this.g&&4!=this.readyState&&(this.g=!1,t$(this)),this.readyState=tq},u.$a=function(e){if(this.g&&(this.l=e,this.h||(this.status=this.l.status,this.statusText=this.l.statusText,this.h=e.headers,this.readyState=2,tH(this)),this.g&&(this.readyState=3,tH(this),this.g))){if("arraybuffer"===this.responseType)e.arrayBuffer().then(this.Ya.bind(this),this.ka.bind(this));else if(void 0!==y.ReadableStream&&"body"in e){if(this.j=e.body.getReader(),this.u){if(this.responseType)throw Error('responseType must be empty for "streamBinaryChunks" mode responses.');this.response=[]}else this.response=this.responseText="",this.A=new TextDecoder;tz(this)}else e.text().then(this.Za.bind(this),this.ka.bind(this))}},u.Xa=function(e){if(this.g){if(this.u&&e.value)this.response.push(e.value);else if(!this.u){var t=e.value?e.value:new Uint8Array(0);(t=this.A.decode(t,{stream:!e.done}))&&(this.response=this.responseText+=t)}e.done?t$(this):tH(this),3==this.readyState&&tz(this)}},u.Za=function(e){this.g&&(this.response=this.responseText=e,t$(this))},u.Ya=function(e){this.g&&(this.response=e,t$(this))},u.ka=function(){this.g&&t$(this)},u.setRequestHeader=function(e,t){this.v.append(e,t)},u.getResponseHeader=function(e){return this.h&&this.h.get(e.toLowerCase())||""},u.getAllResponseHeaders=function(){if(!this.h)return"";let e=[],t=this.h.entries();for(var n=t.next();!n.done;)e.push((n=n.value)[0]+": "+n[1]),n=t.next();return e.join("\r\n")},Object.defineProperty(tB.prototype,"withCredentials",{get:function(){return"include"===this.m},set:function(e){this.m=e?"include":"same-origin"}});var tK=y.JSON.parse;function tG(e){eg.call(this),this.headers=new Map,this.u=e||null,this.h=!1,this.C=this.g=null,this.I="",this.m=0,this.j="",this.l=this.G=this.v=this.F=!1,this.B=0,this.A=null,this.K=tW,this.L=this.M=!1}T(tG,eg);var tW="",tQ=/^https?$/i,tZ=["POST","PUT"];function tJ(e,t){e.h=!1,e.g&&(e.l=!0,e.g.abort(),e.l=!1),e.j=t,e.m=5,tX(e),t0(e)}function tX(e){e.F||(e.F=!0,em(e,"complete"),em(e,"error"))}function tY(e){if(e.h&&void 0!==m&&(!e.C[1]||4!=t2(e)||2!=e.da())){if(e.v&&4==t2(e))eC(e.La,0,e);else if(em(e,"readystatechange"),4==t2(e)){e.h=!1;try{let a=e.da();switch(a){case 200:case 201:case 202:case 204:case 206:case 304:case 1223:var t,n,r=!0;break;default:r=!1}if(!(t=r)){if(n=0===a){var i=String(e.I).match(ta)[1]||null;!i&&y.self&&y.self.location&&(i=y.self.location.protocol.slice(0,-1)),n=!tQ.test(i?i.toLowerCase():"")}t=n}if(t)em(e,"complete"),em(e,"success");else{e.m=6;try{var s=2<t2(e)?e.g.statusText:""}catch(e){s=""}e.j=s+" ["+e.da()+"]",tX(e)}}finally{t0(e)}}}}function t0(e,t){if(e.g){t1(e);let n=e.g,r=e.C[0]?()=>{}:null;e.g=null,e.C=null,t||em(e,"ready");try{n.onreadystatechange=r}catch(e){}}}function t1(e){e.g&&e.L&&(e.g.ontimeout=null),e.A&&(y.clearTimeout(e.A),e.A=null)}function t2(e){return e.g?e.g.readyState:0}function t4(e){try{if(!e.g)return null;if("response"in e.g)return e.g.response;switch(e.K){case tW:case"text":return e.g.responseText;case"arraybuffer":if("mozResponseArrayBuffer"in e.g)return e.g.mozResponseArrayBuffer}return null}catch(e){return null}}function t9(e){let t="";return Y(e,function(e,n){t+=n+":"+e+"\r\n"}),t}function t6(e,t,n){e:{for(r in n){var r=!1;break e}r=!0}r||(n=t9(n),"string"==typeof e?null!=n&&encodeURIComponent(String(n)):td(e,t,n))}function t5(e,t,n){return n&&n.internalChannelParams&&n.internalChannelParams[e]||t}function t7(e){this.Ga=0,this.j=[],this.l=new eP,this.pa=this.wa=this.I=this.Y=this.g=this.Da=this.F=this.na=this.o=this.U=this.s=null,this.fb=this.W=0,this.cb=t5("failFast",!1,e),this.G=this.v=this.u=this.m=this.h=null,this.aa=!0,this.Fa=this.V=-1,this.ba=this.A=this.C=0,this.ab=t5("baseRetryDelayMs",5e3,e),this.hb=t5("retryDelaySeedMs",1e4,e),this.eb=t5("forwardChannelMaxRetries",2,e),this.xa=t5("forwardChannelRequestTimeoutMs",2e4,e),this.va=e&&e.xmlHttpFactory||void 0,this.Ha=e&&e.dc||!1,this.L=void 0,this.J=e&&e.supportsCrossDomainXhr||!1,this.K="",this.i=new tA(e&&e.concurrentRequestLimit),this.Ja=new tV,this.P=e&&e.fastHandshake||!1,this.O=e&&e.encodeInitMessageHeaders||!1,this.P&&this.O&&(this.O=!1),this.bb=e&&e.bc||!1,e&&e.Ea&&this.l.Ea(),e&&e.forceLongPolling&&(this.aa=!1),this.ca=!this.P&&this.aa&&e&&e.detectBufferingProxy||!1,this.qa=void 0,e&&e.longPollingTimeout&&0<e.longPollingTimeout&&(this.qa=e.longPollingTimeout),this.oa=void 0,this.S=0,this.M=!1,this.ma=this.B=null}function t3(e){if(ne(e),3==e.H){var t=e.W++,n=tl(e.I);if(td(n,"SID",e.K),td(n,"RID",t),td(n,"TYPE","terminate"),nr(e,n),(t=new e0(e,e.l,t)).L=2,t.v=tf(tl(n)),n=!1,y.navigator&&y.navigator.sendBeacon)try{n=y.navigator.sendBeacon(t.v.toString(),"")}catch(e){}!n&&y.Image&&((new Image).src=t.v,n=!0),n||(t.g=ng(t.l,null),t.g.ha(t.v)),t.G=Date.now(),e8(t)}nf(e)}function t8(e){e.g&&(no(e),e.g.cancel(),e.g=null)}function ne(e){t8(e),e.u&&(y.clearTimeout(e.u),e.u=null),nu(e),e.i.cancel(),e.m&&("number"==typeof e.m&&y.clearTimeout(e.m),e.m=null)}function nt(e){if(!tR(e.i)&&!e.m){e.m=!0;var t=e.Na;eE||eT(),eI||(eE(),eI=!0),e_.add(t,e),e.C=0}}function nn(e,t){var n;n=t?t.m:e.W++;let r=tl(e.I);td(r,"SID",e.K),td(r,"RID",n),td(r,"AID",e.V),nr(e,r),e.o&&e.s&&t6(r,e.o,e.s),n=new e0(e,e.l,n,e.C+1),null===e.o&&(n.I=e.s),t&&(e.j=t.F.concat(e.j)),t=ni(e,n,1e3),n.setTimeout(Math.round(.5*e.xa)+Math.round(.5*e.xa*Math.random())),tP(e.i,n),e6(n,r,t)}function nr(e,t){e.na&&Y(e.na,function(e,n){td(t,n,e)}),e.h&&ts({},function(e,n){td(t,n,e)})}function ni(e,t,n){n=Math.min(e.j.length,n);var r=e.h?I(e.h.Va,e.h,e):null;e:{var i=e.j;let t=-1;for(;;){let e=["count="+n];-1==t?0<n?(t=i[0].g,e.push("ofs="+t)):t=0:e.push("ofs="+t);let s=!0;for(let a=0;a<n;a++){let n=i[a].g,o=i[a].map;if(0>(n-=t))t=Math.max(0,i[a].g-100),s=!1;else try{!function(e,t,n){let r=n||"";try{ts(e,function(e,n){let i=e;w(e)&&(i=ev(e)),t.push(r+n+"="+encodeURIComponent(i))})}catch(e){throw t.push(r+"type="+encodeURIComponent("_badmap")),e}}(o,e,"req"+n+"_")}catch(e){r&&r(o)}}if(s){r=e.join("&");break e}}}return e=e.j.splice(0,n),t.F=e,r}function ns(e){if(!e.g&&!e.u){e.ba=1;var t=e.Ma;eE||eT(),eI||(eE(),eI=!0),e_.add(t,e),e.A=0}}function na(e){return!e.g&&!e.u&&!(3<=e.A)&&(e.ba++,e.u=e$(I(e.Ma,e),nh(e,e.A)),e.A++,!0)}function no(e){null!=e.B&&(y.clearTimeout(e.B),e.B=null)}function nl(e){e.g=new e0(e,e.l,"rpc",e.ba),null===e.o&&(e.g.I=e.s),e.g.O=0;var t=tl(e.wa);td(t,"RID","rpc"),td(t,"SID",e.K),td(t,"AID",e.V),td(t,"CI",e.G?"0":"1"),!e.G&&e.qa&&td(t,"TO",e.qa),td(t,"TYPE","xmlhttp"),nr(e,t),e.o&&e.s&&t6(t,e.o,e.s),e.L&&e.g.setTimeout(e.L);var n=e.g;e=e.pa,n.L=1,n.v=tf(tl(t)),n.s=null,n.S=!0,e5(n,e)}function nu(e){null!=e.v&&(y.clearTimeout(e.v),e.v=null)}function nc(e,t){var n=null;if(e.g==t){nu(e),no(e),e.g=null;var r=2}else{if(!tO(e.i,t))return;n=t.F,tL(e.i,t),r=1}if(0!=e.H){if(t.i){if(1==r){n=t.s?t.s.length:0,t=Date.now()-t.G;var i,s=e.C;em(r=eV(),new ez(r,n)),nt(e)}else ns(e)}else if(3==(s=t.o)||0==s&&0<t.ca||!(1==r&&(i=t,!(tD(e.i)>=e.i.j-(e.m?1:0))&&(e.m?(e.j=i.F.concat(e.j),!0):1!=e.H&&2!=e.H&&!(e.C>=(e.cb?0:e.eb))&&(e.m=e$(I(e.Na,e,i),nh(e,e.C)),e.C++,!0)))||2==r&&na(e)))switch(n&&0<n.length&&((t=e.i).i=t.i.concat(n)),s){case 1:nd(e,5);break;case 4:nd(e,10);break;case 3:nd(e,6);break;default:nd(e,2)}}}function nh(e,t){let n=e.ab+Math.floor(Math.random()*e.hb);return e.isActive()||(n*=2),n*t}function nd(e,t){if(e.l.info("Error code "+t),2==t){var n=null;e.h&&(n=null);var r=I(e.pb,e);n||(n=new to("//www.google.com/images/cleardot.gif"),y.location&&"http"==y.location.protocol||tu(n,"https"),tf(n)),function(e,t){let n=new eP;if(y.Image){let r=new Image;r.onload=_(tU,n,r,"TestLoadImage: loaded",!0,t),r.onerror=_(tU,n,r,"TestLoadImage: error",!1,t),r.onabort=_(tU,n,r,"TestLoadImage: abort",!1,t),r.ontimeout=_(tU,n,r,"TestLoadImage: timeout",!1,t),y.setTimeout(function(){r.ontimeout&&r.ontimeout()},1e4),r.src=e}else t(!1)}(n.toString(),r)}else eq(2);e.H=0,e.h&&e.h.za(t),nf(e),ne(e)}function nf(e){if(e.H=0,e.ma=[],e.h){let t=tM(e.i);(0!=t.length||0!=e.j.length)&&(C(e.ma,t),C(e.ma,e.j),e.i.i.length=0,x(e.j),e.j.length=0),e.h.ya()}}function np(e,t,n){var r=n instanceof to?tl(n):new to(n);if(""!=r.g)t&&(r.g=t+"."+r.g),tc(r,r.m);else{var i=y.location;r=i.protocol,t=t?t+"."+i.hostname:i.hostname,i=+i.port;var s=new to(null);r&&tu(s,r),t&&(s.g=t),i&&tc(s,i),n&&(s.l=n),r=s}return n=e.F,t=e.Da,n&&t&&td(r,n,t),td(r,"VER",e.ra),nr(e,r),r}function ng(e,t,n){if(t&&!e.J)throw Error("Can't create secondary domain capable XhrIo object.");return(t=new tG(n&&e.Ha&&!e.va?new tj({ob:!0}):e.va)).Oa(e.J),t}function nm(){}function ny(){if(M&&!(10<=Number(K)))throw Error("Environmental error: no available transport.")}function nv(e,t){eg.call(this),this.g=new t7(t),this.l=e,this.h=t&&t.messageUrlParams||null,e=t&&t.messageHeaders||null,t&&t.clientProtocolHeaderRequired&&(e?e["X-Client-Protocol"]="webchannel":e={"X-Client-Protocol":"webchannel"}),this.g.s=e,e=t&&t.initMessageHeaders||null,t&&t.messageContentType&&(e?e["X-WebChannel-Content-Type"]=t.messageContentType:e={"X-WebChannel-Content-Type":t.messageContentType}),t&&t.Ca&&(e?e["X-WebChannel-Client-Profile"]=t.Ca:e={"X-WebChannel-Client-Profile":t.Ca}),this.g.U=e,(e=t&&t.cc)&&!R(e)&&(this.g.o=e),this.A=t&&t.supportsCrossDomainXhr||!1,this.v=t&&t.sendRawJson||!1,(t=t&&t.httpSessionIdParam)&&!R(t)&&(this.g.F=t,null!==(e=this.h)&&t in e&&t in(e=this.h)&&delete e[t]),this.j=new nE(this)}function nw(e){eJ.call(this),e.__headers__&&(this.headers=e.__headers__,this.statusCode=e.__status__,delete e.__headers__,delete e.__status__);var t=e.__sm__;if(t){e:{for(let n in t){e=n;break e}e=void 0}(this.i=e)&&(e=this.i,t=null!==t&&e in t?t[e]:void 0),this.data=t}else this.data=e}function nb(){eX.call(this),this.status=1}function nE(e){this.g=e}function nI(){this.blockSize=-1,this.blockSize=64,this.g=[,,,,],this.m=Array(this.blockSize),this.i=this.h=0,this.reset()}function n_(e,t,n){n||(n=0);var r=Array(16);if("string"==typeof t)for(var i=0;16>i;++i)r[i]=t.charCodeAt(n++)|t.charCodeAt(n++)<<8|t.charCodeAt(n++)<<16|t.charCodeAt(n++)<<24;else for(i=0;16>i;++i)r[i]=t[n++]|t[n++]<<8|t[n++]<<16|t[n++]<<24;t=e.g[0],n=e.g[1],i=e.g[2];var s=e.g[3],a=t+(s^n&(i^s))+r[0]+3614090360&4294967295;a=s+(i^(t=n+(a<<7&4294967295|a>>>25))&(n^i))+r[1]+3905402710&4294967295,a=i+(n^(s=t+(a<<12&4294967295|a>>>20))&(t^n))+r[2]+606105819&4294967295,a=n+(t^(i=s+(a<<17&4294967295|a>>>15))&(s^t))+r[3]+3250441966&4294967295,a=t+(s^(n=i+(a<<22&4294967295|a>>>10))&(i^s))+r[4]+4118548399&4294967295,a=s+(i^(t=n+(a<<7&4294967295|a>>>25))&(n^i))+r[5]+1200080426&4294967295,a=i+(n^(s=t+(a<<12&4294967295|a>>>20))&(t^n))+r[6]+2821735955&4294967295,a=n+(t^(i=s+(a<<17&4294967295|a>>>15))&(s^t))+r[7]+4249261313&4294967295,a=t+(s^(n=i+(a<<22&4294967295|a>>>10))&(i^s))+r[8]+1770035416&4294967295,a=s+(i^(t=n+(a<<7&4294967295|a>>>25))&(n^i))+r[9]+2336552879&4294967295,a=i+(n^(s=t+(a<<12&4294967295|a>>>20))&(t^n))+r[10]+4294925233&4294967295,a=n+(t^(i=s+(a<<17&4294967295|a>>>15))&(s^t))+r[11]+2304563134&4294967295,a=t+(s^(n=i+(a<<22&4294967295|a>>>10))&(i^s))+r[12]+1804603682&4294967295,a=s+(i^(t=n+(a<<7&4294967295|a>>>25))&(n^i))+r[13]+4254626195&4294967295,a=i+(n^(s=t+(a<<12&4294967295|a>>>20))&(t^n))+r[14]+2792965006&4294967295,a=n+(t^(i=s+(a<<17&4294967295|a>>>15))&(s^t))+r[15]+1236535329&4294967295,n=i+(a<<22&4294967295|a>>>10),a=t+(i^s&(n^i))+r[1]+4129170786&4294967295,t=n+(a<<5&4294967295|a>>>27),a=s+(n^i&(t^n))+r[6]+3225465664&4294967295,s=t+(a<<9&4294967295|a>>>23),a=i+(t^n&(s^t))+r[11]+643717713&4294967295,i=s+(a<<14&4294967295|a>>>18),a=n+(s^t&(i^s))+r[0]+3921069994&4294967295,n=i+(a<<20&4294967295|a>>>12),a=t+(i^s&(n^i))+r[5]+3593408605&4294967295,t=n+(a<<5&4294967295|a>>>27),a=s+(n^i&(t^n))+r[10]+38016083&4294967295,s=t+(a<<9&4294967295|a>>>23),a=i+(t^n&(s^t))+r[15]+3634488961&4294967295,i=s+(a<<14&4294967295|a>>>18),a=n+(s^t&(i^s))+r[4]+3889429448&4294967295,n=i+(a<<20&4294967295|a>>>12),a=t+(i^s&(n^i))+r[9]+568446438&4294967295,t=n+(a<<5&4294967295|a>>>27),a=s+(n^i&(t^n))+r[14]+3275163606&4294967295,s=t+(a<<9&4294967295|a>>>23),a=i+(t^n&(s^t))+r[3]+4107603335&4294967295,i=s+(a<<14&4294967295|a>>>18),a=n+(s^t&(i^s))+r[8]+1163531501&4294967295,n=i+(a<<20&4294967295|a>>>12),a=t+(i^s&(n^i))+r[13]+2850285829&4294967295,t=n+(a<<5&4294967295|a>>>27),a=s+(n^i&(t^n))+r[2]+4243563512&4294967295,s=t+(a<<9&4294967295|a>>>23),a=i+(t^n&(s^t))+r[7]+1735328473&4294967295,i=s+(a<<14&4294967295|a>>>18),a=n+(s^t&(i^s))+r[12]+2368359562&4294967295,a=t+((n=i+(a<<20&4294967295|a>>>12))^i^s)+r[5]+4294588738&4294967295,a=s+((t=n+(a<<4&4294967295|a>>>28))^n^i)+r[8]+2272392833&4294967295,a=i+((s=t+(a<<11&4294967295|a>>>21))^t^n)+r[11]+1839030562&4294967295,a=n+((i=s+(a<<16&4294967295|a>>>16))^s^t)+r[14]+4259657740&4294967295,a=t+((n=i+(a<<23&4294967295|a>>>9))^i^s)+r[1]+2763975236&4294967295,a=s+((t=n+(a<<4&4294967295|a>>>28))^n^i)+r[4]+1272893353&4294967295,a=i+((s=t+(a<<11&4294967295|a>>>21))^t^n)+r[7]+4139469664&4294967295,a=n+((i=s+(a<<16&4294967295|a>>>16))^s^t)+r[10]+3200236656&4294967295,a=t+((n=i+(a<<23&4294967295|a>>>9))^i^s)+r[13]+681279174&4294967295,a=s+((t=n+(a<<4&4294967295|a>>>28))^n^i)+r[0]+3936430074&4294967295,a=i+((s=t+(a<<11&4294967295|a>>>21))^t^n)+r[3]+3572445317&4294967295,a=n+((i=s+(a<<16&4294967295|a>>>16))^s^t)+r[6]+76029189&4294967295,a=t+((n=i+(a<<23&4294967295|a>>>9))^i^s)+r[9]+3654602809&4294967295,a=s+((t=n+(a<<4&4294967295|a>>>28))^n^i)+r[12]+3873151461&4294967295,a=i+((s=t+(a<<11&4294967295|a>>>21))^t^n)+r[15]+530742520&4294967295,a=n+((i=s+(a<<16&4294967295|a>>>16))^s^t)+r[2]+3299628645&4294967295,n=i+(a<<23&4294967295|a>>>9),a=t+(i^(n|~s))+r[0]+4096336452&4294967295,t=n+(a<<6&4294967295|a>>>26),a=s+(n^(t|~i))+r[7]+1126891415&4294967295,s=t+(a<<10&4294967295|a>>>22),a=i+(t^(s|~n))+r[14]+2878612391&4294967295,i=s+(a<<15&4294967295|a>>>17),a=n+(s^(i|~t))+r[5]+4237533241&4294967295,n=i+(a<<21&4294967295|a>>>11),a=t+(i^(n|~s))+r[12]+1700485571&4294967295,t=n+(a<<6&4294967295|a>>>26),a=s+(n^(t|~i))+r[3]+2399980690&4294967295,s=t+(a<<10&4294967295|a>>>22),a=i+(t^(s|~n))+r[10]+4293915773&4294967295,i=s+(a<<15&4294967295|a>>>17),a=n+(s^(i|~t))+r[1]+2240044497&4294967295,n=i+(a<<21&4294967295|a>>>11),a=t+(i^(n|~s))+r[8]+1873313359&4294967295,t=n+(a<<6&4294967295|a>>>26),a=s+(n^(t|~i))+r[15]+4264355552&4294967295,s=t+(a<<10&4294967295|a>>>22),a=i+(t^(s|~n))+r[6]+2734768916&4294967295,i=s+(a<<15&4294967295|a>>>17),a=n+(s^(i|~t))+r[13]+1309151649&4294967295,n=i+(a<<21&4294967295|a>>>11),a=t+(i^(n|~s))+r[4]+4149444226&4294967295,t=n+(a<<6&4294967295|a>>>26),a=s+(n^(t|~i))+r[11]+3174756917&4294967295,s=t+(a<<10&4294967295|a>>>22),a=i+(t^(s|~n))+r[2]+718787259&4294967295,i=s+(a<<15&4294967295|a>>>17),a=n+(s^(i|~t))+r[9]+3951481745&4294967295,e.g[0]=e.g[0]+t&4294967295,e.g[1]=e.g[1]+(i+(a<<21&4294967295|a>>>11))&4294967295,e.g[2]=e.g[2]+i&4294967295,e.g[3]=e.g[3]+s&4294967295}function nT(e,t){this.h=t;for(var n=[],r=!0,i=e.length-1;0<=i;i--){var s=0|e[i];r&&s==t||(n[i]=s,r=!1)}this.g=n}(u=tG.prototype).Oa=function(e){this.M=e},u.ha=function(e,t,n,r){if(this.g)throw Error("[goog.net.XhrIo] Object is active with another request="+this.I+"; newUri="+e);t=t?t.toUpperCase():"GET",this.I=e,this.j="",this.m=0,this.F=!1,this.h=!0,this.g=this.u?this.u.g():a.g(),this.C=this.u?eW(this.u):eW(a),this.g.onreadystatechange=I(this.La,this);try{this.G=!0,this.g.open(t,String(e),!0),this.G=!1}catch(e){tJ(this,e);return}if(e=n||"",n=new Map(this.headers),r){if(Object.getPrototypeOf(r)===Object.prototype)for(var i in r)n.set(i,r[i]);else if("function"==typeof r.keys&&"function"==typeof r.get)for(let e of r.keys())n.set(e,r.get(e));else throw Error("Unknown input type for opt_headers: "+String(r))}for(let[s,a]of(r=Array.from(n.keys()).find(e=>"content-type"==e.toLowerCase()),i=y.FormData&&e instanceof y.FormData,!(0<=S(tZ,t))||r||i||n.set("Content-Type","application/x-www-form-urlencoded;charset=utf-8"),n))this.g.setRequestHeader(s,a);this.K&&(this.g.responseType=this.K),"withCredentials"in this.g&&this.g.withCredentials!==this.M&&(this.g.withCredentials=this.M);try{var s;t1(this),0<this.B&&((this.L=(s=this.g,M&&"number"==typeof s.timeout&&void 0!==s.ontimeout))?(this.g.timeout=this.B,this.g.ontimeout=I(this.ua,this)):this.A=eC(this.ua,this.B,this)),this.v=!0,this.g.send(e),this.v=!1}catch(e){tJ(this,e)}},u.ua=function(){void 0!==m&&this.g&&(this.j="Timed out after "+this.B+"ms, aborting",this.m=8,em(this,"timeout"),this.abort(8))},u.abort=function(e){this.g&&this.h&&(this.h=!1,this.l=!0,this.g.abort(),this.l=!1,this.m=e||7,em(this,"complete"),em(this,"abort"),t0(this))},u.N=function(){this.g&&(this.h&&(this.h=!1,this.l=!0,this.g.abort(),this.l=!1),t0(this,!0)),tG.$.N.call(this)},u.La=function(){this.s||(this.G||this.v||this.l?tY(this):this.kb())},u.kb=function(){tY(this)},u.isActive=function(){return!!this.g},u.da=function(){try{return 2<t2(this)?this.g.status:-1}catch(e){return -1}},u.ja=function(){try{return this.g?this.g.responseText:""}catch(e){return""}},u.Wa=function(e){if(this.g){var t=this.g.responseText;return e&&0==t.indexOf(e)&&(t=t.substring(e.length)),tK(t)}},u.Ia=function(){return this.m},u.Sa=function(){return"string"==typeof this.j?this.j:String(this.j)},(u=t7.prototype).ra=8,u.H=1,u.Na=function(e){if(this.m){if(this.m=null,1==this.H){if(!e){this.W=Math.floor(1e5*Math.random()),e=this.W++;let i=new e0(this,this.l,e),s=this.s;if(this.U&&(s?en(s=ee(s),this.U):s=this.U),null!==this.o||this.O||(i.I=s,s=null),this.P)e:{for(var t=0,n=0;n<this.j.length;n++){t:{var r=this.j[n];if("__data__"in r.map&&"string"==typeof(r=r.map.__data__)){r=r.length;break t}r=void 0}if(void 0===r)break;if(4096<(t+=r)){t=n;break e}if(4096===t||n===this.j.length-1){t=n+1;break e}}t=1e3}else t=1e3;t=ni(this,i,t),td(n=tl(this.I),"RID",e),td(n,"CVER",22),this.F&&td(n,"X-HTTP-Session-Id",this.F),nr(this,n),s&&(this.O?t="headers="+encodeURIComponent(String(t9(s)))+"&"+t:this.o&&t6(n,this.o,s)),tP(this.i,i),this.bb&&td(n,"TYPE","init"),this.P?(td(n,"$req",t),td(n,"SID","null"),i.aa=!0,e6(i,n,null)):e6(i,n,t),this.H=2}}else 3==this.H&&(e?nn(this,e):0==this.j.length||tR(this.i)||nn(this))}},u.Ma=function(){if(this.u=null,nl(this),this.ca&&!(this.M||null==this.g||0>=this.S)){var e=2*this.S;this.l.info("BP detection timer enabled: "+e),this.B=e$(I(this.jb,this),e)}},u.jb=function(){this.B&&(this.B=null,this.l.info("BP detection timeout reached."),this.l.info("Buffering proxy detected and switch to long-polling!"),this.G=!1,this.M=!0,eq(10),t8(this),nl(this))},u.ib=function(){null!=this.v&&(this.v=null,t8(this),na(this),eq(19))},u.pb=function(e){e?(this.l.info("Successfully pinged google.com"),eq(2)):(this.l.info("Failed to ping google.com"),eq(1))},u.isActive=function(){return!!this.h&&this.h.isActive(this)},(u=nm.prototype).Ba=function(){},u.Aa=function(){},u.za=function(){},u.ya=function(){},u.isActive=function(){return!0},u.Va=function(){},ny.prototype.g=function(e,t){return new nv(e,t)},T(nv,eg),nv.prototype.m=function(){this.g.h=this.j,this.A&&(this.g.J=!0);var e=this.g,t=this.l,n=this.h||void 0;eq(0),e.Y=t,e.na=n||{},e.G=e.aa,e.I=np(e,null,e.Y),nt(e)},nv.prototype.close=function(){t3(this.g)},nv.prototype.u=function(e){var t=this.g;if("string"==typeof e){var n={};n.__data__=e,e=n}else this.v&&((n={}).__data__=ev(e),e=n);t.j.push(new tC(t.fb++,e)),3==t.H&&nt(t)},nv.prototype.N=function(){this.g.h=null,delete this.j,t3(this.g),delete this.g,nv.$.N.call(this)},T(nw,eJ),T(nb,eX),T(nE,nm),nE.prototype.Ba=function(){em(this.g,"a")},nE.prototype.Aa=function(e){em(this.g,new nw(e))},nE.prototype.za=function(e){em(this.g,new nb)},nE.prototype.ya=function(){em(this.g,"b")},T(nI,function(){this.blockSize=-1}),nI.prototype.reset=function(){this.g[0]=1732584193,this.g[1]=4023233417,this.g[2]=2562383102,this.g[3]=271733878,this.i=this.h=0},nI.prototype.j=function(e,t){void 0===t&&(t=e.length);for(var n=t-this.blockSize,r=this.m,i=this.h,s=0;s<t;){if(0==i)for(;s<=n;)n_(this,e,s),s+=this.blockSize;if("string"==typeof e){for(;s<t;)if(r[i++]=e.charCodeAt(s++),i==this.blockSize){n_(this,r),i=0;break}}else for(;s<t;)if(r[i++]=e[s++],i==this.blockSize){n_(this,r),i=0;break}}this.h=i,this.i+=t},nI.prototype.l=function(){var e=Array((56>this.h?this.blockSize:2*this.blockSize)-this.h);e[0]=128;for(var t=1;t<e.length-8;++t)e[t]=0;var n=8*this.i;for(t=e.length-8;t<e.length;++t)e[t]=255&n,n/=256;for(this.j(e),e=Array(16),t=n=0;4>t;++t)for(var r=0;32>r;r+=8)e[n++]=this.g[t]>>>r&255;return e};var nk={};function nS(e){return -128<=e&&128>e?Object.prototype.hasOwnProperty.call(nk,e)?nk[e]:nk[e]=new nT([0|e],0>e?-1:0):new nT([0|e],0>e?-1:0)}function nx(e){if(isNaN(e)||!isFinite(e))return nA;if(0>e)return nP(nx(-e));for(var t=[],n=1,r=0;e>=n;r++)t[r]=e/n|0,n*=nC;return new nT(t,0)}var nC=4294967296,nA=nS(0),nN=nS(1),nR=nS(16777216);function nD(e){if(0!=e.h)return!1;for(var t=0;t<e.g.length;t++)if(0!=e.g[t])return!1;return!0}function nO(e){return -1==e.h}function nP(e){for(var t=e.g.length,n=[],r=0;r<t;r++)n[r]=~e.g[r];return new nT(n,~e.h).add(nN)}function nL(e,t){return e.add(nP(t))}function nM(e,t){for(;(65535&e[t])!=e[t];)e[t+1]+=e[t]>>>16,e[t]&=65535,t++}function nF(e,t){this.g=e,this.h=t}function nV(e,t){if(nD(t))throw Error("division by zero");if(nD(e))return new nF(nA,nA);if(nO(e))return t=nV(nP(e),t),new nF(nP(t.g),nP(t.h));if(nO(t))return t=nV(e,nP(t)),new nF(nP(t.g),t.h);if(30<e.g.length){if(nO(e)||nO(t))throw Error("slowDivide_ only works with positive integers.");for(var n=nN,r=t;0>=r.X(e);)n=nU(n),r=nU(r);var i=nj(n,1),s=nj(r,1);for(r=nj(r,2),n=nj(n,2);!nD(r);){var a=s.add(r);0>=a.X(e)&&(i=i.add(n),s=a),r=nj(r,1),n=nj(n,1)}return t=nL(e,i.R(t)),new nF(i,t)}for(i=nA;0<=e.X(t);){for(r=48>=(r=Math.ceil(Math.log(n=Math.max(1,Math.floor(e.ea()/t.ea())))/Math.LN2))?1:Math.pow(2,r-48),a=(s=nx(n)).R(t);nO(a)||0<a.X(e);)n-=r,a=(s=nx(n)).R(t);nD(s)&&(s=nN),i=i.add(s),e=nL(e,a)}return new nF(i,e)}function nU(e){for(var t=e.g.length+1,n=[],r=0;r<t;r++)n[r]=e.D(r)<<1|e.D(r-1)>>>31;return new nT(n,e.h)}function nj(e,t){var n=t>>5;t%=32;for(var r=e.g.length-n,i=[],s=0;s<r;s++)i[s]=0<t?e.D(s+n)>>>t|e.D(s+n+1)<<32-t:e.D(s+n);return new nT(i,e.h)}(u=nT.prototype).ea=function(){if(nO(this))return-nP(this).ea();for(var e=0,t=1,n=0;n<this.g.length;n++){var r=this.D(n);e+=(0<=r?r:nC+r)*t,t*=nC}return e},u.toString=function(e){if(2>(e=e||10)||36<e)throw Error("radix out of range: "+e);if(nD(this))return"0";if(nO(this))return"-"+nP(this).toString(e);for(var t=nx(Math.pow(e,6)),n=this,r="";;){var i=nV(n,t).g,s=((0<(n=nL(n,i.R(t))).g.length?n.g[0]:n.h)>>>0).toString(e);if(nD(n=i))return s+r;for(;6>s.length;)s="0"+s;r=s+r}},u.D=function(e){return 0>e?0:e<this.g.length?this.g[e]:this.h},u.X=function(e){return nO(e=nL(this,e))?-1:nD(e)?0:1},u.abs=function(){return nO(this)?nP(this):this},u.add=function(e){for(var t=Math.max(this.g.length,e.g.length),n=[],r=0,i=0;i<=t;i++){var s=r+(65535&this.D(i))+(65535&e.D(i)),a=(s>>>16)+(this.D(i)>>>16)+(e.D(i)>>>16);r=a>>>16,s&=65535,a&=65535,n[i]=a<<16|s}return new nT(n,-2147483648&n[n.length-1]?-1:0)},u.R=function(e){if(nD(this)||nD(e))return nA;if(nO(this))return nO(e)?nP(this).R(nP(e)):nP(nP(this).R(e));if(nO(e))return nP(this.R(nP(e)));if(0>this.X(nR)&&0>e.X(nR))return nx(this.ea()*e.ea());for(var t=this.g.length+e.g.length,n=[],r=0;r<2*t;r++)n[r]=0;for(r=0;r<this.g.length;r++)for(var i=0;i<e.g.length;i++){var s=this.D(r)>>>16,a=65535&this.D(r),o=e.D(i)>>>16,l=65535&e.D(i);n[2*r+2*i]+=a*l,nM(n,2*r+2*i),n[2*r+2*i+1]+=s*l,nM(n,2*r+2*i+1),n[2*r+2*i+1]+=a*o,nM(n,2*r+2*i+1),n[2*r+2*i+2]+=s*o,nM(n,2*r+2*i+2)}for(r=0;r<t;r++)n[r]=n[2*r+1]<<16|n[2*r];for(r=t;r<2*t;r++)n[r]=0;return new nT(n,0)},u.gb=function(e){return nV(this,e).h},u.and=function(e){for(var t=Math.max(this.g.length,e.g.length),n=[],r=0;r<t;r++)n[r]=this.D(r)&e.D(r);return new nT(n,this.h&e.h)},u.or=function(e){for(var t=Math.max(this.g.length,e.g.length),n=[],r=0;r<t;r++)n[r]=this.D(r)|e.D(r);return new nT(n,this.h|e.h)},u.xor=function(e){for(var t=Math.max(this.g.length,e.g.length),n=[],r=0;r<t;r++)n[r]=this.D(r)^e.D(r);return new nT(n,this.h^e.h)},ny.prototype.createWebChannel=ny.prototype.g,nv.prototype.send=nv.prototype.u,nv.prototype.open=nv.prototype.m,nv.prototype.close=nv.prototype.close,eH.NO_ERROR=0,eH.TIMEOUT=8,eH.HTTP_ERROR=6,eK.COMPLETE="complete",eQ.EventType=eZ,eZ.OPEN="a",eZ.CLOSE="b",eZ.ERROR="c",eZ.MESSAGE="d",eg.prototype.listen=eg.prototype.O,tG.prototype.listenOnce=tG.prototype.P,tG.prototype.getLastError=tG.prototype.Sa,tG.prototype.getLastErrorCode=tG.prototype.Ia,tG.prototype.getStatus=tG.prototype.da,tG.prototype.getResponseJson=tG.prototype.Wa,tG.prototype.getResponseText=tG.prototype.ja,tG.prototype.send=tG.prototype.ha,tG.prototype.setWithCredentials=tG.prototype.Oa,nI.prototype.digest=nI.prototype.l,nI.prototype.reset=nI.prototype.reset,nI.prototype.update=nI.prototype.j,nT.prototype.add=nT.prototype.add,nT.prototype.multiply=nT.prototype.R,nT.prototype.modulo=nT.prototype.gb,nT.prototype.compare=nT.prototype.X,nT.prototype.toNumber=nT.prototype.ea,nT.prototype.toString=nT.prototype.toString,nT.prototype.getBits=nT.prototype.D,nT.fromNumber=nx,nT.fromString=function e(t,n){if(0==t.length)throw Error("number format error: empty string");if(2>(n=n||10)||36<n)throw Error("radix out of range: "+n);if("-"==t.charAt(0))return nP(e(t.substring(1),n));if(0<=t.indexOf("-"))throw Error('number format error: interior "-" character');for(var r=nx(Math.pow(n,8)),i=nA,s=0;s<t.length;s+=8){var a=Math.min(8,t.length-s),o=parseInt(t.substring(s,s+a),n);8>a?(a=nx(Math.pow(n,a)),i=i.R(a).add(nx(o))):i=(i=i.R(r)).add(nx(o))}return i};var nB=g.createWebChannelTransport=function(){return new ny},nq=g.getStatEventTarget=function(){return eV()},nz=g.ErrorCode=eH,n$=g.EventType=eK,nH=g.Event=eM,nK=g.Stat={xb:0,Ab:1,Bb:2,Ub:3,Zb:4,Wb:5,Xb:6,Vb:7,Tb:8,Yb:9,PROXY:10,NOPROXY:11,Rb:12,Nb:13,Ob:14,Mb:15,Pb:16,Qb:17,tb:18,sb:19,ub:20},nG=g.FetchXmlHttpFactory=tj,nW=g.WebChannel=eQ,nQ=g.XhrIo=tG,nZ=g.Md5=nI,nJ=g.Integer=nT;n(2601);let nX="@firebase/firestore";/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class nY{constructor(e){this.uid=e}isAuthenticated(){return null!=this.uid}toKey(){return this.isAuthenticated()?"uid:"+this.uid:"anonymous-user"}isEqual(e){return e.uid===this.uid}}nY.UNAUTHENTICATED=new nY(null),nY.GOOGLE_CREDENTIALS=new nY("google-credentials-uid"),nY.FIRST_PARTY=new nY("first-party-uid"),nY.MOCK_USER=new nY("mock-user");/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let n0="9.23.0",n1=new d.Yd("@firebase/firestore");function n2(){return n1.logLevel}function n4(e,...t){if(n1.logLevel<=d.in.DEBUG){let n=t.map(n5);n1.debug(`Firestore (${n0}): ${e}`,...n)}}function n9(e,...t){if(n1.logLevel<=d.in.ERROR){let n=t.map(n5);n1.error(`Firestore (${n0}): ${e}`,...n)}}function n6(e,...t){if(n1.logLevel<=d.in.WARN){let n=t.map(n5);n1.warn(`Firestore (${n0}): ${e}`,...n)}}function n5(e){if("string"==typeof e)return e;try{return JSON.stringify(e)}catch(t){return e}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function n7(e="Unexpected state"){let t=`FIRESTORE (${n0}) INTERNAL ASSERTION FAILED: `+e;throw n9(t),Error(t)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let n3={OK:"ok",CANCELLED:"cancelled",UNKNOWN:"unknown",INVALID_ARGUMENT:"invalid-argument",DEADLINE_EXCEEDED:"deadline-exceeded",NOT_FOUND:"not-found",ALREADY_EXISTS:"already-exists",PERMISSION_DENIED:"permission-denied",UNAUTHENTICATED:"unauthenticated",RESOURCE_EXHAUSTED:"resource-exhausted",FAILED_PRECONDITION:"failed-precondition",ABORTED:"aborted",OUT_OF_RANGE:"out-of-range",UNIMPLEMENTED:"unimplemented",INTERNAL:"internal",UNAVAILABLE:"unavailable",DATA_LOSS:"data-loss"};class n8 extends f.ZR{constructor(e,t){super(e,t),this.code=e,this.message=t,this.toString=()=>`${this.name}: [code=${this.code}]: ${this.message}`}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class re{constructor(){this.promise=new Promise((e,t)=>{this.resolve=e,this.reject=t})}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rt{constructor(e,t){this.user=t,this.type="OAuth",this.headers=new Map,this.headers.set("Authorization",`Bearer ${e}`)}}class rn{getToken(){return Promise.resolve(null)}invalidateToken(){}start(e,t){e.enqueueRetryable(()=>t(nY.UNAUTHENTICATED))}shutdown(){}}class rr{constructor(e){this.token=e,this.changeListener=null}getToken(){return Promise.resolve(this.token)}invalidateToken(){}start(e,t){this.changeListener=t,e.enqueueRetryable(()=>t(this.token.user))}shutdown(){this.changeListener=null}}class ri{constructor(e){this.t=e,this.currentUser=nY.UNAUTHENTICATED,this.i=0,this.forceRefresh=!1,this.auth=null}start(e,t){let n=this.i,r=e=>this.i!==n?(n=this.i,t(e)):Promise.resolve(),i=new re;this.o=()=>{this.i++,this.currentUser=this.u(),i.resolve(),i=new re,e.enqueueRetryable(()=>r(this.currentUser))};let s=()=>{let t=i;e.enqueueRetryable(async()=>{await t.promise,await r(this.currentUser)})},a=e=>{n4("FirebaseAuthCredentialsProvider","Auth detected"),this.auth=e,this.auth.addAuthTokenListener(this.o),s()};this.t.onInit(e=>a(e)),setTimeout(()=>{if(!this.auth){let e=this.t.getImmediate({optional:!0});e?a(e):(n4("FirebaseAuthCredentialsProvider","Auth not yet detected"),i.resolve(),i=new re)}},0),s()}getToken(){let e=this.i,t=this.forceRefresh;return this.forceRefresh=!1,this.auth?this.auth.getToken(t).then(t=>this.i!==e?(n4("FirebaseAuthCredentialsProvider","getToken aborted due to token change."),this.getToken()):t?("string"==typeof t.accessToken||n7(),new rt(t.accessToken,this.currentUser)):null):Promise.resolve(null)}invalidateToken(){this.forceRefresh=!0}shutdown(){this.auth&&this.auth.removeAuthTokenListener(this.o)}u(){let e=this.auth&&this.auth.getUid();return null===e||"string"==typeof e||n7(),new nY(e)}}class rs{constructor(e,t,n){this.h=e,this.l=t,this.m=n,this.type="FirstParty",this.user=nY.FIRST_PARTY,this.g=new Map}p(){return this.m?this.m():null}get headers(){this.g.set("X-Goog-AuthUser",this.h);let e=this.p();return e&&this.g.set("Authorization",e),this.l&&this.g.set("X-Goog-Iam-Authorization-Token",this.l),this.g}}class ra{constructor(e,t,n){this.h=e,this.l=t,this.m=n}getToken(){return Promise.resolve(new rs(this.h,this.l,this.m))}start(e,t){e.enqueueRetryable(()=>t(nY.FIRST_PARTY))}shutdown(){}invalidateToken(){}}class ro{constructor(e){this.value=e,this.type="AppCheck",this.headers=new Map,e&&e.length>0&&this.headers.set("x-firebase-appcheck",this.value)}}class rl{constructor(e){this.I=e,this.forceRefresh=!1,this.appCheck=null,this.T=null}start(e,t){let n=e=>{null!=e.error&&n4("FirebaseAppCheckTokenProvider",`Error getting App Check token; using placeholder token instead. Error: ${e.error.message}`);let n=e.token!==this.T;return this.T=e.token,n4("FirebaseAppCheckTokenProvider",`Received ${n?"new":"existing"} token.`),n?t(e.token):Promise.resolve()};this.o=t=>{e.enqueueRetryable(()=>n(t))};let r=e=>{n4("FirebaseAppCheckTokenProvider","AppCheck detected"),this.appCheck=e,this.appCheck.addTokenListener(this.o)};this.I.onInit(e=>r(e)),setTimeout(()=>{if(!this.appCheck){let e=this.I.getImmediate({optional:!0});e?r(e):n4("FirebaseAppCheckTokenProvider","AppCheck not yet detected")}},0)}getToken(){let e=this.forceRefresh;return this.forceRefresh=!1,this.appCheck?this.appCheck.getToken(e).then(e=>e?("string"==typeof e.token||n7(),this.T=e.token,new ro(e.token)):null):Promise.resolve(null)}invalidateToken(){this.forceRefresh=!0}shutdown(){this.appCheck&&this.appCheck.removeTokenListener(this.o)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ru{static A(){let e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",t=Math.floor(256/e.length)*e.length,n="";for(;n.length<20;){let r=/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function(e){let t="undefined"!=typeof self&&(self.crypto||self.msCrypto),n=new Uint8Array(e);if(t&&"function"==typeof t.getRandomValues)t.getRandomValues(n);else for(let t=0;t<e;t++)n[t]=Math.floor(256*Math.random());return n}(40);for(let i=0;i<r.length;++i)n.length<20&&r[i]<t&&(n+=e.charAt(r[i]%e.length))}return n}}function rc(e,t){return e<t?-1:e>t?1:0}function rh(e,t,n){return e.length===t.length&&e.every((e,r)=>n(e,t[r]))}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rd{constructor(e,t){if(this.seconds=e,this.nanoseconds=t,t<0||t>=1e9)throw new n8(n3.INVALID_ARGUMENT,"Timestamp nanoseconds out of range: "+t);if(e<-62135596800||e>=253402300800)throw new n8(n3.INVALID_ARGUMENT,"Timestamp seconds out of range: "+e)}static now(){return rd.fromMillis(Date.now())}static fromDate(e){return rd.fromMillis(e.getTime())}static fromMillis(e){let t=Math.floor(e/1e3),n=Math.floor(1e6*(e-1e3*t));return new rd(t,n)}toDate(){return new Date(this.toMillis())}toMillis(){return 1e3*this.seconds+this.nanoseconds/1e6}_compareTo(e){return this.seconds===e.seconds?rc(this.nanoseconds,e.nanoseconds):rc(this.seconds,e.seconds)}isEqual(e){return e.seconds===this.seconds&&e.nanoseconds===this.nanoseconds}toString(){return"Timestamp(seconds="+this.seconds+", nanoseconds="+this.nanoseconds+")"}toJSON(){return{seconds:this.seconds,nanoseconds:this.nanoseconds}}valueOf(){let e=this.seconds- -62135596800;return String(e).padStart(12,"0")+"."+String(this.nanoseconds).padStart(9,"0")}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rf{constructor(e){this.timestamp=e}static fromTimestamp(e){return new rf(e)}static min(){return new rf(new rd(0,0))}static max(){return new rf(new rd(253402300799,999999999))}compareTo(e){return this.timestamp._compareTo(e.timestamp)}isEqual(e){return this.timestamp.isEqual(e.timestamp)}toMicroseconds(){return 1e6*this.timestamp.seconds+this.timestamp.nanoseconds/1e3}toString(){return"SnapshotVersion("+this.timestamp.toString()+")"}toTimestamp(){return this.timestamp}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rp{constructor(e,t,n){void 0===t?t=0:t>e.length&&n7(),void 0===n?n=e.length-t:n>e.length-t&&n7(),this.segments=e,this.offset=t,this.len=n}get length(){return this.len}isEqual(e){return 0===rp.comparator(this,e)}child(e){let t=this.segments.slice(this.offset,this.limit());return e instanceof rp?e.forEach(e=>{t.push(e)}):t.push(e),this.construct(t)}limit(){return this.offset+this.length}popFirst(e){return e=void 0===e?1:e,this.construct(this.segments,this.offset+e,this.length-e)}popLast(){return this.construct(this.segments,this.offset,this.length-1)}firstSegment(){return this.segments[this.offset]}lastSegment(){return this.get(this.length-1)}get(e){return this.segments[this.offset+e]}isEmpty(){return 0===this.length}isPrefixOf(e){if(e.length<this.length)return!1;for(let t=0;t<this.length;t++)if(this.get(t)!==e.get(t))return!1;return!0}isImmediateParentOf(e){if(this.length+1!==e.length)return!1;for(let t=0;t<this.length;t++)if(this.get(t)!==e.get(t))return!1;return!0}forEach(e){for(let t=this.offset,n=this.limit();t<n;t++)e(this.segments[t])}toArray(){return this.segments.slice(this.offset,this.limit())}static comparator(e,t){let n=Math.min(e.length,t.length);for(let r=0;r<n;r++){let n=e.get(r),i=t.get(r);if(n<i)return -1;if(n>i)return 1}return e.length<t.length?-1:e.length>t.length?1:0}}class rg extends rp{construct(e,t,n){return new rg(e,t,n)}canonicalString(){return this.toArray().join("/")}toString(){return this.canonicalString()}static fromString(...e){let t=[];for(let n of e){if(n.indexOf("//")>=0)throw new n8(n3.INVALID_ARGUMENT,`Invalid segment (${n}). Paths must not contain // in them.`);t.push(...n.split("/").filter(e=>e.length>0))}return new rg(t)}static emptyPath(){return new rg([])}}let rm=/^[_a-zA-Z][_a-zA-Z0-9]*$/;class ry extends rp{construct(e,t,n){return new ry(e,t,n)}static isValidIdentifier(e){return rm.test(e)}canonicalString(){return this.toArray().map(e=>(e=e.replace(/\\/g,"\\\\").replace(/`/g,"\\`"),ry.isValidIdentifier(e)||(e="`"+e+"`"),e)).join(".")}toString(){return this.canonicalString()}isKeyField(){return 1===this.length&&"__name__"===this.get(0)}static keyField(){return new ry(["__name__"])}static fromServerFormat(e){let t=[],n="",r=0,i=()=>{if(0===n.length)throw new n8(n3.INVALID_ARGUMENT,`Invalid field path (${e}). Paths must not be empty, begin with '.', end with '.', or contain '..'`);t.push(n),n=""},s=!1;for(;r<e.length;){let t=e[r];if("\\"===t){if(r+1===e.length)throw new n8(n3.INVALID_ARGUMENT,"Path has trailing escape character: "+e);let t=e[r+1];if("\\"!==t&&"."!==t&&"`"!==t)throw new n8(n3.INVALID_ARGUMENT,"Path has invalid escape sequence: "+e);n+=t,r+=2}else"`"===t?s=!s:"."!==t||s?n+=t:i(),r++}if(i(),s)throw new n8(n3.INVALID_ARGUMENT,"Unterminated ` in path: "+e);return new ry(t)}static emptyPath(){return new ry([])}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rv{constructor(e){this.path=e}static fromPath(e){return new rv(rg.fromString(e))}static fromName(e){return new rv(rg.fromString(e).popFirst(5))}static empty(){return new rv(rg.emptyPath())}get collectionGroup(){return this.path.popLast().lastSegment()}hasCollectionId(e){return this.path.length>=2&&this.path.get(this.path.length-2)===e}getCollectionGroup(){return this.path.get(this.path.length-2)}getCollectionPath(){return this.path.popLast()}isEqual(e){return null!==e&&0===rg.comparator(this.path,e.path)}toString(){return this.path.toString()}static comparator(e,t){return rg.comparator(e.path,t.path)}static isDocumentKey(e){return e.length%2==0}static fromSegments(e){return new rv(new rg(e.slice()))}}class rw{constructor(e,t,n){this.readTime=e,this.documentKey=t,this.largestBatchId=n}static min(){return new rw(rf.min(),rv.empty(),-1)}static max(){return new rw(rf.max(),rv.empty(),-1)}}class rb{constructor(){this.onCommittedListeners=[]}addOnCommittedListener(e){this.onCommittedListeners.push(e)}raiseOnCommittedEvent(){this.onCommittedListeners.forEach(e=>e())}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function rE(e){if(e.code!==n3.FAILED_PRECONDITION||"The current tab is not in the required state to perform this operation. It might be necessary to refresh the browser tab."!==e.message)throw e;n4("LocalStore","Unexpectedly lost primary lease")}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rI{constructor(e){this.nextCallback=null,this.catchCallback=null,this.result=void 0,this.error=void 0,this.isDone=!1,this.callbackAttached=!1,e(e=>{this.isDone=!0,this.result=e,this.nextCallback&&this.nextCallback(e)},e=>{this.isDone=!0,this.error=e,this.catchCallback&&this.catchCallback(e)})}catch(e){return this.next(void 0,e)}next(e,t){return this.callbackAttached&&n7(),this.callbackAttached=!0,this.isDone?this.error?this.wrapFailure(t,this.error):this.wrapSuccess(e,this.result):new rI((n,r)=>{this.nextCallback=t=>{this.wrapSuccess(e,t).next(n,r)},this.catchCallback=e=>{this.wrapFailure(t,e).next(n,r)}})}toPromise(){return new Promise((e,t)=>{this.next(e,t)})}wrapUserFunction(e){try{let t=e();return t instanceof rI?t:rI.resolve(t)}catch(e){return rI.reject(e)}}wrapSuccess(e,t){return e?this.wrapUserFunction(()=>e(t)):rI.resolve(t)}wrapFailure(e,t){return e?this.wrapUserFunction(()=>e(t)):rI.reject(t)}static resolve(e){return new rI((t,n)=>{t(e)})}static reject(e){return new rI((t,n)=>{n(e)})}static waitFor(e){return new rI((t,n)=>{let r=0,i=0,s=!1;e.forEach(e=>{++r,e.next(()=>{++i,s&&i===r&&t()},e=>n(e))}),s=!0,i===r&&t()})}static or(e){let t=rI.resolve(!1);for(let n of e)t=t.next(e=>e?rI.resolve(e):n());return t}static forEach(e,t){let n=[];return e.forEach((e,r)=>{n.push(t.call(this,e,r))}),this.waitFor(n)}static mapArray(e,t){return new rI((n,r)=>{let i=e.length,s=Array(i),a=0;for(let o=0;o<i;o++){let l=o;t(e[l]).next(e=>{s[l]=e,++a===i&&n(s)},e=>r(e))}})}static doWhile(e,t){return new rI((n,r)=>{let i=()=>{!0===e()?t().next(()=>{i()},r):n()};i()})}}function r_(e){return"IndexedDbTransactionError"===e.name}/**
 * @license
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rT{constructor(e,t){this.previousValue=e,t&&(t.sequenceNumberHandler=e=>this.ot(e),this.ut=e=>t.writeSequenceNumber(e))}ot(e){return this.previousValue=Math.max(e,this.previousValue),this.previousValue}next(){let e=++this.previousValue;return this.ut&&this.ut(e),e}}function rk(e){return 0===e&&1/e==-1/0}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function rS(e){let t=0;for(let n in e)Object.prototype.hasOwnProperty.call(e,n)&&t++;return t}function rx(e,t){for(let n in e)Object.prototype.hasOwnProperty.call(e,n)&&t(n,e[n])}function rC(e){for(let t in e)if(Object.prototype.hasOwnProperty.call(e,t))return!1;return!0}rT.ct=-1;/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rA{constructor(e,t){this.comparator=e,this.root=t||rR.EMPTY}insert(e,t){return new rA(this.comparator,this.root.insert(e,t,this.comparator).copy(null,null,rR.BLACK,null,null))}remove(e){return new rA(this.comparator,this.root.remove(e,this.comparator).copy(null,null,rR.BLACK,null,null))}get(e){let t=this.root;for(;!t.isEmpty();){let n=this.comparator(e,t.key);if(0===n)return t.value;n<0?t=t.left:n>0&&(t=t.right)}return null}indexOf(e){let t=0,n=this.root;for(;!n.isEmpty();){let r=this.comparator(e,n.key);if(0===r)return t+n.left.size;r<0?n=n.left:(t+=n.left.size+1,n=n.right)}return -1}isEmpty(){return this.root.isEmpty()}get size(){return this.root.size}minKey(){return this.root.minKey()}maxKey(){return this.root.maxKey()}inorderTraversal(e){return this.root.inorderTraversal(e)}forEach(e){this.inorderTraversal((t,n)=>(e(t,n),!1))}toString(){let e=[];return this.inorderTraversal((t,n)=>(e.push(`${t}:${n}`),!1)),`{${e.join(", ")}}`}reverseTraversal(e){return this.root.reverseTraversal(e)}getIterator(){return new rN(this.root,null,this.comparator,!1)}getIteratorFrom(e){return new rN(this.root,e,this.comparator,!1)}getReverseIterator(){return new rN(this.root,null,this.comparator,!0)}getReverseIteratorFrom(e){return new rN(this.root,e,this.comparator,!0)}}class rN{constructor(e,t,n,r){this.isReverse=r,this.nodeStack=[];let i=1;for(;!e.isEmpty();)if(i=t?n(e.key,t):1,t&&r&&(i*=-1),i<0)e=this.isReverse?e.left:e.right;else{if(0===i){this.nodeStack.push(e);break}this.nodeStack.push(e),e=this.isReverse?e.right:e.left}}getNext(){let e=this.nodeStack.pop(),t={key:e.key,value:e.value};if(this.isReverse)for(e=e.left;!e.isEmpty();)this.nodeStack.push(e),e=e.right;else for(e=e.right;!e.isEmpty();)this.nodeStack.push(e),e=e.left;return t}hasNext(){return this.nodeStack.length>0}peek(){if(0===this.nodeStack.length)return null;let e=this.nodeStack[this.nodeStack.length-1];return{key:e.key,value:e.value}}}class rR{constructor(e,t,n,r,i){this.key=e,this.value=t,this.color=null!=n?n:rR.RED,this.left=null!=r?r:rR.EMPTY,this.right=null!=i?i:rR.EMPTY,this.size=this.left.size+1+this.right.size}copy(e,t,n,r,i){return new rR(null!=e?e:this.key,null!=t?t:this.value,null!=n?n:this.color,null!=r?r:this.left,null!=i?i:this.right)}isEmpty(){return!1}inorderTraversal(e){return this.left.inorderTraversal(e)||e(this.key,this.value)||this.right.inorderTraversal(e)}reverseTraversal(e){return this.right.reverseTraversal(e)||e(this.key,this.value)||this.left.reverseTraversal(e)}min(){return this.left.isEmpty()?this:this.left.min()}minKey(){return this.min().key}maxKey(){return this.right.isEmpty()?this.key:this.right.maxKey()}insert(e,t,n){let r=this,i=n(e,r.key);return(r=i<0?r.copy(null,null,null,r.left.insert(e,t,n),null):0===i?r.copy(null,t,null,null,null):r.copy(null,null,null,null,r.right.insert(e,t,n))).fixUp()}removeMin(){if(this.left.isEmpty())return rR.EMPTY;let e=this;return e.left.isRed()||e.left.left.isRed()||(e=e.moveRedLeft()),(e=e.copy(null,null,null,e.left.removeMin(),null)).fixUp()}remove(e,t){let n,r=this;if(0>t(e,r.key))r.left.isEmpty()||r.left.isRed()||r.left.left.isRed()||(r=r.moveRedLeft()),r=r.copy(null,null,null,r.left.remove(e,t),null);else{if(r.left.isRed()&&(r=r.rotateRight()),r.right.isEmpty()||r.right.isRed()||r.right.left.isRed()||(r=r.moveRedRight()),0===t(e,r.key)){if(r.right.isEmpty())return rR.EMPTY;n=r.right.min(),r=r.copy(n.key,n.value,null,null,r.right.removeMin())}r=r.copy(null,null,null,null,r.right.remove(e,t))}return r.fixUp()}isRed(){return this.color}fixUp(){let e=this;return e.right.isRed()&&!e.left.isRed()&&(e=e.rotateLeft()),e.left.isRed()&&e.left.left.isRed()&&(e=e.rotateRight()),e.left.isRed()&&e.right.isRed()&&(e=e.colorFlip()),e}moveRedLeft(){let e=this.colorFlip();return e.right.left.isRed()&&(e=(e=(e=e.copy(null,null,null,null,e.right.rotateRight())).rotateLeft()).colorFlip()),e}moveRedRight(){let e=this.colorFlip();return e.left.left.isRed()&&(e=(e=e.rotateRight()).colorFlip()),e}rotateLeft(){let e=this.copy(null,null,rR.RED,null,this.right.left);return this.right.copy(null,null,this.color,e,null)}rotateRight(){let e=this.copy(null,null,rR.RED,this.left.right,null);return this.left.copy(null,null,this.color,null,e)}colorFlip(){let e=this.left.copy(null,null,!this.left.color,null,null),t=this.right.copy(null,null,!this.right.color,null,null);return this.copy(null,null,!this.color,e,t)}checkMaxDepth(){let e=this.check();return Math.pow(2,e)<=this.size+1}check(){if(this.isRed()&&this.left.isRed()||this.right.isRed())throw n7();let e=this.left.check();if(e!==this.right.check())throw n7();return e+(this.isRed()?0:1)}}rR.EMPTY=null,rR.RED=!0,rR.BLACK=!1,rR.EMPTY=new class{constructor(){this.size=0}get key(){throw n7()}get value(){throw n7()}get color(){throw n7()}get left(){throw n7()}get right(){throw n7()}copy(e,t,n,r,i){return this}insert(e,t,n){return new rR(e,t)}remove(e,t){return this}isEmpty(){return!0}inorderTraversal(e){return!1}reverseTraversal(e){return!1}minKey(){return null}maxKey(){return null}isRed(){return!1}checkMaxDepth(){return!0}check(){return 0}};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rD{constructor(e){this.comparator=e,this.data=new rA(this.comparator)}has(e){return null!==this.data.get(e)}first(){return this.data.minKey()}last(){return this.data.maxKey()}get size(){return this.data.size}indexOf(e){return this.data.indexOf(e)}forEach(e){this.data.inorderTraversal((t,n)=>(e(t),!1))}forEachInRange(e,t){let n=this.data.getIteratorFrom(e[0]);for(;n.hasNext();){let r=n.getNext();if(this.comparator(r.key,e[1])>=0)return;t(r.key)}}forEachWhile(e,t){let n;for(n=void 0!==t?this.data.getIteratorFrom(t):this.data.getIterator();n.hasNext();)if(!e(n.getNext().key))return}firstAfterOrEqual(e){let t=this.data.getIteratorFrom(e);return t.hasNext()?t.getNext().key:null}getIterator(){return new rO(this.data.getIterator())}getIteratorFrom(e){return new rO(this.data.getIteratorFrom(e))}add(e){return this.copy(this.data.remove(e).insert(e,!0))}delete(e){return this.has(e)?this.copy(this.data.remove(e)):this}isEmpty(){return this.data.isEmpty()}unionWith(e){let t=this;return t.size<e.size&&(t=e,e=this),e.forEach(e=>{t=t.add(e)}),t}isEqual(e){if(!(e instanceof rD)||this.size!==e.size)return!1;let t=this.data.getIterator(),n=e.data.getIterator();for(;t.hasNext();){let e=t.getNext().key,r=n.getNext().key;if(0!==this.comparator(e,r))return!1}return!0}toArray(){let e=[];return this.forEach(t=>{e.push(t)}),e}toString(){let e=[];return this.forEach(t=>e.push(t)),"SortedSet("+e.toString()+")"}copy(e){let t=new rD(this.comparator);return t.data=e,t}}class rO{constructor(e){this.iter=e}getNext(){return this.iter.getNext().key}hasNext(){return this.iter.hasNext()}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rP{constructor(e){this.fields=e,e.sort(ry.comparator)}static empty(){return new rP([])}unionWith(e){let t=new rD(ry.comparator);for(let e of this.fields)t=t.add(e);for(let n of e)t=t.add(n);return new rP(t.toArray())}covers(e){for(let t of this.fields)if(t.isPrefixOf(e))return!0;return!1}isEqual(e){return rh(this.fields,e.fields,(e,t)=>e.isEqual(t))}}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rL extends Error{constructor(){super(...arguments),this.name="Base64DecodeError"}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class rM{constructor(e){this.binaryString=e}static fromBase64String(e){let t=function(e){try{return atob(e)}catch(e){throw"undefined"!=typeof DOMException&&e instanceof DOMException?new rL("Invalid base64 string: "+e):e}}(e);return new rM(t)}static fromUint8Array(e){let t=function(e){let t="";for(let n=0;n<e.length;++n)t+=String.fromCharCode(e[n]);return t}(e);return new rM(t)}[Symbol.iterator](){let e=0;return{next:()=>e<this.binaryString.length?{value:this.binaryString.charCodeAt(e++),done:!1}:{value:void 0,done:!0}}}toBase64(){return btoa(this.binaryString)}toUint8Array(){return function(e){let t=new Uint8Array(e.length);for(let n=0;n<e.length;n++)t[n]=e.charCodeAt(n);return t}(this.binaryString)}approximateByteSize(){return 2*this.binaryString.length}compareTo(e){return rc(this.binaryString,e.binaryString)}isEqual(e){return this.binaryString===e.binaryString}}rM.EMPTY_BYTE_STRING=new rM("");let rF=new RegExp(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.(\d+))?Z$/);function rV(e){if(e||n7(),"string"==typeof e){let t=0,n=rF.exec(e);if(n||n7(),n[1]){let e=n[1];t=Number(e=(e+"000000000").substr(0,9))}let r=new Date(e);return{seconds:Math.floor(r.getTime()/1e3),nanos:t}}return{seconds:rU(e.seconds),nanos:rU(e.nanos)}}function rU(e){return"number"==typeof e?e:"string"==typeof e?Number(e):0}function rj(e){return"string"==typeof e?rM.fromBase64String(e):rM.fromUint8Array(e)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function rB(e){var t,n;return"server_timestamp"===(null===(n=((null===(t=null==e?void 0:e.mapValue)||void 0===t?void 0:t.fields)||{}).__type__)||void 0===n?void 0:n.stringValue)}function rq(e){let t=e.mapValue.fields.__previous_value__;return rB(t)?rq(t):t}function rz(e){let t=rV(e.mapValue.fields.__local_write_time__.timestampValue);return new rd(t.seconds,t.nanos)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class r${constructor(e,t,n,r,i,s,a,o,l){this.databaseId=e,this.appId=t,this.persistenceKey=n,this.host=r,this.ssl=i,this.forceLongPolling=s,this.autoDetectLongPolling=a,this.longPollingOptions=o,this.useFetchStreams=l}}class rH{constructor(e,t){this.projectId=e,this.database=t||"(default)"}static empty(){return new rH("","")}get isDefaultDatabase(){return"(default)"===this.database}isEqual(e){return e instanceof rH&&e.projectId===this.projectId&&e.database===this.database}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let rK={mapValue:{fields:{__type__:{stringValue:"__max__"}}}};function rG(e){return"nullValue"in e?0:"booleanValue"in e?1:"integerValue"in e||"doubleValue"in e?2:"timestampValue"in e?3:"stringValue"in e?5:"bytesValue"in e?6:"referenceValue"in e?7:"geoPointValue"in e?8:"arrayValue"in e?9:"mapValue"in e?rB(e)?4:r5(e)?9007199254740991:10:n7()}function rW(e,t){if(e===t)return!0;let n=rG(e);if(n!==rG(t))return!1;switch(n){case 0:case 9007199254740991:return!0;case 1:return e.booleanValue===t.booleanValue;case 4:return rz(e).isEqual(rz(t));case 3:return function(e,t){if("string"==typeof e.timestampValue&&"string"==typeof t.timestampValue&&e.timestampValue.length===t.timestampValue.length)return e.timestampValue===t.timestampValue;let n=rV(e.timestampValue),r=rV(t.timestampValue);return n.seconds===r.seconds&&n.nanos===r.nanos}(e,t);case 5:return e.stringValue===t.stringValue;case 6:return rj(e.bytesValue).isEqual(rj(t.bytesValue));case 7:return e.referenceValue===t.referenceValue;case 8:return rU(e.geoPointValue.latitude)===rU(t.geoPointValue.latitude)&&rU(e.geoPointValue.longitude)===rU(t.geoPointValue.longitude);case 2:return function(e,t){if("integerValue"in e&&"integerValue"in t)return rU(e.integerValue)===rU(t.integerValue);if("doubleValue"in e&&"doubleValue"in t){let n=rU(e.doubleValue),r=rU(t.doubleValue);return n===r?rk(n)===rk(r):isNaN(n)&&isNaN(r)}return!1}(e,t);case 9:return rh(e.arrayValue.values||[],t.arrayValue.values||[],rW);case 10:return function(e,t){let n=e.mapValue.fields||{},r=t.mapValue.fields||{};if(rS(n)!==rS(r))return!1;for(let e in n)if(n.hasOwnProperty(e)&&(void 0===r[e]||!rW(n[e],r[e])))return!1;return!0}(e,t);default:return n7()}}function rQ(e,t){return void 0!==(e.values||[]).find(e=>rW(e,t))}function rZ(e,t){if(e===t)return 0;let n=rG(e),r=rG(t);if(n!==r)return rc(n,r);switch(n){case 0:case 9007199254740991:return 0;case 1:return rc(e.booleanValue,t.booleanValue);case 2:return function(e,t){let n=rU(e.integerValue||e.doubleValue),r=rU(t.integerValue||t.doubleValue);return n<r?-1:n>r?1:n===r?0:isNaN(n)?isNaN(r)?0:-1:1}(e,t);case 3:return rJ(e.timestampValue,t.timestampValue);case 4:return rJ(rz(e),rz(t));case 5:return rc(e.stringValue,t.stringValue);case 6:return function(e,t){let n=rj(e),r=rj(t);return n.compareTo(r)}(e.bytesValue,t.bytesValue);case 7:return function(e,t){let n=e.split("/"),r=t.split("/");for(let e=0;e<n.length&&e<r.length;e++){let t=rc(n[e],r[e]);if(0!==t)return t}return rc(n.length,r.length)}(e.referenceValue,t.referenceValue);case 8:return function(e,t){let n=rc(rU(e.latitude),rU(t.latitude));return 0!==n?n:rc(rU(e.longitude),rU(t.longitude))}(e.geoPointValue,t.geoPointValue);case 9:return function(e,t){let n=e.values||[],r=t.values||[];for(let e=0;e<n.length&&e<r.length;++e){let t=rZ(n[e],r[e]);if(t)return t}return rc(n.length,r.length)}(e.arrayValue,t.arrayValue);case 10:return function(e,t){if(e===rK.mapValue&&t===rK.mapValue)return 0;if(e===rK.mapValue)return 1;if(t===rK.mapValue)return -1;let n=e.fields||{},r=Object.keys(n),i=t.fields||{},s=Object.keys(i);r.sort(),s.sort();for(let e=0;e<r.length&&e<s.length;++e){let t=rc(r[e],s[e]);if(0!==t)return t;let a=rZ(n[r[e]],i[s[e]]);if(0!==a)return a}return rc(r.length,s.length)}(e.mapValue,t.mapValue);default:throw n7()}}function rJ(e,t){if("string"==typeof e&&"string"==typeof t&&e.length===t.length)return rc(e,t);let n=rV(e),r=rV(t),i=rc(n.seconds,r.seconds);return 0!==i?i:rc(n.nanos,r.nanos)}function rX(e){var t,n;return"nullValue"in e?"null":"booleanValue"in e?""+e.booleanValue:"integerValue"in e?""+e.integerValue:"doubleValue"in e?""+e.doubleValue:"timestampValue"in e?function(e){let t=rV(e);return`time(${t.seconds},${t.nanos})`}(e.timestampValue):"stringValue"in e?e.stringValue:"bytesValue"in e?rj(e.bytesValue).toBase64():"referenceValue"in e?(n=e.referenceValue,rv.fromName(n).toString()):"geoPointValue"in e?`geo(${(t=e.geoPointValue).latitude},${t.longitude})`:"arrayValue"in e?function(e){let t="[",n=!0;for(let r of e.values||[])n?n=!1:t+=",",t+=rX(r);return t+"]"}(e.arrayValue):"mapValue"in e?function(e){let t=Object.keys(e.fields||{}).sort(),n="{",r=!0;for(let i of t)r?r=!1:n+=",",n+=`${i}:${rX(e.fields[i])}`;return n+"}"}(e.mapValue):n7()}function rY(e,t){return{referenceValue:`projects/${e.projectId}/databases/${e.database}/documents/${t.path.canonicalString()}`}}function r0(e){return!!e&&"integerValue"in e}function r1(e){return!!e&&"arrayValue"in e}function r2(e){return!!e&&"nullValue"in e}function r4(e){return!!e&&"doubleValue"in e&&isNaN(Number(e.doubleValue))}function r9(e){return!!e&&"mapValue"in e}function r6(e){if(e.geoPointValue)return{geoPointValue:Object.assign({},e.geoPointValue)};if(e.timestampValue&&"object"==typeof e.timestampValue)return{timestampValue:Object.assign({},e.timestampValue)};if(e.mapValue){let t={mapValue:{fields:{}}};return rx(e.mapValue.fields,(e,n)=>t.mapValue.fields[e]=r6(n)),t}if(e.arrayValue){let t={arrayValue:{values:[]}};for(let n=0;n<(e.arrayValue.values||[]).length;++n)t.arrayValue.values[n]=r6(e.arrayValue.values[n]);return t}return Object.assign({},e)}function r5(e){return"__max__"===(((e.mapValue||{}).fields||{}).__type__||{}).stringValue}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class r7{constructor(e){this.value=e}static empty(){return new r7({mapValue:{}})}field(e){if(e.isEmpty())return this.value;{let t=this.value;for(let n=0;n<e.length-1;++n)if(!r9(t=(t.mapValue.fields||{})[e.get(n)]))return null;return(t=(t.mapValue.fields||{})[e.lastSegment()])||null}}set(e,t){this.getFieldsMap(e.popLast())[e.lastSegment()]=r6(t)}setAll(e){let t=ry.emptyPath(),n={},r=[];e.forEach((e,i)=>{if(!t.isImmediateParentOf(i)){let e=this.getFieldsMap(t);this.applyChanges(e,n,r),n={},r=[],t=i.popLast()}e?n[i.lastSegment()]=r6(e):r.push(i.lastSegment())});let i=this.getFieldsMap(t);this.applyChanges(i,n,r)}delete(e){let t=this.field(e.popLast());r9(t)&&t.mapValue.fields&&delete t.mapValue.fields[e.lastSegment()]}isEqual(e){return rW(this.value,e.value)}getFieldsMap(e){let t=this.value;t.mapValue.fields||(t.mapValue={fields:{}});for(let n=0;n<e.length;++n){let r=t.mapValue.fields[e.get(n)];r9(r)&&r.mapValue.fields||(r={mapValue:{fields:{}}},t.mapValue.fields[e.get(n)]=r),t=r}return t.mapValue.fields}applyChanges(e,t,n){for(let r of(rx(t,(t,n)=>e[t]=n),n))delete e[r]}clone(){return new r7(r6(this.value))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class r3{constructor(e,t,n,r,i,s,a){this.key=e,this.documentType=t,this.version=n,this.readTime=r,this.createTime=i,this.data=s,this.documentState=a}static newInvalidDocument(e){return new r3(e,0,rf.min(),rf.min(),rf.min(),r7.empty(),0)}static newFoundDocument(e,t,n,r){return new r3(e,1,t,rf.min(),n,r,0)}static newNoDocument(e,t){return new r3(e,2,t,rf.min(),rf.min(),r7.empty(),0)}static newUnknownDocument(e,t){return new r3(e,3,t,rf.min(),rf.min(),r7.empty(),2)}convertToFoundDocument(e,t){return this.createTime.isEqual(rf.min())&&(2===this.documentType||0===this.documentType)&&(this.createTime=e),this.version=e,this.documentType=1,this.data=t,this.documentState=0,this}convertToNoDocument(e){return this.version=e,this.documentType=2,this.data=r7.empty(),this.documentState=0,this}convertToUnknownDocument(e){return this.version=e,this.documentType=3,this.data=r7.empty(),this.documentState=2,this}setHasCommittedMutations(){return this.documentState=2,this}setHasLocalMutations(){return this.documentState=1,this.version=rf.min(),this}setReadTime(e){return this.readTime=e,this}get hasLocalMutations(){return 1===this.documentState}get hasCommittedMutations(){return 2===this.documentState}get hasPendingWrites(){return this.hasLocalMutations||this.hasCommittedMutations}isValidDocument(){return 0!==this.documentType}isFoundDocument(){return 1===this.documentType}isNoDocument(){return 2===this.documentType}isUnknownDocument(){return 3===this.documentType}isEqual(e){return e instanceof r3&&this.key.isEqual(e.key)&&this.version.isEqual(e.version)&&this.documentType===e.documentType&&this.documentState===e.documentState&&this.data.isEqual(e.data)}mutableCopy(){return new r3(this.key,this.documentType,this.version,this.readTime,this.createTime,this.data.clone(),this.documentState)}toString(){return`Document(${this.key}, ${this.version}, ${JSON.stringify(this.data.value)}, {createTime: ${this.createTime}}), {documentType: ${this.documentType}}), {documentState: ${this.documentState}})`}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class r8{constructor(e,t){this.position=e,this.inclusive=t}}function ie(e,t,n){let r=0;for(let i=0;i<e.position.length;i++){let s=t[i],a=e.position[i];if(r=s.field.isKeyField()?rv.comparator(rv.fromName(a.referenceValue),n.key):rZ(a,n.data.field(s.field)),"desc"===s.dir&&(r*=-1),0!==r)break}return r}function it(e,t){if(null===e)return null===t;if(null===t||e.inclusive!==t.inclusive||e.position.length!==t.position.length)return!1;for(let n=0;n<e.position.length;n++)if(!rW(e.position[n],t.position[n]))return!1;return!0}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ir{constructor(e,t="asc"){this.field=e,this.dir=t}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ii{}class is extends ii{constructor(e,t,n){super(),this.field=e,this.op=t,this.value=n}static create(e,t,n){return e.isKeyField()?"in"===t||"not-in"===t?this.createKeyFieldInFilter(e,t,n):new iu(e,t,n):"array-contains"===t?new ip(e,n):"in"===t?new ig(e,n):"not-in"===t?new im(e,n):"array-contains-any"===t?new iy(e,n):new is(e,t,n)}static createKeyFieldInFilter(e,t,n){return"in"===t?new ic(e,n):new ih(e,n)}matches(e){let t=e.data.field(this.field);return"!="===this.op?null!==t&&this.matchesComparison(rZ(t,this.value)):null!==t&&rG(this.value)===rG(t)&&this.matchesComparison(rZ(t,this.value))}matchesComparison(e){switch(this.op){case"<":return e<0;case"<=":return e<=0;case"==":return 0===e;case"!=":return 0!==e;case">":return e>0;case">=":return e>=0;default:return n7()}}isInequality(){return["<","<=",">",">=","!=","not-in"].indexOf(this.op)>=0}getFlattenedFilters(){return[this]}getFilters(){return[this]}getFirstInequalityField(){return this.isInequality()?this.field:null}}class ia extends ii{constructor(e,t){super(),this.filters=e,this.op=t,this.lt=null}static create(e,t){return new ia(e,t)}matches(e){return io(this)?void 0===this.filters.find(t=>!t.matches(e)):void 0!==this.filters.find(t=>t.matches(e))}getFlattenedFilters(){return null!==this.lt||(this.lt=this.filters.reduce((e,t)=>e.concat(t.getFlattenedFilters()),[])),this.lt}getFilters(){return Object.assign([],this.filters)}getFirstInequalityField(){let e=this.ft(e=>e.isInequality());return null!==e?e.field:null}ft(e){for(let t of this.getFlattenedFilters())if(e(t))return t;return null}}function io(e){return"and"===e.op}function il(e){for(let t of e.filters)if(t instanceof ia)return!1;return!0}class iu extends is{constructor(e,t,n){super(e,t,n),this.key=rv.fromName(n.referenceValue)}matches(e){let t=rv.comparator(e.key,this.key);return this.matchesComparison(t)}}class ic extends is{constructor(e,t){super(e,"in",t),this.keys=id("in",t)}matches(e){return this.keys.some(t=>t.isEqual(e.key))}}class ih extends is{constructor(e,t){super(e,"not-in",t),this.keys=id("not-in",t)}matches(e){return!this.keys.some(t=>t.isEqual(e.key))}}function id(e,t){var n;return((null===(n=t.arrayValue)||void 0===n?void 0:n.values)||[]).map(e=>rv.fromName(e.referenceValue))}class ip extends is{constructor(e,t){super(e,"array-contains",t)}matches(e){let t=e.data.field(this.field);return r1(t)&&rQ(t.arrayValue,this.value)}}class ig extends is{constructor(e,t){super(e,"in",t)}matches(e){let t=e.data.field(this.field);return null!==t&&rQ(this.value.arrayValue,t)}}class im extends is{constructor(e,t){super(e,"not-in",t)}matches(e){if(rQ(this.value.arrayValue,{nullValue:"NULL_VALUE"}))return!1;let t=e.data.field(this.field);return null!==t&&!rQ(this.value.arrayValue,t)}}class iy extends is{constructor(e,t){super(e,"array-contains-any",t)}matches(e){let t=e.data.field(this.field);return!(!r1(t)||!t.arrayValue.values)&&t.arrayValue.values.some(e=>rQ(this.value.arrayValue,e))}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class iv{constructor(e,t=null,n=[],r=[],i=null,s=null,a=null){this.path=e,this.collectionGroup=t,this.orderBy=n,this.filters=r,this.limit=i,this.startAt=s,this.endAt=a,this.dt=null}}function iw(e,t=null,n=[],r=[],i=null,s=null,a=null){return new iv(e,t,n,r,i,s,a)}function ib(e){if(null===e.dt){let t=e.path.canonicalString();null!==e.collectionGroup&&(t+="|cg:"+e.collectionGroup),t+="|f:"+e.filters.map(e=>(function e(t){if(t instanceof is)return t.field.canonicalString()+t.op.toString()+rX(t.value);if(il(t)&&io(t))return t.filters.map(t=>e(t)).join(",");{let n=t.filters.map(t=>e(t)).join(",");return`${t.op}(${n})`}})(e)).join(",")+"|ob:"+e.orderBy.map(e=>e.field.canonicalString()+e.dir).join(","),null==e.limit||(t+="|l:"+e.limit),e.startAt&&(t+="|lb:"+(e.startAt.inclusive?"b:":"a:")+e.startAt.position.map(e=>rX(e)).join(",")),e.endAt&&(t+="|ub:"+(e.endAt.inclusive?"a:":"b:")+e.endAt.position.map(e=>rX(e)).join(",")),e.dt=t}return e.dt}function iE(e,t){if(e.limit!==t.limit||e.orderBy.length!==t.orderBy.length)return!1;for(let i=0;i<e.orderBy.length;i++){var n,r;if(n=e.orderBy[i],r=t.orderBy[i],!(n.dir===r.dir&&n.field.isEqual(r.field)))return!1}if(e.filters.length!==t.filters.length)return!1;for(let n=0;n<e.filters.length;n++)if(!function e(t,n){return t instanceof is?n instanceof is&&t.op===n.op&&t.field.isEqual(n.field)&&rW(t.value,n.value):t instanceof ia?n instanceof ia&&t.op===n.op&&t.filters.length===n.filters.length&&t.filters.reduce((t,r,i)=>t&&e(r,n.filters[i]),!0):void n7()}(e.filters[n],t.filters[n]))return!1;return e.collectionGroup===t.collectionGroup&&!!e.path.isEqual(t.path)&&!!it(e.startAt,t.startAt)&&it(e.endAt,t.endAt)}function iI(e){return rv.isDocumentKey(e.path)&&null===e.collectionGroup&&0===e.filters.length}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class i_{constructor(e,t=null,n=[],r=[],i=null,s="F",a=null,o=null){this.path=e,this.collectionGroup=t,this.explicitOrderBy=n,this.filters=r,this.limit=i,this.limitType=s,this.startAt=a,this.endAt=o,this.wt=null,this._t=null,this.startAt,this.endAt}}function iT(e){return new i_(e)}function ik(e){return 0===e.filters.length&&null===e.limit&&null==e.startAt&&null==e.endAt&&(0===e.explicitOrderBy.length||1===e.explicitOrderBy.length&&e.explicitOrderBy[0].field.isKeyField())}function iS(e){return e.explicitOrderBy.length>0?e.explicitOrderBy[0].field:null}function ix(e){for(let t of e.filters){let e=t.getFirstInequalityField();if(null!==e)return e}return null}function iC(e){return null!==e.collectionGroup}function iA(e){if(null===e.wt){e.wt=[];let t=ix(e),n=iS(e);if(null!==t&&null===n)t.isKeyField()||e.wt.push(new ir(t)),e.wt.push(new ir(ry.keyField(),"asc"));else{let t=!1;for(let n of e.explicitOrderBy)e.wt.push(n),n.field.isKeyField()&&(t=!0);if(!t){let t=e.explicitOrderBy.length>0?e.explicitOrderBy[e.explicitOrderBy.length-1].dir:"asc";e.wt.push(new ir(ry.keyField(),t))}}}return e.wt}function iN(e){if(!e._t){if("F"===e.limitType)e._t=iw(e.path,e.collectionGroup,iA(e),e.filters,e.limit,e.startAt,e.endAt);else{let t=[];for(let n of iA(e)){let e="desc"===n.dir?"asc":"desc";t.push(new ir(n.field,e))}let n=e.endAt?new r8(e.endAt.position,e.endAt.inclusive):null,r=e.startAt?new r8(e.startAt.position,e.startAt.inclusive):null;e._t=iw(e.path,e.collectionGroup,t,e.filters,e.limit,n,r)}}return e._t}function iR(e,t){t.getFirstInequalityField(),ix(e);let n=e.filters.concat([t]);return new i_(e.path,e.collectionGroup,e.explicitOrderBy.slice(),n,e.limit,e.limitType,e.startAt,e.endAt)}function iD(e,t,n){return new i_(e.path,e.collectionGroup,e.explicitOrderBy.slice(),e.filters.slice(),t,n,e.startAt,e.endAt)}function iO(e,t){return iE(iN(e),iN(t))&&e.limitType===t.limitType}function iP(e){return`${ib(iN(e))}|lt:${e.limitType}`}function iL(e){var t;let n;return`Query(target=${n=(t=iN(e)).path.canonicalString(),null!==t.collectionGroup&&(n+=" collectionGroup="+t.collectionGroup),t.filters.length>0&&(n+=`, filters: [${t.filters.map(e=>(function e(t){return t instanceof is?`${t.field.canonicalString()} ${t.op} ${rX(t.value)}`:t instanceof ia?t.op.toString()+" {"+t.getFilters().map(e).join(" ,")+"}":"Filter"})(e)).join(", ")}]`),null==t.limit||(n+=", limit: "+t.limit),t.orderBy.length>0&&(n+=`, orderBy: [${t.orderBy.map(e=>`${e.field.canonicalString()} (${e.dir})`).join(", ")}]`),t.startAt&&(n+=", startAt: "+(t.startAt.inclusive?"b:":"a:")+t.startAt.position.map(e=>rX(e)).join(",")),t.endAt&&(n+=", endAt: "+(t.endAt.inclusive?"a:":"b:")+t.endAt.position.map(e=>rX(e)).join(",")),`Target(${n})`}; limitType=${e.limitType})`}function iM(e,t){return t.isFoundDocument()&&function(e,t){let n=t.key.path;return null!==e.collectionGroup?t.key.hasCollectionId(e.collectionGroup)&&e.path.isPrefixOf(n):rv.isDocumentKey(e.path)?e.path.isEqual(n):e.path.isImmediateParentOf(n)}(e,t)&&function(e,t){for(let n of iA(e))if(!n.field.isKeyField()&&null===t.data.field(n.field))return!1;return!0}(e,t)&&function(e,t){for(let n of e.filters)if(!n.matches(t))return!1;return!0}(e,t)&&(!e.startAt||!!function(e,t,n){let r=ie(e,t,n);return e.inclusive?r<=0:r<0}(e.startAt,iA(e),t))&&(!e.endAt||!!function(e,t,n){let r=ie(e,t,n);return e.inclusive?r>=0:r>0}(e.endAt,iA(e),t))}function iF(e){return(t,n)=>{let r=!1;for(let i of iA(e)){let e=function(e,t,n){let r=e.field.isKeyField()?rv.comparator(t.key,n.key):function(e,t,n){let r=t.data.field(e),i=n.data.field(e);return null!==r&&null!==i?rZ(r,i):n7()}(e.field,t,n);switch(e.dir){case"asc":return r;case"desc":return -1*r;default:return n7()}}(i,t,n);if(0!==e)return e;r=r||i.field.isKeyField()}return 0}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class iV{constructor(e,t){this.mapKeyFn=e,this.equalsFn=t,this.inner={},this.innerSize=0}get(e){let t=this.mapKeyFn(e),n=this.inner[t];if(void 0!==n){for(let[t,r]of n)if(this.equalsFn(t,e))return r}}has(e){return void 0!==this.get(e)}set(e,t){let n=this.mapKeyFn(e),r=this.inner[n];if(void 0===r)return this.inner[n]=[[e,t]],void this.innerSize++;for(let n=0;n<r.length;n++)if(this.equalsFn(r[n][0],e))return void(r[n]=[e,t]);r.push([e,t]),this.innerSize++}delete(e){let t=this.mapKeyFn(e),n=this.inner[t];if(void 0===n)return!1;for(let r=0;r<n.length;r++)if(this.equalsFn(n[r][0],e))return 1===n.length?delete this.inner[t]:n.splice(r,1),this.innerSize--,!0;return!1}forEach(e){rx(this.inner,(t,n)=>{for(let[t,r]of n)e(t,r)})}isEmpty(){return rC(this.inner)}size(){return this.innerSize}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let iU=new rA(rv.comparator),ij=new rA(rv.comparator);function iB(...e){let t=ij;for(let n of e)t=t.insert(n.key,n);return t}function iq(e){let t=ij;return e.forEach((e,n)=>t=t.insert(e,n.overlayedDocument)),t}function iz(){return new iV(e=>e.toString(),(e,t)=>e.isEqual(t))}let i$=new rA(rv.comparator),iH=new rD(rv.comparator);function iK(...e){let t=iH;for(let n of e)t=t.add(n);return t}let iG=new rD(rc);/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function iW(e,t){if(e.useProto3Json){if(isNaN(t))return{doubleValue:"NaN"};if(t===1/0)return{doubleValue:"Infinity"};if(t===-1/0)return{doubleValue:"-Infinity"}}return{doubleValue:rk(t)?"-0":t}}function iQ(e){return{integerValue:""+e}}/**
 * @license
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class iZ{constructor(){this._=void 0}}function iJ(e,t){return e instanceof i4?r0(t)||t&&"doubleValue"in t?t:{integerValue:0}:null}class iX extends iZ{}class iY extends iZ{constructor(e){super(),this.elements=e}}function i0(e,t){let n=i6(t);for(let t of e.elements)n.some(e=>rW(e,t))||n.push(t);return{arrayValue:{values:n}}}class i1 extends iZ{constructor(e){super(),this.elements=e}}function i2(e,t){let n=i6(t);for(let t of e.elements)n=n.filter(e=>!rW(e,t));return{arrayValue:{values:n}}}class i4 extends iZ{constructor(e,t){super(),this.serializer=e,this.gt=t}}function i9(e){return rU(e.integerValue||e.doubleValue)}function i6(e){return r1(e)&&e.arrayValue.values?e.arrayValue.values.slice():[]}class i5{constructor(e,t){this.version=e,this.transformResults=t}}class i7{constructor(e,t){this.updateTime=e,this.exists=t}static none(){return new i7}static exists(e){return new i7(void 0,e)}static updateTime(e){return new i7(e)}get isNone(){return void 0===this.updateTime&&void 0===this.exists}isEqual(e){return this.exists===e.exists&&(this.updateTime?!!e.updateTime&&this.updateTime.isEqual(e.updateTime):!e.updateTime)}}function i3(e,t){return void 0!==e.updateTime?t.isFoundDocument()&&t.version.isEqual(e.updateTime):void 0===e.exists||e.exists===t.isFoundDocument()}class i8{}function se(e,t){if(!e.hasLocalMutations||t&&0===t.fields.length)return null;if(null===t)return e.isNoDocument()?new sl(e.key,i7.none()):new sr(e.key,e.data,i7.none());{let n=e.data,r=r7.empty(),i=new rD(ry.comparator);for(let e of t.fields)if(!i.has(e)){let t=n.field(e);null===t&&e.length>1&&(e=e.popLast(),t=n.field(e)),null===t?r.delete(e):r.set(e,t),i=i.add(e)}return new si(e.key,r,new rP(i.toArray()),i7.none())}}function st(e,t,n,r){return e instanceof sr?function(e,t,n,r){if(!i3(e.precondition,t))return n;let i=e.value.clone(),s=so(e.fieldTransforms,r,t);return i.setAll(s),t.convertToFoundDocument(t.version,i).setHasLocalMutations(),null}(e,t,n,r):e instanceof si?function(e,t,n,r){if(!i3(e.precondition,t))return n;let i=so(e.fieldTransforms,r,t),s=t.data;return(s.setAll(ss(e)),s.setAll(i),t.convertToFoundDocument(t.version,s).setHasLocalMutations(),null===n)?null:n.unionWith(e.fieldMask.fields).unionWith(e.fieldTransforms.map(e=>e.field))}(e,t,n,r):i3(e.precondition,t)?(t.convertToNoDocument(t.version).setHasLocalMutations(),null):n}function sn(e,t){var n,r;return e.type===t.type&&!!e.key.isEqual(t.key)&&!!e.precondition.isEqual(t.precondition)&&(n=e.fieldTransforms,r=t.fieldTransforms,!!(void 0===n&&void 0===r||!(!n||!r)&&rh(n,r,(e,t)=>{var n,r;return e.field.isEqual(t.field)&&(n=e.transform,r=t.transform,n instanceof iY&&r instanceof iY||n instanceof i1&&r instanceof i1?rh(n.elements,r.elements,rW):n instanceof i4&&r instanceof i4?rW(n.gt,r.gt):n instanceof iX&&r instanceof iX)})))&&(0===e.type?e.value.isEqual(t.value):1!==e.type||e.data.isEqual(t.data)&&e.fieldMask.isEqual(t.fieldMask))}class sr extends i8{constructor(e,t,n,r=[]){super(),this.key=e,this.value=t,this.precondition=n,this.fieldTransforms=r,this.type=0}getFieldMask(){return null}}class si extends i8{constructor(e,t,n,r,i=[]){super(),this.key=e,this.data=t,this.fieldMask=n,this.precondition=r,this.fieldTransforms=i,this.type=1}getFieldMask(){return this.fieldMask}}function ss(e){let t=new Map;return e.fieldMask.fields.forEach(n=>{if(!n.isEmpty()){let r=e.data.field(n);t.set(n,r)}}),t}function sa(e,t,n){var r;let i=new Map;e.length===n.length||n7();for(let s=0;s<n.length;s++){let a=e[s],o=a.transform,l=t.data.field(a.field);i.set(a.field,(r=n[s],o instanceof iY?i0(o,l):o instanceof i1?i2(o,l):r))}return i}function so(e,t,n){let r=new Map;for(let i of e){let e=i.transform,s=n.data.field(i.field);r.set(i.field,e instanceof iX?function(e,t){let n={fields:{__type__:{stringValue:"server_timestamp"},__local_write_time__:{timestampValue:{seconds:e.seconds,nanos:e.nanoseconds}}}};return t&&rB(t)&&(t=rq(t)),t&&(n.fields.__previous_value__=t),{mapValue:n}}(t,s):e instanceof iY?i0(e,s):e instanceof i1?i2(e,s):function(e,t){let n=iJ(e,t),r=i9(n)+i9(e.gt);return r0(n)&&r0(e.gt)?iQ(r):iW(e.serializer,r)}(e,s))}return r}class sl extends i8{constructor(e,t){super(),this.key=e,this.precondition=t,this.type=2,this.fieldTransforms=[]}getFieldMask(){return null}}class su extends i8{constructor(e,t){super(),this.key=e,this.precondition=t,this.type=3,this.fieldTransforms=[]}getFieldMask(){return null}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sc{constructor(e,t,n,r){this.batchId=e,this.localWriteTime=t,this.baseMutations=n,this.mutations=r}applyToRemoteDocument(e,t){let n=t.mutationResults;for(let t=0;t<this.mutations.length;t++){let i=this.mutations[t];if(i.key.isEqual(e.key)){var r;r=n[t],i instanceof sr?function(e,t,n){let r=e.value.clone(),i=sa(e.fieldTransforms,t,n.transformResults);r.setAll(i),t.convertToFoundDocument(n.version,r).setHasCommittedMutations()}(i,e,r):i instanceof si?function(e,t,n){if(!i3(e.precondition,t))return void t.convertToUnknownDocument(n.version);let r=sa(e.fieldTransforms,t,n.transformResults),i=t.data;i.setAll(ss(e)),i.setAll(r),t.convertToFoundDocument(n.version,i).setHasCommittedMutations()}(i,e,r):function(e,t,n){t.convertToNoDocument(n.version).setHasCommittedMutations()}(0,e,r)}}}applyToLocalView(e,t){for(let n of this.baseMutations)n.key.isEqual(e.key)&&(t=st(n,e,t,this.localWriteTime));for(let n of this.mutations)n.key.isEqual(e.key)&&(t=st(n,e,t,this.localWriteTime));return t}applyToLocalDocumentSet(e,t){let n=iz();return this.mutations.forEach(r=>{let i=e.get(r.key),s=i.overlayedDocument,a=this.applyToLocalView(s,i.mutatedFields);a=t.has(r.key)?null:a;let o=se(s,a);null!==o&&n.set(r.key,o),s.isValidDocument()||s.convertToNoDocument(rf.min())}),n}keys(){return this.mutations.reduce((e,t)=>e.add(t.key),iK())}isEqual(e){return this.batchId===e.batchId&&rh(this.mutations,e.mutations,(e,t)=>sn(e,t))&&rh(this.baseMutations,e.baseMutations,(e,t)=>sn(e,t))}}class sh{constructor(e,t,n,r){this.batch=e,this.commitVersion=t,this.mutationResults=n,this.docVersions=r}static from(e,t,n){e.mutations.length===n.length||n7();let r=i$,i=e.mutations;for(let e=0;e<i.length;e++)r=r.insert(i[e].key,n[e].version);return new sh(e,t,n,r)}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sd{constructor(e,t){this.largestBatchId=e,this.mutation=t}getKey(){return this.mutation.key}isEqual(e){return null!==e&&this.mutation===e.mutation}toString(){return`Overlay{
      largestBatchId: ${this.largestBatchId},
      mutation: ${this.mutation.toString()}
    }`}}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sf{constructor(e,t,n){this.alias=e,this.yt=t,this.fieldPath=n}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sp{constructor(e,t){this.count=e,this.unchangedNames=t}}function sg(e){if(void 0===e)return n9("GRPC error has no .code"),n3.UNKNOWN;switch(e){case o.OK:return n3.OK;case o.CANCELLED:return n3.CANCELLED;case o.UNKNOWN:return n3.UNKNOWN;case o.DEADLINE_EXCEEDED:return n3.DEADLINE_EXCEEDED;case o.RESOURCE_EXHAUSTED:return n3.RESOURCE_EXHAUSTED;case o.INTERNAL:return n3.INTERNAL;case o.UNAVAILABLE:return n3.UNAVAILABLE;case o.UNAUTHENTICATED:return n3.UNAUTHENTICATED;case o.INVALID_ARGUMENT:return n3.INVALID_ARGUMENT;case o.NOT_FOUND:return n3.NOT_FOUND;case o.ALREADY_EXISTS:return n3.ALREADY_EXISTS;case o.PERMISSION_DENIED:return n3.PERMISSION_DENIED;case o.FAILED_PRECONDITION:return n3.FAILED_PRECONDITION;case o.ABORTED:return n3.ABORTED;case o.OUT_OF_RANGE:return n3.OUT_OF_RANGE;case o.UNIMPLEMENTED:return n3.UNIMPLEMENTED;case o.DATA_LOSS:return n3.DATA_LOSS;default:return n7()}}(l=o||(o={}))[l.OK=0]="OK",l[l.CANCELLED=1]="CANCELLED",l[l.UNKNOWN=2]="UNKNOWN",l[l.INVALID_ARGUMENT=3]="INVALID_ARGUMENT",l[l.DEADLINE_EXCEEDED=4]="DEADLINE_EXCEEDED",l[l.NOT_FOUND=5]="NOT_FOUND",l[l.ALREADY_EXISTS=6]="ALREADY_EXISTS",l[l.PERMISSION_DENIED=7]="PERMISSION_DENIED",l[l.UNAUTHENTICATED=16]="UNAUTHENTICATED",l[l.RESOURCE_EXHAUSTED=8]="RESOURCE_EXHAUSTED",l[l.FAILED_PRECONDITION=9]="FAILED_PRECONDITION",l[l.ABORTED=10]="ABORTED",l[l.OUT_OF_RANGE=11]="OUT_OF_RANGE",l[l.UNIMPLEMENTED=12]="UNIMPLEMENTED",l[l.INTERNAL=13]="INTERNAL",l[l.UNAVAILABLE=14]="UNAVAILABLE",l[l.DATA_LOSS=15]="DATA_LOSS";/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sm{constructor(){this.onExistenceFilterMismatchCallbacks=new Map}static get instance(){return sy}static getOrCreateInstance(){return null===sy&&(sy=new sm),sy}onExistenceFilterMismatch(e){let t=Symbol();return this.onExistenceFilterMismatchCallbacks.set(t,e),()=>this.onExistenceFilterMismatchCallbacks.delete(t)}notifyOnExistenceFilterMismatch(e){this.onExistenceFilterMismatchCallbacks.forEach(t=>t(e))}}let sy=null,sv=new nJ([4294967295,4294967295],0);function sw(e){let t=(new TextEncoder).encode(e),n=new nZ;return n.update(t),new Uint8Array(n.digest())}function sb(e){let t=new DataView(e.buffer),n=t.getUint32(0,!0),r=t.getUint32(4,!0),i=t.getUint32(8,!0),s=t.getUint32(12,!0);return[new nJ([n,r],0),new nJ([i,s],0)]}class sE{constructor(e,t,n){if(this.bitmap=e,this.padding=t,this.hashCount=n,t<0||t>=8)throw new sI(`Invalid padding: ${t}`);if(n<0||e.length>0&&0===this.hashCount)throw new sI(`Invalid hash count: ${n}`);if(0===e.length&&0!==t)throw new sI(`Invalid padding when bitmap length is 0: ${t}`);this.It=8*e.length-t,this.Tt=nJ.fromNumber(this.It)}Et(e,t,n){let r=e.add(t.multiply(nJ.fromNumber(n)));return 1===r.compare(sv)&&(r=new nJ([r.getBits(0),r.getBits(1)],0)),r.modulo(this.Tt).toNumber()}At(e){return 0!=(this.bitmap[Math.floor(e/8)]&1<<e%8)}vt(e){if(0===this.It)return!1;let t=sw(e),[n,r]=sb(t);for(let e=0;e<this.hashCount;e++){let t=this.Et(n,r,e);if(!this.At(t))return!1}return!0}static create(e,t,n){let r=new Uint8Array(Math.ceil(e/8)),i=new sE(r,e%8==0?0:8-e%8,t);return n.forEach(e=>i.insert(e)),i}insert(e){if(0===this.It)return;let t=sw(e),[n,r]=sb(t);for(let e=0;e<this.hashCount;e++){let t=this.Et(n,r,e);this.Rt(t)}}Rt(e){this.bitmap[Math.floor(e/8)]|=1<<e%8}}class sI extends Error{constructor(){super(...arguments),this.name="BloomFilterError"}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s_{constructor(e,t,n,r,i){this.snapshotVersion=e,this.targetChanges=t,this.targetMismatches=n,this.documentUpdates=r,this.resolvedLimboDocuments=i}static createSynthesizedRemoteEventForCurrentChange(e,t,n){let r=new Map;return r.set(e,sT.createSynthesizedTargetChangeForCurrentChange(e,t,n)),new s_(rf.min(),r,new rA(rc),iU,iK())}}class sT{constructor(e,t,n,r,i){this.resumeToken=e,this.current=t,this.addedDocuments=n,this.modifiedDocuments=r,this.removedDocuments=i}static createSynthesizedTargetChangeForCurrentChange(e,t,n){return new sT(n,t,iK(),iK(),iK())}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sk{constructor(e,t,n,r){this.Pt=e,this.removedTargetIds=t,this.key=n,this.bt=r}}class sS{constructor(e,t){this.targetId=e,this.Vt=t}}class sx{constructor(e,t,n=rM.EMPTY_BYTE_STRING,r=null){this.state=e,this.targetIds=t,this.resumeToken=n,this.cause=r}}class sC{constructor(){this.St=0,this.Dt=sR(),this.Ct=rM.EMPTY_BYTE_STRING,this.xt=!1,this.Nt=!0}get current(){return this.xt}get resumeToken(){return this.Ct}get kt(){return 0!==this.St}get Mt(){return this.Nt}$t(e){e.approximateByteSize()>0&&(this.Nt=!0,this.Ct=e)}Ot(){let e=iK(),t=iK(),n=iK();return this.Dt.forEach((r,i)=>{switch(i){case 0:e=e.add(r);break;case 2:t=t.add(r);break;case 1:n=n.add(r);break;default:n7()}}),new sT(this.Ct,this.xt,e,t,n)}Ft(){this.Nt=!1,this.Dt=sR()}Bt(e,t){this.Nt=!0,this.Dt=this.Dt.insert(e,t)}Lt(e){this.Nt=!0,this.Dt=this.Dt.remove(e)}qt(){this.St+=1}Ut(){this.St-=1}Kt(){this.Nt=!0,this.xt=!0}}class sA{constructor(e){this.Gt=e,this.Qt=new Map,this.jt=iU,this.zt=sN(),this.Wt=new rA(rc)}Ht(e){for(let t of e.Pt)e.bt&&e.bt.isFoundDocument()?this.Jt(t,e.bt):this.Yt(t,e.key,e.bt);for(let t of e.removedTargetIds)this.Yt(t,e.key,e.bt)}Xt(e){this.forEachTarget(e,t=>{let n=this.Zt(t);switch(e.state){case 0:this.te(t)&&n.$t(e.resumeToken);break;case 1:n.Ut(),n.kt||n.Ft(),n.$t(e.resumeToken);break;case 2:n.Ut(),n.kt||this.removeTarget(t);break;case 3:this.te(t)&&(n.Kt(),n.$t(e.resumeToken));break;case 4:this.te(t)&&(this.ee(t),n.$t(e.resumeToken));break;default:n7()}})}forEachTarget(e,t){e.targetIds.length>0?e.targetIds.forEach(t):this.Qt.forEach((e,n)=>{this.te(n)&&t(n)})}ne(e){var t;let n=e.targetId,r=e.Vt.count,i=this.se(n);if(i){let s=i.target;if(iI(s)){if(0===r){let e=new rv(s.path);this.Yt(n,e,r3.newNoDocument(e,rf.min()))}else 1===r||n7()}else{let i=this.ie(n);if(i!==r){let r=this.re(e,i);if(0!==r){this.ee(n);let e=2===r?"TargetPurposeExistenceFilterMismatchBloom":"TargetPurposeExistenceFilterMismatch";this.Wt=this.Wt.insert(n,e)}null===(t=sm.instance)||void 0===t||t.notifyOnExistenceFilterMismatch(function(e,t,n){var r,i,s,a,o,l;let u={localCacheCount:t,existenceFilterCount:n.count},c=n.unchangedNames;return c&&(u.bloomFilter={applied:0===e,hashCount:null!==(r=null==c?void 0:c.hashCount)&&void 0!==r?r:0,bitmapLength:null!==(a=null===(s=null===(i=null==c?void 0:c.bits)||void 0===i?void 0:i.bitmap)||void 0===s?void 0:s.length)&&void 0!==a?a:0,padding:null!==(l=null===(o=null==c?void 0:c.bits)||void 0===o?void 0:o.padding)&&void 0!==l?l:0}),u}(r,i,e.Vt))}}}}re(e,t){let n,r;let{unchangedNames:i,count:s}=e.Vt;if(!i||!i.bits)return 1;let{bits:{bitmap:a="",padding:o=0},hashCount:l=0}=i;try{n=rj(a).toUint8Array()}catch(e){if(e instanceof rL)return n6("Decoding the base64 bloom filter in existence filter failed ("+e.message+"); ignoring the bloom filter and falling back to full re-query."),1;throw e}try{r=new sE(n,o,l)}catch(e){return n6(e instanceof sI?"BloomFilter error: ":"Applying bloom filter failed: ",e),1}return 0===r.It?1:s!==t-this.oe(e.targetId,r)?2:0}oe(e,t){let n=this.Gt.getRemoteKeysForTarget(e),r=0;return n.forEach(n=>{let i=this.Gt.ue(),s=`projects/${i.projectId}/databases/${i.database}/documents/${n.path.canonicalString()}`;t.vt(s)||(this.Yt(e,n,null),r++)}),r}ce(e){let t=new Map;this.Qt.forEach((n,r)=>{let i=this.se(r);if(i){if(n.current&&iI(i.target)){let t=new rv(i.target.path);null!==this.jt.get(t)||this.ae(r,t)||this.Yt(r,t,r3.newNoDocument(t,e))}n.Mt&&(t.set(r,n.Ot()),n.Ft())}});let n=iK();this.zt.forEach((e,t)=>{let r=!0;t.forEachWhile(e=>{let t=this.se(e);return!t||"TargetPurposeLimboResolution"===t.purpose||(r=!1,!1)}),r&&(n=n.add(e))}),this.jt.forEach((t,n)=>n.setReadTime(e));let r=new s_(e,t,this.Wt,this.jt,n);return this.jt=iU,this.zt=sN(),this.Wt=new rA(rc),r}Jt(e,t){if(!this.te(e))return;let n=this.ae(e,t.key)?2:0;this.Zt(e).Bt(t.key,n),this.jt=this.jt.insert(t.key,t),this.zt=this.zt.insert(t.key,this.he(t.key).add(e))}Yt(e,t,n){if(!this.te(e))return;let r=this.Zt(e);this.ae(e,t)?r.Bt(t,1):r.Lt(t),this.zt=this.zt.insert(t,this.he(t).delete(e)),n&&(this.jt=this.jt.insert(t,n))}removeTarget(e){this.Qt.delete(e)}ie(e){let t=this.Zt(e).Ot();return this.Gt.getRemoteKeysForTarget(e).size+t.addedDocuments.size-t.removedDocuments.size}qt(e){this.Zt(e).qt()}Zt(e){let t=this.Qt.get(e);return t||(t=new sC,this.Qt.set(e,t)),t}he(e){let t=this.zt.get(e);return t||(t=new rD(rc),this.zt=this.zt.insert(e,t)),t}te(e){let t=null!==this.se(e);return t||n4("WatchChangeAggregator","Detected inactive target",e),t}se(e){let t=this.Qt.get(e);return t&&t.kt?null:this.Gt.le(e)}ee(e){this.Qt.set(e,new sC),this.Gt.getRemoteKeysForTarget(e).forEach(t=>{this.Yt(e,t,null)})}ae(e,t){return this.Gt.getRemoteKeysForTarget(e).has(t)}}function sN(){return new rA(rv.comparator)}function sR(){return new rA(rv.comparator)}let sD={asc:"ASCENDING",desc:"DESCENDING"},sO={"<":"LESS_THAN","<=":"LESS_THAN_OR_EQUAL",">":"GREATER_THAN",">=":"GREATER_THAN_OR_EQUAL","==":"EQUAL","!=":"NOT_EQUAL","array-contains":"ARRAY_CONTAINS",in:"IN","not-in":"NOT_IN","array-contains-any":"ARRAY_CONTAINS_ANY"},sP={and:"AND",or:"OR"};class sL{constructor(e,t){this.databaseId=e,this.useProto3Json=t}}function sM(e,t){return e.useProto3Json||null==t?t:{value:t}}function sF(e,t){return e.useProto3Json?`${new Date(1e3*t.seconds).toISOString().replace(/\.\d*/,"").replace("Z","")}.${("000000000"+t.nanoseconds).slice(-9)}Z`:{seconds:""+t.seconds,nanos:t.nanoseconds}}function sV(e,t){return e.useProto3Json?t.toBase64():t.toUint8Array()}function sU(e){return e||n7(),rf.fromTimestamp(function(e){let t=rV(e);return new rd(t.seconds,t.nanos)}(e))}function sj(e,t){return new rg(["projects",e.projectId,"databases",e.database]).child("documents").child(t).canonicalString()}function sB(e){let t=rg.fromString(e);return sJ(t)||n7(),t}function sq(e,t){return sj(e.databaseId,t.path)}function sz(e,t){let n=sB(t);if(n.get(1)!==e.databaseId.projectId)throw new n8(n3.INVALID_ARGUMENT,"Tried to deserialize key from different project: "+n.get(1)+" vs "+e.databaseId.projectId);if(n.get(3)!==e.databaseId.database)throw new n8(n3.INVALID_ARGUMENT,"Tried to deserialize key from different database: "+n.get(3)+" vs "+e.databaseId.database);return new rv(sK(n))}function s$(e,t){return sj(e.databaseId,t)}function sH(e){return new rg(["projects",e.databaseId.projectId,"databases",e.databaseId.database]).canonicalString()}function sK(e){return e.length>4&&"documents"===e.get(4)||n7(),e.popFirst(5)}function sG(e,t,n){return{name:sq(e,t),fields:n.value.mapValue.fields}}function sW(e,t){var n,r;let i={structuredQuery:{}},s=t.path;null!==t.collectionGroup?(i.parent=s$(e,s),i.structuredQuery.from=[{collectionId:t.collectionGroup,allDescendants:!0}]):(i.parent=s$(e,s.popLast()),i.structuredQuery.from=[{collectionId:s.lastSegment()}]);let a=function(e){if(0!==e.length)return function e(t){return t instanceof is?function(e){if("=="===e.op){if(r4(e.value))return{unaryFilter:{field:sQ(e.field),op:"IS_NAN"}};if(r2(e.value))return{unaryFilter:{field:sQ(e.field),op:"IS_NULL"}}}else if("!="===e.op){if(r4(e.value))return{unaryFilter:{field:sQ(e.field),op:"IS_NOT_NAN"}};if(r2(e.value))return{unaryFilter:{field:sQ(e.field),op:"IS_NOT_NULL"}}}return{fieldFilter:{field:sQ(e.field),op:sO[e.op],value:e.value}}}(t):t instanceof ia?function(t){let n=t.getFilters().map(t=>e(t));return 1===n.length?n[0]:{compositeFilter:{op:sP[t.op],filters:n}}}(t):n7()}(ia.create(e,"and"))}(t.filters);a&&(i.structuredQuery.where=a);let o=function(e){if(0!==e.length)return e.map(e=>({field:sQ(e.field),direction:sD[e.dir]}))}(t.orderBy);o&&(i.structuredQuery.orderBy=o);let l=sM(e,t.limit);return null!==l&&(i.structuredQuery.limit=l),t.startAt&&(i.structuredQuery.startAt={before:(n=t.startAt).inclusive,values:n.position}),t.endAt&&(i.structuredQuery.endAt={before:!(r=t.endAt).inclusive,values:r.position}),i}function sQ(e){return{fieldPath:e.canonicalString()}}function sZ(e){return ry.fromServerFormat(e.fieldPath)}function sJ(e){return e.length>=4&&"projects"===e.get(0)&&"databases"===e.get(2)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sX{constructor(e,t,n,r,i=rf.min(),s=rf.min(),a=rM.EMPTY_BYTE_STRING,o=null){this.target=e,this.targetId=t,this.purpose=n,this.sequenceNumber=r,this.snapshotVersion=i,this.lastLimboFreeSnapshotVersion=s,this.resumeToken=a,this.expectedCount=o}withSequenceNumber(e){return new sX(this.target,this.targetId,this.purpose,e,this.snapshotVersion,this.lastLimboFreeSnapshotVersion,this.resumeToken,this.expectedCount)}withResumeToken(e,t){return new sX(this.target,this.targetId,this.purpose,this.sequenceNumber,t,this.lastLimboFreeSnapshotVersion,e,null)}withExpectedCount(e){return new sX(this.target,this.targetId,this.purpose,this.sequenceNumber,this.snapshotVersion,this.lastLimboFreeSnapshotVersion,this.resumeToken,e)}withLastLimboFreeSnapshotVersion(e){return new sX(this.target,this.targetId,this.purpose,this.sequenceNumber,this.snapshotVersion,e,this.resumeToken,this.expectedCount)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sY{constructor(e){this.fe=e}}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s0{constructor(){}_e(e,t){this.me(e,t),t.ge()}me(e,t){if("nullValue"in e)this.ye(t,5);else if("booleanValue"in e)this.ye(t,10),t.pe(e.booleanValue?1:0);else if("integerValue"in e)this.ye(t,15),t.pe(rU(e.integerValue));else if("doubleValue"in e){let n=rU(e.doubleValue);isNaN(n)?this.ye(t,13):(this.ye(t,15),rk(n)?t.pe(0):t.pe(n))}else if("timestampValue"in e){let n=e.timestampValue;this.ye(t,20),"string"==typeof n?t.Ie(n):(t.Ie(`${n.seconds||""}`),t.pe(n.nanos||0))}else if("stringValue"in e)this.Te(e.stringValue,t),this.Ee(t);else if("bytesValue"in e)this.ye(t,30),t.Ae(rj(e.bytesValue)),this.Ee(t);else if("referenceValue"in e)this.ve(e.referenceValue,t);else if("geoPointValue"in e){let n=e.geoPointValue;this.ye(t,45),t.pe(n.latitude||0),t.pe(n.longitude||0)}else"mapValue"in e?r5(e)?this.ye(t,Number.MAX_SAFE_INTEGER):(this.Re(e.mapValue,t),this.Ee(t)):"arrayValue"in e?(this.Pe(e.arrayValue,t),this.Ee(t)):n7()}Te(e,t){this.ye(t,25),this.be(e,t)}be(e,t){t.Ie(e)}Re(e,t){let n=e.fields||{};for(let e of(this.ye(t,55),Object.keys(n)))this.Te(e,t),this.me(n[e],t)}Pe(e,t){let n=e.values||[];for(let e of(this.ye(t,50),n))this.me(e,t)}ve(e,t){this.ye(t,37),rv.fromName(e).path.forEach(e=>{this.ye(t,60),this.be(e,t)})}ye(e,t){e.pe(t)}Ee(e){e.pe(2)}}s0.Ve=new s0;/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s1{constructor(){this.rn=new s2}addToCollectionParentIndex(e,t){return this.rn.add(t),rI.resolve()}getCollectionParents(e,t){return rI.resolve(this.rn.getEntries(t))}addFieldIndex(e,t){return rI.resolve()}deleteFieldIndex(e,t){return rI.resolve()}getDocumentsMatchingTarget(e,t){return rI.resolve(null)}getIndexType(e,t){return rI.resolve(0)}getFieldIndexes(e,t){return rI.resolve([])}getNextCollectionGroupToUpdate(e){return rI.resolve(null)}getMinOffset(e,t){return rI.resolve(rw.min())}getMinOffsetFromCollectionGroup(e,t){return rI.resolve(rw.min())}updateCollectionGroup(e,t,n){return rI.resolve()}updateIndexEntries(e,t){return rI.resolve()}}class s2{constructor(){this.index={}}add(e){let t=e.lastSegment(),n=e.popLast(),r=this.index[t]||new rD(rg.comparator),i=!r.has(n);return this.index[t]=r.add(n),i}has(e){let t=e.lastSegment(),n=e.popLast(),r=this.index[t];return r&&r.has(n)}getEntries(e){return(this.index[e]||new rD(rg.comparator)).toArray()}}new Uint8Array(0);class s4{constructor(e,t,n){this.cacheSizeCollectionThreshold=e,this.percentileToCollect=t,this.maximumSequenceNumbersToCollect=n}static withCacheSize(e){return new s4(e,s4.DEFAULT_COLLECTION_PERCENTILE,s4.DEFAULT_MAX_SEQUENCE_NUMBERS_TO_COLLECT)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */s4.DEFAULT_COLLECTION_PERCENTILE=10,s4.DEFAULT_MAX_SEQUENCE_NUMBERS_TO_COLLECT=1e3,s4.DEFAULT=new s4(41943040,s4.DEFAULT_COLLECTION_PERCENTILE,s4.DEFAULT_MAX_SEQUENCE_NUMBERS_TO_COLLECT),s4.DISABLED=new s4(-1,0,0);/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s9{constructor(e){this.Nn=e}next(){return this.Nn+=2,this.Nn}static kn(){return new s9(0)}static Mn(){return new s9(-1)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s6{constructor(){this.changes=new iV(e=>e.toString(),(e,t)=>e.isEqual(t)),this.changesApplied=!1}addEntry(e){this.assertNotApplied(),this.changes.set(e.key,e)}removeEntry(e,t){this.assertNotApplied(),this.changes.set(e,r3.newInvalidDocument(e).setReadTime(t))}getEntry(e,t){this.assertNotApplied();let n=this.changes.get(t);return void 0!==n?rI.resolve(n):this.getFromCache(e,t)}getEntries(e,t){return this.getAllFromCache(e,t)}apply(e){return this.assertNotApplied(),this.changesApplied=!0,this.applyChanges(e)}assertNotApplied(){}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *//**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s5{constructor(e,t){this.overlayedDocument=e,this.mutatedFields=t}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s7{constructor(e,t,n,r){this.remoteDocumentCache=e,this.mutationQueue=t,this.documentOverlayCache=n,this.indexManager=r}getDocument(e,t){let n=null;return this.documentOverlayCache.getOverlay(e,t).next(r=>(n=r,this.remoteDocumentCache.getEntry(e,t))).next(e=>(null!==n&&st(n.mutation,e,rP.empty(),rd.now()),e))}getDocuments(e,t){return this.remoteDocumentCache.getEntries(e,t).next(t=>this.getLocalViewOfDocuments(e,t,iK()).next(()=>t))}getLocalViewOfDocuments(e,t,n=iK()){let r=iz();return this.populateOverlays(e,r,t).next(()=>this.computeViews(e,t,r,n).next(e=>{let t=iB();return e.forEach((e,n)=>{t=t.insert(e,n.overlayedDocument)}),t}))}getOverlayedDocuments(e,t){let n=iz();return this.populateOverlays(e,n,t).next(()=>this.computeViews(e,t,n,iK()))}populateOverlays(e,t,n){let r=[];return n.forEach(e=>{t.has(e)||r.push(e)}),this.documentOverlayCache.getOverlays(e,r).next(e=>{e.forEach((e,n)=>{t.set(e,n)})})}computeViews(e,t,n,r){let i=iU,s=iz(),a=iz();return t.forEach((e,t)=>{let a=n.get(t.key);r.has(t.key)&&(void 0===a||a.mutation instanceof si)?i=i.insert(t.key,t):void 0!==a?(s.set(t.key,a.mutation.getFieldMask()),st(a.mutation,t,a.mutation.getFieldMask(),rd.now())):s.set(t.key,rP.empty())}),this.recalculateAndSaveOverlays(e,i).next(e=>(e.forEach((e,t)=>s.set(e,t)),t.forEach((e,t)=>{var n;return a.set(e,new s5(t,null!==(n=s.get(e))&&void 0!==n?n:null))}),a))}recalculateAndSaveOverlays(e,t){let n=iz(),r=new rA((e,t)=>e-t),i=iK();return this.mutationQueue.getAllMutationBatchesAffectingDocumentKeys(e,t).next(e=>{for(let i of e)i.keys().forEach(e=>{let s=t.get(e);if(null===s)return;let a=n.get(e)||rP.empty();a=i.applyToLocalView(s,a),n.set(e,a);let o=(r.get(i.batchId)||iK()).add(e);r=r.insert(i.batchId,o)})}).next(()=>{let s=[],a=r.getReverseIterator();for(;a.hasNext();){let r=a.getNext(),o=r.key,l=r.value,u=iz();l.forEach(e=>{if(!i.has(e)){let r=se(t.get(e),n.get(e));null!==r&&u.set(e,r),i=i.add(e)}}),s.push(this.documentOverlayCache.saveOverlays(e,o,u))}return rI.waitFor(s)}).next(()=>n)}recalculateAndSaveOverlaysForDocumentKeys(e,t){return this.remoteDocumentCache.getEntries(e,t).next(t=>this.recalculateAndSaveOverlays(e,t))}getDocumentsMatchingQuery(e,t,n){return rv.isDocumentKey(t.path)&&null===t.collectionGroup&&0===t.filters.length?this.getDocumentsMatchingDocumentQuery(e,t.path):iC(t)?this.getDocumentsMatchingCollectionGroupQuery(e,t,n):this.getDocumentsMatchingCollectionQuery(e,t,n)}getNextDocuments(e,t,n,r){return this.remoteDocumentCache.getAllFromCollectionGroup(e,t,n,r).next(i=>{let s=r-i.size>0?this.documentOverlayCache.getOverlaysForCollectionGroup(e,t,n.largestBatchId,r-i.size):rI.resolve(iz()),a=-1,o=i;return s.next(t=>rI.forEach(t,(t,n)=>(a<n.largestBatchId&&(a=n.largestBatchId),i.get(t)?rI.resolve():this.remoteDocumentCache.getEntry(e,t).next(e=>{o=o.insert(t,e)}))).next(()=>this.populateOverlays(e,t,i)).next(()=>this.computeViews(e,o,t,iK())).next(e=>({batchId:a,changes:iq(e)})))})}getDocumentsMatchingDocumentQuery(e,t){return this.getDocument(e,new rv(t)).next(e=>{let t=iB();return e.isFoundDocument()&&(t=t.insert(e.key,e)),t})}getDocumentsMatchingCollectionGroupQuery(e,t,n){let r=t.collectionGroup,i=iB();return this.indexManager.getCollectionParents(e,r).next(s=>rI.forEach(s,s=>{var a;let o=(a=s.child(r),new i_(a,null,t.explicitOrderBy.slice(),t.filters.slice(),t.limit,t.limitType,t.startAt,t.endAt));return this.getDocumentsMatchingCollectionQuery(e,o,n).next(e=>{e.forEach((e,t)=>{i=i.insert(e,t)})})}).next(()=>i))}getDocumentsMatchingCollectionQuery(e,t,n){let r;return this.documentOverlayCache.getOverlaysForCollection(e,t.path,n.largestBatchId).next(i=>(r=i,this.remoteDocumentCache.getDocumentsMatchingQuery(e,t,n,r))).next(e=>{r.forEach((t,n)=>{let r=n.getKey();null===e.get(r)&&(e=e.insert(r,r3.newInvalidDocument(r)))});let n=iB();return e.forEach((e,i)=>{let s=r.get(e);void 0!==s&&st(s.mutation,i,rP.empty(),rd.now()),iM(t,i)&&(n=n.insert(e,i))}),n})}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s3{constructor(e){this.serializer=e,this.cs=new Map,this.hs=new Map}getBundleMetadata(e,t){return rI.resolve(this.cs.get(t))}saveBundleMetadata(e,t){return this.cs.set(t.id,{id:t.id,version:t.version,createTime:sU(t.createTime)}),rI.resolve()}getNamedQuery(e,t){return rI.resolve(this.hs.get(t))}saveNamedQuery(e,t){return this.hs.set(t.name,{name:t.name,query:function(e){let t=function(e){var t,n,r,i,s,a,o,l;let u,c=function(e){let t=sB(e);return 4===t.length?rg.emptyPath():sK(t)}(e.parent),h=e.structuredQuery,d=h.from?h.from.length:0,f=null;if(d>0){1===d||n7();let e=h.from[0];e.allDescendants?f=e.collectionId:c=c.child(e.collectionId)}let p=[];h.where&&(p=function(e){var t;let n=function e(t){return void 0!==t.unaryFilter?function(e){switch(e.unaryFilter.op){case"IS_NAN":let t=sZ(e.unaryFilter.field);return is.create(t,"==",{doubleValue:NaN});case"IS_NULL":let n=sZ(e.unaryFilter.field);return is.create(n,"==",{nullValue:"NULL_VALUE"});case"IS_NOT_NAN":let r=sZ(e.unaryFilter.field);return is.create(r,"!=",{doubleValue:NaN});case"IS_NOT_NULL":let i=sZ(e.unaryFilter.field);return is.create(i,"!=",{nullValue:"NULL_VALUE"});default:return n7()}}(t):void 0!==t.fieldFilter?is.create(sZ(t.fieldFilter.field),function(e){switch(e){case"EQUAL":return"==";case"NOT_EQUAL":return"!=";case"GREATER_THAN":return">";case"GREATER_THAN_OR_EQUAL":return">=";case"LESS_THAN":return"<";case"LESS_THAN_OR_EQUAL":return"<=";case"ARRAY_CONTAINS":return"array-contains";case"IN":return"in";case"NOT_IN":return"not-in";case"ARRAY_CONTAINS_ANY":return"array-contains-any";default:return n7()}}(t.fieldFilter.op),t.fieldFilter.value):void 0!==t.compositeFilter?ia.create(t.compositeFilter.filters.map(t=>e(t)),function(e){switch(e){case"AND":return"and";case"OR":return"or";default:return n7()}}(t.compositeFilter.op)):n7()}(e);return n instanceof ia&&il(t=n)&&io(t)?n.getFilters():[n]}(h.where));let g=[];h.orderBy&&(g=h.orderBy.map(e=>new ir(sZ(e.field),function(e){switch(e){case"ASCENDING":return"asc";case"DESCENDING":return"desc";default:return}}(e.direction))));let m=null;h.limit&&(m=null==(u="object"==typeof(t=h.limit)?t.value:t)?null:u);let y=null;h.startAt&&(y=function(e){let t=!!e.before,n=e.values||[];return new r8(n,t)}(h.startAt));let v=null;return h.endAt&&(v=function(e){let t=!e.before,n=e.values||[];return new r8(n,t)}(h.endAt)),n=c,r=f,i=g,s=p,a=m,o=y,l=v,new i_(n,r,i,s,a,"F",o,l)}({parent:e.parent,structuredQuery:e.structuredQuery});return"LAST"===e.limitType?iD(t,t.limit,"L"):t}(t.bundledQuery),readTime:sU(t.readTime)}),rI.resolve()}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class s8{constructor(){this.overlays=new rA(rv.comparator),this.ls=new Map}getOverlay(e,t){return rI.resolve(this.overlays.get(t))}getOverlays(e,t){let n=iz();return rI.forEach(t,t=>this.getOverlay(e,t).next(e=>{null!==e&&n.set(t,e)})).next(()=>n)}saveOverlays(e,t,n){return n.forEach((n,r)=>{this.we(e,t,r)}),rI.resolve()}removeOverlaysForBatchId(e,t,n){let r=this.ls.get(n);return void 0!==r&&(r.forEach(e=>this.overlays=this.overlays.remove(e)),this.ls.delete(n)),rI.resolve()}getOverlaysForCollection(e,t,n){let r=iz(),i=t.length+1,s=new rv(t.child("")),a=this.overlays.getIteratorFrom(s);for(;a.hasNext();){let e=a.getNext().value,s=e.getKey();if(!t.isPrefixOf(s.path))break;s.path.length===i&&e.largestBatchId>n&&r.set(e.getKey(),e)}return rI.resolve(r)}getOverlaysForCollectionGroup(e,t,n,r){let i=new rA((e,t)=>e-t),s=this.overlays.getIterator();for(;s.hasNext();){let e=s.getNext().value;if(e.getKey().getCollectionGroup()===t&&e.largestBatchId>n){let t=i.get(e.largestBatchId);null===t&&(t=iz(),i=i.insert(e.largestBatchId,t)),t.set(e.getKey(),e)}}let a=iz(),o=i.getIterator();for(;o.hasNext()&&(o.getNext().value.forEach((e,t)=>a.set(e,t)),!(a.size()>=r)););return rI.resolve(a)}we(e,t,n){let r=this.overlays.get(n.key);if(null!==r){let e=this.ls.get(r.largestBatchId).delete(n.key);this.ls.set(r.largestBatchId,e)}this.overlays=this.overlays.insert(n.key,new sd(t,n));let i=this.ls.get(t);void 0===i&&(i=iK(),this.ls.set(t,i)),this.ls.set(t,i.add(n.key))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ae{constructor(){this.fs=new rD(at.ds),this.ws=new rD(at._s)}isEmpty(){return this.fs.isEmpty()}addReference(e,t){let n=new at(e,t);this.fs=this.fs.add(n),this.ws=this.ws.add(n)}gs(e,t){e.forEach(e=>this.addReference(e,t))}removeReference(e,t){this.ys(new at(e,t))}ps(e,t){e.forEach(e=>this.removeReference(e,t))}Is(e){let t=new rv(new rg([])),n=new at(t,e),r=new at(t,e+1),i=[];return this.ws.forEachInRange([n,r],e=>{this.ys(e),i.push(e.key)}),i}Ts(){this.fs.forEach(e=>this.ys(e))}ys(e){this.fs=this.fs.delete(e),this.ws=this.ws.delete(e)}Es(e){let t=new rv(new rg([])),n=new at(t,e),r=new at(t,e+1),i=iK();return this.ws.forEachInRange([n,r],e=>{i=i.add(e.key)}),i}containsKey(e){let t=new at(e,0),n=this.fs.firstAfterOrEqual(t);return null!==n&&e.isEqual(n.key)}}class at{constructor(e,t){this.key=e,this.As=t}static ds(e,t){return rv.comparator(e.key,t.key)||rc(e.As,t.As)}static _s(e,t){return rc(e.As,t.As)||rv.comparator(e.key,t.key)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class an{constructor(e,t){this.indexManager=e,this.referenceDelegate=t,this.mutationQueue=[],this.vs=1,this.Rs=new rD(at.ds)}checkEmpty(e){return rI.resolve(0===this.mutationQueue.length)}addMutationBatch(e,t,n,r){let i=this.vs;this.vs++,this.mutationQueue.length>0&&this.mutationQueue[this.mutationQueue.length-1];let s=new sc(i,t,n,r);for(let t of(this.mutationQueue.push(s),r))this.Rs=this.Rs.add(new at(t.key,i)),this.indexManager.addToCollectionParentIndex(e,t.key.path.popLast());return rI.resolve(s)}lookupMutationBatch(e,t){return rI.resolve(this.Ps(t))}getNextMutationBatchAfterBatchId(e,t){let n=this.bs(t+1),r=n<0?0:n;return rI.resolve(this.mutationQueue.length>r?this.mutationQueue[r]:null)}getHighestUnacknowledgedBatchId(){return rI.resolve(0===this.mutationQueue.length?-1:this.vs-1)}getAllMutationBatches(e){return rI.resolve(this.mutationQueue.slice())}getAllMutationBatchesAffectingDocumentKey(e,t){let n=new at(t,0),r=new at(t,Number.POSITIVE_INFINITY),i=[];return this.Rs.forEachInRange([n,r],e=>{let t=this.Ps(e.As);i.push(t)}),rI.resolve(i)}getAllMutationBatchesAffectingDocumentKeys(e,t){let n=new rD(rc);return t.forEach(e=>{let t=new at(e,0),r=new at(e,Number.POSITIVE_INFINITY);this.Rs.forEachInRange([t,r],e=>{n=n.add(e.As)})}),rI.resolve(this.Vs(n))}getAllMutationBatchesAffectingQuery(e,t){let n=t.path,r=n.length+1,i=n;rv.isDocumentKey(i)||(i=i.child(""));let s=new at(new rv(i),0),a=new rD(rc);return this.Rs.forEachWhile(e=>{let t=e.key.path;return!!n.isPrefixOf(t)&&(t.length===r&&(a=a.add(e.As)),!0)},s),rI.resolve(this.Vs(a))}Vs(e){let t=[];return e.forEach(e=>{let n=this.Ps(e);null!==n&&t.push(n)}),t}removeMutationBatch(e,t){0===this.Ss(t.batchId,"removed")||n7(),this.mutationQueue.shift();let n=this.Rs;return rI.forEach(t.mutations,r=>{let i=new at(r.key,t.batchId);return n=n.delete(i),this.referenceDelegate.markPotentiallyOrphaned(e,r.key)}).next(()=>{this.Rs=n})}Cn(e){}containsKey(e,t){let n=new at(t,0),r=this.Rs.firstAfterOrEqual(n);return rI.resolve(t.isEqual(r&&r.key))}performConsistencyCheck(e){return this.mutationQueue.length,rI.resolve()}Ss(e,t){return this.bs(e)}bs(e){return 0===this.mutationQueue.length?0:e-this.mutationQueue[0].batchId}Ps(e){let t=this.bs(e);return t<0||t>=this.mutationQueue.length?null:this.mutationQueue[t]}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ar{constructor(e){this.Ds=e,this.docs=new rA(rv.comparator),this.size=0}setIndexManager(e){this.indexManager=e}addEntry(e,t){let n=t.key,r=this.docs.get(n),i=r?r.size:0,s=this.Ds(t);return this.docs=this.docs.insert(n,{document:t.mutableCopy(),size:s}),this.size+=s-i,this.indexManager.addToCollectionParentIndex(e,n.path.popLast())}removeEntry(e){let t=this.docs.get(e);t&&(this.docs=this.docs.remove(e),this.size-=t.size)}getEntry(e,t){let n=this.docs.get(t);return rI.resolve(n?n.document.mutableCopy():r3.newInvalidDocument(t))}getEntries(e,t){let n=iU;return t.forEach(e=>{let t=this.docs.get(e);n=n.insert(e,t?t.document.mutableCopy():r3.newInvalidDocument(e))}),rI.resolve(n)}getDocumentsMatchingQuery(e,t,n,r){let i=iU,s=t.path,a=new rv(s.child("")),o=this.docs.getIteratorFrom(a);for(;o.hasNext();){let{key:e,value:{document:a}}=o.getNext();if(!s.isPrefixOf(e.path))break;e.path.length>s.length+1||0>=function(e,t){let n=e.readTime.compareTo(t.readTime);return 0!==n?n:0!==(n=rv.comparator(e.documentKey,t.documentKey))?n:rc(e.largestBatchId,t.largestBatchId)}(new rw(a.readTime,a.key,-1),n)||(r.has(a.key)||iM(t,a))&&(i=i.insert(a.key,a.mutableCopy()))}return rI.resolve(i)}getAllFromCollectionGroup(e,t,n,r){n7()}Cs(e,t){return rI.forEach(this.docs,e=>t(e))}newChangeBuffer(e){return new ai(this)}getSize(e){return rI.resolve(this.size)}}class ai extends s6{constructor(e){super(),this.os=e}applyChanges(e){let t=[];return this.changes.forEach((n,r)=>{r.isValidDocument()?t.push(this.os.addEntry(e,r)):this.os.removeEntry(n)}),rI.waitFor(t)}getFromCache(e,t){return this.os.getEntry(e,t)}getAllFromCache(e,t){return this.os.getEntries(e,t)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class as{constructor(e){this.persistence=e,this.xs=new iV(e=>ib(e),iE),this.lastRemoteSnapshotVersion=rf.min(),this.highestTargetId=0,this.Ns=0,this.ks=new ae,this.targetCount=0,this.Ms=s9.kn()}forEachTarget(e,t){return this.xs.forEach((e,n)=>t(n)),rI.resolve()}getLastRemoteSnapshotVersion(e){return rI.resolve(this.lastRemoteSnapshotVersion)}getHighestSequenceNumber(e){return rI.resolve(this.Ns)}allocateTargetId(e){return this.highestTargetId=this.Ms.next(),rI.resolve(this.highestTargetId)}setTargetsMetadata(e,t,n){return n&&(this.lastRemoteSnapshotVersion=n),t>this.Ns&&(this.Ns=t),rI.resolve()}Fn(e){this.xs.set(e.target,e);let t=e.targetId;t>this.highestTargetId&&(this.Ms=new s9(t),this.highestTargetId=t),e.sequenceNumber>this.Ns&&(this.Ns=e.sequenceNumber)}addTargetData(e,t){return this.Fn(t),this.targetCount+=1,rI.resolve()}updateTargetData(e,t){return this.Fn(t),rI.resolve()}removeTargetData(e,t){return this.xs.delete(t.target),this.ks.Is(t.targetId),this.targetCount-=1,rI.resolve()}removeTargets(e,t,n){let r=0,i=[];return this.xs.forEach((s,a)=>{a.sequenceNumber<=t&&null===n.get(a.targetId)&&(this.xs.delete(s),i.push(this.removeMatchingKeysForTargetId(e,a.targetId)),r++)}),rI.waitFor(i).next(()=>r)}getTargetCount(e){return rI.resolve(this.targetCount)}getTargetData(e,t){let n=this.xs.get(t)||null;return rI.resolve(n)}addMatchingKeys(e,t,n){return this.ks.gs(t,n),rI.resolve()}removeMatchingKeys(e,t,n){this.ks.ps(t,n);let r=this.persistence.referenceDelegate,i=[];return r&&t.forEach(t=>{i.push(r.markPotentiallyOrphaned(e,t))}),rI.waitFor(i)}removeMatchingKeysForTargetId(e,t){return this.ks.Is(t),rI.resolve()}getMatchingKeysForTargetId(e,t){let n=this.ks.Es(t);return rI.resolve(n)}containsKey(e,t){return rI.resolve(this.ks.containsKey(t))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class aa{constructor(e,t){this.$s={},this.overlays={},this.Os=new rT(0),this.Fs=!1,this.Fs=!0,this.referenceDelegate=e(this),this.Bs=new as(this),this.indexManager=new s1,this.remoteDocumentCache=new ar(e=>this.referenceDelegate.Ls(e)),this.serializer=new sY(t),this.qs=new s3(this.serializer)}start(){return Promise.resolve()}shutdown(){return this.Fs=!1,Promise.resolve()}get started(){return this.Fs}setDatabaseDeletedListener(){}setNetworkEnabled(){}getIndexManager(e){return this.indexManager}getDocumentOverlayCache(e){let t=this.overlays[e.toKey()];return t||(t=new s8,this.overlays[e.toKey()]=t),t}getMutationQueue(e,t){let n=this.$s[e.toKey()];return n||(n=new an(t,this.referenceDelegate),this.$s[e.toKey()]=n),n}getTargetCache(){return this.Bs}getRemoteDocumentCache(){return this.remoteDocumentCache}getBundleCache(){return this.qs}runTransaction(e,t,n){n4("MemoryPersistence","Starting transaction:",e);let r=new ao(this.Os.next());return this.referenceDelegate.Us(),n(r).next(e=>this.referenceDelegate.Ks(r).next(()=>e)).toPromise().then(e=>(r.raiseOnCommittedEvent(),e))}Gs(e,t){return rI.or(Object.values(this.$s).map(n=>()=>n.containsKey(e,t)))}}class ao extends rb{constructor(e){super(),this.currentSequenceNumber=e}}class al{constructor(e){this.persistence=e,this.Qs=new ae,this.js=null}static zs(e){return new al(e)}get Ws(){if(this.js)return this.js;throw n7()}addReference(e,t,n){return this.Qs.addReference(n,t),this.Ws.delete(n.toString()),rI.resolve()}removeReference(e,t,n){return this.Qs.removeReference(n,t),this.Ws.add(n.toString()),rI.resolve()}markPotentiallyOrphaned(e,t){return this.Ws.add(t.toString()),rI.resolve()}removeTarget(e,t){this.Qs.Is(t.targetId).forEach(e=>this.Ws.add(e.toString()));let n=this.persistence.getTargetCache();return n.getMatchingKeysForTargetId(e,t.targetId).next(e=>{e.forEach(e=>this.Ws.add(e.toString()))}).next(()=>n.removeTargetData(e,t))}Us(){this.js=new Set}Ks(e){let t=this.persistence.getRemoteDocumentCache().newChangeBuffer();return rI.forEach(this.Ws,n=>{let r=rv.fromPath(n);return this.Hs(e,r).next(e=>{e||t.removeEntry(r,rf.min())})}).next(()=>(this.js=null,t.apply(e)))}updateLimboDocument(e,t){return this.Hs(e,t).next(e=>{e?this.Ws.delete(t.toString()):this.Ws.add(t.toString())})}Ls(e){return 0}Hs(e,t){return rI.or([()=>rI.resolve(this.Qs.containsKey(t)),()=>this.persistence.getTargetCache().containsKey(e,t),()=>this.persistence.Gs(e,t)])}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class au{constructor(e,t,n,r){this.targetId=e,this.fromCache=t,this.Fi=n,this.Bi=r}static Li(e,t){let n=iK(),r=iK();for(let e of t.docChanges)switch(e.type){case 0:n=n.add(e.doc.key);break;case 1:r=r.add(e.doc.key)}return new au(e,t.fromCache,n,r)}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ac{constructor(){this.qi=!1}initialize(e,t){this.Ui=e,this.indexManager=t,this.qi=!0}getDocumentsMatchingQuery(e,t,n,r){return this.Ki(e,t).next(i=>i||this.Gi(e,t,r,n)).next(n=>n||this.Qi(e,t))}Ki(e,t){if(ik(t))return rI.resolve(null);let n=iN(t);return this.indexManager.getIndexType(e,n).next(r=>0===r?null:(null!==t.limit&&1===r&&(n=iN(t=iD(t,null,"F"))),this.indexManager.getDocumentsMatchingTarget(e,n).next(r=>{let i=iK(...r);return this.Ui.getDocuments(e,i).next(r=>this.indexManager.getMinOffset(e,n).next(n=>{let s=this.ji(t,r);return this.zi(t,s,i,n.readTime)?this.Ki(e,iD(t,null,"F")):this.Wi(e,s,t,n)}))})))}Gi(e,t,n,r){return ik(t)||r.isEqual(rf.min())?this.Qi(e,t):this.Ui.getDocuments(e,n).next(i=>{let s=this.ji(t,i);return this.zi(t,s,n,r)?this.Qi(e,t):(n2()<=d.in.DEBUG&&n4("QueryEngine","Re-using previous result from %s to execute query: %s",r.toString(),iL(t)),this.Wi(e,s,t,function(e,t){let n=e.toTimestamp().seconds,r=e.toTimestamp().nanoseconds+1,i=rf.fromTimestamp(1e9===r?new rd(n+1,0):new rd(n,r));return new rw(i,rv.empty(),-1)}(r,0)))})}ji(e,t){let n=new rD(iF(e));return t.forEach((t,r)=>{iM(e,r)&&(n=n.add(r))}),n}zi(e,t,n,r){if(null===e.limit)return!1;if(n.size!==t.size)return!0;let i="F"===e.limitType?t.last():t.first();return!!i&&(i.hasPendingWrites||i.version.compareTo(r)>0)}Qi(e,t){return n2()<=d.in.DEBUG&&n4("QueryEngine","Using full collection scan to execute query:",iL(t)),this.Ui.getDocumentsMatchingQuery(e,t,rw.min())}Wi(e,t,n,r){return this.Ui.getDocumentsMatchingQuery(e,n,r).next(e=>(t.forEach(t=>{e=e.insert(t.key,t)}),e))}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ah{constructor(e,t,n,r){this.persistence=e,this.Hi=t,this.serializer=r,this.Ji=new rA(rc),this.Yi=new iV(e=>ib(e),iE),this.Xi=new Map,this.Zi=e.getRemoteDocumentCache(),this.Bs=e.getTargetCache(),this.qs=e.getBundleCache(),this.tr(n)}tr(e){this.documentOverlayCache=this.persistence.getDocumentOverlayCache(e),this.indexManager=this.persistence.getIndexManager(e),this.mutationQueue=this.persistence.getMutationQueue(e,this.indexManager),this.localDocuments=new s7(this.Zi,this.mutationQueue,this.documentOverlayCache,this.indexManager),this.Zi.setIndexManager(this.indexManager),this.Hi.initialize(this.localDocuments,this.indexManager)}collectGarbage(e){return this.persistence.runTransaction("Collect garbage","readwrite-primary",t=>e.collect(t,this.Ji))}}async function ad(e,t){return await e.persistence.runTransaction("Handle user change","readonly",n=>{let r;return e.mutationQueue.getAllMutationBatches(n).next(i=>(r=i,e.tr(t),e.mutationQueue.getAllMutationBatches(n))).next(t=>{let i=[],s=[],a=iK();for(let e of r)for(let t of(i.push(e.batchId),e.mutations))a=a.add(t.key);for(let e of t)for(let t of(s.push(e.batchId),e.mutations))a=a.add(t.key);return e.localDocuments.getDocuments(n,a).next(e=>({er:e,removedBatchIds:i,addedBatchIds:s}))})})}function af(e){return e.persistence.runTransaction("Get last remote snapshot version","readonly",t=>e.Bs.getLastRemoteSnapshotVersion(t))}async function ap(e,t,n){let r=e.Ji.get(t);try{n||await e.persistence.runTransaction("Release target",n?"readwrite":"readwrite-primary",t=>e.persistence.referenceDelegate.removeTarget(t,r))}catch(e){if(!r_(e))throw e;n4("LocalStore",`Failed to update sequence numbers for target ${t}: ${e}`)}e.Ji=e.Ji.remove(t),e.Yi.delete(r.target)}function ag(e,t,n){let r=rf.min(),i=iK();return e.persistence.runTransaction("Execute query","readonly",s=>(function(e,t,n){let r=e.Yi.get(n);return void 0!==r?rI.resolve(e.Ji.get(r)):e.Bs.getTargetData(t,n)})(e,s,iN(t)).next(t=>{if(t)return r=t.lastLimboFreeSnapshotVersion,e.Bs.getMatchingKeysForTargetId(s,t.targetId).next(e=>{i=e})}).next(()=>e.Hi.getDocumentsMatchingQuery(s,t,n?r:rf.min(),n?i:iK())).next(n=>{var r;let s;return r=t.collectionGroup||(t.path.length%2==1?t.path.lastSegment():t.path.get(t.path.length-2)),s=e.Xi.get(r)||rf.min(),n.forEach((e,t)=>{t.readTime.compareTo(s)>0&&(s=t.readTime)}),e.Xi.set(r,s),{documents:n,ir:i}}))}class am{constructor(){this.activeTargetIds=iG}lr(e){this.activeTargetIds=this.activeTargetIds.add(e)}dr(e){this.activeTargetIds=this.activeTargetIds.delete(e)}hr(){let e={activeTargetIds:this.activeTargetIds.toArray(),updateTimeMs:Date.now()};return JSON.stringify(e)}}class ay{constructor(){this.Hr=new am,this.Jr={},this.onlineStateHandler=null,this.sequenceNumberHandler=null}addPendingMutation(e){}updateMutationState(e,t,n){}addLocalQueryTarget(e){return this.Hr.lr(e),this.Jr[e]||"not-current"}updateQueryState(e,t,n){this.Jr[e]=t}removeLocalQueryTarget(e){this.Hr.dr(e)}isLocalQueryTarget(e){return this.Hr.activeTargetIds.has(e)}clearQueryState(e){delete this.Jr[e]}getAllActiveQueryTargets(){return this.Hr.activeTargetIds}isActiveQueryTarget(e){return this.Hr.activeTargetIds.has(e)}start(){return this.Hr=new am,Promise.resolve()}handleUserChange(e,t,n){}setOnlineState(e){}shutdown(){}writeSequenceNumber(e){}notifyBundleLoaded(e){}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class av{Yr(e){}shutdown(){}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class aw{constructor(){this.Xr=()=>this.Zr(),this.eo=()=>this.no(),this.so=[],this.io()}Yr(e){this.so.push(e)}shutdown(){window.removeEventListener("online",this.Xr),window.removeEventListener("offline",this.eo)}io(){window.addEventListener("online",this.Xr),window.addEventListener("offline",this.eo)}Zr(){for(let e of(n4("ConnectivityMonitor","Network connectivity changed: AVAILABLE"),this.so))e(0)}no(){for(let e of(n4("ConnectivityMonitor","Network connectivity changed: UNAVAILABLE"),this.so))e(1)}static D(){return"undefined"!=typeof window&&void 0!==window.addEventListener&&void 0!==window.removeEventListener}}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let ab=null;function aE(){return null===ab?ab=268435456+Math.round(2147483648*Math.random()):ab++,"0x"+ab.toString(16)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let aI={BatchGetDocuments:"batchGet",Commit:"commit",RunQuery:"runQuery",RunAggregationQuery:"runAggregationQuery"};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class a_{constructor(e){this.ro=e.ro,this.oo=e.oo}uo(e){this.co=e}ao(e){this.ho=e}onMessage(e){this.lo=e}close(){this.oo()}send(e){this.ro(e)}fo(){this.co()}wo(e){this.ho(e)}_o(e){this.lo(e)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let aT="WebChannelConnection";class ak extends class{constructor(e){this.databaseInfo=e,this.databaseId=e.databaseId;let t=e.ssl?"https":"http";this.mo=t+"://"+e.host,this.yo="projects/"+this.databaseId.projectId+"/databases/"+this.databaseId.database+"/documents"}get po(){return!1}Io(e,t,n,r,i){let s=aE(),a=this.To(e,t);n4("RestConnection",`Sending RPC '${e}' ${s}:`,a,n);let o={};return this.Eo(o,r,i),this.Ao(e,a,o,n).then(t=>(n4("RestConnection",`Received RPC '${e}' ${s}: `,t),t),t=>{throw n6("RestConnection",`RPC '${e}' ${s} failed with error: `,t,"url: ",a,"request:",n),t})}vo(e,t,n,r,i,s){return this.Io(e,t,n,r,i)}Eo(e,t,n){e["X-Goog-Api-Client"]="gl-js/ fire/"+n0,e["Content-Type"]="text/plain",this.databaseInfo.appId&&(e["X-Firebase-GMPID"]=this.databaseInfo.appId),t&&t.headers.forEach((t,n)=>e[n]=t),n&&n.headers.forEach((t,n)=>e[n]=t)}To(e,t){let n=aI[e];return`${this.mo}/v1/${t}:${n}`}}{constructor(e){super(e),this.forceLongPolling=e.forceLongPolling,this.autoDetectLongPolling=e.autoDetectLongPolling,this.useFetchStreams=e.useFetchStreams,this.longPollingOptions=e.longPollingOptions}Ao(e,t,n,r){let i=aE();return new Promise((s,a)=>{let o=new nQ;o.setWithCredentials(!0),o.listenOnce(n$.COMPLETE,()=>{try{switch(o.getLastErrorCode()){case nz.NO_ERROR:let t=o.getResponseJson();n4(aT,`XHR for RPC '${e}' ${i} received:`,JSON.stringify(t)),s(t);break;case nz.TIMEOUT:n4(aT,`RPC '${e}' ${i} timed out`),a(new n8(n3.DEADLINE_EXCEEDED,"Request time out"));break;case nz.HTTP_ERROR:let n=o.getStatus();if(n4(aT,`RPC '${e}' ${i} failed with status:`,n,"response text:",o.getResponseText()),n>0){let e=o.getResponseJson();Array.isArray(e)&&(e=e[0]);let t=null==e?void 0:e.error;if(t&&t.status&&t.message){let e=function(e){let t=e.toLowerCase().replace(/_/g,"-");return Object.values(n3).indexOf(t)>=0?t:n3.UNKNOWN}(t.status);a(new n8(e,t.message))}else a(new n8(n3.UNKNOWN,"Server responded with status "+o.getStatus()))}else a(new n8(n3.UNAVAILABLE,"Connection failed."));break;default:n7()}}finally{n4(aT,`RPC '${e}' ${i} completed.`)}});let l=JSON.stringify(r);n4(aT,`RPC '${e}' ${i} sending request:`,r),o.send(t,"POST",l,n,15)})}Ro(e,t,n){let r=aE(),i=[this.mo,"/","google.firestore.v1.Firestore","/",e,"/channel"],s=nB(),a=nq(),l={httpSessionIdParam:"gsessionid",initMessageHeaders:{},messageUrlParams:{database:`projects/${this.databaseId.projectId}/databases/${this.databaseId.database}`},sendRawJson:!0,supportsCrossDomainXhr:!0,internalChannelParams:{forwardChannelRequestTimeoutMs:6e5},forceLongPolling:this.forceLongPolling,detectBufferingProxy:this.autoDetectLongPolling},u=this.longPollingOptions.timeoutSeconds;void 0!==u&&(l.longPollingTimeout=Math.round(1e3*u)),this.useFetchStreams&&(l.xmlHttpFactory=new nG({})),this.Eo(l.initMessageHeaders,t,n),l.encodeInitMessageHeaders=!0;let c=i.join("");n4(aT,`Creating RPC '${e}' stream ${r}: ${c}`,l);let h=s.createWebChannel(c,l),d=!1,f=!1,p=new a_({ro:t=>{f?n4(aT,`Not sending because RPC '${e}' stream ${r} is closed:`,t):(d||(n4(aT,`Opening RPC '${e}' stream ${r} transport.`),h.open(),d=!0),n4(aT,`RPC '${e}' stream ${r} sending:`,t),h.send(t))},oo:()=>h.close()}),g=(e,t,n)=>{e.listen(t,e=>{try{n(e)}catch(e){setTimeout(()=>{throw e},0)}})};return g(h,nW.EventType.OPEN,()=>{f||n4(aT,`RPC '${e}' stream ${r} transport opened.`)}),g(h,nW.EventType.CLOSE,()=>{f||(f=!0,n4(aT,`RPC '${e}' stream ${r} transport closed`),p.wo())}),g(h,nW.EventType.ERROR,t=>{f||(f=!0,n6(aT,`RPC '${e}' stream ${r} transport errored:`,t),p.wo(new n8(n3.UNAVAILABLE,"The operation could not be completed")))}),g(h,nW.EventType.MESSAGE,t=>{var n;if(!f){let i=t.data[0];i||n7();let s=i.error||(null===(n=i[0])||void 0===n?void 0:n.error);if(s){n4(aT,`RPC '${e}' stream ${r} received error:`,s);let t=s.status,n=function(e){let t=o[e];if(void 0!==t)return sg(t)}(t),i=s.message;void 0===n&&(n=n3.INTERNAL,i="Unknown error status: "+t+" with message "+s.message),f=!0,p.wo(new n8(n,i)),h.close()}else n4(aT,`RPC '${e}' stream ${r} received:`,i),p._o(i)}}),g(a,nH.STAT_EVENT,t=>{t.stat===nK.PROXY?n4(aT,`RPC '${e}' stream ${r} detected buffering proxy`):t.stat===nK.NOPROXY&&n4(aT,`RPC '${e}' stream ${r} detected no buffering proxy`)}),setTimeout(()=>{p.fo()},0),p}}function aS(){return"undefined"!=typeof document?document:null}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function ax(e){return new sL(e,!0)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class aC{constructor(e,t,n=1e3,r=1.5,i=6e4){this.ii=e,this.timerId=t,this.Po=n,this.bo=r,this.Vo=i,this.So=0,this.Do=null,this.Co=Date.now(),this.reset()}reset(){this.So=0}xo(){this.So=this.Vo}No(e){this.cancel();let t=Math.floor(this.So+this.ko()),n=Math.max(0,Date.now()-this.Co),r=Math.max(0,t-n);r>0&&n4("ExponentialBackoff",`Backing off for ${r} ms (base delay: ${this.So} ms, delay with jitter: ${t} ms, last attempt: ${n} ms ago)`),this.Do=this.ii.enqueueAfterDelay(this.timerId,r,()=>(this.Co=Date.now(),e())),this.So*=this.bo,this.So<this.Po&&(this.So=this.Po),this.So>this.Vo&&(this.So=this.Vo)}Mo(){null!==this.Do&&(this.Do.skipDelay(),this.Do=null)}cancel(){null!==this.Do&&(this.Do.cancel(),this.Do=null)}ko(){return(Math.random()-.5)*this.So}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class aA{constructor(e,t,n,r,i,s,a,o){this.ii=e,this.$o=n,this.Oo=r,this.connection=i,this.authCredentialsProvider=s,this.appCheckCredentialsProvider=a,this.listener=o,this.state=0,this.Fo=0,this.Bo=null,this.Lo=null,this.stream=null,this.qo=new aC(e,t)}Uo(){return 1===this.state||5===this.state||this.Ko()}Ko(){return 2===this.state||3===this.state}start(){4!==this.state?this.auth():this.Go()}async stop(){this.Uo()&&await this.close(0)}Qo(){this.state=0,this.qo.reset()}jo(){this.Ko()&&null===this.Bo&&(this.Bo=this.ii.enqueueAfterDelay(this.$o,6e4,()=>this.zo()))}Wo(e){this.Ho(),this.stream.send(e)}async zo(){if(this.Ko())return this.close(0)}Ho(){this.Bo&&(this.Bo.cancel(),this.Bo=null)}Jo(){this.Lo&&(this.Lo.cancel(),this.Lo=null)}async close(e,t){this.Ho(),this.Jo(),this.qo.cancel(),this.Fo++,4!==e?this.qo.reset():t&&t.code===n3.RESOURCE_EXHAUSTED?(n9(t.toString()),n9("Using maximum backoff delay to prevent overloading the backend."),this.qo.xo()):t&&t.code===n3.UNAUTHENTICATED&&3!==this.state&&(this.authCredentialsProvider.invalidateToken(),this.appCheckCredentialsProvider.invalidateToken()),null!==this.stream&&(this.Yo(),this.stream.close(),this.stream=null),this.state=e,await this.listener.ao(t)}Yo(){}auth(){this.state=1;let e=this.Xo(this.Fo),t=this.Fo;Promise.all([this.authCredentialsProvider.getToken(),this.appCheckCredentialsProvider.getToken()]).then(([e,n])=>{this.Fo===t&&this.Zo(e,n)},t=>{e(()=>{let e=new n8(n3.UNKNOWN,"Fetching auth token failed: "+t.message);return this.tu(e)})})}Zo(e,t){let n=this.Xo(this.Fo);this.stream=this.eu(e,t),this.stream.uo(()=>{n(()=>(this.state=2,this.Lo=this.ii.enqueueAfterDelay(this.Oo,1e4,()=>(this.Ko()&&(this.state=3),Promise.resolve())),this.listener.uo()))}),this.stream.ao(e=>{n(()=>this.tu(e))}),this.stream.onMessage(e=>{n(()=>this.onMessage(e))})}Go(){this.state=5,this.qo.No(async()=>{this.state=0,this.start()})}tu(e){return n4("PersistentStream",`close with error: ${e}`),this.stream=null,this.close(4,e)}Xo(e){return t=>{this.ii.enqueueAndForget(()=>this.Fo===e?t():(n4("PersistentStream","stream callback skipped by getCloseGuardedDispatcher."),Promise.resolve()))}}}class aN extends aA{constructor(e,t,n,r,i,s){super(e,"listen_stream_connection_backoff","listen_stream_idle","health_check_timeout",t,n,r,s),this.serializer=i}eu(e,t){return this.connection.Ro("Listen",e,t)}onMessage(e){this.qo.reset();let t=function(e,t){let n;if("targetChange"in t){var r,i;t.targetChange;let s="NO_CHANGE"===(r=t.targetChange.targetChangeType||"NO_CHANGE")?0:"ADD"===r?1:"REMOVE"===r?2:"CURRENT"===r?3:"RESET"===r?4:n7(),a=t.targetChange.targetIds||[],o=(i=t.targetChange.resumeToken,e.useProto3Json?(void 0===i||"string"==typeof i||n7(),rM.fromBase64String(i||"")):(void 0===i||i instanceof Uint8Array||n7(),rM.fromUint8Array(i||new Uint8Array))),l=t.targetChange.cause,u=l&&function(e){let t=void 0===e.code?n3.UNKNOWN:sg(e.code);return new n8(t,e.message||"")}(l);n=new sx(s,a,o,u||null)}else if("documentChange"in t){t.documentChange;let r=t.documentChange;r.document,r.document.name,r.document.updateTime;let i=sz(e,r.document.name),s=sU(r.document.updateTime),a=r.document.createTime?sU(r.document.createTime):rf.min(),o=new r7({mapValue:{fields:r.document.fields}}),l=r3.newFoundDocument(i,s,a,o),u=r.targetIds||[],c=r.removedTargetIds||[];n=new sk(u,c,l.key,l)}else if("documentDelete"in t){t.documentDelete;let r=t.documentDelete;r.document;let i=sz(e,r.document),s=r.readTime?sU(r.readTime):rf.min(),a=r3.newNoDocument(i,s),o=r.removedTargetIds||[];n=new sk([],o,a.key,a)}else if("documentRemove"in t){t.documentRemove;let r=t.documentRemove;r.document;let i=sz(e,r.document),s=r.removedTargetIds||[];n=new sk([],s,i,null)}else{if(!("filter"in t))return n7();{t.filter;let e=t.filter;e.targetId;let{count:r=0,unchangedNames:i}=e,s=new sp(r,i),a=e.targetId;n=new sS(a,s)}}return n}(this.serializer,e),n=function(e){if(!("targetChange"in e))return rf.min();let t=e.targetChange;return t.targetIds&&t.targetIds.length?rf.min():t.readTime?sU(t.readTime):rf.min()}(e);return this.listener.nu(t,n)}su(e){let t={};t.database=sH(this.serializer),t.addTarget=function(e,t){let n;let r=t.target;if((n=iI(r)?{documents:{documents:[s$(e,r.path)]}}:{query:sW(e,r)}).targetId=t.targetId,t.resumeToken.approximateByteSize()>0){n.resumeToken=sV(e,t.resumeToken);let r=sM(e,t.expectedCount);null!==r&&(n.expectedCount=r)}else if(t.snapshotVersion.compareTo(rf.min())>0){n.readTime=sF(e,t.snapshotVersion.toTimestamp());let r=sM(e,t.expectedCount);null!==r&&(n.expectedCount=r)}return n}(this.serializer,e);let n=function(e,t){let n=function(e){switch(e){case"TargetPurposeListen":return null;case"TargetPurposeExistenceFilterMismatch":return"existence-filter-mismatch";case"TargetPurposeExistenceFilterMismatchBloom":return"existence-filter-mismatch-bloom";case"TargetPurposeLimboResolution":return"limbo-document";default:return n7()}}(t.purpose);return null==n?null:{"goog-listen-tags":n}}(this.serializer,e);n&&(t.labels=n),this.Wo(t)}iu(e){let t={};t.database=sH(this.serializer),t.removeTarget=e,this.Wo(t)}}class aR extends aA{constructor(e,t,n,r,i,s){super(e,"write_stream_connection_backoff","write_stream_idle","health_check_timeout",t,n,r,s),this.serializer=i,this.ru=!1}get ou(){return this.ru}start(){this.ru=!1,this.lastStreamToken=void 0,super.start()}Yo(){this.ru&&this.uu([])}eu(e,t){return this.connection.Ro("Write",e,t)}onMessage(e){var t,n;if(e.streamToken||n7(),this.lastStreamToken=e.streamToken,this.ru){this.qo.reset();let r=(t=e.writeResults,n=e.commitTime,t&&t.length>0?(void 0!==n||n7(),t.map(e=>{let t;return(t=e.updateTime?sU(e.updateTime):sU(n)).isEqual(rf.min())&&(t=sU(n)),new i5(t,e.transformResults||[])})):[]),i=sU(e.commitTime);return this.listener.cu(i,r)}return e.writeResults&&0!==e.writeResults.length&&n7(),this.ru=!0,this.listener.au()}hu(){let e={};e.database=sH(this.serializer),this.Wo(e)}uu(e){let t={streamToken:this.lastStreamToken,writes:e.map(e=>(function(e,t){var n;let r;if(t instanceof sr)r={update:sG(e,t.key,t.value)};else if(t instanceof sl)r={delete:sq(e,t.key)};else if(t instanceof si)r={update:sG(e,t.key,t.data),updateMask:function(e){let t=[];return e.fields.forEach(e=>t.push(e.canonicalString())),{fieldPaths:t}}(t.fieldMask)};else{if(!(t instanceof su))return n7();r={verify:sq(e,t.key)}}return t.fieldTransforms.length>0&&(r.updateTransforms=t.fieldTransforms.map(e=>(function(e,t){let n=t.transform;if(n instanceof iX)return{fieldPath:t.field.canonicalString(),setToServerValue:"REQUEST_TIME"};if(n instanceof iY)return{fieldPath:t.field.canonicalString(),appendMissingElements:{values:n.elements}};if(n instanceof i1)return{fieldPath:t.field.canonicalString(),removeAllFromArray:{values:n.elements}};if(n instanceof i4)return{fieldPath:t.field.canonicalString(),increment:n.gt};throw n7()})(0,e))),t.precondition.isNone||(r.currentDocument=void 0!==(n=t.precondition).updateTime?{updateTime:sF(e,n.updateTime.toTimestamp())}:void 0!==n.exists?{exists:n.exists}:n7()),r})(this.serializer,e))};this.Wo(t)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class aD extends class{}{constructor(e,t,n,r){super(),this.authCredentials=e,this.appCheckCredentials=t,this.connection=n,this.serializer=r,this.lu=!1}fu(){if(this.lu)throw new n8(n3.FAILED_PRECONDITION,"The client has already been terminated.")}Io(e,t,n){return this.fu(),Promise.all([this.authCredentials.getToken(),this.appCheckCredentials.getToken()]).then(([r,i])=>this.connection.Io(e,t,n,r,i)).catch(e=>{throw"FirebaseError"===e.name?(e.code===n3.UNAUTHENTICATED&&(this.authCredentials.invalidateToken(),this.appCheckCredentials.invalidateToken()),e):new n8(n3.UNKNOWN,e.toString())})}vo(e,t,n,r){return this.fu(),Promise.all([this.authCredentials.getToken(),this.appCheckCredentials.getToken()]).then(([i,s])=>this.connection.vo(e,t,n,i,s,r)).catch(e=>{throw"FirebaseError"===e.name?(e.code===n3.UNAUTHENTICATED&&(this.authCredentials.invalidateToken(),this.appCheckCredentials.invalidateToken()),e):new n8(n3.UNKNOWN,e.toString())})}terminate(){this.lu=!0}}async function aO(e,t,n){var r;let{request:i,du:s}=function(e,t,n){let r=sW(e,t),i={},s=[],a=0;return n.forEach(e=>{let t="aggregate_"+a++;i[t]=e.alias,"count"===e.yt?s.push({alias:t,count:{}}):"avg"===e.yt?s.push({alias:t,avg:{field:sQ(e.fieldPath)}}):"sum"===e.yt&&s.push({alias:t,sum:{field:sQ(e.fieldPath)}})}),{request:{structuredAggregationQuery:{aggregations:s,structuredQuery:r.structuredQuery},parent:r.parent},du:i}}(e.serializer,iN(t),n),a=i.parent;e.connection.po||delete i.parent;let o=(await e.vo("RunAggregationQuery",a,i,1)).filter(e=>!!e.result);1===o.length||n7();let l=null===(r=o[0].result)||void 0===r?void 0:r.aggregateFields;return Object.keys(l).reduce((e,t)=>(e[s[t]]=l[t],e),{})}class aP{constructor(e,t){this.asyncQueue=e,this.onlineStateHandler=t,this.state="Unknown",this.wu=0,this._u=null,this.mu=!0}gu(){0===this.wu&&(this.yu("Unknown"),this._u=this.asyncQueue.enqueueAfterDelay("online_state_timeout",1e4,()=>(this._u=null,this.pu("Backend didn't respond within 10 seconds."),this.yu("Offline"),Promise.resolve())))}Iu(e){"Online"===this.state?this.yu("Unknown"):(this.wu++,this.wu>=1&&(this.Tu(),this.pu(`Connection failed 1 times. Most recent error: ${e.toString()}`),this.yu("Offline")))}set(e){this.Tu(),this.wu=0,"Online"===e&&(this.mu=!1),this.yu(e)}yu(e){e!==this.state&&(this.state=e,this.onlineStateHandler(e))}pu(e){let t=`Could not reach Cloud Firestore backend. ${e}
This typically indicates that your device does not have a healthy Internet connection at the moment. The client will operate in offline mode until it is able to successfully connect to the backend.`;this.mu?(n9(t),this.mu=!1):n4("OnlineStateTracker",t)}Tu(){null!==this._u&&(this._u.cancel(),this._u=null)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class aL{constructor(e,t,n,r,i){this.localStore=e,this.datastore=t,this.asyncQueue=n,this.remoteSyncer={},this.Eu=[],this.Au=new Map,this.vu=new Set,this.Ru=[],this.Pu=i,this.Pu.Yr(e=>{n.enqueueAndForget(async()=>{a$(this)&&(n4("RemoteStore","Restarting streams for network reachability change."),await async function(e){e.vu.add(4),await aF(e),e.bu.set("Unknown"),e.vu.delete(4),await aM(e)}(this))})}),this.bu=new aP(n,r)}}async function aM(e){if(a$(e))for(let t of e.Ru)await t(!0)}async function aF(e){for(let t of e.Ru)await t(!1)}function aV(e,t){e.Au.has(t.targetId)||(e.Au.set(t.targetId,t),az(e)?aq(e):a6(e).Ko()&&aj(e,t))}function aU(e,t){let n=a6(e);e.Au.delete(t),n.Ko()&&aB(e,t),0===e.Au.size&&(n.Ko()?n.jo():a$(e)&&e.bu.set("Unknown"))}function aj(e,t){if(e.Vu.qt(t.targetId),t.resumeToken.approximateByteSize()>0||t.snapshotVersion.compareTo(rf.min())>0){let n=e.remoteSyncer.getRemoteKeysForTarget(t.targetId).size;t=t.withExpectedCount(n)}a6(e).su(t)}function aB(e,t){e.Vu.qt(t),a6(e).iu(t)}function aq(e){e.Vu=new sA({getRemoteKeysForTarget:t=>e.remoteSyncer.getRemoteKeysForTarget(t),le:t=>e.Au.get(t)||null,ue:()=>e.datastore.serializer.databaseId}),a6(e).start(),e.bu.gu()}function az(e){return a$(e)&&!a6(e).Uo()&&e.Au.size>0}function a$(e){return 0===e.vu.size}async function aH(e){e.Au.forEach((t,n)=>{aj(e,t)})}async function aK(e,t){e.Vu=void 0,az(e)?(e.bu.Iu(t),aq(e)):e.bu.set("Unknown")}async function aG(e,t,n){if(e.bu.set("Online"),t instanceof sx&&2===t.state&&t.cause)try{await async function(e,t){let n=t.cause;for(let r of t.targetIds)e.Au.has(r)&&(await e.remoteSyncer.rejectListen(r,n),e.Au.delete(r),e.Vu.removeTarget(r))}(e,t)}catch(n){n4("RemoteStore","Failed to remove targets %s: %s ",t.targetIds.join(","),n),await aW(e,n)}else if(t instanceof sk?e.Vu.Ht(t):t instanceof sS?e.Vu.ne(t):e.Vu.Xt(t),!n.isEqual(rf.min()))try{let t=await af(e.localStore);n.compareTo(t)>=0&&await function(e,t){let n=e.Vu.ce(t);return n.targetChanges.forEach((n,r)=>{if(n.resumeToken.approximateByteSize()>0){let i=e.Au.get(r);i&&e.Au.set(r,i.withResumeToken(n.resumeToken,t))}}),n.targetMismatches.forEach((t,n)=>{let r=e.Au.get(t);if(!r)return;e.Au.set(t,r.withResumeToken(rM.EMPTY_BYTE_STRING,r.snapshotVersion)),aB(e,t);let i=new sX(r.target,t,n,r.sequenceNumber);aj(e,i)}),e.remoteSyncer.applyRemoteEvent(n)}(e,n)}catch(t){n4("RemoteStore","Failed to raise snapshot:",t),await aW(e,t)}}async function aW(e,t,n){if(!r_(t))throw t;e.vu.add(1),await aF(e),e.bu.set("Offline"),n||(n=()=>af(e.localStore)),e.asyncQueue.enqueueRetryable(async()=>{n4("RemoteStore","Retrying IndexedDB access"),await n(),e.vu.delete(1),await aM(e)})}function aQ(e,t){return t().catch(n=>aW(e,n,t))}async function aZ(e){let t=a5(e),n=e.Eu.length>0?e.Eu[e.Eu.length-1].batchId:-1;for(;a$(e)&&e.Eu.length<10;)try{let r=await function(e,t){return e.persistence.runTransaction("Get next mutation batch","readonly",n=>(void 0===t&&(t=-1),e.mutationQueue.getNextMutationBatchAfterBatchId(n,t)))}(e.localStore,n);if(null===r){0===e.Eu.length&&t.jo();break}n=r.batchId,function(e,t){e.Eu.push(t);let n=a5(e);n.Ko()&&n.ou&&n.uu(t.mutations)}(e,r)}catch(t){await aW(e,t)}aJ(e)&&aX(e)}function aJ(e){return a$(e)&&!a5(e).Uo()&&e.Eu.length>0}function aX(e){a5(e).start()}async function aY(e){a5(e).hu()}async function a0(e){let t=a5(e);for(let n of e.Eu)t.uu(n.mutations)}async function a1(e,t,n){let r=e.Eu.shift(),i=sh.from(r,t,n);await aQ(e,()=>e.remoteSyncer.applySuccessfulWrite(i)),await aZ(e)}async function a2(e,t){t&&a5(e).ou&&await async function(e,t){var n;if(function(e){switch(e){default:return n7();case n3.CANCELLED:case n3.UNKNOWN:case n3.DEADLINE_EXCEEDED:case n3.RESOURCE_EXHAUSTED:case n3.INTERNAL:case n3.UNAVAILABLE:case n3.UNAUTHENTICATED:return!1;case n3.INVALID_ARGUMENT:case n3.NOT_FOUND:case n3.ALREADY_EXISTS:case n3.PERMISSION_DENIED:case n3.FAILED_PRECONDITION:case n3.ABORTED:case n3.OUT_OF_RANGE:case n3.UNIMPLEMENTED:case n3.DATA_LOSS:return!0}}(n=t.code)&&n!==n3.ABORTED){let n=e.Eu.shift();a5(e).Qo(),await aQ(e,()=>e.remoteSyncer.rejectFailedWrite(n.batchId,t)),await aZ(e)}}(e,t),aJ(e)&&aX(e)}async function a4(e,t){e.asyncQueue.verifyOperationInProgress(),n4("RemoteStore","RemoteStore received new credentials");let n=a$(e);e.vu.add(3),await aF(e),n&&e.bu.set("Unknown"),await e.remoteSyncer.handleCredentialChange(t),e.vu.delete(3),await aM(e)}async function a9(e,t){t?(e.vu.delete(2),await aM(e)):t||(e.vu.add(2),await aF(e),e.bu.set("Unknown"))}function a6(e){var t,n,r;return e.Su||(e.Su=(t=e.datastore,n=e.asyncQueue,r={uo:aH.bind(null,e),ao:aK.bind(null,e),nu:aG.bind(null,e)},t.fu(),new aN(n,t.connection,t.authCredentials,t.appCheckCredentials,t.serializer,r)),e.Ru.push(async t=>{t?(e.Su.Qo(),az(e)?aq(e):e.bu.set("Unknown")):(await e.Su.stop(),e.Vu=void 0)})),e.Su}function a5(e){var t,n,r;return e.Du||(e.Du=(t=e.datastore,n=e.asyncQueue,r={uo:aY.bind(null,e),ao:a2.bind(null,e),au:a0.bind(null,e),cu:a1.bind(null,e)},t.fu(),new aR(n,t.connection,t.authCredentials,t.appCheckCredentials,t.serializer,r)),e.Ru.push(async t=>{t?(e.Du.Qo(),await aZ(e)):(await e.Du.stop(),e.Eu.length>0&&(n4("RemoteStore",`Stopping write stream with ${e.Eu.length} pending writes`),e.Eu=[]))})),e.Du}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class a7{constructor(e,t,n,r,i){this.asyncQueue=e,this.timerId=t,this.targetTimeMs=n,this.op=r,this.removalCallback=i,this.deferred=new re,this.then=this.deferred.promise.then.bind(this.deferred.promise),this.deferred.promise.catch(e=>{})}static createAndSchedule(e,t,n,r,i){let s=Date.now()+n,a=new a7(e,t,s,r,i);return a.start(n),a}start(e){this.timerHandle=setTimeout(()=>this.handleDelayElapsed(),e)}skipDelay(){return this.handleDelayElapsed()}cancel(e){null!==this.timerHandle&&(this.clearTimeout(),this.deferred.reject(new n8(n3.CANCELLED,"Operation cancelled"+(e?": "+e:""))))}handleDelayElapsed(){this.asyncQueue.enqueueAndForget(()=>null!==this.timerHandle?(this.clearTimeout(),this.op().then(e=>this.deferred.resolve(e))):Promise.resolve())}clearTimeout(){null!==this.timerHandle&&(this.removalCallback(this),clearTimeout(this.timerHandle),this.timerHandle=null)}}function a3(e,t){if(n9("AsyncQueue",`${t}: ${e}`),r_(e))return new n8(n3.UNAVAILABLE,`${t}: ${e}`);throw e}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class a8{constructor(e){this.comparator=e?(t,n)=>e(t,n)||rv.comparator(t.key,n.key):(e,t)=>rv.comparator(e.key,t.key),this.keyedMap=iB(),this.sortedSet=new rA(this.comparator)}static emptySet(e){return new a8(e.comparator)}has(e){return null!=this.keyedMap.get(e)}get(e){return this.keyedMap.get(e)}first(){return this.sortedSet.minKey()}last(){return this.sortedSet.maxKey()}isEmpty(){return this.sortedSet.isEmpty()}indexOf(e){let t=this.keyedMap.get(e);return t?this.sortedSet.indexOf(t):-1}get size(){return this.sortedSet.size}forEach(e){this.sortedSet.inorderTraversal((t,n)=>(e(t),!1))}add(e){let t=this.delete(e.key);return t.copy(t.keyedMap.insert(e.key,e),t.sortedSet.insert(e,null))}delete(e){let t=this.get(e);return t?this.copy(this.keyedMap.remove(e),this.sortedSet.remove(t)):this}isEqual(e){if(!(e instanceof a8)||this.size!==e.size)return!1;let t=this.sortedSet.getIterator(),n=e.sortedSet.getIterator();for(;t.hasNext();){let e=t.getNext().key,r=n.getNext().key;if(!e.isEqual(r))return!1}return!0}toString(){let e=[];return this.forEach(t=>{e.push(t.toString())}),0===e.length?"DocumentSet ()":"DocumentSet (\n  "+e.join("  \n")+"\n)"}copy(e,t){let n=new a8;return n.comparator=this.comparator,n.keyedMap=e,n.sortedSet=t,n}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class oe{constructor(){this.Cu=new rA(rv.comparator)}track(e){let t=e.doc.key,n=this.Cu.get(t);n?0!==e.type&&3===n.type?this.Cu=this.Cu.insert(t,e):3===e.type&&1!==n.type?this.Cu=this.Cu.insert(t,{type:n.type,doc:e.doc}):2===e.type&&2===n.type?this.Cu=this.Cu.insert(t,{type:2,doc:e.doc}):2===e.type&&0===n.type?this.Cu=this.Cu.insert(t,{type:0,doc:e.doc}):1===e.type&&0===n.type?this.Cu=this.Cu.remove(t):1===e.type&&2===n.type?this.Cu=this.Cu.insert(t,{type:1,doc:n.doc}):0===e.type&&1===n.type?this.Cu=this.Cu.insert(t,{type:2,doc:e.doc}):n7():this.Cu=this.Cu.insert(t,e)}xu(){let e=[];return this.Cu.inorderTraversal((t,n)=>{e.push(n)}),e}}class ot{constructor(e,t,n,r,i,s,a,o,l){this.query=e,this.docs=t,this.oldDocs=n,this.docChanges=r,this.mutatedKeys=i,this.fromCache=s,this.syncStateChanged=a,this.excludesMetadataChanges=o,this.hasCachedResults=l}static fromInitialDocuments(e,t,n,r,i){let s=[];return t.forEach(e=>{s.push({type:0,doc:e})}),new ot(e,t,a8.emptySet(t),s,n,r,!0,!1,i)}get hasPendingWrites(){return!this.mutatedKeys.isEmpty()}isEqual(e){if(!(this.fromCache===e.fromCache&&this.hasCachedResults===e.hasCachedResults&&this.syncStateChanged===e.syncStateChanged&&this.mutatedKeys.isEqual(e.mutatedKeys)&&iO(this.query,e.query)&&this.docs.isEqual(e.docs)&&this.oldDocs.isEqual(e.oldDocs)))return!1;let t=this.docChanges,n=e.docChanges;if(t.length!==n.length)return!1;for(let e=0;e<t.length;e++)if(t[e].type!==n[e].type||!t[e].doc.isEqual(n[e].doc))return!1;return!0}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class on{constructor(){this.Nu=void 0,this.listeners=[]}}class or{constructor(){this.queries=new iV(e=>iP(e),iO),this.onlineState="Unknown",this.ku=new Set}}async function oi(e,t){let n=t.query,r=!1,i=e.queries.get(n);if(i||(r=!0,i=new on),r)try{i.Nu=await e.onListen(n)}catch(n){let e=a3(n,`Initialization of query '${iL(t.query)}' failed`);return void t.onError(e)}e.queries.set(n,i),i.listeners.push(t),t.Mu(e.onlineState),i.Nu&&t.$u(i.Nu)&&ol(e)}async function os(e,t){let n=t.query,r=!1,i=e.queries.get(n);if(i){let e=i.listeners.indexOf(t);e>=0&&(i.listeners.splice(e,1),r=0===i.listeners.length)}if(r)return e.queries.delete(n),e.onUnlisten(n)}function oa(e,t){let n=!1;for(let r of t){let t=r.query,i=e.queries.get(t);if(i){for(let e of i.listeners)e.$u(r)&&(n=!0);i.Nu=r}}n&&ol(e)}function oo(e,t,n){let r=e.queries.get(t);if(r)for(let e of r.listeners)e.onError(n);e.queries.delete(t)}function ol(e){e.ku.forEach(e=>{e.next()})}class ou{constructor(e,t,n){this.query=e,this.Ou=t,this.Fu=!1,this.Bu=null,this.onlineState="Unknown",this.options=n||{}}$u(e){if(!this.options.includeMetadataChanges){let t=[];for(let n of e.docChanges)3!==n.type&&t.push(n);e=new ot(e.query,e.docs,e.oldDocs,t,e.mutatedKeys,e.fromCache,e.syncStateChanged,!0,e.hasCachedResults)}let t=!1;return this.Fu?this.Lu(e)&&(this.Ou.next(e),t=!0):this.qu(e,this.onlineState)&&(this.Uu(e),t=!0),this.Bu=e,t}onError(e){this.Ou.error(e)}Mu(e){this.onlineState=e;let t=!1;return this.Bu&&!this.Fu&&this.qu(this.Bu,e)&&(this.Uu(this.Bu),t=!0),t}qu(e,t){return!e.fromCache||(!this.options.Ku||!("Offline"!==t))&&(!e.docs.isEmpty()||e.hasCachedResults||"Offline"===t)}Lu(e){if(e.docChanges.length>0)return!0;let t=this.Bu&&this.Bu.hasPendingWrites!==e.hasPendingWrites;return!(!e.syncStateChanged&&!t)&&!0===this.options.includeMetadataChanges}Uu(e){e=ot.fromInitialDocuments(e.query,e.docs,e.mutatedKeys,e.fromCache,e.hasCachedResults),this.Fu=!0,this.Ou.next(e)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class oc{constructor(e){this.key=e}}class oh{constructor(e){this.key=e}}class od{constructor(e,t){this.query=e,this.Yu=t,this.Xu=null,this.hasCachedResults=!1,this.current=!1,this.Zu=iK(),this.mutatedKeys=iK(),this.tc=iF(e),this.ec=new a8(this.tc)}get nc(){return this.Yu}sc(e,t){let n=t?t.ic:new oe,r=t?t.ec:this.ec,i=t?t.mutatedKeys:this.mutatedKeys,s=r,a=!1,o="F"===this.query.limitType&&r.size===this.query.limit?r.last():null,l="L"===this.query.limitType&&r.size===this.query.limit?r.first():null;if(e.inorderTraversal((e,t)=>{let u=r.get(e),c=iM(this.query,t)?t:null,h=!!u&&this.mutatedKeys.has(u.key),d=!!c&&(c.hasLocalMutations||this.mutatedKeys.has(c.key)&&c.hasCommittedMutations),f=!1;u&&c?u.data.isEqual(c.data)?h!==d&&(n.track({type:3,doc:c}),f=!0):this.rc(u,c)||(n.track({type:2,doc:c}),f=!0,(o&&this.tc(c,o)>0||l&&0>this.tc(c,l))&&(a=!0)):!u&&c?(n.track({type:0,doc:c}),f=!0):u&&!c&&(n.track({type:1,doc:u}),f=!0,(o||l)&&(a=!0)),f&&(c?(s=s.add(c),i=d?i.add(e):i.delete(e)):(s=s.delete(e),i=i.delete(e)))}),null!==this.query.limit)for(;s.size>this.query.limit;){let e="F"===this.query.limitType?s.last():s.first();s=s.delete(e.key),i=i.delete(e.key),n.track({type:1,doc:e})}return{ec:s,ic:n,zi:a,mutatedKeys:i}}rc(e,t){return e.hasLocalMutations&&t.hasCommittedMutations&&!t.hasLocalMutations}applyChanges(e,t,n){let r=this.ec;this.ec=e.ec,this.mutatedKeys=e.mutatedKeys;let i=e.ic.xu();i.sort((e,t)=>(function(e,t){let n=e=>{switch(e){case 0:return 1;case 2:case 3:return 2;case 1:return 0;default:return n7()}};return n(e)-n(t)})(e.type,t.type)||this.tc(e.doc,t.doc)),this.oc(n);let s=t?this.uc():[],a=0===this.Zu.size&&this.current?1:0,o=a!==this.Xu;return(this.Xu=a,0!==i.length||o)?{snapshot:new ot(this.query,e.ec,r,i,e.mutatedKeys,0===a,o,!1,!!n&&n.resumeToken.approximateByteSize()>0),cc:s}:{cc:s}}Mu(e){return this.current&&"Offline"===e?(this.current=!1,this.applyChanges({ec:this.ec,ic:new oe,mutatedKeys:this.mutatedKeys,zi:!1},!1)):{cc:[]}}ac(e){return!this.Yu.has(e)&&!!this.ec.has(e)&&!this.ec.get(e).hasLocalMutations}oc(e){e&&(e.addedDocuments.forEach(e=>this.Yu=this.Yu.add(e)),e.modifiedDocuments.forEach(e=>{}),e.removedDocuments.forEach(e=>this.Yu=this.Yu.delete(e)),this.current=e.current)}uc(){if(!this.current)return[];let e=this.Zu;this.Zu=iK(),this.ec.forEach(e=>{this.ac(e.key)&&(this.Zu=this.Zu.add(e.key))});let t=[];return e.forEach(e=>{this.Zu.has(e)||t.push(new oh(e))}),this.Zu.forEach(n=>{e.has(n)||t.push(new oc(n))}),t}hc(e){this.Yu=e.ir,this.Zu=iK();let t=this.sc(e.documents);return this.applyChanges(t,!0)}lc(){return ot.fromInitialDocuments(this.query,this.ec,this.mutatedKeys,0===this.Xu,this.hasCachedResults)}}class of{constructor(e,t,n){this.query=e,this.targetId=t,this.view=n}}class op{constructor(e){this.key=e,this.fc=!1}}class og{constructor(e,t,n,r,i,s){this.localStore=e,this.remoteStore=t,this.eventManager=n,this.sharedClientState=r,this.currentUser=i,this.maxConcurrentLimboResolutions=s,this.dc={},this.wc=new iV(e=>iP(e),iO),this._c=new Map,this.mc=new Set,this.gc=new rA(rv.comparator),this.yc=new Map,this.Ic=new ae,this.Tc={},this.Ec=new Map,this.Ac=s9.Mn(),this.onlineState="Unknown",this.vc=void 0}get isPrimaryClient(){return!0===this.vc}}async function om(e,t){var n,r;let i,s;let a=(e.remoteStore.remoteSyncer.applyRemoteEvent=ob.bind(null,e),e.remoteStore.remoteSyncer.getRemoteKeysForTarget=oO.bind(null,e),e.remoteStore.remoteSyncer.rejectListen=oI.bind(null,e),e.dc.nu=oa.bind(null,e.eventManager),e.dc.Pc=oo.bind(null,e.eventManager),e),o=a.wc.get(t);if(o)i=o.targetId,a.sharedClientState.addLocalQueryTarget(i),s=o.view.lc();else{let e=await (n=a.localStore,r=iN(t),n.persistence.runTransaction("Allocate target","readwrite",e=>{let t;return n.Bs.getTargetData(e,r).next(i=>i?(t=i,rI.resolve(t)):n.Bs.allocateTargetId(e).next(i=>(t=new sX(r,i,"TargetPurposeListen",e.currentSequenceNumber),n.Bs.addTargetData(e,t).next(()=>t))))}).then(e=>{let t=n.Ji.get(e.targetId);return(null===t||e.snapshotVersion.compareTo(t.snapshotVersion)>0)&&(n.Ji=n.Ji.insert(e.targetId,e),n.Yi.set(r,e.targetId)),e})),o=a.sharedClientState.addLocalQueryTarget(e.targetId);i=e.targetId,s=await oy(a,t,i,"current"===o,e.resumeToken),a.isPrimaryClient&&aV(a.remoteStore,e)}return s}async function oy(e,t,n,r,i){e.Rc=(t,n,r)=>(async function(e,t,n,r){let i=t.view.sc(n);i.zi&&(i=await ag(e.localStore,t.query,!1).then(({documents:e})=>t.view.sc(e,i)));let s=r&&r.targetChanges.get(t.targetId),a=t.view.applyChanges(i,e.isPrimaryClient,s);return oA(e,t.targetId,a.cc),a.snapshot})(e,t,n,r);let s=await ag(e.localStore,t,!0),a=new od(t,s.ir),o=a.sc(s.documents),l=sT.createSynthesizedTargetChangeForCurrentChange(n,r&&"Offline"!==e.onlineState,i),u=a.applyChanges(o,e.isPrimaryClient,l);oA(e,n,u.cc);let c=new of(t,n,a);return e.wc.set(t,c),e._c.has(n)?e._c.get(n).push(t):e._c.set(n,[t]),u.snapshot}async function ov(e,t){let n=e.wc.get(t),r=e._c.get(n.targetId);if(r.length>1)return e._c.set(n.targetId,r.filter(e=>!iO(e,t))),void e.wc.delete(t);e.isPrimaryClient?(e.sharedClientState.removeLocalQueryTarget(n.targetId),e.sharedClientState.isActiveQueryTarget(n.targetId)||await ap(e.localStore,n.targetId,!1).then(()=>{e.sharedClientState.clearQueryState(n.targetId),aU(e.remoteStore,n.targetId),ox(e,n.targetId)}).catch(rE)):(ox(e,n.targetId),await ap(e.localStore,n.targetId,!0))}async function ow(e,t,n){var r;let i=(e.remoteStore.remoteSyncer.applySuccessfulWrite=o_.bind(null,e),e.remoteStore.remoteSyncer.rejectFailedWrite=oT.bind(null,e),e);try{let e;let s=await function(e,t){let n,r;let i=rd.now(),s=t.reduce((e,t)=>e.add(t.key),iK());return e.persistence.runTransaction("Locally write mutations","readwrite",a=>{let o=iU,l=iK();return e.Zi.getEntries(a,s).next(e=>{(o=e).forEach((e,t)=>{t.isValidDocument()||(l=l.add(e))})}).next(()=>e.localDocuments.getOverlayedDocuments(a,o)).next(r=>{n=r;let s=[];for(let e of t){let t=function(e,t){let n=null;for(let r of e.fieldTransforms){let e=t.data.field(r.field),i=iJ(r.transform,e||null);null!=i&&(null===n&&(n=r7.empty()),n.set(r.field,i))}return n||null}(e,n.get(e.key).overlayedDocument);null!=t&&s.push(new si(e.key,t,function e(t){let n=[];return rx(t.fields,(t,r)=>{let i=new ry([t]);if(r9(r)){let t=e(r.mapValue).fields;if(0===t.length)n.push(i);else for(let e of t)n.push(i.child(e))}else n.push(i)}),new rP(n)}(t.value.mapValue),i7.exists(!0)))}return e.mutationQueue.addMutationBatch(a,i,s,t)}).next(t=>{r=t;let i=t.applyToLocalDocumentSet(n,l);return e.documentOverlayCache.saveOverlays(a,t.batchId,i)})}).then(()=>({batchId:r.batchId,changes:iq(n)}))}(i.localStore,t);i.sharedClientState.addPendingMutation(s.batchId),r=s.batchId,(e=i.Tc[i.currentUser.toKey()])||(e=new rA(rc)),e=e.insert(r,n),i.Tc[i.currentUser.toKey()]=e,await oR(i,s.changes),await aZ(i.remoteStore)}catch(t){let e=a3(t,"Failed to persist write");n.reject(e)}}async function ob(e,t){try{let n=await function(e,t){let n=t.snapshotVersion,r=e.Ji;return e.persistence.runTransaction("Apply remote event","readwrite-primary",i=>{var s;let a,o;let l=e.Zi.newChangeBuffer({trackRemovals:!0});r=e.Ji;let u=[];t.targetChanges.forEach((s,a)=>{var o;let l=r.get(a);if(!l)return;u.push(e.Bs.removeMatchingKeys(i,s.removedDocuments,a).next(()=>e.Bs.addMatchingKeys(i,s.addedDocuments,a)));let c=l.withSequenceNumber(i.currentSequenceNumber);null!==t.targetMismatches.get(a)?c=c.withResumeToken(rM.EMPTY_BYTE_STRING,rf.min()).withLastLimboFreeSnapshotVersion(rf.min()):s.resumeToken.approximateByteSize()>0&&(c=c.withResumeToken(s.resumeToken,n)),r=r.insert(a,c),o=c,(0===l.resumeToken.approximateByteSize()||o.snapshotVersion.toMicroseconds()-l.snapshotVersion.toMicroseconds()>=3e8||s.addedDocuments.size+s.modifiedDocuments.size+s.removedDocuments.size>0)&&u.push(e.Bs.updateTargetData(i,c))});let c=iU,h=iK();if(t.documentUpdates.forEach(n=>{t.resolvedLimboDocuments.has(n)&&u.push(e.persistence.referenceDelegate.updateLimboDocument(i,n))}),u.push((s=t.documentUpdates,a=iK(),o=iK(),s.forEach(e=>a=a.add(e)),l.getEntries(i,a).next(e=>{let t=iU;return s.forEach((n,r)=>{let i=e.get(n);r.isFoundDocument()!==i.isFoundDocument()&&(o=o.add(n)),r.isNoDocument()&&r.version.isEqual(rf.min())?(l.removeEntry(n,r.readTime),t=t.insert(n,r)):!i.isValidDocument()||r.version.compareTo(i.version)>0||0===r.version.compareTo(i.version)&&i.hasPendingWrites?(l.addEntry(r),t=t.insert(n,r)):n4("LocalStore","Ignoring outdated watch update for ",n,". Current version:",i.version," Watch version:",r.version)}),{nr:t,sr:o}})).next(e=>{c=e.nr,h=e.sr})),!n.isEqual(rf.min())){let t=e.Bs.getLastRemoteSnapshotVersion(i).next(t=>e.Bs.setTargetsMetadata(i,i.currentSequenceNumber,n));u.push(t)}return rI.waitFor(u).next(()=>l.apply(i)).next(()=>e.localDocuments.getLocalViewOfDocuments(i,c,h)).next(()=>c)}).then(t=>(e.Ji=r,t))}(e.localStore,t);t.targetChanges.forEach((t,n)=>{let r=e.yc.get(n);r&&(t.addedDocuments.size+t.modifiedDocuments.size+t.removedDocuments.size<=1||n7(),t.addedDocuments.size>0?r.fc=!0:t.modifiedDocuments.size>0?r.fc||n7():t.removedDocuments.size>0&&(r.fc||n7(),r.fc=!1))}),await oR(e,n,t)}catch(e){await rE(e)}}function oE(e,t,n){var r;if(e.isPrimaryClient&&0===n||!e.isPrimaryClient&&1===n){let n;let i=[];e.wc.forEach((e,n)=>{let r=n.view.Mu(t);r.snapshot&&i.push(r.snapshot)}),(r=e.eventManager).onlineState=t,n=!1,r.queries.forEach((e,r)=>{for(let e of r.listeners)e.Mu(t)&&(n=!0)}),n&&ol(r),i.length&&e.dc.nu(i),e.onlineState=t,e.isPrimaryClient&&e.sharedClientState.setOnlineState(t)}}async function oI(e,t,n){e.sharedClientState.updateQueryState(t,"rejected",n);let r=e.yc.get(t),i=r&&r.key;if(i){let n=new rA(rv.comparator);n=n.insert(i,r3.newNoDocument(i,rf.min()));let r=iK().add(i),s=new s_(rf.min(),new Map,new rA(rc),n,r);await ob(e,s),e.gc=e.gc.remove(i),e.yc.delete(t),oN(e)}else await ap(e.localStore,t,!1).then(()=>ox(e,t,n)).catch(rE)}async function o_(e,t){var n;let r=t.batch.batchId;try{let i=await (n=e.localStore).persistence.runTransaction("Acknowledge batch","readwrite-primary",e=>{let r=t.batch.keys(),i=n.Zi.newChangeBuffer({trackRemovals:!0});return(function(e,t,n,r){let i=n.batch,s=i.keys(),a=rI.resolve();return s.forEach(e=>{a=a.next(()=>r.getEntry(t,e)).next(t=>{let s=n.docVersions.get(e);null!==s||n7(),0>t.version.compareTo(s)&&(i.applyToRemoteDocument(t,n),t.isValidDocument()&&(t.setReadTime(n.commitVersion),r.addEntry(t)))})}),a.next(()=>e.mutationQueue.removeMutationBatch(t,i))})(n,e,t,i).next(()=>i.apply(e)).next(()=>n.mutationQueue.performConsistencyCheck(e)).next(()=>n.documentOverlayCache.removeOverlaysForBatchId(e,r,t.batch.batchId)).next(()=>n.localDocuments.recalculateAndSaveOverlaysForDocumentKeys(e,function(e){let t=iK();for(let n=0;n<e.mutationResults.length;++n)e.mutationResults[n].transformResults.length>0&&(t=t.add(e.batch.mutations[n].key));return t}(t))).next(()=>n.localDocuments.getDocuments(e,r))});oS(e,r,null),ok(e,r),e.sharedClientState.updateMutationState(r,"acknowledged"),await oR(e,i)}catch(e){await rE(e)}}async function oT(e,t,n){var r;try{let i=await (r=e.localStore).persistence.runTransaction("Reject batch","readwrite-primary",e=>{let n;return r.mutationQueue.lookupMutationBatch(e,t).next(t=>(null!==t||n7(),n=t.keys(),r.mutationQueue.removeMutationBatch(e,t))).next(()=>r.mutationQueue.performConsistencyCheck(e)).next(()=>r.documentOverlayCache.removeOverlaysForBatchId(e,n,t)).next(()=>r.localDocuments.recalculateAndSaveOverlaysForDocumentKeys(e,n)).next(()=>r.localDocuments.getDocuments(e,n))});oS(e,t,n),ok(e,t),e.sharedClientState.updateMutationState(t,"rejected",n),await oR(e,i)}catch(e){await rE(e)}}function ok(e,t){(e.Ec.get(t)||[]).forEach(e=>{e.resolve()}),e.Ec.delete(t)}function oS(e,t,n){let r=e.Tc[e.currentUser.toKey()];if(r){let i=r.get(t);i&&(n?i.reject(n):i.resolve(),r=r.remove(t)),e.Tc[e.currentUser.toKey()]=r}}function ox(e,t,n=null){for(let r of(e.sharedClientState.removeLocalQueryTarget(t),e._c.get(t)))e.wc.delete(r),n&&e.dc.Pc(r,n);e._c.delete(t),e.isPrimaryClient&&e.Ic.Is(t).forEach(t=>{e.Ic.containsKey(t)||oC(e,t)})}function oC(e,t){e.mc.delete(t.path.canonicalString());let n=e.gc.get(t);null!==n&&(aU(e.remoteStore,n),e.gc=e.gc.remove(t),e.yc.delete(n),oN(e))}function oA(e,t,n){for(let r of n)r instanceof oc?(e.Ic.addReference(r.key,t),function(e,t){let n=t.key,r=n.path.canonicalString();e.gc.get(n)||e.mc.has(r)||(n4("SyncEngine","New document in limbo: "+n),e.mc.add(r),oN(e))}(e,r)):r instanceof oh?(n4("SyncEngine","Document no longer in limbo: "+r.key),e.Ic.removeReference(r.key,t),e.Ic.containsKey(r.key)||oC(e,r.key)):n7()}function oN(e){for(;e.mc.size>0&&e.gc.size<e.maxConcurrentLimboResolutions;){let t=e.mc.values().next().value;e.mc.delete(t);let n=new rv(rg.fromString(t)),r=e.Ac.next();e.yc.set(r,new op(n)),e.gc=e.gc.insert(n,r),aV(e.remoteStore,new sX(iN(iT(n.path)),r,"TargetPurposeLimboResolution",rT.ct))}}async function oR(e,t,n){let r=[],i=[],s=[];e.wc.isEmpty()||(e.wc.forEach((a,o)=>{s.push(e.Rc(o,t,n).then(t=>{if((t||n)&&e.isPrimaryClient&&e.sharedClientState.updateQueryState(o.targetId,(null==t?void 0:t.fromCache)?"not-current":"current"),t){r.push(t);let e=au.Li(o.targetId,t);i.push(e)}}))}),await Promise.all(s),e.dc.nu(r),await async function(e,t){try{await e.persistence.runTransaction("notifyLocalViewChanges","readwrite",n=>rI.forEach(t,t=>rI.forEach(t.Fi,r=>e.persistence.referenceDelegate.addReference(n,t.targetId,r)).next(()=>rI.forEach(t.Bi,r=>e.persistence.referenceDelegate.removeReference(n,t.targetId,r)))))}catch(e){if(!r_(e))throw e;n4("LocalStore","Failed to update sequence numbers: "+e)}for(let n of t){let t=n.targetId;if(!n.fromCache){let n=e.Ji.get(t),r=n.snapshotVersion,i=n.withLastLimboFreeSnapshotVersion(r);e.Ji=e.Ji.insert(t,i)}}}(e.localStore,i))}async function oD(e,t){if(!e.currentUser.isEqual(t)){n4("SyncEngine","User change. New user:",t.toKey());let n=await ad(e.localStore,t);e.currentUser=t,e.Ec.forEach(e=>{e.forEach(e=>{e.reject(new n8(n3.CANCELLED,"'waitForPendingWrites' promise is rejected due to a user change."))})}),e.Ec.clear(),e.sharedClientState.handleUserChange(t,n.removedBatchIds,n.addedBatchIds),await oR(e,n.er)}}function oO(e,t){let n=e.yc.get(t);if(n&&n.fc)return iK().add(n.key);{let n=iK(),r=e._c.get(t);if(!r)return n;for(let t of r){let r=e.wc.get(t);n=n.unionWith(r.view.nc)}return n}}class oP{constructor(){this.synchronizeTabs=!1}async initialize(e){this.serializer=ax(e.databaseInfo.databaseId),this.sharedClientState=this.createSharedClientState(e),this.persistence=this.createPersistence(e),await this.persistence.start(),this.localStore=this.createLocalStore(e),this.gcScheduler=this.createGarbageCollectionScheduler(e,this.localStore),this.indexBackfillerScheduler=this.createIndexBackfillerScheduler(e,this.localStore)}createGarbageCollectionScheduler(e,t){return null}createIndexBackfillerScheduler(e,t){return null}createLocalStore(e){var t,n,r,i;return t=this.persistence,n=new ac,r=e.initialUser,i=this.serializer,new ah(t,n,r,i)}createPersistence(e){return new aa(al.zs,this.serializer)}createSharedClientState(e){return new ay}async terminate(){this.gcScheduler&&this.gcScheduler.stop(),await this.sharedClientState.shutdown(),await this.persistence.shutdown()}}class oL{async initialize(e,t){this.localStore||(this.localStore=e.localStore,this.sharedClientState=e.sharedClientState,this.datastore=this.createDatastore(t),this.remoteStore=this.createRemoteStore(t),this.eventManager=this.createEventManager(t),this.syncEngine=this.createSyncEngine(t,!e.synchronizeTabs),this.sharedClientState.onlineStateHandler=e=>oE(this.syncEngine,e,1),this.remoteStore.remoteSyncer.handleCredentialChange=oD.bind(null,this.syncEngine),await a9(this.remoteStore,this.syncEngine.isPrimaryClient))}createEventManager(e){return new or}createDatastore(e){var t,n,r;let i=ax(e.databaseInfo.databaseId),s=(t=e.databaseInfo,new ak(t));return n=e.authCredentials,r=e.appCheckCredentials,new aD(n,r,s,i)}createRemoteStore(e){var t,n,r,i;return t=this.localStore,n=this.datastore,r=e.asyncQueue,i=aw.D()?new aw:new av,new aL(t,n,r,e=>oE(this.syncEngine,e,0),i)}createSyncEngine(e,t){return function(e,t,n,r,i,s,a){let o=new og(e,t,n,r,i,s);return a&&(o.vc=!0),o}(this.localStore,this.remoteStore,this.eventManager,this.sharedClientState,e.initialUser,e.maxConcurrentLimboResolutions,t)}terminate(){return async function(e){n4("RemoteStore","RemoteStore shutting down."),e.vu.add(5),await aF(e),e.Pu.shutdown(),e.bu.set("Unknown")}(this.remoteStore)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *//**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class oM{constructor(e){this.observer=e,this.muted=!1}next(e){this.observer.next&&this.Sc(this.observer.next,e)}error(e){this.observer.error?this.Sc(this.observer.error,e):n9("Uncaught Error in snapshot listener:",e.toString())}Dc(){this.muted=!0}Sc(e,t){this.muted||setTimeout(()=>{this.muted||e(t)},0)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class oF{constructor(e,t,n,r){this.authCredentials=e,this.appCheckCredentials=t,this.asyncQueue=n,this.databaseInfo=r,this.user=nY.UNAUTHENTICATED,this.clientId=ru.A(),this.authCredentialListener=()=>Promise.resolve(),this.appCheckCredentialListener=()=>Promise.resolve(),this.authCredentials.start(n,async e=>{n4("FirestoreClient","Received user=",e.uid),await this.authCredentialListener(e),this.user=e}),this.appCheckCredentials.start(n,e=>(n4("FirestoreClient","Received new app check token=",e),this.appCheckCredentialListener(e,this.user)))}async getConfiguration(){return{asyncQueue:this.asyncQueue,databaseInfo:this.databaseInfo,clientId:this.clientId,authCredentials:this.authCredentials,appCheckCredentials:this.appCheckCredentials,initialUser:this.user,maxConcurrentLimboResolutions:100}}setCredentialChangeListener(e){this.authCredentialListener=e}setAppCheckTokenChangeListener(e){this.appCheckCredentialListener=e}verifyNotTerminated(){if(this.asyncQueue.isShuttingDown)throw new n8(n3.FAILED_PRECONDITION,"The client has already been terminated.")}terminate(){this.asyncQueue.enterRestrictedMode();let e=new re;return this.asyncQueue.enqueueAndForgetEvenWhileRestricted(async()=>{try{this._onlineComponents&&await this._onlineComponents.terminate(),this._offlineComponents&&await this._offlineComponents.terminate(),this.authCredentials.shutdown(),this.appCheckCredentials.shutdown(),e.resolve()}catch(n){let t=a3(n,"Failed to shutdown persistence");e.reject(t)}}),e.promise}}async function oV(e,t){e.asyncQueue.verifyOperationInProgress(),n4("FirestoreClient","Initializing OfflineComponentProvider");let n=await e.getConfiguration();await t.initialize(n);let r=n.initialUser;e.setCredentialChangeListener(async e=>{r.isEqual(e)||(await ad(t.localStore,e),r=e)}),t.persistence.setDatabaseDeletedListener(()=>e.terminate()),e._offlineComponents=t}async function oU(e,t){e.asyncQueue.verifyOperationInProgress();let n=await oj(e);n4("FirestoreClient","Initializing OnlineComponentProvider");let r=await e.getConfiguration();await t.initialize(n,r),e.setCredentialChangeListener(e=>a4(t.remoteStore,e)),e.setAppCheckTokenChangeListener((e,n)=>a4(t.remoteStore,n)),e._onlineComponents=t}async function oj(e){if(!e._offlineComponents){if(e._uninitializedComponentsProvider){n4("FirestoreClient","Using user provided OfflineComponentProvider");try{await oV(e,e._uninitializedComponentsProvider._offline)}catch(t){if(!("FirebaseError"===t.name?t.code===n3.FAILED_PRECONDITION||t.code===n3.UNIMPLEMENTED:!("undefined"!=typeof DOMException&&t instanceof DOMException)||22===t.code||20===t.code||11===t.code))throw t;n6("Error using user provided cache. Falling back to memory cache: "+t),await oV(e,new oP)}}else n4("FirestoreClient","Using default OfflineComponentProvider"),await oV(e,new oP)}return e._offlineComponents}async function oB(e){return e._onlineComponents||(e._uninitializedComponentsProvider?(n4("FirestoreClient","Using user provided OnlineComponentProvider"),await oU(e,e._uninitializedComponentsProvider._online)):(n4("FirestoreClient","Using default OnlineComponentProvider"),await oU(e,new oL))),e._onlineComponents}async function oq(e){let t=await oB(e),n=t.eventManager;return n.onListen=om.bind(null,t.syncEngine),n.onUnlisten=ov.bind(null,t.syncEngine),n}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function oz(e){let t={};return void 0!==e.timeoutSeconds&&(t.timeoutSeconds=e.timeoutSeconds),t}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let o$=new Map;/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function oH(e,t,n){if(!n)throw new n8(n3.INVALID_ARGUMENT,`Function ${e}() cannot be called with an empty ${t}.`)}function oK(e){if(!rv.isDocumentKey(e))throw new n8(n3.INVALID_ARGUMENT,`Invalid document reference. Document references must have an even number of segments, but ${e} has ${e.length}.`)}function oG(e){if(rv.isDocumentKey(e))throw new n8(n3.INVALID_ARGUMENT,`Invalid collection reference. Collection references must have an odd number of segments, but ${e} has ${e.length}.`)}function oW(e){if(void 0===e)return"undefined";if(null===e)return"null";if("string"==typeof e)return e.length>20&&(e=`${e.substring(0,20)}...`),JSON.stringify(e);if("number"==typeof e||"boolean"==typeof e)return""+e;if("object"==typeof e){if(e instanceof Array)return"an array";{var t;let n=(t=e).constructor?t.constructor.name:null;return n?`a custom ${n} object`:"an object"}}return"function"==typeof e?"a function":n7()}function oQ(e,t){if("_delegate"in e&&(e=e._delegate),!(e instanceof t)){if(t.name===e.constructor.name)throw new n8(n3.INVALID_ARGUMENT,"Type does not match the expected instance. Did you pass a reference from a different Firestore SDK?");{let n=oW(e);throw new n8(n3.INVALID_ARGUMENT,`Expected type '${t.name}', but it was: ${n}`)}}return e}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class oZ{constructor(e){var t,n;if(void 0===e.host){if(void 0!==e.ssl)throw new n8(n3.INVALID_ARGUMENT,"Can't provide ssl option if host option is not set");this.host="firestore.googleapis.com",this.ssl=!0}else this.host=e.host,this.ssl=null===(t=e.ssl)||void 0===t||t;if(this.credentials=e.credentials,this.ignoreUndefinedProperties=!!e.ignoreUndefinedProperties,this.cache=e.localCache,void 0===e.cacheSizeBytes)this.cacheSizeBytes=41943040;else{if(-1!==e.cacheSizeBytes&&e.cacheSizeBytes<1048576)throw new n8(n3.INVALID_ARGUMENT,"cacheSizeBytes must be at least 1048576");this.cacheSizeBytes=e.cacheSizeBytes}(function(e,t,n,r){if(!0===t&&!0===r)throw new n8(n3.INVALID_ARGUMENT,`${e} and ${n} cannot be used together.`)})("experimentalForceLongPolling",e.experimentalForceLongPolling,"experimentalAutoDetectLongPolling",e.experimentalAutoDetectLongPolling),this.experimentalForceLongPolling=!!e.experimentalForceLongPolling,this.experimentalForceLongPolling?this.experimentalAutoDetectLongPolling=!1:void 0===e.experimentalAutoDetectLongPolling?this.experimentalAutoDetectLongPolling=!0:this.experimentalAutoDetectLongPolling=!!e.experimentalAutoDetectLongPolling,this.experimentalLongPollingOptions=oz(null!==(n=e.experimentalLongPollingOptions)&&void 0!==n?n:{}),function(e){if(void 0!==e.timeoutSeconds){if(isNaN(e.timeoutSeconds))throw new n8(n3.INVALID_ARGUMENT,`invalid long polling timeout: ${e.timeoutSeconds} (must not be NaN)`);if(e.timeoutSeconds<5)throw new n8(n3.INVALID_ARGUMENT,`invalid long polling timeout: ${e.timeoutSeconds} (minimum allowed value is 5)`);if(e.timeoutSeconds>30)throw new n8(n3.INVALID_ARGUMENT,`invalid long polling timeout: ${e.timeoutSeconds} (maximum allowed value is 30)`)}}(this.experimentalLongPollingOptions),this.useFetchStreams=!!e.useFetchStreams}isEqual(e){var t,n;return this.host===e.host&&this.ssl===e.ssl&&this.credentials===e.credentials&&this.cacheSizeBytes===e.cacheSizeBytes&&this.experimentalForceLongPolling===e.experimentalForceLongPolling&&this.experimentalAutoDetectLongPolling===e.experimentalAutoDetectLongPolling&&(t=this.experimentalLongPollingOptions,n=e.experimentalLongPollingOptions,t.timeoutSeconds===n.timeoutSeconds)&&this.ignoreUndefinedProperties===e.ignoreUndefinedProperties&&this.useFetchStreams===e.useFetchStreams}}class oJ{constructor(e,t,n,r){this._authCredentials=e,this._appCheckCredentials=t,this._databaseId=n,this._app=r,this.type="firestore-lite",this._persistenceKey="(lite)",this._settings=new oZ({}),this._settingsFrozen=!1}get app(){if(!this._app)throw new n8(n3.FAILED_PRECONDITION,"Firestore was not initialized using the Firebase SDK. 'app' is not available");return this._app}get _initialized(){return this._settingsFrozen}get _terminated(){return void 0!==this._terminateTask}_setSettings(e){if(this._settingsFrozen)throw new n8(n3.FAILED_PRECONDITION,"Firestore has already been started and its settings can no longer be changed. You can only modify settings before calling any other methods on a Firestore object.");this._settings=new oZ(e),void 0!==e.credentials&&(this._authCredentials=function(e){if(!e)return new rn;switch(e.type){case"firstParty":return new ra(e.sessionIndex||"0",e.iamToken||null,e.authTokenFactory||null);case"provider":return e.client;default:throw new n8(n3.INVALID_ARGUMENT,"makeAuthCredentialsProvider failed due to invalid credential type")}}(e.credentials))}_getSettings(){return this._settings}_freezeSettings(){return this._settingsFrozen=!0,this._settings}_delete(){return this._terminateTask||(this._terminateTask=this._terminate()),this._terminateTask}toJSON(){return{app:this._app,databaseId:this._databaseId,settings:this._settings}}_terminate(){return function(e){let t=o$.get(e);t&&(n4("ComponentProvider","Removing Datastore"),o$.delete(e),t.terminate())}(this),Promise.resolve()}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class oX{constructor(e,t,n){this.converter=t,this._key=n,this.type="document",this.firestore=e}get _path(){return this._key.path}get id(){return this._key.path.lastSegment()}get path(){return this._key.path.canonicalString()}get parent(){return new o0(this.firestore,this.converter,this._key.path.popLast())}withConverter(e){return new oX(this.firestore,e,this._key)}}class oY{constructor(e,t,n){this.converter=t,this._query=n,this.type="query",this.firestore=e}withConverter(e){return new oY(this.firestore,e,this._query)}}class o0 extends oY{constructor(e,t,n){super(e,t,iT(n)),this._path=n,this.type="collection"}get id(){return this._query.path.lastSegment()}get path(){return this._query.path.canonicalString()}get parent(){let e=this._path.popLast();return e.isEmpty()?null:new oX(this.firestore,null,new rv(e))}withConverter(e){return new o0(this.firestore,e,this._path)}}function o1(e,t,...n){if(e=(0,f.m9)(e),oH("collection","path",t),e instanceof oJ){let r=rg.fromString(t,...n);return oG(r),new o0(e,null,r)}{if(!(e instanceof oX||e instanceof o0))throw new n8(n3.INVALID_ARGUMENT,"Expected first argument to collection() to be a CollectionReference, a DocumentReference or FirebaseFirestore");let r=e._path.child(rg.fromString(t,...n));return oG(r),new o0(e.firestore,null,r)}}function o2(e,t,...n){if(e=(0,f.m9)(e),1==arguments.length&&(t=ru.A()),oH("doc","path",t),e instanceof oJ){let r=rg.fromString(t,...n);return oK(r),new oX(e,null,new rv(r))}{if(!(e instanceof oX||e instanceof o0))throw new n8(n3.INVALID_ARGUMENT,"Expected first argument to collection() to be a CollectionReference, a DocumentReference or FirebaseFirestore");let r=e._path.child(rg.fromString(t,...n));return oK(r),new oX(e.firestore,e instanceof o0?e.converter:null,new rv(r))}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class o4{constructor(){this.Gc=Promise.resolve(),this.Qc=[],this.jc=!1,this.zc=[],this.Wc=null,this.Hc=!1,this.Jc=!1,this.Yc=[],this.qo=new aC(this,"async_queue_retry"),this.Xc=()=>{let e=aS();e&&n4("AsyncQueue","Visibility state changed to "+e.visibilityState),this.qo.Mo()};let e=aS();e&&"function"==typeof e.addEventListener&&e.addEventListener("visibilitychange",this.Xc)}get isShuttingDown(){return this.jc}enqueueAndForget(e){this.enqueue(e)}enqueueAndForgetEvenWhileRestricted(e){this.Zc(),this.ta(e)}enterRestrictedMode(e){if(!this.jc){this.jc=!0,this.Jc=e||!1;let t=aS();t&&"function"==typeof t.removeEventListener&&t.removeEventListener("visibilitychange",this.Xc)}}enqueue(e){if(this.Zc(),this.jc)return new Promise(()=>{});let t=new re;return this.ta(()=>this.jc&&this.Jc?Promise.resolve():(e().then(t.resolve,t.reject),t.promise)).then(()=>t.promise)}enqueueRetryable(e){this.enqueueAndForget(()=>(this.Qc.push(e),this.ea()))}async ea(){if(0!==this.Qc.length){try{await this.Qc[0](),this.Qc.shift(),this.qo.reset()}catch(e){if(!r_(e))throw e;n4("AsyncQueue","Operation failed with retryable error: "+e)}this.Qc.length>0&&this.qo.No(()=>this.ea())}}ta(e){let t=this.Gc.then(()=>(this.Hc=!0,e().catch(e=>{let t;this.Wc=e,this.Hc=!1;let n=(t=e.message||"",e.stack&&(t=e.stack.includes(e.message)?e.stack:e.message+"\n"+e.stack),t);throw n9("INTERNAL UNHANDLED ERROR: ",n),e}).then(e=>(this.Hc=!1,e))));return this.Gc=t,t}enqueueAfterDelay(e,t,n){this.Zc(),this.Yc.indexOf(e)>-1&&(t=0);let r=a7.createAndSchedule(this,e,t,n,e=>this.na(e));return this.zc.push(r),r}Zc(){this.Wc&&n7()}verifyOperationInProgress(){}async sa(){let e;do e=this.Gc,await e;while(e!==this.Gc)}ia(e){for(let t of this.zc)if(t.timerId===e)return!0;return!1}ra(e){return this.sa().then(()=>{for(let t of(this.zc.sort((e,t)=>e.targetTimeMs-t.targetTimeMs),this.zc))if(t.skipDelay(),"all"!==e&&t.timerId===e)break;return this.sa()})}oa(e){this.Yc.push(e)}na(e){let t=this.zc.indexOf(e);this.zc.splice(t,1)}}function o9(e){return function(e,t){if("object"!=typeof e||null===e)return!1;for(let n of t)if(n in e&&"function"==typeof e[n])return!0;return!1}(e,["next","error","complete"])}class o6 extends oJ{constructor(e,t,n,r){super(e,t,n,r),this.type="firestore",this._queue=new o4,this._persistenceKey=(null==r?void 0:r.name)||"[DEFAULT]"}_terminate(){return this._firestoreClient||o3(this),this._firestoreClient.terminate()}}function o5(e,t){let n="object"==typeof e?e:(0,c.Mq)(),r=(0,c.qX)(n,"firestore").getImmediate({identifier:"string"==typeof e?e:t||"(default)"});if(!r._initialized){let e=(0,f.P0)("firestore");e&&function(e,t,n,r={}){var i;let s=(e=oQ(e,oJ))._getSettings(),a=`${t}:${n}`;if("firestore.googleapis.com"!==s.host&&s.host!==a&&n6("Host has been set in both settings() and connectFirestoreEmulator(), emulator host will be used."),e._setSettings(Object.assign(Object.assign({},s),{host:a,ssl:!1})),r.mockUserToken){let t,n;if("string"==typeof r.mockUserToken)t=r.mockUserToken,n=nY.MOCK_USER;else{t=(0,f.Sg)(r.mockUserToken,null===(i=e._app)||void 0===i?void 0:i.options.projectId);let s=r.mockUserToken.sub||r.mockUserToken.user_id;if(!s)throw new n8(n3.INVALID_ARGUMENT,"mockUserToken must contain 'sub' or 'user_id' field!");n=new nY(s)}e._authCredentials=new rr(new rt(t,n))}}(r,...e)}return r}function o7(e){return e._firestoreClient||o3(e),e._firestoreClient.verifyNotTerminated(),e._firestoreClient}function o3(e){var t,n,r,i,s,a;let o=e._freezeSettings(),l=(i=e._databaseId,s=(null===(t=e._app)||void 0===t?void 0:t.options.appId)||"",a=e._persistenceKey,new r$(i,s,a,o.host,o.ssl,o.experimentalForceLongPolling,o.experimentalAutoDetectLongPolling,oz(o.experimentalLongPollingOptions),o.useFetchStreams));e._firestoreClient=new oF(e._authCredentials,e._appCheckCredentials,e._queue,l),(null===(n=o.cache)||void 0===n?void 0:n._offlineComponentProvider)&&(null===(r=o.cache)||void 0===r?void 0:r._onlineComponentProvider)&&(e._firestoreClient._uninitializedComponentsProvider={_offlineKind:o.cache.kind,_offline:o.cache._offlineComponentProvider,_online:o.cache._onlineComponentProvider})}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *//**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class o8{constructor(e="count",t){this._aggregateType=e,this._internalFieldPath=t,this.type="AggregateField"}}class le{constructor(e,t,n){this._userDataWriter=t,this._data=n,this.type="AggregateQuerySnapshot",this.query=e}data(){return this._userDataWriter.convertObjectMap(this._data)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class lt{constructor(e){this._byteString=e}static fromBase64String(e){try{return new lt(rM.fromBase64String(e))}catch(e){throw new n8(n3.INVALID_ARGUMENT,"Failed to construct data from Base64 string: "+e)}}static fromUint8Array(e){return new lt(rM.fromUint8Array(e))}toBase64(){return this._byteString.toBase64()}toUint8Array(){return this._byteString.toUint8Array()}toString(){return"Bytes(base64: "+this.toBase64()+")"}isEqual(e){return this._byteString.isEqual(e._byteString)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ln{constructor(...e){for(let t=0;t<e.length;++t)if(0===e[t].length)throw new n8(n3.INVALID_ARGUMENT,"Invalid field name at argument $(i + 1). Field names must not be empty.");this._internalPath=new ry(e)}isEqual(e){return this._internalPath.isEqual(e._internalPath)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class lr{constructor(e){this._methodName=e}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class li{constructor(e,t){if(!isFinite(e)||e<-90||e>90)throw new n8(n3.INVALID_ARGUMENT,"Latitude must be a number between -90 and 90, but was: "+e);if(!isFinite(t)||t<-180||t>180)throw new n8(n3.INVALID_ARGUMENT,"Longitude must be a number between -180 and 180, but was: "+t);this._lat=e,this._long=t}get latitude(){return this._lat}get longitude(){return this._long}isEqual(e){return this._lat===e._lat&&this._long===e._long}toJSON(){return{latitude:this._lat,longitude:this._long}}_compareTo(e){return rc(this._lat,e._lat)||rc(this._long,e._long)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let ls=/^__.*__$/;class la{constructor(e,t,n){this.data=e,this.fieldMask=t,this.fieldTransforms=n}toMutation(e,t){return new si(e,this.data,this.fieldMask,t,this.fieldTransforms)}}function lo(e){switch(e){case 0:case 2:case 1:return!0;case 3:case 4:return!1;default:throw n7()}}class ll{constructor(e,t,n,r,i,s){this.settings=e,this.databaseId=t,this.serializer=n,this.ignoreUndefinedProperties=r,void 0===i&&this.ua(),this.fieldTransforms=i||[],this.fieldMask=s||[]}get path(){return this.settings.path}get ca(){return this.settings.ca}aa(e){return new ll(Object.assign(Object.assign({},this.settings),e),this.databaseId,this.serializer,this.ignoreUndefinedProperties,this.fieldTransforms,this.fieldMask)}ha(e){var t;let n=null===(t=this.path)||void 0===t?void 0:t.child(e),r=this.aa({path:n,la:!1});return r.fa(e),r}da(e){var t;let n=null===(t=this.path)||void 0===t?void 0:t.child(e),r=this.aa({path:n,la:!1});return r.ua(),r}wa(e){return this.aa({path:void 0,la:!0})}_a(e){return lw(e,this.settings.methodName,this.settings.ma||!1,this.path,this.settings.ga)}contains(e){return void 0!==this.fieldMask.find(t=>e.isPrefixOf(t))||void 0!==this.fieldTransforms.find(t=>e.isPrefixOf(t.field))}ua(){if(this.path)for(let e=0;e<this.path.length;e++)this.fa(this.path.get(e))}fa(e){if(0===e.length)throw this._a("Document fields must not be empty");if(lo(this.ca)&&ls.test(e))throw this._a('Document fields cannot begin and end with "__"')}}class lu{constructor(e,t,n){this.databaseId=e,this.ignoreUndefinedProperties=t,this.serializer=n||ax(e)}ya(e,t,n,r=!1){return new ll({ca:e,methodName:t,ga:n,path:ry.emptyPath(),la:!1,ma:r},this.databaseId,this.serializer,this.ignoreUndefinedProperties)}}function lc(e){let t=e._freezeSettings(),n=ax(e._databaseId);return new lu(e._databaseId,!!t.ignoreUndefinedProperties,n)}class lh extends lr{_toFieldTransform(e){if(2!==e.ca)throw 1===e.ca?e._a(`${this._methodName}() can only appear at the top level of your update data`):e._a(`${this._methodName}() cannot be used with set() unless you pass {merge:true}`);return e.fieldMask.push(e.path),null}isEqual(e){return e instanceof lh}}function ld(e,t,n,r=!1){return lf(n,e.ya(r?4:3,t))}function lf(e,t){if(lp(e=(0,f.m9)(e)))return lg("Unsupported field value:",t,e),function(e,t){let n={};return rC(e)?t.path&&t.path.length>0&&t.fieldMask.push(t.path):rx(e,(e,r)=>{let i=lf(r,t.ha(e));null!=i&&(n[e]=i)}),{mapValue:{fields:n}}}(e,t);if(e instanceof lr)return function(e,t){if(!lo(t.ca))throw t._a(`${e._methodName}() can only be used with update() and set()`);if(!t.path)throw t._a(`${e._methodName}() is not currently supported inside arrays`);let n=e._toFieldTransform(t);n&&t.fieldTransforms.push(n)}(e,t),null;if(void 0===e&&t.ignoreUndefinedProperties)return null;if(t.path&&t.fieldMask.push(t.path),e instanceof Array){if(t.settings.la&&4!==t.ca)throw t._a("Nested arrays are not supported");return function(e,t){let n=[],r=0;for(let i of e){let e=lf(i,t.wa(r));null==e&&(e={nullValue:"NULL_VALUE"}),n.push(e),r++}return{arrayValue:{values:n}}}(e,t)}return function(e,t){if(null===(e=(0,f.m9)(e)))return{nullValue:"NULL_VALUE"};if("number"==typeof e){var n,r,i;return n=t.serializer,"number"==typeof(i=r=e)&&Number.isInteger(i)&&!rk(i)&&i<=Number.MAX_SAFE_INTEGER&&i>=Number.MIN_SAFE_INTEGER?iQ(r):iW(n,r)}if("boolean"==typeof e)return{booleanValue:e};if("string"==typeof e)return{stringValue:e};if(e instanceof Date){let n=rd.fromDate(e);return{timestampValue:sF(t.serializer,n)}}if(e instanceof rd){let n=new rd(e.seconds,1e3*Math.floor(e.nanoseconds/1e3));return{timestampValue:sF(t.serializer,n)}}if(e instanceof li)return{geoPointValue:{latitude:e.latitude,longitude:e.longitude}};if(e instanceof lt)return{bytesValue:sV(t.serializer,e._byteString)};if(e instanceof oX){let n=t.databaseId,r=e.firestore._databaseId;if(!r.isEqual(n))throw t._a(`Document reference is for database ${r.projectId}/${r.database} but should be for database ${n.projectId}/${n.database}`);return{referenceValue:sj(e.firestore._databaseId||t.databaseId,e._key.path)}}throw t._a(`Unsupported field value: ${oW(e)}`)}(e,t)}function lp(e){return!("object"!=typeof e||null===e||e instanceof Array||e instanceof Date||e instanceof rd||e instanceof li||e instanceof lt||e instanceof oX||e instanceof lr)}function lg(e,t,n){if(!lp(n)||!("object"==typeof n&&null!==n&&(Object.getPrototypeOf(n)===Object.prototype||null===Object.getPrototypeOf(n)))){let r=oW(n);throw"an object"===r?t._a(e+" a custom object"):t._a(e+" "+r)}}function lm(e,t,n){if((t=(0,f.m9)(t))instanceof ln)return t._internalPath;if("string"==typeof t)return lv(e,t);throw lw("Field path arguments must be of type string or ",e,!1,void 0,n)}let ly=RegExp("[~\\*/\\[\\]]");function lv(e,t,n){if(t.search(ly)>=0)throw lw(`Invalid field path (${t}). Paths must not contain '~', '*', '/', '[', or ']'`,e,!1,void 0,n);try{return new ln(...t.split("."))._internalPath}catch(r){throw lw(`Invalid field path (${t}). Paths must not be empty, begin with '.', end with '.', or contain '..'`,e,!1,void 0,n)}}function lw(e,t,n,r,i){let s=r&&!r.isEmpty(),a=void 0!==i,o=`Function ${t}() called with invalid data`;n&&(o+=" (via `toFirestore()`)"),o+=". ";let l="";return(s||a)&&(l+=" (found",s&&(l+=` in field ${r}`),a&&(l+=` in document ${i}`),l+=")"),new n8(n3.INVALID_ARGUMENT,o+e+l)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class lb{constructor(e,t,n,r,i){this._firestore=e,this._userDataWriter=t,this._key=n,this._document=r,this._converter=i}get id(){return this._key.path.lastSegment()}get ref(){return new oX(this._firestore,this._converter,this._key)}exists(){return null!==this._document}data(){if(this._document){if(this._converter){let e=new lE(this._firestore,this._userDataWriter,this._key,this._document,null);return this._converter.fromFirestore(e)}return this._userDataWriter.convertValue(this._document.data.value)}}get(e){if(this._document){let t=this._document.data.field(lI("DocumentSnapshot.get",e));if(null!==t)return this._userDataWriter.convertValue(t)}}}class lE extends lb{data(){return super.data()}}function lI(e,t){return"string"==typeof t?lv(e,t):t instanceof ln?t._internalPath:t._delegate._internalPath}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function l_(e){if("L"===e.limitType&&0===e.explicitOrderBy.length)throw new n8(n3.UNIMPLEMENTED,"limitToLast() queries require specifying at least one orderBy() clause")}class lT{}class lk extends lT{}function lS(e,t,...n){let r=[];for(let i of(t instanceof lT&&r.push(t),function(e){let t=e.filter(e=>e instanceof lA).length,n=e.filter(e=>e instanceof lx).length;if(t>1||t>0&&n>0)throw new n8(n3.INVALID_ARGUMENT,"InvalidQuery. When using composite filters, you cannot use more than one filter at the top level. Consider nesting the multiple filters within an `and(...)` statement. For example: change `query(query, where(...), or(...))` to `query(query, and(where(...), or(...)))`.")}(r=r.concat(n)),r))e=i._apply(e);return e}class lx extends lk{constructor(e,t,n){super(),this._field=e,this._op=t,this._value=n,this.type="where"}static _create(e,t,n){return new lx(e,t,n)}_apply(e){let t=this._parse(e);return lV(e._query,t),new oY(e.firestore,e.converter,iR(e._query,t))}_parse(e){let t=lc(e.firestore),n=function(e,t,n,r,i,s,a){let o;if(i.isKeyField()){if("array-contains"===s||"array-contains-any"===s)throw new n8(n3.INVALID_ARGUMENT,`Invalid Query. You can't perform '${s}' queries on documentId().`);if("in"===s||"not-in"===s){lF(a,s);let t=[];for(let n of a)t.push(lM(r,e,n));o={arrayValue:{values:t}}}else o=lM(r,e,a)}else"in"!==s&&"not-in"!==s&&"array-contains-any"!==s||lF(a,s),o=ld(n,t,a,"in"===s||"not-in"===s);return is.create(i,s,o)}(e._query,"where",t,e.firestore._databaseId,this._field,this._op,this._value);return n}}function lC(e,t,n){let r=lI("where",e);return lx._create(r,t,n)}class lA extends lT{constructor(e,t){super(),this.type=e,this._queryConstraints=t}static _create(e,t){return new lA(e,t)}_parse(e){let t=this._queryConstraints.map(t=>t._parse(e)).filter(e=>e.getFilters().length>0);return 1===t.length?t[0]:ia.create(t,this._getOperator())}_apply(e){let t=this._parse(e);return 0===t.getFilters().length?e:(function(e,t){let n=e,r=t.getFlattenedFilters();for(let e of r)lV(n,e),n=iR(n,e)}(e._query,t),new oY(e.firestore,e.converter,iR(e._query,t)))}_getQueryConstraints(){return this._queryConstraints}_getOperator(){return"and"===this.type?"and":"or"}}class lN extends lk{constructor(e,t){super(),this._field=e,this._direction=t,this.type="orderBy"}static _create(e,t){return new lN(e,t)}_apply(e){let t=function(e,t,n){if(null!==e.startAt)throw new n8(n3.INVALID_ARGUMENT,"Invalid query. You must not call startAt() or startAfter() before calling orderBy().");if(null!==e.endAt)throw new n8(n3.INVALID_ARGUMENT,"Invalid query. You must not call endAt() or endBefore() before calling orderBy().");let r=new ir(t,n);return function(e,t){if(null===iS(e)){let n=ix(e);null!==n&&lU(e,n,t.field)}}(e,r),r}(e._query,this._field,this._direction);return new oY(e.firestore,e.converter,function(e,t){let n=e.explicitOrderBy.concat([t]);return new i_(e.path,e.collectionGroup,n,e.filters.slice(),e.limit,e.limitType,e.startAt,e.endAt)}(e._query,t))}}function lR(e,t="asc"){let n=lI("orderBy",e);return lN._create(n,t)}class lD extends lk{constructor(e,t,n){super(),this.type=e,this._limit=t,this._limitType=n}static _create(e,t,n){return new lD(e,t,n)}_apply(e){return new oY(e.firestore,e.converter,iD(e._query,this._limit,this._limitType))}}function lO(e){return function(e,t){if(t<=0)throw new n8(n3.INVALID_ARGUMENT,`Function ${e}() requires a positive number, but it was: ${t}.`)}("limit",e),lD._create("limit",e,"F")}class lP extends lk{constructor(e,t,n){super(),this.type=e,this._docOrFields=t,this._inclusive=n}static _create(e,t,n){return new lP(e,t,n)}_apply(e){var t;let n=function(e,t,n,r){if(n[0]=(0,f.m9)(n[0]),n[0]instanceof lb)return function(e,t,n,r,i){if(!r)throw new n8(n3.NOT_FOUND,`Can't use a DocumentSnapshot that doesn't exist for ${n}().`);let s=[];for(let n of iA(e))if(n.field.isKeyField())s.push(rY(t,r.key));else{let e=r.data.field(n.field);if(rB(e))throw new n8(n3.INVALID_ARGUMENT,'Invalid query. You are trying to start or end a query using a document for which the field "'+n.field+'" is an uncommitted server timestamp. (Since the value of this field is unknown, you cannot start/end a query with it.)');if(null===e){let e=n.field.canonicalString();throw new n8(n3.INVALID_ARGUMENT,`Invalid query. You are trying to start or end a query using a document for which the field '${e}' (used as the orderBy) does not exist.`)}s.push(e)}return new r8(s,i)}(e._query,e.firestore._databaseId,t,n[0]._document,r);{let i=lc(e.firestore);return function(e,t,n,r,i,s){let a=e.explicitOrderBy;if(i.length>a.length)throw new n8(n3.INVALID_ARGUMENT,`Too many arguments provided to ${r}(). The number of arguments must be less than or equal to the number of orderBy() clauses`);let o=[];for(let s=0;s<i.length;s++){let l=i[s];if(a[s].field.isKeyField()){if("string"!=typeof l)throw new n8(n3.INVALID_ARGUMENT,`Invalid query. Expected a string for document ID in ${r}(), but got a ${typeof l}`);if(!iC(e)&&-1!==l.indexOf("/"))throw new n8(n3.INVALID_ARGUMENT,`Invalid query. When querying a collection and ordering by documentId(), the value passed to ${r}() must be a plain document ID, but '${l}' contains a slash.`);let n=e.path.child(rg.fromString(l));if(!rv.isDocumentKey(n))throw new n8(n3.INVALID_ARGUMENT,`Invalid query. When querying a collection group and ordering by documentId(), the value passed to ${r}() must result in a valid document path, but '${n}' is not because it contains an odd number of segments.`);let i=new rv(n);o.push(rY(t,i))}else{let e=ld(n,r,l);o.push(e)}}return new r8(o,s)}(e._query,e.firestore._databaseId,i,t,n,r)}}(e,this.type,this._docOrFields,this._inclusive);return new oY(e.firestore,e.converter,(t=e._query,new i_(t.path,t.collectionGroup,t.explicitOrderBy.slice(),t.filters.slice(),t.limit,t.limitType,n,t.endAt)))}}function lL(...e){return lP._create("startAfter",e,!1)}function lM(e,t,n){if("string"==typeof(n=(0,f.m9)(n))){if(""===n)throw new n8(n3.INVALID_ARGUMENT,"Invalid query. When querying with documentId(), you must provide a valid document ID, but it was an empty string.");if(!iC(t)&&-1!==n.indexOf("/"))throw new n8(n3.INVALID_ARGUMENT,`Invalid query. When querying a collection by documentId(), you must provide a plain document ID, but '${n}' contains a '/' character.`);let r=t.path.child(rg.fromString(n));if(!rv.isDocumentKey(r))throw new n8(n3.INVALID_ARGUMENT,`Invalid query. When querying a collection group by documentId(), the value provided must result in a valid document path, but '${r}' is not because it has an odd number of segments (${r.length}).`);return rY(e,new rv(r))}if(n instanceof oX)return rY(e,n._key);throw new n8(n3.INVALID_ARGUMENT,`Invalid query. When querying with documentId(), you must provide a valid string or a DocumentReference, but it was: ${oW(n)}.`)}function lF(e,t){if(!Array.isArray(e)||0===e.length)throw new n8(n3.INVALID_ARGUMENT,`Invalid Query. A non-empty array is required for '${t.toString()}' filters.`)}function lV(e,t){if(t.isInequality()){let n=ix(e),r=t.field;if(null!==n&&!n.isEqual(r))throw new n8(n3.INVALID_ARGUMENT,`Invalid query. All where filters with an inequality (<, <=, !=, not-in, >, or >=) must be on the same field. But you have inequality filters on '${n.toString()}' and '${r.toString()}'`);let i=iS(e);null!==i&&lU(e,r,i)}let n=function(e,t){for(let n of e)for(let e of n.getFlattenedFilters())if(t.indexOf(e.op)>=0)return e.op;return null}(e.filters,function(e){switch(e){case"!=":return["!=","not-in"];case"array-contains-any":case"in":return["not-in"];case"not-in":return["array-contains-any","in","not-in","!="];default:return[]}}(t.op));if(null!==n)throw n===t.op?new n8(n3.INVALID_ARGUMENT,`Invalid query. You cannot use more than one '${t.op.toString()}' filter.`):new n8(n3.INVALID_ARGUMENT,`Invalid query. You cannot use '${t.op.toString()}' filters with '${n.toString()}' filters.`)}function lU(e,t,n){if(!n.isEqual(t))throw new n8(n3.INVALID_ARGUMENT,`Invalid query. You have a where filter with an inequality (<, <=, !=, not-in, >, or >=) on field '${t.toString()}' and so you must also use '${t.toString()}' as your first argument to orderBy(), but your first orderBy() is on field '${n.toString()}' instead.`)}class lj{convertValue(e,t="none"){switch(rG(e)){case 0:return null;case 1:return e.booleanValue;case 2:return rU(e.integerValue||e.doubleValue);case 3:return this.convertTimestamp(e.timestampValue);case 4:return this.convertServerTimestamp(e,t);case 5:return e.stringValue;case 6:return this.convertBytes(rj(e.bytesValue));case 7:return this.convertReference(e.referenceValue);case 8:return this.convertGeoPoint(e.geoPointValue);case 9:return this.convertArray(e.arrayValue,t);case 10:return this.convertObject(e.mapValue,t);default:throw n7()}}convertObject(e,t){return this.convertObjectMap(e.fields,t)}convertObjectMap(e,t="none"){let n={};return rx(e,(e,r)=>{n[e]=this.convertValue(r,t)}),n}convertGeoPoint(e){return new li(rU(e.latitude),rU(e.longitude))}convertArray(e,t){return(e.values||[]).map(e=>this.convertValue(e,t))}convertServerTimestamp(e,t){switch(t){case"previous":let n=rq(e);return null==n?null:this.convertValue(n,t);case"estimate":return this.convertTimestamp(rz(e));default:return null}}convertTimestamp(e){let t=rV(e);return new rd(t.seconds,t.nanos)}convertDocumentKey(e,t){let n=rg.fromString(e);sJ(n)||n7();let r=new rH(n.get(1),n.get(3)),i=new rv(n.popFirst(5));return r.isEqual(t)||n9(`Document ${i} contains a document reference within a different database (${r.projectId}/${r.database}) which is not supported. It will be treated as a reference in the current database (${t.projectId}/${t.database}) instead.`),i}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class lB{constructor(e,t){this.hasPendingWrites=e,this.fromCache=t}isEqual(e){return this.hasPendingWrites===e.hasPendingWrites&&this.fromCache===e.fromCache}}class lq extends lb{constructor(e,t,n,r,i,s){super(e,t,n,r,s),this._firestore=e,this._firestoreImpl=e,this.metadata=i}exists(){return super.exists()}data(e={}){if(this._document){if(this._converter){let t=new lz(this._firestore,this._userDataWriter,this._key,this._document,this.metadata,null);return this._converter.fromFirestore(t,e)}return this._userDataWriter.convertValue(this._document.data.value,e.serverTimestamps)}}get(e,t={}){if(this._document){let n=this._document.data.field(lI("DocumentSnapshot.get",e));if(null!==n)return this._userDataWriter.convertValue(n,t.serverTimestamps)}}}class lz extends lq{data(e={}){return super.data(e)}}class l${constructor(e,t,n,r){this._firestore=e,this._userDataWriter=t,this._snapshot=r,this.metadata=new lB(r.hasPendingWrites,r.fromCache),this.query=n}get docs(){let e=[];return this.forEach(t=>e.push(t)),e}get size(){return this._snapshot.docs.size}get empty(){return 0===this.size}forEach(e,t){this._snapshot.docs.forEach(n=>{e.call(t,new lz(this._firestore,this._userDataWriter,n.key,n,new lB(this._snapshot.mutatedKeys.has(n.key),this._snapshot.fromCache),this.query.converter))})}docChanges(e={}){let t=!!e.includeMetadataChanges;if(t&&this._snapshot.excludesMetadataChanges)throw new n8(n3.INVALID_ARGUMENT,"To include metadata changes with your document changes, you must also pass { includeMetadataChanges:true } to onSnapshot().");return this._cachedChanges&&this._cachedChangesIncludeMetadataChanges===t||(this._cachedChanges=function(e,t){if(e._snapshot.oldDocs.isEmpty()){let t=0;return e._snapshot.docChanges.map(n=>{let r=new lz(e._firestore,e._userDataWriter,n.doc.key,n.doc,new lB(e._snapshot.mutatedKeys.has(n.doc.key),e._snapshot.fromCache),e.query.converter);return n.doc,{type:"added",doc:r,oldIndex:-1,newIndex:t++}})}{let n=e._snapshot.oldDocs;return e._snapshot.docChanges.filter(e=>t||3!==e.type).map(t=>{let r=new lz(e._firestore,e._userDataWriter,t.doc.key,t.doc,new lB(e._snapshot.mutatedKeys.has(t.doc.key),e._snapshot.fromCache),e.query.converter),i=-1,s=-1;return 0!==t.type&&(i=n.indexOf(t.doc.key),n=n.delete(t.doc.key)),1!==t.type&&(s=(n=n.add(t.doc)).indexOf(t.doc.key)),{type:function(e){switch(e){case 0:return"added";case 2:case 3:return"modified";case 1:return"removed";default:return n7()}}(t.type),doc:r,oldIndex:i,newIndex:s}})}}(this,t),this._cachedChangesIncludeMetadataChanges=t),this._cachedChanges}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function lH(e){e=oQ(e,oX);let t=oQ(e.firestore,o6);return(function(e,t,n={}){let r=new re;return e.asyncQueue.enqueueAndForget(async()=>(function(e,t,n,r,i){let s=new oM({next:s=>{t.enqueueAndForget(()=>os(e,a));let o=s.docs.has(n);!o&&s.fromCache?i.reject(new n8(n3.UNAVAILABLE,"Failed to get document because the client is offline.")):o&&s.fromCache&&r&&"server"===r.source?i.reject(new n8(n3.UNAVAILABLE,'Failed to get document from server. (However, this document does exist in the local cache. Run again without setting source to "server" to retrieve the cached document.)')):i.resolve(s)},error:e=>i.reject(e)}),a=new ou(iT(n.path),s,{includeMetadataChanges:!0,Ku:!0});return oi(e,a)})(await oq(e),e.asyncQueue,t,n,r)),r.promise})(o7(t),e._key).then(n=>lX(t,e,n))}class lK extends lj{constructor(e){super(),this.firestore=e}convertBytes(e){return new lt(e)}convertReference(e){let t=this.convertDocumentKey(e,this.firestore._databaseId);return new oX(this.firestore,null,t)}}function lG(e){e=oQ(e,oY);let t=oQ(e.firestore,o6),n=o7(t),r=new lK(t);return l_(e._query),(function(e,t,n={}){let r=new re;return e.asyncQueue.enqueueAndForget(async()=>(function(e,t,n,r,i){let s=new oM({next:n=>{t.enqueueAndForget(()=>os(e,a)),n.fromCache&&"server"===r.source?i.reject(new n8(n3.UNAVAILABLE,'Failed to get documents from server. (However, these documents may exist in the local cache. Run again without setting source to "server" to retrieve the cached documents.)')):i.resolve(n)},error:e=>i.reject(e)}),a=new ou(n,s,{includeMetadataChanges:!0,Ku:!0});return oi(e,a)})(await oq(e),e.asyncQueue,t,n,r)),r.promise})(n,e._query).then(n=>new l$(t,r,e,n))}function lW(e,t,n,...r){let i;e=oQ(e,oX);let s=oQ(e.firestore,o6),a=lc(s);return i="string"==typeof(t=(0,f.m9)(t))||t instanceof ln?function(e,t,n,r,i,s){let a=e.ya(1,t,n),o=[lm(t,r,n)],l=[i];if(s.length%2!=0)throw new n8(n3.INVALID_ARGUMENT,`Function ${t}() needs to be called with an even number of arguments that alternate between field names and values.`);for(let e=0;e<s.length;e+=2)o.push(lm(t,s[e])),l.push(s[e+1]);let u=[],c=r7.empty();for(let e=o.length-1;e>=0;--e)if(!function(e,t){return e.some(e=>e.isEqual(t))}(u,o[e])){let t=o[e],n=l[e];n=(0,f.m9)(n);let r=a.da(t);if(n instanceof lh)u.push(t);else{let e=lf(n,r);null!=e&&(u.push(t),c.set(t,e))}}let h=new rP(u);return new la(c,h,a.fieldTransforms)}(a,"updateDoc",e._key,t,n,r):function(e,t,n,r){let i=e.ya(1,t,n);lg("Data must be an object, but it was:",i,r);let s=[],a=r7.empty();rx(r,(e,r)=>{let o=lv(t,e,n);r=(0,f.m9)(r);let l=i.da(o);if(r instanceof lh)s.push(o);else{let e=lf(r,l);null!=e&&(s.push(o),a.set(o,e))}});let o=new rP(s);return new la(a,o,i.fieldTransforms)}(a,"updateDoc",e._key,t),lJ(s,[i.toMutation(e._key,i7.exists(!0))])}function lQ(e){return lJ(oQ(e.firestore,o6),[new sl(e._key,i7.none())])}function lZ(e,...t){var n,r,i;let s,a,o;e=(0,f.m9)(e);let l={includeMetadataChanges:!1},u=0;"object"!=typeof t[0]||o9(t[u])||(l=t[u],u++);let c={includeMetadataChanges:l.includeMetadataChanges};if(o9(t[u])){let e=t[u];t[u]=null===(n=e.next)||void 0===n?void 0:n.bind(e),t[u+1]=null===(r=e.error)||void 0===r?void 0:r.bind(e),t[u+2]=null===(i=e.complete)||void 0===i?void 0:i.bind(e)}if(e instanceof oX)a=oQ(e.firestore,o6),o=iT(e._key.path),s={next:n=>{t[u]&&t[u](lX(a,e,n))},error:t[u+1],complete:t[u+2]};else{let n=oQ(e,oY);a=oQ(n.firestore,o6),o=n._query;let r=new lK(a);s={next:e=>{t[u]&&t[u](new l$(a,r,n,e))},error:t[u+1],complete:t[u+2]},l_(e._query)}return function(e,t,n,r){let i=new oM(r),s=new ou(t,i,n);return e.asyncQueue.enqueueAndForget(async()=>oi(await oq(e),s)),()=>{i.Dc(),e.asyncQueue.enqueueAndForget(async()=>os(await oq(e),s))}}(o7(a),o,c,s)}function lJ(e,t){return function(e,t){let n=new re;return e.asyncQueue.enqueueAndForget(async()=>ow(await oB(e).then(e=>e.syncEngine),t,n)),n.promise}(o7(e),t)}function lX(e,t,n){let r=n.docs.get(t._key),i=new lK(e);return new lq(e,i,t._key,r,new lB(n.hasPendingWrites,n.fromCache),t.converter)}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function lY(e){return function(e,t){let n=oQ(e.firestore,o6),r=o7(n),i=function(e,t){let n=[];for(let r in e)Object.prototype.hasOwnProperty.call(e,r)&&n.push(t(e[r],r,e));return n}(t,(e,t)=>new sf(t,e._aggregateType,e._internalFieldPath));return(function(e,t,n){let r=new re;return e.asyncQueue.enqueueAndForget(async()=>{try{let i=await oB(e).then(e=>e.datastore);r.resolve(aO(i,t,n))}catch(e){r.reject(e)}}),r.promise})(r,e._query,i).then(t=>(function(e,t,n){let r=new lK(e);return new le(t,r,n)})(n,e,t))}(e,{count:new o8("count")})}!function(e,t=!0){n0=c.Jn,(0,c.Xd)(new h.wA("firestore",(e,{instanceIdentifier:n,options:r})=>{let i=e.getProvider("app").getImmediate(),s=new o6(new ri(e.getProvider("auth-internal")),new rl(e.getProvider("app-check-internal")),function(e,t){if(!Object.prototype.hasOwnProperty.apply(e.options,["projectId"]))throw new n8(n3.INVALID_ARGUMENT,'"projectId" not provided in firebase.initializeApp.');return new rH(e.options.projectId,t)}(i,n),i);return r=Object.assign({useFetchStreams:t},r),s._setSettings(r),s},"PUBLIC").setMultipleInstances(!0)),(0,c.KN)(nX,"3.13.0",void 0),(0,c.KN)(nX,"3.13.0","esm2017")}()},2239:function(e,t,n){"use strict";n.d(t,{$C:function(){return w},V1:function(){return b}});var r,i=n(3991),s=n(8745),a=n(5538);function o(e,t){let n={};for(let r in e)e.hasOwnProperty(r)&&(n[r]=t(e[r]));return n}function l(e){if(null==e)return e;if(e["@type"])switch(e["@type"]){case"type.googleapis.com/google.protobuf.Int64Value":case"type.googleapis.com/google.protobuf.UInt64Value":{let t=Number(e.value);if(isNaN(t))throw Error("Data cannot be decoded from JSON: "+e);return t}default:throw Error("Data cannot be decoded from JSON: "+e)}return Array.isArray(e)?e.map(e=>l(e)):"function"==typeof e||"object"==typeof e?o(e,e=>l(e)):e}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let u="functions",c={OK:"ok",CANCELLED:"cancelled",UNKNOWN:"unknown",INVALID_ARGUMENT:"invalid-argument",DEADLINE_EXCEEDED:"deadline-exceeded",NOT_FOUND:"not-found",ALREADY_EXISTS:"already-exists",PERMISSION_DENIED:"permission-denied",UNAUTHENTICATED:"unauthenticated",RESOURCE_EXHAUSTED:"resource-exhausted",FAILED_PRECONDITION:"failed-precondition",ABORTED:"aborted",OUT_OF_RANGE:"out-of-range",UNIMPLEMENTED:"unimplemented",INTERNAL:"internal",UNAVAILABLE:"unavailable",DATA_LOSS:"data-loss"};class h extends s.ZR{constructor(e,t,n){super(`${u}/${e}`,t||""),this.details=n}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class d{constructor(e,t,n){this.auth=null,this.messaging=null,this.appCheck=null,this.auth=e.getImmediate({optional:!0}),this.messaging=t.getImmediate({optional:!0}),this.auth||e.get().then(e=>this.auth=e,()=>{}),this.messaging||t.get().then(e=>this.messaging=e,()=>{}),this.appCheck||n.get().then(e=>this.appCheck=e,()=>{})}async getAuthToken(){if(this.auth)try{let e=await this.auth.getToken();return null==e?void 0:e.accessToken}catch(e){return}}async getMessagingToken(){if(this.messaging&&"Notification"in self&&"granted"===Notification.permission)try{return await this.messaging.getToken()}catch(e){return}}async getAppCheckToken(e){if(this.appCheck){let t=e?await this.appCheck.getLimitedUseToken():await this.appCheck.getToken();return t.error?null:t.token}return null}async getContext(e){let t=await this.getAuthToken(),n=await this.getMessagingToken(),r=await this.getAppCheckToken(e);return{authToken:t,messagingToken:n,appCheckToken:r}}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let f="us-central1";class p{constructor(e,t,n,r,i=f,s){this.app=e,this.fetchImpl=s,this.emulatorOrigin=null,this.contextProvider=new d(t,n,r),this.cancelAllRequests=new Promise(e=>{this.deleteService=()=>Promise.resolve(e())});try{let e=new URL(i);this.customDomain=e.origin,this.region=f}catch(e){this.customDomain=null,this.region=i}}_delete(){return this.deleteService()}_url(e){let t=this.app.options.projectId;if(null!==this.emulatorOrigin){let n=this.emulatorOrigin;return`${n}/${t}/${this.region}/${e}`}return null!==this.customDomain?`${this.customDomain}/${e}`:`https://${this.region}-${t}.cloudfunctions.net/${e}`}}async function g(e,t,n,r){let i;n["Content-Type"]="application/json";try{i=await r(e,{method:"POST",body:JSON.stringify(t),headers:n})}catch(e){return{status:0,json:null}}let s=null;try{s=await i.json()}catch(e){}return{status:i.status,json:s}}async function m(e,t,n,r){let i;n=function e(t){if(null==t)return null;if(t instanceof Number&&(t=t.valueOf()),"number"==typeof t&&isFinite(t)||!0===t||!1===t||"[object String]"===Object.prototype.toString.call(t))return t;if(t instanceof Date)return t.toISOString();if(Array.isArray(t))return t.map(t=>e(t));if("function"==typeof t||"object"==typeof t)return o(t,t=>e(t));throw Error("Data cannot be encoded in JSON: "+t)}(n);let s={data:n},a={},u=await e.contextProvider.getContext(r.limitedUseAppCheckTokens);u.authToken&&(a.Authorization="Bearer "+u.authToken),u.messagingToken&&(a["Firebase-Instance-ID-Token"]=u.messagingToken),null!==u.appCheckToken&&(a["X-Firebase-AppCheck"]=u.appCheckToken);let d=r.timeout||7e4,f=(i=null,{promise:new Promise((e,t)=>{i=setTimeout(()=>{t(new h("deadline-exceeded","deadline-exceeded"))},d)}),cancel:()=>{i&&clearTimeout(i)}}),p=await Promise.race([g(t,s,a,e.fetchImpl),f.promise,e.cancelAllRequests]);if(f.cancel(),!p)throw new h("cancelled","Firebase Functions instance was deleted.");let m=function(e,t){let n,r=function(e){if(e>=200&&e<300)return"ok";switch(e){case 0:case 500:return"internal";case 400:return"invalid-argument";case 401:return"unauthenticated";case 403:return"permission-denied";case 404:return"not-found";case 409:return"aborted";case 429:return"resource-exhausted";case 499:return"cancelled";case 501:return"unimplemented";case 503:return"unavailable";case 504:return"deadline-exceeded"}return"unknown"}(e),i=r;try{let e=t&&t.error;if(e){let t=e.status;if("string"==typeof t){if(!c[t])return new h("internal","internal");r=c[t],i=t}let s=e.message;"string"==typeof s&&(i=s),n=e.details,void 0!==n&&(n=l(n))}}catch(e){}return"ok"===r?null:new h(r,i,n)}(p.status,p.json);if(m)throw m;if(!p.json)throw new h("internal","Response is not valid JSON object.");let y=p.json.data;if(void 0===y&&(y=p.json.result),void 0===y)throw new h("internal","Response is missing data field.");let v=l(y);return{data:v}}let y="@firebase/functions",v="0.10.0";/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function w(e=(0,i.Mq)(),t=f){let n=(0,i.qX)((0,s.m9)(e),u),r=n.getImmediate({identifier:t}),a=(0,s.P0)("functions");return a&&function(e,t,n){(0,s.m9)(e).emulatorOrigin=`http://${t}:${n}`}(r,...a),r}function b(e,t,n){var r;return r=(0,s.m9)(e),e=>(function(e,t,n,r){let i=e._url(t);return m(e,i,n,r)})(r,t,e,n||{})}r=fetch.bind(self),(0,i.Xd)(new a.wA(u,(e,{instanceIdentifier:t})=>{let n=e.getProvider("app").getImmediate(),i=e.getProvider("auth-internal"),s=e.getProvider("messaging-internal"),a=e.getProvider("app-check-internal");return new p(n,i,s,a,t,r)},"PUBLIC").setMultipleInstances(!0)),(0,i.KN)(y,v,void 0),(0,i.KN)(y,v,"esm2017")},7865:function(e,t,n){"use strict";n.d(t,{Z:function(){return a}});var r=n(2265),i={xmlns:"http://www.w3.org/2000/svg",width:24,height:24,viewBox:"0 0 24 24",fill:"none",stroke:"currentColor",strokeWidth:2,strokeLinecap:"round",strokeLinejoin:"round"};let s=e=>e.replace(/([a-z0-9])([A-Z])/g,"$1-$2").toLowerCase();var a=(e,t)=>{let n=(0,r.forwardRef)(({color:n="currentColor",size:a=24,strokeWidth:o=2,absoluteStrokeWidth:l,children:u,...c},h)=>(0,r.createElement)("svg",{ref:h,...i,width:a,height:a,stroke:n,strokeWidth:l?24*Number(o)/Number(a):o,className:`lucide lucide-${s(e)}`,...c},[...t.map(([e,t])=>(0,r.createElement)(e,t)),...(Array.isArray(u)?u:[u])||[]]));return n.displayName=`${e}`,n}},4115:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("AlertCircle",[["circle",{cx:"12",cy:"12",r:"10",key:"1mglay"}],["line",{x1:"12",x2:"12",y1:"8",y2:"12",key:"1pkeuh"}],["line",{x1:"12",x2:"12.01",y1:"16",y2:"16",key:"4dfq90"}]])},4919:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("AlertTriangle",[["path",{d:"m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z",key:"c3ski4"}],["path",{d:"M12 9v4",key:"juzpu7"}],["path",{d:"M12 17h.01",key:"p32p05"}]])},1372:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("ArrowLeft",[["path",{d:"m12 19-7-7 7-7",key:"1l729n"}],["path",{d:"M19 12H5",key:"x3x0zl"}]])},3731:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Briefcase",[["rect",{width:"20",height:"14",x:"2",y:"7",rx:"2",ry:"2",key:"eto64e"}],["path",{d:"M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16",key:"zwj3tp"}]])},9799:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Calendar",[["rect",{width:"18",height:"18",x:"3",y:"4",rx:"2",ry:"2",key:"eu3xkr"}],["line",{x1:"16",x2:"16",y1:"2",y2:"6",key:"m3sa8f"}],["line",{x1:"8",x2:"8",y1:"2",y2:"6",key:"18kwsl"}],["line",{x1:"3",x2:"21",y1:"10",y2:"10",key:"xt86sb"}]])},2609:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("CheckCircle2",[["path",{d:"M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z",key:"14v8dr"}],["path",{d:"m9 12 2 2 4-4",key:"dzmm74"}]])},1666:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("CheckCircle",[["path",{d:"M22 11.08V12a10 10 0 1 1-5.93-9.14",key:"g774vq"}],["polyline",{points:"22 4 12 14.01 9 11.01",key:"6xbx8j"}]])},5131:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("ClipboardList",[["rect",{width:"8",height:"4",x:"8",y:"2",rx:"1",ry:"1",key:"tgr4d6"}],["path",{d:"M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2",key:"116196"}],["path",{d:"M12 11h4",key:"1jrz19"}],["path",{d:"M12 16h4",key:"n85exb"}],["path",{d:"M8 11h.01",key:"1dfujw"}],["path",{d:"M8 16h.01",key:"18s6g9"}]])},8523:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Clock",[["circle",{cx:"12",cy:"12",r:"10",key:"1mglay"}],["polyline",{points:"12 6 12 12 16 14",key:"68esgv"}]])},8499:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("CreditCard",[["rect",{width:"20",height:"14",x:"2",y:"5",rx:"2",key:"ynyp8z"}],["line",{x1:"2",x2:"22",y1:"10",y2:"10",key:"1b3vmo"}]])},1184:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("EyeOff",[["path",{d:"M9.88 9.88a3 3 0 1 0 4.24 4.24",key:"1jxqfv"}],["path",{d:"M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68",key:"9wicm4"}],["path",{d:"M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61",key:"1jreej"}],["line",{x1:"2",x2:"22",y1:"2",y2:"22",key:"a6p6uj"}]])},1023:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Eye",[["path",{d:"M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z",key:"rwhkz3"}],["circle",{cx:"12",cy:"12",r:"3",key:"1v7zrd"}]])},7171:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("FileText",[["path",{d:"M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z",key:"1nnpy2"}],["polyline",{points:"14 2 14 8 20 8",key:"1ew0cm"}],["line",{x1:"16",x2:"8",y1:"13",y2:"13",key:"14keom"}],["line",{x1:"16",x2:"8",y1:"17",y2:"17",key:"17nazh"}],["line",{x1:"10",x2:"8",y1:"9",y2:"9",key:"1a5vjj"}]])},7951:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Filter",[["polygon",{points:"22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3",key:"1yg77f"}]])},6324:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("History",[["path",{d:"M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8",key:"1357e3"}],["path",{d:"M3 3v5h5",key:"1xhq8a"}],["path",{d:"M12 7v5l4 2",key:"1fdv2h"}]])},9105:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Image",[["rect",{width:"18",height:"18",x:"3",y:"3",rx:"2",ry:"2",key:"1m3agn"}],["circle",{cx:"9",cy:"9",r:"2",key:"af1f0g"}],["path",{d:"m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21",key:"1xmnt7"}]])},3774:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("IndianRupee",[["path",{d:"M6 3h12",key:"ggurg9"}],["path",{d:"M6 8h12",key:"6g4wlu"}],["path",{d:"m6 13 8.5 8",key:"u1kupk"}],["path",{d:"M6 13h3",key:"wdp6ag"}],["path",{d:"M9 13c6.667 0 6.667-10 0-10",key:"1nkvk2"}]])},6794:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Loader2",[["path",{d:"M21 12a9 9 0 1 1-6.219-8.56",key:"13zald"}]])},8144:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Mail",[["rect",{width:"20",height:"16",x:"2",y:"4",rx:"2",key:"18n3k1"}],["path",{d:"m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7",key:"1ocrg3"}]])},4785:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("MapPin",[["path",{d:"M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z",key:"2oe9fu"}],["circle",{cx:"12",cy:"10",r:"3",key:"ilqhr7"}]])},1871:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Package",[["path",{d:"M16.5 9.4 7.55 4.24",key:"10qotr"}],["path",{d:"M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z",key:"yt0hxn"}],["polyline",{points:"3.29 7 12 12 20.71 7",key:"ousv84"}],["line",{x1:"12",x2:"12",y1:"22",y2:"12",key:"a4e8g8"}]])},1840:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Phone",[["path",{d:"M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z",key:"foiqr5"}]])},9915:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("RefreshCw",[["path",{d:"M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8",key:"v9h5vc"}],["path",{d:"M21 3v5h-5",key:"1q7to0"}],["path",{d:"M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16",key:"3uifl3"}],["path",{d:"M8 16H3v5",key:"1cv678"}]])},3835:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Search",[["circle",{cx:"11",cy:"11",r:"8",key:"4ej97u"}],["path",{d:"m21 21-4.3-4.3",key:"1qie3q"}]])},7730:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Shield",[["path",{d:"M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z",key:"3xmgem"}]])},9937:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Smartphone",[["rect",{width:"14",height:"20",x:"5",y:"2",rx:"2",ry:"2",key:"1yt0o3"}],["path",{d:"M12 18h.01",key:"mhygvu"}]])},3464:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Star",[["polygon",{points:"12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2",key:"8f66p6"}]])},5779:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("TrendingUp",[["polyline",{points:"22 7 13.5 15.5 8.5 10.5 2 17",key:"126l90"}],["polyline",{points:"16 7 22 7 22 13",key:"kwv8wd"}]])},8882:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("UserCheck",[["path",{d:"M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2",key:"1yyitq"}],["circle",{cx:"9",cy:"7",r:"4",key:"nufk8"}],["polyline",{points:"16 11 18 13 22 9",key:"1pwet4"}]])},9839:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("User",[["path",{d:"M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2",key:"975kel"}],["circle",{cx:"12",cy:"7",r:"4",key:"17ys0d"}]])},6773:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Users",[["path",{d:"M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2",key:"1yyitq"}],["circle",{cx:"9",cy:"7",r:"4",key:"nufk8"}],["path",{d:"M22 21v-2a4 4 0 0 0-3-3.87",key:"kshegd"}],["path",{d:"M16 3.13a4 4 0 0 1 0 7.75",key:"1da9ce"}]])},3385:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Wallet",[["path",{d:"M21 12V7H5a2 2 0 0 1 0-4h14v4",key:"195gfw"}],["path",{d:"M3 5v14a2 2 0 0 0 2 2h16v-5",key:"195n9w"}],["path",{d:"M18 12a2 2 0 0 0 0 4h4v-4Z",key:"vllfpd"}]])},2520:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("Wrench",[["path",{d:"M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z",key:"cbrjhi"}]])},1012:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("XCircle",[["circle",{cx:"12",cy:"12",r:"10",key:"1mglay"}],["path",{d:"m15 9-6 6",key:"1uzhvr"}],["path",{d:"m9 9 6 6",key:"z0biqf"}]])},4862:function(e,t,n){"use strict";n.d(t,{Z:function(){return i}});var r=n(7865);let i=(0,r.Z)("X",[["path",{d:"M18 6 6 18",key:"1bl5f8"}],["path",{d:"m6 6 12 12",key:"d8bk6v"}]])}}]);