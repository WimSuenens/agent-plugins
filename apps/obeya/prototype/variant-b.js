// PROTOTYPE variant B - "The Wall": the physical Obeya, digitised. Cork wall, whiteboards, sticky notes,
// an andon light tower with a pull cord, index cards for decisions, an inbox tray with rubber-stamped outcomes.
(function () {
  var O = window.OBEYA;
  document.title = 'Obeya - ' + O.project.name;

  var css = `
  @import url('https://fonts.googleapis.com/css2?family=Caveat:wght@500;700&family=Permanent+Marker&family=Special+Elite&display=swap');
  :root{--ink:#22303c;--red:#d63b2f;--blue:#2a63b8;--green:#2e8a52}
  *{box-sizing:border-box}
  html,body{margin:0;min-height:100vh;color:var(--ink);font-family:Caveat,"Bradley Hand","Segoe Print","Marker Felt",cursive;font-size:19px}
  body{background-color:#c79d6d;
    background-image:radial-gradient(rgba(94,58,26,.38) 1px,transparent 1.6px),radial-gradient(rgba(255,238,205,.3) 1px,transparent 1.6px),
      radial-gradient(1400px 800px at 50% 0%,rgba(255,244,214,.35),transparent 70%),radial-gradient(1400px 900px at 50% 120%,rgba(60,30,8,.4),transparent 70%);
    background-size:7px 7px,11px 11px,auto,auto;background-position:0 0,3px 4px,0 0,0 0;padding:22px 26px 90px}
  .marker{font-family:"Permanent Marker",Caveat,cursive;letter-spacing:.02em}
  .type{font-family:"Special Elite","Courier New",monospace}
  .sign{display:flex;align-items:center;gap:18px;margin:0 auto 20px;max-width:1500px}
  .plank{background:linear-gradient(#7a4f2a,#5e3a1c);color:#ffe9c4;padding:8px 26px;border-radius:6px;font-size:30px;box-shadow:0 5px 0 #3e2511,0 10px 18px rgba(0,0,0,.35);
    transform:rotate(-1deg);border:2px solid #4a2c14}
  .postit{font-size:17px;padding:8px 12px;background:#fff59a;box-shadow:2px 4px 8px rgba(0,0,0,.28);transform:rotate(1.6deg);line-height:1.1}
  .postit.b{background:#bfe3ff;transform:rotate(-1.2deg)}
  .wallgrid{display:grid;grid-template-columns:repeat(12,1fr);gap:26px;max-width:1500px;margin:0 auto}
  .wb{position:relative;background:linear-gradient(135deg,#fdfdfa,#eef0ec);border:11px solid #b4bac3;border-radius:6px;
      box-shadow:0 0 0 2px #8d939c,inset 0 0 28px rgba(0,0,0,.08),0 14px 24px rgba(0,0,0,.35);padding:18px 22px 22px}
  .wb h2{margin:0 0 8px;font-family:"Permanent Marker",cursive;font-weight:400;font-size:25px;color:var(--blue);filter:url(#wobble)}
  .wb h2 small{font-family:Caveat,cursive;font-size:17px;color:#6c7a88;margin-left:8px}
  .tape{position:absolute;width:86px;height:24px;background:rgba(255,239,160,.72);box-shadow:0 1px 3px rgba(0,0,0,.2);transform:rotate(-38deg);z-index:3}
  .tape.tl{left:-30px;top:-6px}.tape.tr{right:-30px;top:-6px;transform:rotate(38deg)}
  .wash{display:inline-block;font:14px/1 "Special Elite",monospace;padding:3px 9px;background:repeating-linear-gradient(135deg,#9fd8b0 0 6px,#b9e6c6 6px 12px);color:#16442a;transform:rotate(-2deg)}
  .wash.fl{background:repeating-linear-gradient(135deg,#ffb870 0 6px,#ffcf9a 6px 12px);color:#6a3300}
  .wash.ev{background:repeating-linear-gradient(135deg,#a9c4f5 0 6px,#c3d7fa 6px 12px);color:#1d3d7a}
  .north{grid-column:span 7;min-height:290px}
  .goalrow{display:flex;gap:22px;align-items:center}
  .goal{font-size:34px;line-height:1.05;color:#162330}
  .goal em{font-style:normal;background:linear-gradient(transparent 60%,rgba(255,224,60,.75) 60%)}
  .arrownote{position:relative;margin-top:14px;display:inline-block;background:#ffe97a;padding:10px 46px 10px 16px;font-size:22px;line-height:1.1;
      clip-path:polygon(0 0,calc(100% - 30px) 0,100% 50%,calc(100% - 30px) 100%,0 100%);box-shadow:2px 3px 6px rgba(0,0,0,.2)}
  .hist{display:flex;gap:18px;margin-top:14px;font-size:18px;color:#4a5866}
  .hist div{border-top:3px solid #4a5866;padding-top:3px;flex:1;position:relative}
  .hist div::before{content:"";position:absolute;top:-8px;left:-2px;width:12px;height:12px;border-radius:50%;background:var(--red)}
  .hist b{color:var(--ink)}
  .andonbox{grid-column:span 5;display:grid;grid-template-columns:150px 1fr;gap:12px;min-height:290px}
  .tower{position:relative;width:110px;margin:0 auto;padding-top:6px}
  .lamp{width:70px;height:56px;margin:0 auto 4px;border-radius:12px 12px 6px 6px;border:3px solid #333;background:#3a3a3a;position:relative}
  .lamp.on-r{background:radial-gradient(circle at 50% 40%,#ff9a8c,#e0261b 60%);animation:lampRed 1s ease-in-out infinite;box-shadow:0 0 28px 8px rgba(255,60,40,.7)}
  .lamp.on-g{background:radial-gradient(circle at 50% 40%,#b9ffc9,#22b54e 60%);box-shadow:0 0 24px 6px rgba(60,220,110,.6)}
  .lamp.off-a{background:#5b4a1d}
  @keyframes lampRed{50%{box-shadow:0 0 10px 2px rgba(255,60,40,.4);filter:brightness(.8)}}
  .pole{width:14px;height:90px;margin:0 auto;background:linear-gradient(90deg,#666,#bbb,#666)}
  .basep{width:80px;height:12px;margin:0 auto;background:#444;border-radius:4px}
  .cord{position:absolute;right:-6px;top:40px;width:3px;height:150px;background:#2b2b2b;transform-origin:top center;animation:swing 4s ease-in-out infinite}
  .cord::after{content:"ANDON";position:absolute;left:-22px;bottom:-22px;font:12px/1 "Permanent Marker";background:#ffd400;color:#222;padding:3px 5px;border-radius:3px;border:2px solid #222}
  @keyframes swing{50%{transform:rotate(4deg)}}
  .alertnote{background:#ff9d92;padding:12px 14px;box-shadow:3px 5px 9px rgba(0,0,0,.3);transform:rotate(1deg);font-size:20px;line-height:1.1;position:relative}
  .alertnote b{font-family:"Permanent Marker";color:#8d0f06;font-weight:400}
  .goodnote{background:#c7f2cf;padding:8px 12px;margin-top:12px;transform:rotate(-1.2deg);box-shadow:2px 3px 6px rgba(0,0,0,.2);font-size:17px;line-height:1.1}
  .torn{margin-top:14px;background:#f7f0dd;padding:10px 12px 14px;font-size:16px;line-height:1.1;color:#5a4a2a;transform:rotate(-1deg);
        clip-path:polygon(0 0,100% 0,100% 90%,94% 100%,88% 92%,80% 100%,70% 91%,61% 100%,52% 92%,44% 100%,34% 92%,24% 100%,14% 92%,6% 100%,0 92%);
        background-image:radial-gradient(circle at 80% 30%,rgba(120,70,20,.22) 0 14px,transparent 15px)}
  .torn .type{font-size:12px}
  .kanban{grid-column:span 12}
  .cols{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:0}
  .colw{border-left:3px dashed rgba(34,48,60,.35);padding:4px 10px 10px;min-height:340px}
  .colw:first-child{border-left:0}
  .colw h3{font-family:"Permanent Marker";font-weight:400;font-size:19px;margin:0 0 10px;display:flex;justify-content:space-between;align-items:baseline;filter:url(#wobble)}
  .colw h3 span{font-family:Caveat;font-size:20px;color:#7a8794}
  .colw.you{background:repeating-linear-gradient(135deg,rgba(214,59,47,.06) 0 10px,transparent 10px 20px);outline:4px solid rgba(214,59,47,.65);outline-offset:-4px;border-radius:6px;filter:url(#wobble)}
  .colw.you h3{color:var(--red)}
  .colw.done{opacity:.62}
  .note{position:relative;margin:0 0 14px;padding:16px 10px 10px;cursor:pointer;box-shadow:2px 4px 8px rgba(0,0,0,.26);transition:transform .18s,box-shadow .18s;line-height:1.05;font-size:18px}
  .note:hover{transform:rotate(0deg) scale(1.04)!important;z-index:5;box-shadow:4px 8px 16px rgba(0,0,0,.34)}
  .note .n{font-family:"Permanent Marker";font-size:17px;display:block;margin-bottom:2px}
  .note .who{font-size:15px;color:rgba(0,0,0,.5);display:block;margin-top:4px}
  .note .pin{position:absolute;left:50%;top:-6px;width:14px;height:14px;border-radius:50%;background:radial-gradient(circle at 35% 30%,#ff8a80,#c4281c);box-shadow:1px 3px 3px rgba(0,0,0,.4)}
  .note .more{display:none;margin-top:8px;padding-top:6px;border-top:2px dotted rgba(0,0,0,.35);font-size:16px}
  .note.open .more{display:block}
  .note .wash{position:absolute;left:-10px;top:-11px;font-size:12px;transform:rotate(-4deg)}
  .note.r-developer{background:#ffe97a}.note.r-qa-engineer{background:#ffb3c7}.note.r-architect{background:#a9d3ff}.note.r-devops{background:#b5f0b9}.note.r-lead{background:#ffc78a}
  .note.r--{background:#f6f2e4;background-image:repeating-linear-gradient(transparent 0 21px,rgba(60,110,200,.25) 21px 22px)}
  .note.wait{animation:wiggle 3s ease-in-out infinite}
  @keyframes wiggle{0%,90%,100%{transform:rotate(-1deg)}93%{transform:rotate(2deg)}96%{transform:rotate(-3deg)}}
  .note.wait::after{content:"!";position:absolute;right:-12px;top:-14px;width:30px;height:30px;border-radius:50%;background:var(--red);color:#fff;font:21px/30px "Permanent Marker";text-align:center;box-shadow:1px 2px 4px rgba(0,0,0,.4)}
  .stamp{font-family:"Permanent Marker";border:3px solid currentColor;padding:1px 9px;display:inline-block;transform:rotate(-9deg);opacity:.82;mix-blend-mode:multiply;font-size:18px;letter-spacing:.04em}
  .note .stamp.blk{color:#a3191a;font-size:20px;transform:rotate(-8deg);margin:8px 0 2px 4px}
  .note.blocked{filter:saturate(.55)}
  .lower{grid-column:span 12;display:grid;grid-template-columns:7fr 5fr;gap:26px}
  .cork{position:relative;background:rgba(120,78,34,.35);border:8px solid #7a4f2a;border-radius:6px;box-shadow:inset 0 0 24px rgba(0,0,0,.35),0 14px 22px rgba(0,0,0,.3);padding:16px 18px 20px}
  .cork h2{margin:0 0 10px;font-family:"Permanent Marker";font-weight:400;font-size:24px;color:#fff3d2;text-shadow:1px 2px 0 rgba(0,0,0,.45)}
  .cork h2 small{font-family:Caveat;font-size:17px;opacity:.85;margin-left:8px}
  .decgrid{display:grid;grid-template-columns:1.15fr 1fr;gap:18px}
  .fan{display:flex;flex-wrap:wrap;gap:8px}
  .icard{width:calc(50% - 4px);background:#fffdf3;padding:5px 7px 6px;font-size:11px;line-height:1.15;border-top:3px solid #d96b6b;
       box-shadow:1px 2px 4px rgba(0,0,0,.32);position:relative;background-image:repeating-linear-gradient(transparent 0 14px,rgba(60,110,200,.22) 14px 15px)}
  .icard b{display:block;color:#a02a2a;font-size:11px}
  .icard::after{content:"\\2713";position:absolute;right:5px;bottom:1px;color:var(--green);font:700 16px Caveat}
  .todo{display:flex;flex-direction:column;gap:16px}
  .dcard{position:relative;background:#fffdf3;padding:14px 14px 10px;box-shadow:3px 5px 9px rgba(0,0,0,.35);font-size:18px;line-height:1.08}
  .dcard .pin{position:absolute;left:46%;top:-8px;width:16px;height:16px;border-radius:50%;background:radial-gradient(circle at 35% 30%,#ff8a80,#c4281c);box-shadow:1px 3px 3px rgba(0,0,0,.4)}
  .dcard .door{font-family:"Special Elite";font-size:12px;color:#8d0f06;display:block}
  .dcard .opts{margin-top:6px;display:flex;gap:6px;flex-wrap:wrap}
  .dcard .opts span{font:14px "Special Elite";border:1.5px dashed #777;padding:1px 7px;color:#666}
  .tray{background:linear-gradient(#e9dfc9,#d9ccb0);border:8px solid #8a6a3d;border-radius:4px 4px 14px 14px;box-shadow:inset 0 10px 18px rgba(0,0,0,.25),0 14px 22px rgba(0,0,0,.3);padding:16px 14px 18px;position:relative}
  .tray h2{margin:0 0 10px;font-family:"Permanent Marker";font-weight:400;font-size:24px;color:#5b3f1c}
  .tray h2 small{font-family:Caveat;font-size:17px;margin-left:8px;color:#7b6340}
  .slip{position:relative;background:#fff;margin-bottom:12px;padding:8px 10px 8px 52px;box-shadow:1px 3px 6px rgba(0,0,0,.28);font-size:18px;line-height:1.05}
  .slip:nth-child(odd){transform:rotate(-.7deg)}.slip:nth-child(even){transform:rotate(.8deg)}
  .slip small{display:block;font-size:15px;color:#6d7885;margin-top:2px}
  .slip .stamp{position:absolute;right:8px;top:8px;font-size:14px}
  .slip .ico{position:absolute;left:10px;top:10px;width:32px;height:32px;border-radius:8px;color:#fff;font:17px/32px "Permanent Marker";text-align:center}
  .st-slice{color:#1f7a3a}.st-research{color:#1d5fa6}.st-rejected{color:#7d838a}.st-needs{color:var(--red)}.st-parked{color:#b86a00}.st-direction{color:#6a2c91}
  @media (max-width:1100px){.north,.andonbox,.lower{grid-column:span 12}.lower{grid-template-columns:1fr}.cols{grid-template-columns:repeat(2,1fr)}}
  `;
  var st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

  function rot(n, k) { return (((n * 37 + (k || 0)) % 7) - 3) * 0.7; }
  var order = ['Backlog', 'Ready', 'Running', 'Waiting on you', 'Blocked', 'Done'];
  var srcIco = { slack: ['#', '#611f69'], mail: ['@', '#c0392b'], teams: ['T', '#464eb8'], inbox: ['⇩', '#6d4c1d'], terminal: ['>_', '#222'] };
  var stampCls = { 'slice candidate': 'st-slice', 'research ticket': 'st-research', 'rejected': 'st-rejected', 'needs you': 'st-needs', 'parked': 'st-parked', 'direction': 'st-direction' };
  function wash(p) { return p === 'merged' ? '' : '<span class="wash ' + (p === 'event' ? 'ev' : 'fl') + '">' + (p === 'event' ? 'event' : p) + '</span>'; }

  var d = O.direction;
  var open = O.andon.filter(function (a) { return a.open; }), shut = O.andon.filter(function (a) { return !a.open; });
  var c = O.counts();

  var compass = '<svg width="150" height="150" viewBox="-75 -75 150 150" style="filter:url(#wobble)">' +
    '<circle r="66" fill="#fff" stroke="#22303c" stroke-width="3"/><circle r="56" fill="none" stroke="#22303c" stroke-width="1.5" stroke-dasharray="3 5"/>' +
    '<path d="M0 -52 L9 0 L0 52 L-9 0Z" fill="none" stroke="#22303c" stroke-width="2"/>' +
    '<path d="M0 -52 L9 0 L-9 0Z" fill="#d63b2f"/><path d="M-52 0 L0 -7 L52 0 L0 7Z" fill="none" stroke="#22303c" stroke-width="1.5"/>' +
    '<text y="-58" text-anchor="middle" font-family="Permanent Marker" font-size="17" fill="#d63b2f" transform="translate(0 -4)">★</text>' +
    '<text x="0" y="68" text-anchor="middle" font-family="Permanent Marker" font-size="12" fill="#22303c" transform="translate(0 6)">goal</text></svg>';

  var html =
    '<svg width="0" height="0" style="position:absolute"><filter id="wobble"><feTurbulence type="fractalNoise" baseFrequency="0.02" numOctaves="2" seed="3"/><feDisplacementMap in="SourceGraphic" scale="3"/></filter></svg>' +
    '<div class="sign"><div class="plank marker">OBEYA &middot; ' + O.project.name + '</div>' +
    '<div class="postit">🔒 look, don&#39;t touch<br><small>read-only &middot; ' + O.project.bind + '</small></div>' +
    '<div class="postit b">updated ' + O.project.refreshed + '<br><small>next look in <span id="cd">' + O.project.pollSec + '</span>s</small></div>' +
    '<div class="postit" style="background:#ffd1e8">' + c['Waiting on you'] + ' note(s) waiting<br>on <b>you</b></div></div>' +
    '<div class="wallgrid">' +

    // direction
    '<section class="wb north"><i class="tape tl"></i><i class="tape tr"></i><h2>Where we&#39;re going <small>' + wash(d.prov) + ' ' + d.source + '</small></h2>' +
    '<div class="goalrow">' + compass + '<div class="goal">' + O.esc(d.goal).replace('keeps a project moving on its own', '<em>keeps a project moving on its own</em>') + '</div></div>' +
    '<div class="arrownote">Now heading: ' + O.esc(d.heading) + '</div>' +
    '<div class="hist">' + d.history.map(function (h) { return '<div><b>' + h.date.slice(5) + '</b> ' + O.esc(h.idea) + '<br><small style="font-size:16px">' + O.esc(h.effect) + '</small></div>'; }).join('') + '</div></section>' +

    // andon
    '<section class="wb andonbox"><i class="tape tl"></i><div><h2>Andon</h2><div class="tower">' +
    '<div class="lamp ' + (open.length ? 'on-r' : 'off-a') + '"></div><div class="lamp off-a"></div><div class="lamp ' + (open.length ? '' : 'on-g') + '" ' + (open.length ? 'style="background:#1d3a26"' : '') + '></div>' +
    '<div class="pole"></div><div class="basep"></div><div class="cord"></div></div></div>' +
    '<div style="padding-top:34px">' + open.map(function (a) { return '<div class="alertnote"><b>' + a.id + ' &middot; #' + a.item + '</b><br>' + O.esc(a.title) + '<br><small style="font-size:15px">pulled ' + a.raised + ' &middot; owner: ' + a.owner + '</small></div>'; }).join('') +
    shut.map(function (a) { return '<div class="goodnote">✓ ' + a.id + ' fixed (#' + a.item + ')<br><small>' + O.esc(a.fix) + '</small></div>'; }).join('') +
    O.parseFailures.map(function (p) { return '<div class="torn"><b class="marker" style="color:#a3191a">?? can&#39;t read this one</b><br>' + O.esc(p.reason) + '<br><span class="type">' + O.esc(p.path.split('/').slice(-3).join('/')) + '</span> ' + wash(p.prov) + '</div>'; }).join('') +
    '</div></section>' +

    // kanban
    '<section class="wb kanban"><i class="tape tl"></i><i class="tape tr"></i><h2>The line <small>' + O.board.length + ' notes &middot; read left to right</small></h2><div class="cols">' +
    order.map(function (s) {
      return '<div class="colw ' + (s === 'Waiting on you' ? 'you' : s === 'Done' ? 'done' : '') + '"><h3>' + s + '<span>' + O.by(s).length + '</span></h3>' +
        O.by(s).map(function (b) {
          return '<div class="note r-' + b.role + (s === 'Waiting on you' ? ' wait' : '') + (s === 'Blocked' ? ' blocked' : '') + '" style="transform:rotate(' + rot(b.n) + 'deg)">' +
            (b.role === '-' ? '' : '<i class="pin"></i>') + wash(b.prov) +
            '<span class="n">#' + b.n + '</span>' + O.esc(b.title) +
            (s === 'Blocked' ? '<span class="stamp blk">BLOCKED</span><span class="who">waiting for #' + b.blockedBy + '</span>' : '<span class="who">' + (b.role === '-' ? 'nobody yet' : b.role) + '</span>') +
            '<div class="more">kind: ' + b.kind + '<br>effort: ' + (b.line === 'older' ? 'earlier run' : '#' + b.line) + '<br>source: ' + O.provText(b.prov) + (b.note ? '<br>' + O.esc(b.note) : '') + (b.since ? '<br>waiting ' + b.since : '') + '</div></div>';
        }).join('') + '</div>';
    }).join('') + '</div></section>' +

    // lower
    '<div class="lower"><section class="cork"><h2>Decisions <small>pinned for everyone to see</small></h2><div class="decgrid">' +
    '<div><div class="marker" style="color:#fff3d2;font-size:17px;margin-bottom:6px">Decided (' + O.adrs.length + ')</div><div class="fan">' +
    O.adrs.map(function (a) { return '<div class="icard type" style="transform:rotate(' + rot(a.n, 3) * .7 + 'deg)" title="' + O.esc(a.title) + '"><b>' + a.id + '</b>' + O.esc(a.title) + '</div>'; }).join('') + '</div></div>' +
    '<div><div class="marker" style="color:#ffd9d2;font-size:17px;margin-bottom:10px">Still to decide (' + O.pending.length + ')</div><div class="todo">' +
    O.pending.map(function (p) {
      return '<div class="dcard" style="transform:rotate(' + rot(p.id.length * 5 + p.title.length) + 'deg)"><i class="pin"></i><span class="door">🚪 ' + p.door + ' door &middot; ' + (p.waiting === 'not yet asked' ? 'not asked yet' : 'waiting ' + p.waiting) + '</span><b>' + p.id + '</b> ' + O.esc(p.title) +
        (p.options.length ? '<div class="opts">' + p.options.map(function (o) { return '<span>' + O.esc(o) + '</span>'; }).join('') + '</div>' : '') + '<div style="margin-top:6px">' + wash(p.prov) + '</div></div>'; }).join('') +
    '</div></div></div></section>' +

    '<section class="tray"><h2>Inbox <small>slack &middot; mail &middot; teams &middot; folder &middot; terminal</small></h2>' +
    O.intake.map(function (i) {
      var ic = srcIco[i.src] || ['?', '#555'];
      return '<div class="slip"><span class="ico" style="background:' + ic[1] + '">' + ic[0] + '</span>' + O.esc(i.text) + '<small>' + O.esc(i.reason) + ' &middot; ' + i.when + '</small><span class="stamp ' + stampCls[i.outcome] + '">' + i.outcome.toUpperCase() + '</span></div>';
    }).join('') + '</section></div>' +
    '</div>';

  document.body.innerHTML = html;

  Array.prototype.forEach.call(document.querySelectorAll('.note'), function (n) { n.addEventListener('click', function () { n.classList.toggle('open'); }); });
  var t = O.project.pollSec;
  setInterval(function () { t = t <= 1 ? O.project.pollSec : t - 1; var cd = document.getElementById('cd'); if (cd) cd.textContent = t; }, 1000);
})();
