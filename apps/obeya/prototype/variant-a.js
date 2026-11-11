// PROTOTYPE variant A - "Orbit": futuristic mission-control HUD.
// Idea: the direction is the core; every work item orbits it, nearer = closer to done-with-you. The radar sweeps the rings.
(function () {
  var O = window.OBEYA;
  document.title = 'OBEYA // ' + O.project.name;

  var css = `
  :root{--bg:#04060c;--cy:#3df5ff;--mg:#ff3d8b;--am:#ffb000;--lm:#7dff6b;--rd:#ff4d4d;--dim:#6b7a99;--ink:#d8f6ff}
  *{box-sizing:border-box}
  html,body{margin:0;background:var(--bg);color:var(--ink);font:12px/1.45 "SF Mono","JetBrains Mono",ui-monospace,Menlo,monospace;min-height:100vh}
  body{background:
     radial-gradient(1200px 700px at 50% 38%,rgba(20,60,110,.45),transparent 70%),
     linear-gradient(rgba(61,245,255,.045) 1px,transparent 1px) 0 0/44px 44px,
     linear-gradient(90deg,rgba(61,245,255,.045) 1px,transparent 1px) 0 0/44px 44px,var(--bg);padding-bottom:70px}
  body::after{content:"";position:fixed;inset:0;pointer-events:none;z-index:50;
     background:repeating-linear-gradient(0deg,rgba(0,0,0,.18) 0,rgba(0,0,0,.18) 1px,transparent 1px,transparent 3px);mix-blend-mode:multiply}
  h1,h2,h3{margin:0;font-weight:600;letter-spacing:.18em;text-transform:uppercase}
  .top{display:flex;align-items:center;gap:18px;padding:10px 18px;border-bottom:1px solid rgba(61,245,255,.3);
     background:linear-gradient(90deg,rgba(61,245,255,.12),transparent 60%)}
  .brand{font-size:15px;letter-spacing:.3em;color:var(--cy);text-shadow:0 0 12px var(--cy)}
  .brand b{color:#fff}
  .chips{display:flex;gap:8px;flex-wrap:wrap;flex:1}
  .chip{border:1px solid rgba(61,245,255,.35);padding:2px 8px;color:var(--cy);font-size:10.5px;letter-spacing:.12em;text-transform:uppercase}
  .chip.ok{color:var(--lm);border-color:rgba(125,255,107,.45)}
  .sync{display:flex;align-items:center;gap:8px;color:var(--dim);font-size:10.5px;letter-spacing:.12em}
  .grid{display:grid;grid-template-columns:330px minmax(480px,1fr) 340px;gap:14px;padding:14px 18px}
  .col{display:flex;flex-direction:column;gap:14px;min-width:0}
  .panel{position:relative;border:1px solid rgba(61,245,255,.3);background:rgba(7,14,28,.72);padding:12px 14px;backdrop-filter:blur(2px)}
  .panel::before,.panel::after{content:"";position:absolute;width:12px;height:12px;border:2px solid var(--cy);filter:drop-shadow(0 0 4px var(--cy))}
  .panel::before{left:-2px;top:-2px;border-right:0;border-bottom:0}
  .panel::after{right:-2px;bottom:-2px;border-left:0;border-top:0}
  .panel h2{font-size:10.5px;color:var(--cy);margin-bottom:8px;display:flex;justify-content:space-between;align-items:center}
  .panel h2 em{font-style:normal;color:var(--dim);letter-spacing:.08em}
  .goal{font-size:15px;line-height:1.45;color:#fff;text-shadow:0 0 14px rgba(61,245,255,.5)}
  .head{margin-top:10px;color:var(--am)}
  .head::before{content:"> HEADING  ";color:var(--dim)}
  .head::after{content:"\\2588";animation:blink 1s steps(2) infinite;margin-left:3px}
  @keyframes blink{50%{opacity:0}}
  .tag{display:inline-block;padding:0 6px;border:1px solid currentColor;font-size:10px;letter-spacing:.1em;text-transform:uppercase}
  .tag.m{color:var(--lm)} .tag.f{color:var(--am);border-style:dashed} .tag.e{color:var(--cy)}
  .log div{padding:5px 0;border-top:1px dashed rgba(61,245,255,.18)} .log div:first-child{border-top:0}
  .log b{color:var(--cy);font-weight:500}.log i{color:var(--dim);font-style:normal}
  .need{color:var(--mg);animation:glow 2s ease-in-out infinite}
  @keyframes glow{50%{text-shadow:0 0 12px var(--mg)}}
  .dc{padding:7px 8px;margin-top:6px;border-left:3px solid var(--mg);background:rgba(255,61,139,.08)}
  .dc small{color:var(--dim)} .dc strong{color:#fff;font-weight:500}
  #orbit{width:100%;height:auto;display:block;overflow:visible}
  .ringlbl{font-size:8.5px;fill:var(--dim);letter-spacing:.2em}
  .node{cursor:pointer}
  .node text{font-size:8.5px;fill:#fff;text-anchor:middle;pointer-events:none}
  .node:hover circle.body{filter:drop-shadow(0 0 8px currentColor)}
  .node.sel circle.sel{opacity:1}
  circle.sel{opacity:0;stroke:#fff;fill:none;stroke-width:1.2}
  .pulse{transform-box:fill-box;transform-origin:center;animation:pulse 1.6s ease-out infinite}
  @keyframes pulse{0%{transform:scale(1);opacity:.9}100%{transform:scale(2.6);opacity:0}}
  .insp dl{display:grid;grid-template-columns:86px 1fr;gap:4px 8px;margin:8px 0 0}
  .insp dt{color:var(--dim)} .insp dd{margin:0}
  .insp .big{font-size:14px;color:#fff;margin-top:6px}
  .alert{border:1px solid var(--rd);background:rgba(255,77,77,.1);padding:10px;animation:alarm 1.4s ease-in-out infinite;position:relative}
  @keyframes alarm{50%{box-shadow:0 0 22px rgba(255,77,77,.55) inset;border-color:#ff9a9a}}
  .alert b{color:var(--rd);letter-spacing:.2em}
  .ok-line{color:var(--lm);margin-top:8px;padding-top:8px;border-top:1px dashed rgba(125,255,107,.3)}
  .glitch{position:relative;color:var(--am);border:1px dashed var(--am);padding:8px;background:repeating-linear-gradient(45deg,rgba(255,176,0,.08) 0 6px,transparent 6px 12px)}
  .glitch .t{animation:gl 3s infinite steps(1);display:block;color:#fff}
  @keyframes gl{0%,92%{transform:none;text-shadow:none}93%{transform:translateX(-2px);text-shadow:2px 0 var(--mg),-2px 0 var(--cy)}95%{transform:translateX(3px)}97%{transform:none;text-shadow:none}}
  .foot{display:grid;grid-template-columns:1.1fr 1fr;gap:14px;padding:0 18px 14px}
  .rail{display:flex;gap:4px;flex-wrap:wrap;margin-top:4px}
  .seg{flex:1;min-width:24px;height:26px;border:1px solid var(--cy);background:linear-gradient(rgba(61,245,255,.55),rgba(61,245,255,.12));
     color:#001317;font-size:9px;display:flex;align-items:center;justify-content:center;cursor:default;font-weight:700}
  .seg:hover{background:var(--cy)}
  .seg.p{flex:0 0 46px;border-color:var(--mg);border-style:dashed;background:transparent;color:var(--mg);animation:flick 2.4s infinite}
  @keyframes flick{0%,100%{opacity:1}48%{opacity:1}50%{opacity:.35}52%{opacity:1}}
  #readout{margin-top:8px;color:var(--ink);min-height:18px}
  .feed{max-height:210px;overflow:auto}
  .feed div{display:grid;grid-template-columns:84px 70px 1fr auto;gap:8px;padding:4px 0;border-top:1px dashed rgba(61,245,255,.15);align-items:baseline}
  .feed div:first-child{border-top:0}
  .src{color:var(--cy)} .time{color:var(--dim)} .o{font-size:10px;text-transform:uppercase;letter-spacing:.1em;white-space:nowrap}
  .o.slice-candidate{color:var(--lm)} .o.research-ticket{color:var(--cy)} .o.rejected{color:var(--dim)} .o.needs-you{color:var(--mg)} .o.parked{color:var(--am)} .o.direction{color:#fff}
  .legend{display:flex;gap:12px;flex-wrap:wrap;color:var(--dim);font-size:10px;margin-top:6px}
  .legend span::before{content:"";display:inline-block;width:8px;height:8px;border-radius:50%;background:var(--c);margin-right:5px;vertical-align:-1px;box-shadow:0 0 6px var(--c)}
  @media (max-width:1100px){.grid,.foot{grid-template-columns:1fr}}
  `;
  var st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

  var colors = { 'Running': '#3df5ff', 'Waiting on you': '#ff3d8b', 'Blocked': '#ff4d4d', 'Ready': '#7dff6b', 'Backlog': '#6b7a99', 'Done': '#2a8f87' };
  var radii = { 'Running': 95, 'Waiting on you': 150, 'Blocked': 205, 'Ready': 260, 'Backlog': 315, 'Done': 362 };

  // ---- orbit svg
  var svg = '<svg id="orbit" viewBox="-390 -390 780 780" role="img" aria-label="Work items orbiting the project direction">' +
    '<defs><radialGradient id="core"><stop offset="0" stop-color="#3df5ff" stop-opacity=".55"/><stop offset="1" stop-color="#3df5ff" stop-opacity="0"/></radialGradient>' +
    '<linearGradient id="sweep" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3df5ff" stop-opacity="0"/><stop offset="1" stop-color="#3df5ff" stop-opacity=".38"/></linearGradient></defs>';
  O.statuses.forEach(function (s) {
    svg += '<circle r="' + radii[s] + '" fill="none" stroke="' + colors[s] + '" stroke-opacity="' + (s === 'Done' ? .22 : .3) + '" stroke-dasharray="' + (s === 'Backlog' ? '2 6' : s === 'Done' ? '1 3' : '0') + '"/>';
    svg += '<text class="ringlbl" x="8" y="' + (-radii[s] + 12) + '">' + s.toUpperCase() + ' &#183; ' + O.by(s).length + '</text>';
  });
  svg += '<g><animateTransform attributeName="transform" type="rotate" from="0" to="360" dur="9s" repeatCount="indefinite"/>' +
    '<path d="M0 0 L380 0 A380 380 0 0 0 ' + (380 * Math.cos(-0.7)).toFixed(1) + ' ' + (380 * Math.sin(-0.7)).toFixed(1) + ' Z" fill="url(#sweep)"/>' +
    '<line x1="0" y1="0" x2="380" y2="0" stroke="#3df5ff" stroke-opacity=".8"/></g>';
  svg += '<circle r="64" fill="url(#core)"/><circle r="46" fill="#04101c" stroke="#3df5ff" stroke-width="1.5"/>' +
    '<circle r="54" fill="none" stroke="#3df5ff" stroke-opacity=".5" stroke-dasharray="3 5"><animateTransform attributeName="transform" type="rotate" from="360" to="0" dur="24s" repeatCount="indefinite"/></circle>' +
    '<text y="-4" text-anchor="middle" fill="#fff" font-size="10" letter-spacing="3">DIRECTION</text>' +
    '<text y="10" text-anchor="middle" fill="#6b7a99" font-size="7.5">docs/direction.md</text>';
  var nodes = {};
  O.statuses.forEach(function (s) {
    var list = O.by(s);
    list.forEach(function (b, i) {
      var a = (-90 + 360 * (i + .5) / list.length + (s === 'Ready' ? 14 : s === 'Blocked' ? -20 : 0)) * Math.PI / 180;
      var x = Math.cos(a) * radii[s], y = Math.sin(a) * radii[s], c = colors[s];
      nodes[b.n] = b;
      svg += '<g class="node" data-n="' + b.n + '" transform="translate(' + x.toFixed(1) + ' ' + y.toFixed(1) + ')" style="color:' + c + '">' +
        (s === 'Waiting on you' ? '<circle class="pulse" r="15" fill="none" stroke="' + c + '" stroke-width="1.5"/>' : '') +
        (s === 'Running' ? '<circle class="pulse" r="15" fill="' + c + '" fill-opacity=".25"/>' : '') +
        '<circle class="body" r="15" fill="#04101c" stroke="' + c + '" stroke-width="' + (s === 'Backlog' ? 1 : 2) + '"' + (b.prov === 'merged' ? '' : ' stroke-dasharray="3 3"') + '/>' +
        '<circle class="sel" r="21"/>' +
        (s === 'Blocked' ? '<path d="M-7 -7 L7 7 M7 -7 L-7 7" stroke="' + c + '" stroke-width="2"/>' : '<text y="3">' + b.n + '</text>') +
        '</g>';
    });
  });
  svg += '</svg>';

  // ---- panels
  var d = O.direction;
  var waitingItems = O.by('Waiting on you');
  var left =
    '<div class="panel"><h2>North star <span class="tag m">' + d.prov + '</span></h2><div class="goal">' + O.esc(d.goal) + '</div>' +
    '<div class="head">' + O.esc(d.heading) + '</div></div>' +
    '<div class="panel"><h2>Direction log <em>' + d.source + '</em></h2><div class="log">' +
    d.history.slice().reverse().map(function (h) { return '<div><i>' + h.date + '</i> <b>' + O.esc(h.idea) + '</b><br>' + O.esc(h.effect) + '</div>'; }).join('') + '</div></div>' +
    '<div class="panel"><h2><span class="need">&#9888; Needs you</span><em>' + (O.pending.filter(function (p) { return p.waiting !== 'not yet asked'; }).length + waitingItems.length) + ' open</em></h2>' +
    waitingItems.map(function (b) { return '<div class="dc"><strong>#' + b.n + ' ' + O.esc(b.title) + '</strong><br><small>' + O.esc(b.note || '') + ' &#183; waiting ' + b.since + '</small></div>'; }).join('') +
    O.pending.filter(function (p) { return p.waiting !== 'not yet asked'; }).map(function (p) {
      return '<div class="dc"><strong>' + p.id + '</strong> ' + O.esc(p.title) + '<br><small>' + p.door + ' door &#183; waiting ' + p.waiting + ' &#183; ' + O.provText(p.prov) + '</small></div>'; }).join('') + '</div>';

  var open = O.andon.filter(function (a) { return a.open; }), shut = O.andon.filter(function (a) { return !a.open; });
  var right =
    '<div class="panel insp" id="insp"></div>' +
    '<div class="panel"><h2>Andon <em>' + open.length + ' open</em></h2>' +
    open.map(function (a) { return '<div class="alert"><b>&#9632; STOP ' + a.id + '</b> &#183; #' + a.item + '<br>' + O.esc(a.title) + '<br><small style="color:var(--dim)">raised ' + a.raised + ' &#183; owner ' + a.owner + '</small></div>'; }).join('') +
    shut.map(function (a) { return '<div class="ok-line">&#10003; ' + a.id + ' resolved &#183; #' + a.item + '<br><small>' + O.esc(a.fix) + '</small></div>'; }).join('') + '</div>' +
    '<div class="panel"><h2>Signal integrity <em>' + O.parseFailures.length + ' corrupt</em></h2>' +
    O.parseFailures.map(function (p) { return '<div class="glitch"><span class="t">CAN&#39;T PARSE THIS ARTIFACT</span><small>' + O.esc(p.path) + '</small><br>' + O.esc(p.reason) + '<br><span class="tag f">' + O.provText(p.prov) + '</span></div>'; }).join('') + '</div>';

  var foot =
    '<div class="panel"><h2>Decisions <em>' + O.adrs.length + ' made &#183; ' + O.pending.length + ' ahead</em></h2><div class="rail">' +
    O.adrs.map(function (a) { return '<div class="seg" data-t="' + a.id + ' &#183; ' + O.esc(a.title) + ' &#183; merged">' + ('0' + a.n).slice(-2) + '</div>'; }).join('') +
    O.pending.map(function (p) { return '<div class="seg p" data-t="' + p.id + ' &#183; ' + O.esc(p.title) + ' &#183; ' + p.door + ' door &#183; ' + O.provText(p.prov) + '">' + p.id.replace('ADR-00', 'A').replace('DC-0', 'D') + '</div>'; }).join('') +
    '</div><div id="readout">hover a segment</div></div>' +
    '<div class="panel"><h2>Intake signal feed <em>slack &#183; mail &#183; teams &#183; inbox &#183; terminal</em></h2><div class="feed">' +
    O.intake.map(function (i) { return '<div><span class="src">[' + i.src + ']</span><span class="time">' + i.when + '</span><span title="' + O.esc(i.reason) + '">' + O.esc(i.text) + '<br><small style="color:var(--dim)">' + O.esc(i.reason) + '</small></span><span class="o ' + i.outcome.replace(' ', '-') + '">' + i.outcome + '</span></div>'; }).join('') + '</div></div>';

  var c = O.counts();
  document.body.innerHTML =
    '<div class="top"><h1 class="brand">OBEYA <b>//</b> ' + O.project.name + '</h1><div class="chips">' +
    '<span class="chip ok">lens: read-only</span><span class="chip">bind ' + O.project.bind + '</span><span class="chip">mount ' + O.project.mount + '</span><span class="chip">factory ' + O.project.factory + '</span>' +
    '<span class="chip">' + c['Running'] + ' running</span><span class="chip" style="color:var(--mg);border-color:var(--mg)">' + c['Waiting on you'] + ' waiting on you</span><span class="chip" style="color:var(--rd);border-color:var(--rd)">' + c['Blocked'] + ' blocked</span></div>' +
    '<div class="sync"><svg width="26" height="26" viewBox="0 0 26 26"><circle cx="13" cy="13" r="10" fill="none" stroke="#1d3350" stroke-width="3"/><circle id="ring" cx="13" cy="13" r="10" fill="none" stroke="#3df5ff" stroke-width="3" stroke-dasharray="62.8" stroke-dashoffset="0" transform="rotate(-90 13 13)"/></svg><span id="sync">SYNC</span></div></div>' +
    '<div class="grid"><div class="col">' + left + '</div><div class="col"><div class="panel">' + svg +
    '<div class="legend">' + O.statuses.map(function (s) { return '<span style="--c:' + colors[s] + '">' + s + '</span>'; }).join('') + '<span style="--c:#fff">dashed outline = in flight, not merged</span></div></div></div><div class="col">' + right + '</div></div>' +
    '<div class="foot">' + foot + '</div>';

  // ---- behaviour
  function inspect(n) {
    var b = nodes[n]; if (!b) return;
    Array.prototype.forEach.call(document.querySelectorAll('.node'), function (g) { g.classList.toggle('sel', g.getAttribute('data-n') == n); });
    document.getElementById('insp').innerHTML = '<h2>Inspector <em>#' + b.n + '</em></h2><div class="big">' + O.esc(b.title) + '</div><dl>' +
      '<dt>status</dt><dd style="color:' + colors[b.status] + '">' + b.status + '</dd><dt>kind</dt><dd>' + b.kind + '</dd><dt>role</dt><dd>' + b.role + '</dd>' +
      '<dt>effort</dt><dd>' + (b.line === 'older' ? 'earlier run' : '#' + b.line) + '</dd><dt>source</dt><dd><span class="tag ' + (b.prov === 'merged' ? 'm' : b.prov === 'event' ? 'e' : 'f') + '">' + O.provText(b.prov) + '</span></dd>' +
      (b.blockedBy ? '<dt>blocked by</dt><dd style="color:var(--rd)">#' + b.blockedBy + '</dd>' : '') + (b.since ? '<dt>waiting</dt><dd>' + b.since + '</dd>' : '') + (b.note ? '<dt>note</dt><dd>' + O.esc(b.note) + '</dd>' : '') + '</dl>';
  }
  Array.prototype.forEach.call(document.querySelectorAll('.node'), function (g) { g.addEventListener('click', function () { inspect(g.getAttribute('data-n')); }); });
  Array.prototype.forEach.call(document.querySelectorAll('.seg'), function (s) { s.addEventListener('mouseenter', function () { document.getElementById('readout').innerHTML = s.getAttribute('data-t'); }); });
  inspect(114);

  var t = 0, poll = O.project.pollSec;
  setInterval(function () {
    t = (t + 1) % (poll + 1);
    document.getElementById('ring').style.strokeDashoffset = (62.8 * t / poll).toFixed(1);
    document.getElementById('sync').textContent = 'SYNC T-' + (poll - t) + 's';
  }, 1000);
})();
