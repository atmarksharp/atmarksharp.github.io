/*
* Check Mobile Css - css-mobile.js
*
* License:
*
*   Public Domain
*
* Dependency:
*
*   contentloaded.js (https://github.com/dperini/ContentLoaded)
*   mobile-detect.js (https://github.com/hgoebl/mobile-detect.js)
*
* Usage: 
*
*   1. Insert mobile-detect.js and this library like below.
*
*       <script src="js/contentloaded.js"></script>
*       <script src="js/mobile-detect.js"></script>
*       <script src="js/css-mobile.js"></script>
*
*   2. Add your tag the class "check-mobile" like below.
*
*       <div class="check-mobile"> ... </div>
*
*   3. Then, your tag will get class in runtime.
*
*       <div class="mobile webkit"> ... </div>
*
* Configure:
*
*   var css_mobile_prefix = 'cm_' // '' is default
*
*      This will change class names (ex. mobile) to prepend the prefix (ex. cm_mobile.)
*
*      << NOTE >>: Please set this var before [Usage 1.]
*/

(function(){
  // var _ua = (function(){
  //  return {
  //   ltIE6:typeof window.addEventListener == "undefined" && typeof document.documentElement.style.maxHeight == "undefined",
  //   ltIE7:typeof window.addEventListener == "undefined" && typeof document.querySelectorAll == "undefined",
  //   ltIE8:typeof window.addEventListener == "undefined" && typeof document.getElementsByClassName == "undefined",
  //   ltIE9:document.uniqueID && !window.matchMedia,
  //   gtIE10:document.uniqueID && document.documentMode >= 10,
  //   Trident:document.uniqueID,
  //   Gecko:'MozAppearance' in document.documentElement.style,
  //   Presto:window.opera,
  //   Blink:window.chrome,
  //   Webkit:!window.chrome && 'WebkitAppearance' in document.documentElement.style,
  //   Touch:typeof document.ontouchstart != "undefined",
  //   Mobile:typeof window.orientation != "undefined",
  //   Pointer:window.navigator.pointerEnabled,
  //   MSPoniter:window.navigator.msPointerEnabled
  //  }
  // })();

  var md = new MobileDetect(window.navigator.userAgent);

  var _cpf = (window['css_mobile_prefix'] !== undefined)? window['css_mobile_prefix'] : false;
  var _pf = (_cpf)? _cpf : '';

  var _c = [];
  if(md.tablet()){
    _c.push(_pf + "tablet")
  }else if(md.mobile()){
    _c.push(_pf + "mobile")
  }else{
    _c.push(_pf + "desktop")
  }

  var cls = _c.join(" ");

  contentLoaded(window, function(){
    var l = document.querySelectorAll(".check-mobile");
    var len = l.length;
    for(var i=0;i<len;i++){
      var a = l[i];
      a.className = a.className.replace("check-mobile", "");
      a.className+=" "+cls;
    }
  });
})();