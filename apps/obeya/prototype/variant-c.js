// PROTOTYPE variant C - "Transit": the project is a metro map. The past is solid track, the future is dashed.
// Decisions are stations on the main route, efforts are coloured lines, ideas are a feeder line that merges into the direction.
// What needs you is a split-flap departures board; an andon is a service disruption.
(function () {
  var O = window.OBEYA;
  document.title = 'Obeya - ' + O.project.name + ' - route map';

  var css = `
  :root{--paper:#f4efe3;--ink:#1c1c1c;--red:#e3242b;--blue:#0a62c9;--green:#0a8f4f;--amber:#ffb400;--mute:#7a7567}
  *{box-sizing:border-box}
  html,body{margin:0;background:var(--paper);color:var(--ink);font-family:"Helvetica Neue",Helvetica,Arial,sans-serif;min-height:100vh}
  body{padding:0 0 90px}
  .wrap{max-width:1480px;margin:0 auto;padding:0 28px}
  header.hd{display:grid;grid-template-columns:auto 1fr;gap:28px;align-items:end;padding:26px 0 14px;border-bottom:6px solid var(--ink)}
  .roundel{display:flex;align-items:center;gap:12px}
  .rd{position:relative;width:62px;height:62px;border-radius:50%;border:9px solid var(--red)}
  .rd::after{content:"OBEYA";position:absolute;left:-18px;right:-18px;top:50%;transform:translateY(-50%);background:var(--blue);color:#fff;
     font:800 11px/1 Arial;letter-spacing:.14em;text-align:center;padding:5px 0}
  .proj{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--mute);font-weight:700;margin-left:18px}
  .proj b{display:block;font-size:30px;letter-spacing:-.01em;color:var(--ink);text-transform:none}
  .goal{font-size:clamp(22px,2.6vw,38px);font-weight:800;line-height:1.08;letter-spacing:-.02em;max-width:1000px}
  .goal span{color:var(--red)}
  .heading{margin-top:8px;font-size:15px;color:#3b3a36;max-width:900px}
  .heading b{background:var(--ink);color:#fff;padding:1px 7px;margin-right:8px;font-size:11px;letter-spacing:.12em;text-transform:uppercase}
  .meta{margin-top:6px;font-size:12px;color:var(--mute)}
  .status{display:grid;grid-template-columns:repeat(3,1fr);gap:0;margin:16px 0;border:2px solid var(--ink);background:#fff}
  .status div{padding:10px 14px;border-left:2px solid var(--ink);display:grid;grid-template-columns:auto 1fr;gap:2px 12px;align-items:center}
  .status div:first-child{border-left:0}
  .status .badge{grid-row:span 2;width:44px;height:44px;border-radius:6px;color:#fff;font:800 15px/44px Arial;text-align:center}
  .status b{font-size:15px}.status em{font-style:normal;font-size:13px}
  .st-bad{color:#b4141a}.st-warn{color:#a55a00}.st-ok{color:#0a7a41}
  .mapbox{background:#fff;border:2px solid var(--ink);padding:6px 10px 10px;position:relative;overflow-x:auto}
  svg#map{display:block;width:100%;min-width:1100px;height:auto}
  svg text{font-family:"Helvetica Neue",Helvetica,Arial,sans-serif}
  .lbl{font-size:9.5px;font-weight:700;fill:var(--ink);text-anchor:middle}
  .sm{font-size:8px;fill:var(--mute);text-anchor:middle}
  .st{cursor:pointer}
  .st:hover .core,.st.hl .core{stroke-width:6}
  .st.hl .halo{opacity:1}
  .halo{opacity:0;fill:none;stroke:var(--ink);stroke-width:2;stroke-dasharray:2 3}
  .pulseR{transform-box:fill-box;transform-origin:center;animation:ring 1.8s ease-out infinite;fill:none;stroke-width:3}
  @keyframes ring{0%{transform:scale(.8);opacity:.9}100%{transform:scale(2.4);opacity:0}}
  .blink{animation:bl 1.1s steps(2) infinite}@keyframes bl{50%{opacity:.25}}
  .legend{display:flex;gap:18px;flex-wrap:wrap;padding:10px 4px 0;font-size:12px;color:#3b3a36;align-items:center}
  .legend span{display:inline-flex;align-items:center;gap:6px}
  .two{display:grid;grid-template-columns:minmax(0,1fr) 380px;gap:24px;margin-top:24px;align-items:start}
  .board{background:#111;border:6px solid #2c2c2c;border-radius:8px;padding:14px 16px 16px;box-shadow:0 10px 0 #cfc9b8;overflow-x:auto}
  .board h2{margin:0 0 10px;color:#fff;font:800 20px Arial;letter-spacing:.14em;text-transform:uppercase;display:flex;justify-content:space-between;align-items:baseline}
  .board h2 small{color:var(--amber);font:600 14px "SF Mono",Menlo,monospace;letter-spacing:.06em}
  .row{display:flex;gap:16px;padding:5px 0;border-top:1px solid #2a2a2a;align-items:center;cursor:pointer;min-width:880px}
  .row.head{cursor:default;color:#8a8a8a;font:700 10px Arial;letter-spacing:.18em;text-transform:uppercase;border-top:0}
  .row.hl{background:#262210;outline:1px solid var(--amber)}
  .cell{display:flex;flex-shrink:0}
  .c1{width:70px}.c2{width:72px}.c3{width:420px}.c4{width:138px}.c5{width:140px}
  .ch{display:inline-block;width:12.5px;height:21px;margin-right:1.5px;background:#1d1d1d;border-radius:2px;color:var(--amber);position:relative;
      font:700 14px/21px "SF Mono",Menlo,monospace;text-align:center;animation:flip .5s ease-out backwards;overflow:hidden}
  .ch::after{content:"";position:absolute;left:0;right:0;top:50%;height:1px;background:#000;box-shadow:0 1px 0 rgba(255,255,255,.07)}
  @keyframes flip{0%{transform:rotateX(90deg);opacity:0}100%{transform:none;opacity:1}}
  .you .ch{color:#fff;background:#8a1017}.run .ch{color:#7dffa3}.blk .ch{color:#ff8a8a}
  .rm-blink .ch{animation:flip .5s ease-out backwards,bl 1.1s steps(2) .6s infinite}
  .more{color:#8a8a8a;font:12px "SF Mono",monospace;padding:8px 0 0}
  .notices{display:flex;flex-direction:column;gap:12px}
  .notices h2{margin:0;font:800 14px Arial;letter-spacing:.16em;text-transform:uppercase;border-bottom:4px solid var(--ink);padding-bottom:6px}
  .nt{background:#fff;border:2px solid var(--ink);border-left-width:14px;padding:10px 12px;font-size:13px;line-height:1.35}
  .nt b{display:block;font-size:14px;margin-bottom:2px}
  .nt .chip{display:inline-block;margin-top:5px;font-size:10.5px;padding:1px 7px;border:1.5px solid var(--ink);letter-spacing:.06em;text-transform:uppercase}
  .nt .chip.fl{border-style:dashed}
  .nt.bad{border-left-color:var(--red)}.nt.dc{border-left-color:var(--amber)}.nt.sig{border-left-color:#555;background:repeating-linear-gradient(135deg,#fff 0 8px,#f0ece0 8px 16px)}.nt.in{border-left-color:var(--green)}
  #tip{position:fixed;z-index:9999;pointer-events:none;background:var(--ink);color:#fff;padding:7px 10px;font-size:12px;line-height:1.3;max-width:300px;display:none;box-shadow:0 6px 16px rgba(0,0,0,.3)}
  #tip b{color:var(--amber)}
  @media (max-width:1150px){.two{grid-template-columns:1fr}header.hd{grid-template-columns:1fr}}
  `;
  var st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

  var INK = '#1c1c1c', RED = '#e3242b', BLUE = '#0a62c9', GREEN = '#0a8f4f';
  var d = O.direction, c = O.counts();

  // ---------- metro map
  function tipData(title, body, prov) { return ' data-tip="' + O.esc('<b>' + title + '</b><br>' + body + '<br><i>' + prov + '</i>') + '"'; }
  function station(x, y, b, color, up) {
    var s = b.status, g = '<g class="st" data-n="' + b.n + '"' + tipData('#' + b.n + ' ' + b.title, s + (b.role !== '-' ? ' - ' + b.role : '') + (b.blockedBy ? ' - waiting for #' + b.blockedBy : ''), O.provText(b.prov)) + '>';
    if (b.prov !== 'merged') g += '<circle class="halo" cx="' + x + '" cy="' + y + '" r="15" style="opacity:.55"/>';
    g += '<circle class="halo" cx="' + x + '" cy="' + y + '" r="15"/>';
    if (s === 'Running') g += '<circle class="pulseR" cx="' + x + '" cy="' + y + '" r="10" stroke="' + color + '"/>';
    if (s === 'Done') g += '<circle class="core" cx="' + x + '" cy="' + y + '" r="9" fill="' + color + '" stroke="' + INK + '" stroke-width="3"/><path d="M' + (x - 4) + ' ' + y + ' l3 3.5 l5.5 -7" stroke="#fff" stroke-width="2.2" fill="none"/>';
    else if (s === 'Blocked') g += '<circle class="core" cx="' + x + '" cy="' + y + '" r="9" fill="' + INK + '" stroke="' + INK + '" stroke-width="3"/><path d="M' + (x - 4) + ' ' + (y - 4) + ' l8 8 M' + (x + 4) + ' ' + (y - 4) + ' l-8 8" stroke="#fff" stroke-width="2.2"/>';
    else if (s === 'Backlog') g += '<circle class="core" cx="' + x + '" cy="' + y + '" r="6" fill="#f4efe3" stroke="#9a9484" stroke-width="3"/>';
    else g += '<circle class="core" cx="' + x + '" cy="' + y + '" r="9" fill="#fff" stroke="' + INK + '" stroke-width="4"/>' + (s === 'Ready' ? '' : '<circle cx="' + x + '" cy="' + y + '" r="4" fill="' + color + '"/>');
    if (s === 'Waiting on you') g += '<g class="blink"><circle cx="' + (x + 11) + '" cy="' + (y - 11) + '" r="8" fill="#ff8a00" stroke="#fff" stroke-width="1.5"/><text x="' + (x + 11) + '" y="' + (y - 7.6) + '" class="lbl" fill="#fff" style="fill:#fff;font-size:11px">!</text></g>';
    g += '<text class="lbl" x="' + x + '" y="' + (up ? y - 19 : y + 27) + '">' + b.n + '</text></g>';
    return g;
  }
  function pill(x, y, w, color, text) {
    return '<rect x="' + x + '" y="' + y + '" width="' + w + '" height="22" rx="11" fill="' + color + '"/><text x="' + (x + w / 2) + '" y="' + (y + 15) + '" style="fill:#fff;font-size:11.5px;font-weight:800;letter-spacing:.04em;text-anchor:middle">' + text + '</text>';
  }

  var m = '<svg id="map" viewBox="0 0 1320 362" role="img" aria-label="Route map of the project">' +
    '<defs><pattern id="haz" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="4" height="8" fill="#ffcf00"/><rect x="4" width="4" height="8" fill="#1c1c1c"/></pattern></defs>';

  // main route: solid to 700 (the past), dashed beyond (the future)
  m += '<path d="M40 110 H700" stroke="' + INK + '" stroke-width="10" stroke-linecap="round" fill="none"/>' +
    '<path d="M700 110 H1275" stroke="' + INK + '" stroke-width="10" stroke-dasharray="16 10" fill="none"/><path d="M1275 98 L1300 110 L1275 122Z" fill="' + INK + '"/>';
  m += '<text x="40" y="70" style="font-size:12px;font-weight:800;letter-spacing:.14em;fill:' + INK + '">THE ROUTE &#183; DIRECTION</text>' +
    '<text x="40" y="84" style="font-size:10px;fill:' + '#7a7567' + '">' + d.source + ' &#183; ' + d.prov + '</text>';
  // ADR stations
  O.adrs.forEach(function (a, k) {
    var x = 70 + 30 * k;
    m += '<g class="st"' + tipData(a.id + ' ' + a.title, 'decision made', 'merged') + '><circle class="core" cx="' + x + '" cy="110" r="7" fill="#fff" stroke="' + INK + '" stroke-width="3.5"/><text class="sm" x="' + x + '" y="132">' + a.n + '</text></g>';
  });
  m += '<path d="M70 146 V152 H520 V146" stroke="#9a9484" fill="none"/><text class="sm" x="295" y="165" style="font-size:9.5px">' + O.adrs.length + ' decisions made (ADRs)</text>';
  // interchange where intake joins
  m += '<g class="st"' + tipData('Interchange: ideas feed the direction', 'Triaged ideas change docs/direction.md', 'merged') + '><circle cx="564" cy="110" r="13" fill="#fff" stroke="' + INK + '" stroke-width="5"/><circle cx="564" cy="110" r="5" fill="' + GREEN + '"/></g>' +
    '<text class="sm" x="564" y="86" style="font-size:9.5px;fill:' + GREEN + ';font-weight:700">ideas join here</text>';
  // you are here
  m += '<g><circle cx="610" cy="110" r="12" fill="' + RED + '" stroke="#fff" stroke-width="3"/><rect x="560" y="26" width="100" height="26" rx="4" fill="' + RED + '"/><path d="M604 52 L610 62 L616 52Z" fill="' + RED + '"/><text x="610" y="43" style="fill:#fff;font-size:11px;font-weight:800;letter-spacing:.1em;text-anchor:middle">YOU ARE HERE</text></g>';
  // pending decisions: stations ahead
  O.pending.concat([{ id: 'next', title: 'what comes next?', door: 'unknown', prov: 'event', waiting: '-', ghost: true }]).forEach(function (p, k) {
    var x = 780 + 80 * k;
    m += '<g class="st"' + tipData(p.id + ' ' + p.title, p.door + ' door - ' + (p.waiting === 'not yet asked' ? 'not asked yet' : p.ghost ? 'undecided' : 'waiting ' + p.waiting), O.provText(p.prov)) + '>' +
      '<circle class="core" cx="' + x + '" cy="110" r="8" fill="' + '#f4efe3' + '" stroke="' + INK + '" stroke-width="3.5" stroke-dasharray="4 3"/>' +
      '<text class="lbl" transform="rotate(-38 ' + x + ' 90)" x="' + x + '" y="90" style="text-anchor:start;font-size:10px;fill:' + (p.ghost ? '#9a9484' : '#1c1c1c') + '">' + (p.ghost ? '?' : p.id) + '</text></g>';
  });
  m += '<text class="sm" x="900" y="136" style="font-size:9.5px">decisions still ahead</text>';

  // intake feeder line (green)
  m += '<path d="M60 260 H414 L564 110" stroke="' + GREEN + '" stroke-width="9" fill="none" stroke-linejoin="round"/>';
  m += pill(60, 196, 84, GREEN, 'INTAKE');
  var oc = { 'slice candidate': ['slice', '#0a7a41'], 'research ticket': ['research', BLUE], 'rejected': ['rejected', '#7a7567'], 'needs you': ['NEEDS YOU', '#b4141a'], 'parked': ['parked', '#a55a00'], 'direction': ['direction', '#1c1c1c'] };
  O.intake.forEach(function (it, k) {
    var x = 90 + 60 * k, o = oc[it.outcome];
    m += '<g class="st"' + tipData(it.id + ' [' + it.src + '] ' + it.text, it.outcome + ': ' + it.reason, it.when) + '><circle class="core" cx="' + x + '" cy="260" r="9" fill="#fff" stroke="' + INK + '" stroke-width="4"/>' +
      (it.outcome === 'needs you' ? '<circle class="pulseR" cx="' + x + '" cy="260" r="10" stroke="#b4141a"/>' : '') +
      '<text class="lbl" x="' + x + '" y="286">' + it.id + '</text><text class="sm" x="' + x + '" y="298" style="fill:' + o[1] + ';font-weight:700">' + o[0] + '</text>' +
      '<text class="sm" x="' + x + '" y="239" style="font-size:8px">' + it.src + '</text></g>';
  });

  // effort lines
  var l108 = O.board.filter(function (b) { return b.line === '108'; }), l121 = O.board.filter(function (b) { return b.line === '121'; });
  m += '<path d="M700 110 L790 200 H1290" stroke="' + RED + '" stroke-width="9" fill="none" stroke-linejoin="round"/>';
  m += '<path d="M640 110 V245 L690 295 H1290" stroke="' + BLUE + '" stroke-width="9" fill="none" stroke-linejoin="round"/>';
  var bi = l108.findIndex(function (b) { return b.status === 'Blocked'; });
  if (bi >= 0) m += '<path d="M' + (840 + 40 * bi) + ' 200 H1290" stroke="#d6d0c0" stroke-width="9" stroke-dasharray="8 6" fill="none"/>';
  m += pill(800, 150, 190, RED, '108 &#183; CONTINUOUS FACTORY') + pill(696, 255, 150, BLUE, '121 &#183; OBEYA ROOM');
  l108.forEach(function (b, i) { m += station(840 + 40 * i, 200, b, RED, i % 2 === 0 ? false : true); });
  l121.forEach(function (b, i) { m += station(760 + 120 * i, 295, b, BLUE, i % 2 === 0 ? false : true); });

  // andon: a closure between #114 and #115
  O.andon.filter(function (a) { return a.open; }).forEach(function (a) {
    var i = l108.findIndex(function (b) { return b.n === a.item; });
    if (i < 0) return;
    var x = 840 + 40 * i + 20;
    m += '<g class="st"' + tipData('ANDON ' + a.id + ' on #' + a.item, a.title, 'raised ' + a.raised) + '><rect x="' + (x - 4) + '" y="180" width="8" height="40" fill="url(#haz)" stroke="' + INK + '" stroke-width="1.5"/>' +
      '<g class="blink"><path d="M' + x + ' 140 l17 30 h-34z" fill="#ffcf00" stroke="' + INK + '" stroke-width="2.5" stroke-linejoin="round"/><text x="' + x + '" y="166" style="font-size:15px;font-weight:900;text-anchor:middle;fill:' + INK + '">!</text></g>' +
      '<text class="sm" x="' + x + '" y="134" style="font-weight:800;fill:#b4141a;font-size:10px">ANDON ' + a.id + '</text></g>';
  });
  m += '<text class="sm" x="1290" y="352" style="text-anchor:end;font-size:9.5px">' + (O.board.length - l108.length - l121.length) + ' earlier items already done, off the map</text>';
  m += '</svg>';

  function key(svg, t) { return '<span><svg width="24" height="24" viewBox="0 0 24 24">' + svg + '</svg>' + t + '</span>'; }
  var legend = '<div class="legend">' +
    key('<circle cx="12" cy="12" r="9" fill="#e3242b" stroke="#1c1c1c" stroke-width="3"/>', 'done') +
    key('<circle cx="12" cy="12" r="9" fill="#fff" stroke="#1c1c1c" stroke-width="4"/><circle cx="12" cy="12" r="4" fill="#e3242b"/>', 'running') +
    key('<circle cx="12" cy="12" r="9" fill="#fff" stroke="#1c1c1c" stroke-width="4"/>', 'ready') +
    key('<circle cx="12" cy="12" r="9" fill="#fff" stroke="#1c1c1c" stroke-width="4"/><circle cx="19" cy="5" r="5" fill="#ff8a00"/>', 'waiting on you') +
    key('<circle cx="12" cy="12" r="9" fill="#1c1c1c"/><path d="M8 8l8 8M16 8l-8 8" stroke="#fff" stroke-width="2"/>', 'blocked') +
    key('<circle cx="12" cy="12" r="6" fill="#f4efe3" stroke="#9a9484" stroke-width="3"/>', 'backlog') +
    key('<circle cx="12" cy="12" r="8" fill="#f4efe3" stroke="#1c1c1c" stroke-width="3" stroke-dasharray="4 3"/>', 'decision ahead') +
    '<span>solid track = the past &#183; dashed = the future &#183; hover a station</span></div>';

  // ---------- status board strip
  var open = O.andon.filter(function (a) { return a.open; });
  var needsYouIntake = O.intake.filter(function (i) { return i.outcome === 'needs you'; }).length;
  var strip = '<div class="status">' +
    '<div><span class="badge" style="background:' + RED + '">108</span><b>Continuous factory</b><em class="st-bad">Part suspended &#183; andon ' + (open[0] ? open[0].id + ' on #' + open[0].item : '-') + '</em></div>' +
    '<div><span class="badge" style="background:' + BLUE + '">121</span><b>Obeya room</b><em class="st-warn">Planned works &#183; skeleton ready, ' + c['Blocked'] + ' stop blocked</em></div>' +
    '<div><span class="badge" style="background:' + GREEN + '">IN</span><b>Intake</b><em class="st-warn">Delays &#183; ' + needsYouIntake + ' idea waiting on you</em></div></div>';

  // ---------- split-flap departures board
  function flap(text, n, extra) {
    text = String(text).toUpperCase(); if (text.length > n) text = text.slice(0, n - 1) + '.';
    while (text.length < n) text += ' ';
    return '<span class="cell ' + (extra || '') + '">' + text.split('').map(function (ch) { return '<span class="ch" style="animation-delay:' + (Math.random() * .7).toFixed(2) + 's">' + (ch === ' ' ? '&nbsp;' : O.esc(ch)) + '</span>'; }).join('') + '</span>';
  }
  var rows = [];
  O.by('Waiting on you').forEach(function (b) { rows.push({ b: b, cls: 'you', t: b.since, rm: 'ACTION: YOU', blink: true, plat: b.role }); });
  O.by('Running').forEach(function (b) { rows.push({ b: b, cls: 'run', t: 'NOW', rm: 'BOARDING', plat: b.role }); });
  O.by('Blocked').forEach(function (b) { rows.push({ b: b, cls: 'blk', t: '--', rm: 'HELD BY #' + b.blockedBy, plat: b.role === '-' ? 'DEPOT' : b.role }); });
  O.by('Ready').forEach(function (b) { rows.push({ b: b, cls: '', t: 'NEXT', rm: 'ON TIME', plat: 'DEPOT' }); });
  O.by('Backlog').slice(0, 4).forEach(function (b, i) { rows.push({ b: b, cls: '', t: 'LATER', rm: 'SCHEDULED', plat: 'DEPOT' }); });
  var board = '<div class="board"><h2>Departures <small>' + O.project.refreshed + ' &#183; refresh ' + O.project.pollSec + 's</small></h2>' +
    '<div class="row head"><span class="c1">Wait</span><span class="c2">Item</span><span class="c3">Destination</span><span class="c4">Platform</span><span class="c5">Remarks</span></div>' +
    rows.map(function (r) {
      return '<div class="row ' + r.cls + (r.blink ? ' rm-blink' : '') + '" data-n="' + r.b.n + '">' + flap(r.t, 5, 'c1') + flap('#' + r.b.n, 5, 'c2') + flap(r.b.title, 32, 'c3') + flap(r.plat, 10, 'c4') + flap(r.rm, 12, 'c5') + '</div>';
    }).join('') +
    '<div class="more">+ ' + (O.by('Backlog').length - 4) + ' more scheduled &#183; ' + O.by('Done').length + ' arrived</div></div>';

  // ---------- notices
  var notices = '<div class="notices"><h2>Service notices</h2>' +
    open.map(function (a) { return '<div class="nt bad"><b>Service disruption &#183; ' + a.id + '</b>' + O.esc(a.title) + '<br><span class="chip">#' + a.item + ' &#183; owner ' + a.owner + ' &#183; ' + a.raised + '</span></div>'; }).join('') +
    O.pending.filter(function (p) { return p.waiting !== 'not yet asked'; }).map(function (p) {
      return '<div class="nt dc"><b>Decision needed &#183; ' + p.id + '</b>' + O.esc(p.title) + '<br><span class="chip ' + (p.prov === 'merged' ? '' : 'fl') + '">' + p.door + ' door &#183; ' + O.provText(p.prov) + '</span></div>'; }).join('') +
    O.intake.filter(function (i) { return i.outcome === 'needs you'; }).map(function (i) { return '<div class="nt in"><b>Idea waiting on you &#183; ' + i.id + '</b>' + O.esc(i.text) + '<br>' + O.esc(i.reason) + '<br><span class="chip">via ' + i.src + '</span></div>'; }).join('') +
    O.parseFailures.map(function (p) { return '<div class="nt sig"><b>Signal failure</b>One artifact could not be read: ' + O.esc(p.reason) + '<br><small>' + O.esc(p.path) + '</small><br><span class="chip fl">' + O.provText(p.prov) + '</span></div>'; }).join('') + '</div>';

  document.body.innerHTML =
    '<div class="wrap"><header class="hd"><div class="roundel"><div class="rd"></div><div class="proj">Project<b>' + O.project.name + '</b></div></div>' +
    '<div><div class="goal">' + O.esc(d.goal).replace('on its own', '<span>on its own</span>') + '</div><div class="heading"><b>Next stop</b>' + O.esc(d.heading) + '</div>' +
    '<div class="meta">Lens: read-only &#183; ' + O.project.bind + ' &#183; factory ' + O.project.factory + ' &#183; ' + c['Running'] + ' running &#183; ' + c['Waiting on you'] + ' waiting on you &#183; ' + c['Blocked'] + ' blocked</div></div></header>' +
    strip + '<div class="mapbox">' + m + legend + '</div>' +
    '<div class="two">' + board + notices + '</div></div><div id="tip"></div>';

  // ---------- behaviour
  var tip = document.getElementById('tip');
  Array.prototype.forEach.call(document.querySelectorAll('[data-tip]'), function (g) {
    g.addEventListener('mousemove', function (e) { tip.innerHTML = g.getAttribute('data-tip'); tip.style.display = 'block'; tip.style.left = Math.min(e.clientX + 14, innerWidth - 320) + 'px'; tip.style.top = (e.clientY + 14) + 'px'; });
    g.addEventListener('mouseleave', function () { tip.style.display = 'none'; });
  });
  function hl(n) {
    Array.prototype.forEach.call(document.querySelectorAll('.st.hl,.row.hl'), function (x) { x.classList.remove('hl'); });
    Array.prototype.forEach.call(document.querySelectorAll('[data-n="' + n + '"]'), function (x) { x.classList.add('hl'); });
  }
  Array.prototype.forEach.call(document.querySelectorAll('[data-n]'), function (el) { el.addEventListener('click', function () { hl(el.getAttribute('data-n')); }); });
})();
