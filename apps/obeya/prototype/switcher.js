// PROTOTYPE switcher: floating bottom bar, left/right arrows cycle variants, reload-stable via ?variant=
(function () {
  var names = { A: 'Orbit (futuristic HUD)', B: 'The Wall (physical Obeya)', C: 'Transit (metro map)' };
  var keys = ['A', 'B', 'C'];
  var cur = window.OBEYA_VARIANT;
  function go(k) { var u = new URL(location.href); u.searchParams.set('variant', k); location.href = u.toString(); }
  function step(d) { go(keys[(keys.indexOf(cur) + d + keys.length) % keys.length]); }

  var st = document.createElement('style');
  st.textContent =
    '#pt-bar{position:fixed;left:50%;bottom:14px;transform:translateX(-50%);z-index:99999;display:flex;align-items:center;gap:10px;' +
    'background:#111;color:#fff;border:2px solid #fff;border-radius:999px;padding:6px 8px;font:600 13px/1 system-ui,sans-serif;' +
    'box-shadow:0 6px 24px rgba(0,0,0,.45)}' +
    '#pt-bar button{all:unset;cursor:pointer;width:30px;height:30px;border-radius:50%;background:#fff;color:#111;text-align:center;line-height:30px;font-size:16px}' +
    '#pt-bar button:hover{background:#ffd23f}' +
    '#pt-bar span{white-space:nowrap}#pt-bar small{opacity:.6;font-weight:500;margin-left:6px}';
  document.head.appendChild(st);

  var bar = document.createElement('div');
  bar.id = 'pt-bar';
  bar.innerHTML = '<button aria-label="previous variant">&#8592;</button><span>' + cur + ' - ' + names[cur] +
    '<small>PROTOTYPE - SAMPLE DATA</small></span><button aria-label="next variant">&#8594;</button>';
  document.body.appendChild(bar);
  bar.children[0].onclick = function () { step(-1); };
  bar.children[2].onclick = function () { step(1); };
  document.addEventListener('keydown', function (e) {
    var t = e.target, tag = t && t.tagName;
    if (tag === 'INPUT' || tag === 'TEXTAREA' || (t && t.isContentEditable)) return;
    if (e.key === 'ArrowLeft') step(-1);
    if (e.key === 'ArrowRight') step(1);
  });
})();
