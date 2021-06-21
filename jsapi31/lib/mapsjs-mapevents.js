
/**
 * The code below uses open source software. Please visit the URL below for an overview of the licenses:
 * http://js.api.here.com/v3/3.1.26.0/HERE_NOTICE
 */

H.util.eval("function Fo(a){var b=a.ownerDocument;b=b.documentElement||b.body.parentNode||b.body;try{var c=a.getBoundingClientRect()}catch(d){c={top:0,right:0,bottom:0,left:0,height:0,width:0}}return{x:c.left+(\"number\"===typeof window.pageXOffset?window.pageXOffset:b.scrollLeft),y:c.top+(\"number\"===typeof window.pageYOffset?window.pageYOffset:b.scrollTop)}}var Go=Function(\"return this\")();function Ho(a,b,c,d,e,f,g){Ho.l.constructor.call(this,a);this.pointers=b;this.changedPointers=c;this.targetPointers=d;this.currentPointer=e;this.originalEvent=g;this.target=f}u(Ho,rd);t(\"H.mapevents.Event\",Ho);function Io(a,b,c,d,e,f){if(isNaN(a))throw Error(\"x needs to be a number\");if(isNaN(b))throw Error(\"y needs to be a number\");if(isNaN(c))throw Error(\"pointer must have an id\");this.viewportX=a;this.viewportY=b;this.target=null;this.id=c;this.type=d;this.dragTarget=null;this.button=tc(e)?e:-1;this.buttons=tc(f)?f:0;this.a=this.button}t(\"H.mapevents.Pointer\",Io);\nfunction Jo(a,b,c){if(isNaN(b))throw Error(\"x needs to be a number\");if(isNaN(c))throw Error(\"y needs to be a number\");a.viewportX=b;a.viewportY=c}Io.prototype.Ym=function(){return this.a};Io.prototype.getLastChangedButton=Io.prototype.Ym;function Ko(a,b){a.a=b;a.buttons|=Io.prototype.b[+b]||0}function Lo(a,b){a.a=b;a.buttons&=~(Io.prototype.b[+b]||0)}Io.prototype.b=[1,4,2];var Mo={NONE:-1,LEFT:0,MIDDLE:1,RIGHT:2};Io.Button=Mo;function No(a){this.a=a instanceof Array?a.slice(0):[]}n=No.prototype;n.clear=function(){this.a.splice(0,this.a.length)};n.length=function(){return this.a.length};n.indexOf=function(a){for(var b=this.a.length;b--;)if(this.a[b].id===a)return b;return-1};function Oo(a,b){b=a.indexOf(b);return-1!==b?a.a[b]:null}n.remove=function(a){a=this.indexOf(a);return-1!==a?this.a.splice(a,1)[0]:null};function Po(a,b){for(var c=a.a.length,d=[];c--;)a.a[c].type!==b&&d.push(a.a[c]);a.a=d}\nfunction Qo(a,b){for(var c=a.a.length;c--;)if(a.a[c].dragTarget===b)return!0;return!1}n.push=function(a){if(a instanceof Io)return this.a.push(a);throw Error(\"list needs a pointer\");};n.Ma=function(){return this.a};n.clone=function(){return new No(this.a)};function Ro(a,b,c){c=c||{};if(!(a instanceof T))throw Error(\"events: map instance required\");if(!(b instanceof Array))throw Error(\"events: map array required\");nd.call(this);this.mh=c.mh||300;this.Dj=c.Dj||50;this.Al=c.Al||50;this.Bl=c.Bl||500;this.Yh=c.Yh||900;this.Xh=c.Xh||8;this.map=a;this.m=this.map.za;this.j=this.m.element;this.G=b;this.a=new No;this.b=new No;this.i={};this.c=null;this.u=!0;this.$={};this.f={};this.o=null;this.Ge=A(this.Ge,this);this.F={pointerdown:this.im,pointermove:this.jm,\npointerup:this.km,pointercancel:this.hm};So(this)}u(Ro,nd);function So(a,b){var c,d=a.G.length;for(c=0;c<d;c++){var e=a.G[c];var f=e.listener;\"function\"===typeof f&&(b?(e.target||a.j).removeEventListener(e.Ta,f):(e.target||a.j).addEventListener(e.Ta,f))}}function To(a,b,c){var d;if(\"function\"===typeof a.F[b]){\"pointermove\"!==b&&(a.u=!0);var e=0;for(d=a.b.length();e<d;e++){var f=a.b.a[e];a.j.contains(c.composedPath()[0])?Uo(a,f,a.Jj.bind(a,c,b,f)):a.Jj(c,b,f,null)}}a.b.clear()}n=Ro.prototype;\nn.Jj=function(a,b,c,d){Vo(c.id,this.$);this.F[b].call(this,c,d,a)};function Uo(a,b,c){if(a.c===b)c(b.target);else{var d=a.m;var e=b.viewportX;b=b.viewportY;if(0>e||0>b||e>=d.width||b>=d.height)c(y);else{var f=a.map;f.$d(e,b,function(g){c(g||f)})}}}\nn.km=function(a,b,c){var d=a.id;a.target=b;Wo(this,a,c);Xo(this,b,\"pointerup\",c,a);\"mouse\"!==a.type&&Xo(this,b,\"pointerleave\",c,a);b=this.i[a.id];var e={x:a.viewportX,y:a.viewportY},f=c.timeStamp,g=a.target,h=this.o;b&&b.target===g&&b.Ce.Za(e)<this.Al&&f-b.aj<this.Bl?(Xo(this,g,\"tap\",c,a),h&&h.target===g&&f-h.aj<this.mh?h.Ce.Za({x:a.viewportX,y:a.viewportY})<this.Dj&&(Xo(this,g,\"dbltap\",c,a),this.o=null):this.o={target:g,Ce:new I(a.viewportX,a.viewportY),aj:c.timeStamp}):this.o=null;this.i={};Vo(d,\nthis.f)};function Wo(a,b,c){b===a.c&&(Xo(a,b.dragTarget,\"dragend\",c,b),a.c=null,Vo(b.id,a.$));b.dragTarget=null}n.Ge=function(a,b){var c=this;Xo(this,a.dragTarget,\"drag\",b,a);Vo(a.id,this.$);this.$[a.id]=setTimeout(function(){c.Ge(a,b)},150)};function Vo(a,b){b[a]&&(b[a].timeout?clearTimeout(b[a].timeout):clearTimeout(b[a]),delete b[a])}\nfunction Yo(a,b,c){var d=b.target,e=new I(b.viewportX,b.viewportY),f=b.id;Vo(f,a.f);var g=setTimeout(function(){d&&d===b.target&&e.Za({x:b.viewportX,y:b.viewportY})<a.Xh&&(Xo(a,d,\"longpress\",c,b),delete a.i[b.id])},a.Yh);a.f[f]={timeout:g,Ce:e}}\nn.jm=function(a,b,c){var d=a.dragTarget,e=a.id;var f=a.target;a.target=b;f!==b&&(Xo(this,f,\"pointerleave\",c,a),Xo(this,b,\"pointerenter\",c,a));d?this.c?(this.Ge(a,c),this.f[e]&&this.f[e].Ce.Za({x:a.viewportX,y:a.viewportY})>this.Xh&&Vo(e,this.f)):this.u?this.u=!1:(this.c=a,Xo(this,d,\"dragstart\",c,a),this.Ge(a,c),delete this.i[e],this.u=!0):(!this.c||this.c&&this.c.dragTarget!==b&&this.c.dragTarget!==this.map)&&Xo(this,b,\"pointermove\",c,a)};\nn.im=function(a,b,c){var d=!(/^(?:mouse|pen)$/.test(a.type)&&0!==c.button);if(b){a.target=b;this.i[a.id]={Ce:new I(a.viewportX,a.viewportY),target:a.target,aj:c.timeStamp};\"mouse\"!==a.type&&Xo(this,b,\"pointerenter\",c,a);var e=Xo(this,b,\"pointerdown\",c,a);!this.c&&d&&(b.draggable&&!Qo(this.a,b)?a.dragTarget=b:!this.map.draggable||e.defaultPrevented||Qo(this.a,this.map)||(a.dragTarget=this.map));Yo(this,a,c)}};\nn.hm=function(a,b,c){var d=a.id;a.target=null;b?(Xo(this,b,\"pointerleave\",c,a),Xo(this,b,\"pointercancel\",c,a)):Xo(this,this.map,\"pointercancel\",c,a);Wo(this,a,c);this.i={};Vo(d,this.f)};function Xo(a,b,c,d,e){if(b&&\"function\"===typeof b.dispatchEvent){var f=Ho;var g=a.a.Ma(),h=a.b.Ma();a=a.a;var k,l=a.a.length,m=[];for(k=0;k<l;k++)a.a[k].target===b&&m.push(a.a[k]);f=new f(c,g,h,m,e,b,d);e.button=/^(?:longpress|(?:dbl)?tap|pointer(?:down|up))$/.test(c)?e.a:Mo.NONE;b.dispatchEvent(f)}return f}\nn.s=function(){So(this,!0);this.a.clear();this.b.clear();var a=this.$,b;for(b in a)Vo(b,a);a=this.f;for(var c in a)Vo(c,a);this.c=this.i=this.o=this.map=this.b=this.a=this.G=this.R=null;nd.prototype.s.call(this)};function Zo(a){this.g=A(this.g,this);Ro.call(this,a,[{Ta:\"touchstart\",listener:this.g},{Ta:\"touchmove\",listener:this.g},{Ta:\"touchend\",listener:this.g},{Ta:\"touchcancel\",listener:this.g}]);this.L={touchstart:\"pointerdown\",touchmove:\"pointermove\",touchend:\"pointerup\",touchcancel:\"pointercancel\"};this.v=(a=(a=a.o)?a.N():null)?Array.prototype.slice.call(a.querySelectorAll(\"a\"),0):[]}u(Zo,Ro);\nZo.prototype.g=function(a){var b=a.touches,c=this.a.length(),d;if(\"touchstart\"===a.type&&c>=b.length){c=this.a.clone();for(d=b.length;d--;)c.remove(b[d].identifier);for(d=c.length();d--;)this.a.remove(c.a[d].id);this.b=c;To(this,\"pointercancel\",a);this.b.clear()}if(this.L[a.type]){b=Fo(this.m.element);c=a.type;d=a.changedTouches;var e=d.length,f;this.b.clear();for(f=0;f<e;f++){var g=d[f];var h=Oo(this.a,g.identifier);var k=g.pageX-b.x;var l=g.pageY-b.y;if(h)if(\"touchmove\"===c){g=Math.abs(h.viewportX-\nk);var m=Math.abs(h.viewportY-l);if(1<g||1<m||1===g&&1===m)Jo(h,k,l),this.b.push(h)}else\"touchend\"===c&&(this.a.remove(h.id),this.b.push(h),Lo(h,Mo.LEFT));else h=new Io(k,l,g.identifier,\"touch\",Mo.LEFT,1),this.a.push(h),this.b.push(h)}To(this,this.L[a.type],a);-1===this.v.indexOf(a.target)&&a.preventDefault()}};Zo.prototype.s=function(){this.v=null;Ro.prototype.s.call(this)};function $o(a){var b=ap(this);(window.PointerEvent||window.MSPointerEvent)&&b.push({Ta:\"MSHoldVisual\",listener:\"prevent\"});Ro.call(this,a,b)}u($o,Ro);function ap(a){var b=!!window.PointerEvent,c,d,e=[];a.g=A(a.g,a);\"MSPointerDown MSPointerMove MSPointerUp MSPointerCancel MSPointerOut MSPointerOver\".split(\" \").forEach(function(f){c=f.toLowerCase().replace(/ms/g,\"\");d=b?c:f;e.push({Ta:d,listener:a.g,target:/^pointer(up|move)$/.test(c)?window:null})});return e}var bp={2:\"touch\",3:\"pen\",4:\"mouse\"};\n$o.prototype.g=function(a){var b=window.PointerEvent?a.type:a.type.toLowerCase().replace(/ms/g,\"\"),c=Fo(this.j),d=Oo(this.a,a.pointerId),e=a.pageX-c.x;c=a.pageY-c.y;var f=bp[a.pointerType]||a.pointerType;$c&&\"rtl\"===x.getComputedStyle(this.m.element).direction&&(e-=(x.devicePixelRatio-1)*this.m.width);if(!(d||/^pointer(up|out|cancel)$/.test(b)||\"touch\"===f&&\"pointerdown\"!==b)){d={x:e,y:c};var g=a.pointerType;\"number\"===typeof g&&(g=bp[g]);d=new Io(d.x,d.y,a.pointerId,g,a.button,a.buttons);this.a.push(d)}if(d)if(/^pointer(up|cancel)$/.test(b)?\n(\"touch\"===f&&this.a.remove(d.id),Lo(d,a.button)):\"pointerdown\"===b&&(\"touch\"===a.pointerType&&(Po(this.a,\"mouse\"),Po(this.a,\"pen\")),Ko(d,a.button)),this.b.push(d),\"pointermove\"!==b)Jo(d,e,c),To(this,/^pointer(over|out)$/.test(b)?\"pointermove\":b,a);else if(d.viewportX!==e||d.viewportY!==c)Jo(d,e,c),To(this,b,a);this.b.clear()};function cp(a,b,c,d){cp.l.constructor.call(this,\"contextmenu\");this.items=[];this.viewportX=a;this.viewportY=b;this.target=c;this.originalEvent=d}u(cp,rd);t(\"H.mapevents.ContextMenuEvent\",cp);function dp(a){this.Jh=A(this.Jh,this);this.Lh=A(this.Lh,this);this.Kh=A(this.Kh,this);this.v=!1;this.g=-1;this.L=0;dp.l.constructor.call(this,a,[{Ta:\"contextmenu\",listener:this.Jh},{target:a,Ta:\"longpress\",listener:this.Lh},{target:a,Ta:\"dbltap\",listener:this.Kh}])}u(dp,Ro);n=dp.prototype;n.Lh=function(a){var b=a.currentPointer;\"touch\"===b.type&&1===a.pointers.length&&ep(this,b.viewportX,b.viewportY,a.originalEvent,a.target)};n.Kh=function(a){\"touch\"===a.currentPointer.type&&(this.L=Date.now())};\nn.Jh=function(a){var b=this;-1===this.g?this.g=setTimeout(function(){var c=Fo(b.j),d=a.pageX-c.x;c=a.pageY-c.y;b.g=-1;ep(b,d,c,a)},this.mh):(clearInterval(this.g),this.g=-1);a.preventDefault()};function ep(a,b,c,d,e){var f=a.map,g=Date.now()-a.L;e?!a.v&&g>a.Yh&&(a.v=!0,e.dispatchEvent(new cp(b,c,e,d)),Ce(f.N(),a.jj,a.Ij,!1,a)):f.$d(b,c,a.no.bind(a,b,c,d))}n.no=function(a,b,c,d){d=d&&Ca(d.dispatchEvent)?d:this.map;ep(this,a,b,c,d)};n.jj=[\"mousedown\",\"touchstart\",\"pointerdown\",\"wheel\"];\nn.Ij=function(){this.v&&(this.v=!1,this.map.dispatchEvent(new rd(\"contextmenuclose\",this.map)))};n.s=function(){var a=this.map.N();clearInterval(this.g);a&&Je(a,this.jj,this.Ij,!1,this);Ro.prototype.s.call(this)};function fp(a,b,c,d,e){fp.l.constructor.call(this,\"wheel\");this.delta=a;this.viewportX=b;this.viewportY=c;this.target=d;this.originalEvent=e}u(fp,rd);t(\"H.mapevents.WheelEvent\",fp);function gp(a){var b=\"onwheel\"in document;this.S=b;this.L=(b?\"d\":\"wheelD\")+\"elta\";this.g=A(this.g,this);gp.l.constructor.call(this,a,[{Ta:(b?\"\":\"mouse\")+\"wheel\",listener:this.g}]);this.v=this.map.za}u(gp,Ro);\ngp.prototype.g=function(a){if(!a.Ll){var b=Fo(this.j);var c=a.pageX-b.x;b=a.pageY-b.y;var d=this.L,e=a[d+(d+\"Y\"in a?\"Y\":\"\")],f;$c&&\"rtl\"===x.getComputedStyle(this.v.element).direction&&(c-=(x.devicePixelRatio-1)*this.v.width);if(e){var g=Math.abs;var h=g(e);e=(!(f=a[d+\"X\"])||3<=h/g(f))&&(!(f=a[d+\"Z\"])||3<=h/g(f))?((0<e)-(0>e))*(this.S?1:-1):0}c=new fp(e,c,b,null,a);c.delta&&(a.stopImmediatePropagation(),a.preventDefault(),this.map.$d(c.viewportX,c.viewportY,this.U.bind(this,c)))}};\ngp.prototype.U=function(a,b){var c=a.target=b||this.map,d,e;setTimeout(function(){c.dispatchEvent(a);a.f||(d=a.originalEvent,e=new x.WheelEvent(\"wheel\",d),e.Ll=1,d.target.dispatchEvent(e))},0)};function hp(a){this.g=A(this.g,this);Ro.call(this,a,[{Ta:\"mousedown\",listener:this.g},{Ta:\"mousemove\",listener:this.g,target:window},{Ta:\"mouseup\",listener:this.g,target:window},{Ta:\"mouseover\",listener:this.g},{Ta:\"mouseout\",listener:this.g},{Ta:\"dragstart\",listener:this.v}])}u(hp,Ro);\nhp.prototype.g=function(a){var b=a.type,c=Fo(this.j);c={x:a.pageX-c.x,y:a.pageY-c.y};var d;(d=this.a.a[0])||(d=new Io(c.x,c.y,1,\"mouse\"),this.a.push(d));this.b.push(d);Jo(d,c.x,c.y);/^mouse(?:move|over|out)$/.test(b)?To(this,\"pointermove\",a):(/^mouse(down|up)$/.test(b)&&(c=a.which-1,\"up\"===Go.RegExp.$1?Lo(d,c):Ko(d,c)),To(this,b.replace(\"mouse\",\"pointer\"),a));this.b.clear()};hp.prototype.v=function(a){a.preventDefault()};function ip(a){var b=a.za.element.style;if(-1!==jp.indexOf(a))throw Error(\"InvalidArgument: map is already in use\");this.a=a;jp.push(a);b.msTouchAction=b.touchAction=\"none\";ad||!window.PointerEvent&&!window.MSPointerEvent?(this.c=new Zo(this.a),this.b=new hp(this.a)):this.c=new $o(this.a);this.g=new gp(this.a);this.f=new dp(this.a);this.a.xb(this.B,this);nd.call(this)}u(ip,nd);t(\"H.mapevents.MapEvents\",ip);ip.prototype.c=null;ip.prototype.b=null;ip.prototype.g=null;ip.prototype.f=null;\nvar jp=[];Fc(jp);ip.prototype.B=function(){this.a=null;this.c.B();this.g.B();this.f.B();this.b&&this.b.B();jp.splice(jp.indexOf(this.a),1);nd.prototype.B.call(this)};ip.prototype.dispose=ip.prototype.B;ip.prototype.vm=function(){return this.a};ip.prototype.getAttachedMap=ip.prototype.vm;function kp(a,b){b=void 0===b?{}:b;var c;kp.l.constructor.call(this);if(-1!==lp.indexOf(a))throw new D(kp,0,\"events are already used\");this.a=c=a.a;this.j=a;lp.push(a);c.draggable=!0;this.i=b.kinetics||{duration:600,ease:Nl};this.o=b.modifierKey||\"Alt\";this.enable(b.enabled);this.c=c.za;this.f=this.c.element;this.g=0;c.addEventListener(\"dragstart\",this.hi,!1,this);c.addEventListener(\"drag\",this.zk,!1,this);c.addEventListener(\"dragend\",this.gi,!0,this);c.addEventListener(\"wheel\",this.Pk,!1,this);c.addEventListener(\"dbltap\",\nthis.Kk,!1,this);c.addEventListener(\"pointermove\",this.Ak,!1,this);Be(this.f,\"contextmenu\",this.yk,!1,this);a.xb(this.B,this)}u(kp,nd);t(\"H.mapevents.Behavior\",kp);var lp=[];Fc(lp);kp.prototype.b=0;var mp={PANNING:1,PINCH_ZOOM:2,WHEEL_ZOOM:4,DBL_TAP_ZOOM:8,FRACTIONAL_ZOOM:16,TILT:32,HEADING:64};kp.Feature=mp;var np=mp.PANNING,op=mp.PINCH_ZOOM,pp=mp.WHEEL_ZOOM,qp=mp.DBL_TAP_ZOOM,rp=mp.FRACTIONAL_ZOOM,sp=mp.TILT,tp=mp.HEADING,up=np|op|pp|qp|rp|sp|tp;kp.DRAGGING=np;kp.WHEELZOOM=pp;\nkp.DBLTAPZOOM=qp;kp.FRACTIONALZOOM=rp;function vp(a,b){if(a!==+a||a%1||0>a||2147483647<a)throw new D(b,0,\"integer in range [0...0x7FFFFFFF] required\");}kp.prototype.disable=function(a){var b=this.b;a!==B?(vp(a,this.disable),b^=b&a):b=0;this.c.endInteraction(!0);this.b=b;this.a.draggable=0<(b&(np|sp|tp|op))};kp.prototype.disable=kp.prototype.disable;kp.prototype.enable=function(a){var b=this.b;a!==B?(vp(a,this.enable),b|=a&up):b=up;this.b=b;this.a.draggable=0<(b&(np|sp|tp|op))};\nkp.prototype.enable=kp.prototype.enable;kp.prototype.isEnabled=function(a){vp(a,this.isEnabled);return a===(this.b&a)};kp.prototype.isEnabled=kp.prototype.isEnabled;\nfunction wp(a,b,c){var d=\"touch\"===b.currentPointer.type,e=0,f;if(f=!d){f=a.o;var g,h=b.originalEvent;h.getModifierState?g=h.getModifierState(f):g=!!h[f.replace(/^Control$/,\"ctrl\").toLowerCase()+\"Key\"];f=g}f?e|=sp|tp:(e|=np,d&&(b=b.pointers,2===b.length&&(e|=op|tp,c?55>Ad(b[0].viewportY-b[1].viewportY)&&(e|=sp):a.Ph&ul.TILT&&(e|=sp))));e&=a.b;return(e&sp?ul.TILT:0)|(e&tp?ul.HEADING:0)|(e&op?ul.ZOOM:0)|(e&np?ul.COORD:0)}\nfunction xp(a){var b=a.pointers;a=b[0];b=b[1];a=[a.viewportX,a.viewportY];b&&a.push(b.viewportX,b.viewportY);return a}n=kp.prototype;n.Ph=0;n.hi=function(a){var b=wp(this,a,!0);if(this.Ph=b){var c=this.c;a=xp(a);c.startInteraction(b,this.i);c.interaction.apply(c,a);if(this.b&pp&&!(this.b&rp)&&(b=a[0],c=a[1],this.g)){a=this.a.ub();var d=(0>this.g?zd:yd)(a);a!==d&&(this.g=0,yp(this,a,d,b,c))}}};\nn.zk=function(a){var b=wp(this,a,!1);if(b!==this.Ph)\"pointerout\"!==a.originalEvent.type&&\"pointerover\"!==a.originalEvent.type&&(this.gi(a),this.hi(a));else if(b){b=this.c;var c=xp(a);b.interaction.apply(b,c);a.originalEvent.preventDefault()}};n.gi=function(a){wp(this,a,!1)&&this.c.endInteraction(!this.i)};\nfunction yp(a,b,c,d,e){var f=+c-+b;a=a.a.b;if(isNaN(+b))throw Error(\"start zoom needs to be a number\");if(isNaN(+c))throw Error(\"to zoom needs to be a number\");0!==f&&(a.startControl(null,d,e),a.control(0,0,6,0,0,0),a.endControl(!0,function(g){g.zoom=c}))}n.Pk=function(a){if(!a.defaultPrevented&&this.b&pp){var b=a.delta;var c=this.a.ub();var d=this.a;var e=d.fc().type;d=this.b&rp?c-b:(0>-b?zd:yd)(c)-b;if(e===un.P2D||e===un.WEBGL||e===un.HARP)yp(this,c,d,a.viewportX,a.viewportY),this.g=b;a.preventDefault()}};\nn.Ak=function(){};n.Kk=function(a){var b=a.currentPointer,c=this.a.ub(),d=a.currentPointer.type,e=this.a.fc().type;(e===un.P2D||e===un.WEBGL||e===un.HARP)&&this.b&qp&&(a=\"mouse\"===d?0===a.originalEvent.button?-1:1:0<a.pointers.length?1:-1,a=this.b&rp?c-a:(0>-a?zd:yd)(c)-a,yp(this,c,a,b.viewportX,b.viewportY))};n.yk=function(a){return this.b&qp?(a.preventDefault(),!1):!0};\nn.B=function(){var a=this.a;a&&(a.draggable=!1,a.removeEventListener(\"dragstart\",this.hi,!1,this),a.removeEventListener(\"drag\",this.zk,!1,this),a.removeEventListener(\"dragend\",this.gi,!0,this),a.removeEventListener(\"wheel\",this.Pk,!1,this),a.removeEventListener(\"dbltap\",this.Kk,!1,this),a.removeEventListener(\"pointermove\",this.Ak,!1,this),this.a=null);this.f&&(this.f.style.msTouchAction=\"\",Je(this.f,\"contextmenu\",this.yk,!1,this),this.f=null);this.i=this.c=null;lp.splice(lp.indexOf(this.j),1);nd.prototype.B.call(this)};\nkp.prototype.dispose=kp.prototype.B;t(\"H.mapevents.buildInfo\",function(){return Ef(\"H-mapevents\",\"1.26.0\",\"a2dc7f9\")});\n");