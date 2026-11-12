// The one client script: remember the explicit language choice; on entering at the English Home, return to Dutch.
export function langScript(base) {
  return `(function(){var b=${JSON.stringify(base)},k="site-lang";
document.addEventListener("click",function(e){var a=e.target.closest&&e.target.closest("a[data-lang]");if(a){try{localStorage.setItem(k,a.getAttribute("data-lang"))}catch(x){}}});
try{if(location.pathname===b+"/"&&localStorage.getItem(k)==="nl"){document.documentElement.setAttribute("data-lang-pending","");location.replace(b+"/nl/")}}catch(x){}
})();`;
}
