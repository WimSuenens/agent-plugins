"""Replay of AC-23 and AC-26: the same item read from its 1.x stage log and from its 2.0.0 inputs (sub-issues + ledger).
Written from contracts/64-ledger-and-fields.md sections 2 and 7 and the 1.3.0 rules (hansei.md and skills/run/SKILL.md of origin/main), not from the build.
  replay64.py old <old-log.md>                  values read from the 1.x stage log, waits and touches
  replay64.py reexpress <old-log.md> <outdir>   write subissues.json and ledger.md, the 2.0.0 inputs the item would have produced
  replay64.py new <dir>                         values read from subissues.json and ledger.md
Prints  key<TAB>value  lines (keys as in fixtures/board/replay/expected-old.tsv)."""
import json, re, sys, datetime

ROLES = ['product-owner', 'architect', 'developer', 'qa-engineer', 'security-reviewer', 'devops', 'docs-writer']
HELD = ['person', 'limits', 'stalled', 'interrupted', 'andon']


def cells(ln):
    return [c.strip() for c in ln.strip().strip('|').split('|')]


def tables(text):
    """name -> list of dict rows; a table is a header line, a separator, rows; name is the nearest heading above"""
    out, name, cur = {}, None, None
    for ln in text.split('\n'):
        if ln.startswith('#'):
            name = ln.lstrip('# ').strip(); cur = None
        elif ln.startswith('|'):
            c = cells(ln)
            if cur is None:
                cur = {'hdr': c, 'rows': []}; out[name] = cur
            elif set(''.join(c)) <= set('-: '):
                pass
            else:
                cur['rows'].append(dict(zip(cur['hdr'], c)))
        else:
            cur = None if ln.strip() == '' else cur
    return {k: v['rows'] for k, v in out.items()}


def mins(t):
    if not t or t == '-':
        return None
    return int(datetime.datetime.strptime(t, '%Y-%m-%dT%H:%MZ').replace(tzinfo=datetime.timezone.utc).timestamp() // 60)


def iso(m):
    return datetime.datetime.fromtimestamp(m * 60, datetime.timezone.utc).strftime('%Y-%m-%dT%H:%MZ')


def union_len(ivs):
    ivs = sorted(i for i in ivs if i[1] > i[0]); tot = 0; end = None
    for a, b in ivs:
        if end is None or a > end: tot += b - a; end = b
        elif b > end: tot += b - end; end = b
    return tot


def cut(iv, lo, hi):
    return (max(iv[0], lo), min(iv[1], hi))


def measure1(start, approval, waits):
    total = approval - start
    claimed = []; per = {}
    for kind in HELD:
        ivs = [cut((mins(w['Start (UTC)']), mins(w['End (UTC)'])), start, approval) for w in waits if w['Kind'] == kind and w['Held item'] == 'yes']
        before = union_len(claimed); after = union_len(claimed + ivs)
        per[kind] = after - before; claimed += ivs
    return total, per, total - sum(per.values())


def median(v):
    v = sorted(v); n = len(v)
    return v[n // 2] if n % 2 else (v[n // 2 - 1] + v[n // 2]) / 2


def row_working(start, end, wait_ids, waits):
    held = [cut((mins(w['Start (UTC)']), mins(w['End (UTC)'])), start, end) for w in waits
            if w['Id'] in wait_ids and w['Held item'] == 'yes' and w['Kind'] in HELD]
    return (end - start) - union_len(held)


def kind4(rows):
    """rows: list of dict(role, n, working, label); flagged labels"""
    flags = []
    for i, r in enumerate(rows):
        earlier = [x['working'] for x in rows[:i] if x['role'] == r['role']]
        if len(earlier) < 3: continue
        m = median(earlier)
        if r['working'] > 2 * m: flags.append(r['label'])
    return flags


def gemba(rows, ident):
    """rows: dict(stage, role, agents, result, notes) in table order"""
    rr = [r for r in rows if r['role'] in ROLES and r['agents'] not in (None, '', '-')]
    fl = lambda r: not (r['result'] or '').strip().lower().startswith(('done', 'pass')) or re.search(r'paused by A[0-9]', r['notes'] or '')
    el = [r for r in rr if not fl(r)]
    if not el: return None
    r = el[ident % len(el)]
    return '%s/%s' % (r['stage'], r['role'])


def values_old(path):
    t = tables(open(path).read())
    log = t['Stage log']
    for r in log:
        if 'Agent' in r and 'Agents' not in r: r['Agents'] = r['Agent']
        r.setdefault('Waits', '-'); waits = t.get('Waits', []); touches = t.get('Person\'s touches', [])
    out = []
    ident = None
    start = approval = None
    lead_start = [r for r in log if r['Stage'] == 'Start item']
    if lead_start: start = mins(lead_start[0]['Start (UTC)'])
    ap = [r for r in touches if r['Kind'] == 'approval']
    if ap: approval = mins(ap[0]['Time (UTC)'])
    if start is not None and approval is not None:
        total, per, aw = measure1(start, approval, waits)
        out += [('total_min', total), ('person_min', per['person']), ('limits_min', per['limits']), ('stalled_min', per['stalled']),
                ('interrupted_min', per['interrupted']), ('andon_min', per['andon']), ('agent_working_min', aw), ('hours', '%.2f' % (int(total * 100 / 60 + 0.5) / 100.0))]
    krows = []
    for r in log:
        if r['Role'] in ROLES and mins(r.get('Start (UTC)')) is not None:
            ids = [x.strip() for x in r.get('Waits', '-').split(',') if x.strip() not in ('', '-')]
            wk = row_working(mins(r['Start (UTC)']), mins(r['End (UTC)']), ids, waits)
            key = 'row%s_%s_%s_working' % (r['#'], re.sub(r'[^a-z0-9]+', '-', r['Stage'].lower()).strip('-'), r['Role'])
            out.append((key, wk)); krows.append({'role': r['Role'], 'working': wk, 'label': r['#']})
    if krows or start is not None:
        f = kind4(krows); out.append(('kind4_flags', ','.join(str(x) for x in f) if f else 'none'))
    out.append(('touches', len(touches)))
    out.append(('rework_feedback_briefs', sum(1 for r in log if r['Role'] == 'developer' and '(round' in r['Stage'])))
    for role in ROLES:
        ag = []
        for r in log:
            if r['Role'] == role:
                for a in r['Agents'].split(','):
                    a = a.strip()
                    if a and a != '-' and a not in ag: ag.append(a)
        if ag: out.append(('agents_' + role, ','.join(ag)))
    for role in ROLES:
        pk = [int(r['Peak ctx']) for r in log if r['Role'] == role and re.fullmatch(r'[0-9]+', r.get('Peak ctx', ''))]
        if pk: out.append(('peak_' + role, max(pk)))
    out.append(('role_rows', sum(1 for r in log if r['Role'] in ROLES and r['Agents'] not in ('-', '', None))))
    return out, [{'stage': r['Stage'], 'role': r['Role'], 'agents': r.get('Agents', r.get('Agent')), 'result': r.get('Result'), 'notes': r.get('Notes', '')} for r in log]


def reexpress(path, outdir):
    import os
    text = open(path).read(); t = tables(text)
    log = t['Stage log']
    for r in log:
        if 'Agent' in r and 'Agents' not in r: r['Agents'] = r['Agent']
    waits = t.get('Waits', []); touches = t.get('Person\'s touches', [])
    os.makedirs(outdir, exist_ok=True)
    tasks = [r for r in log if r['Role'] in ROLES]
    subs = []; num = 31; rework = 0
    rows = []
    for i, r in enumerate(tasks):
        s = r.get('Start (UTC)', '-'); e = r.get('End (UTC)', '-')
        isrw = r['Role'] == 'developer' and '(round' in r['Stage']
        if isrw: rework += 1
        title = ('rework %d: finding fixed' % rework) if isrw else '%s: %s on #12' % (r['Stage'], r['Role'])
        subs.append({'number': num + i, 'title': title, 'user': {'login': 'lead'}, 'created_at': (s[:-1] + ':00Z') if s != '-' else None,
                     'closed_at': (e[:-1] + ':00Z') if e != '-' else None, 'state': 'closed'})
        rows.append('| %d | #%d | %s | %s | %s | %s | %s | %s | %s |' % (i + 1, num + i, r['Stage'], r['Role'], r.get('Agents', r.get('Agent')), r.get('Waits', '-'),
                    r.get('Peak ctx', '-'), r.get('Result', ''), r.get('Notes', '')))
    json.dump(subs, open(os.path.join(outdir, 'subissues.json'), 'w'), indent=1)
    si = [r for r in log if r['Stage'] == 'Start item']
    L = ['<!-- factory:ledger v1 -->', '## Ledger: #12 replay', '']
    if si: L += ['- started: ' + si[0]['Start (UTC)'], '- start checks: replay', '']
    L += ['### Tasks', '', '| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |', '|---|---|---|---|---|---|---|---|---|'] + rows + ['']
    if waits:
        L += ['### Waits', '', '| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |', '|---|---|---|---|---|---|---|']
        for w in waits: L.append('| ' + ' | '.join(w[k] for k in ['Id', 'Kind', 'Agent', 'Start (UTC)', 'End (UTC)', 'Held item', 'What']) + ' |')
        L.append('')
    if touches:
        L += ["### Person's touches", '', '| Time (UTC) | Kind | What |', '|---|---|---|']
        for x in touches: L.append('| ' + ' | '.join(x[k] for k in ['Time (UTC)', 'Kind', 'What']) + ' |')
        L.append('')
    open(os.path.join(outdir, 'ledger.md'), 'w').write('\n'.join(L))


def values_new(d):
    subs = {s['number']: s for s in json.load(open(d + '/subissues.json')) if s['user']['login'] == 'lead'}
    text = open(d + '/ledger.md').read(); t = tables(text)
    tasks = t['Tasks']; waits = t.get('Waits', []); touches = t.get("Person's touches", [])
    m = re.search(r'^- started: (\S+)', text, re.M)
    start = mins(m.group(1)) if m else None
    ap = [r for r in touches if r['Kind'] == 'approval']
    approval = mins(ap[0]['Time (UTC)']) if ap else None
    out = []
    if start is not None and approval is not None:
        total, per, aw = measure1(start, approval, waits)
        out += [('total_min', total), ('person_min', per['person']), ('limits_min', per['limits']), ('stalled_min', per['stalled']),
                ('interrupted_min', per['interrupted']), ('andon_min', per['andon']), ('agent_working_min', aw), ('hours', '%.2f' % (int(total * 100 / 60 + 0.5) / 100.0))]
    krows = []
    for r in tasks:
        s = subs[int(r['Task'].lstrip('#'))]
        if s['created_at'] is None: continue
        cs = int(datetime.datetime.strptime(s['created_at'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=datetime.timezone.utc).timestamp() // 60)
        ce = int(datetime.datetime.strptime(s['closed_at'], '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=datetime.timezone.utc).timestamp() // 60)
        ids = [x.strip() for x in r['Waits'].split(',') if x.strip() not in ('', '-')]
        wk = row_working(cs, ce, ids, waits)
        out.append(('task%s_%s_%s_working' % (r['#'], re.sub(r'[^a-z0-9]+', '-', r['Stage'].lower()).strip('-'), r['Role']), wk))
        krows.append({'role': r['Role'], 'working': wk, 'label': r['#']})
    if krows or start is not None:
        f = kind4(krows); out.append(('kind4_flags', ','.join(str(x) for x in f) if f else 'none'))
    out.append(('touches', len(touches)))
    out.append(('rework_feedback_briefs', sum(1 for s in subs.values() if s['title'].startswith('rework '))))
    for role in ROLES:
        ag = []
        for r in tasks:
            if r['Role'] == role:
                for a in r['Agents'].split(','):
                    a = a.strip()
                    if a and a != '-' and a not in ag: ag.append(a)
        if ag: out.append(('agents_' + role, ','.join(ag)))
    for role in ROLES:
        pk = [int(r['Peak ctx']) for r in tasks if r['Role'] == role and re.fullmatch(r'[0-9]+', r['Peak ctx'])]
        if pk: out.append(('peak_' + role, max(pk)))
    out.append(('role_rows', sum(1 for r in tasks if r['Role'] in ROLES and r['Agents'] not in ('-', ''))))
    return out, [{'stage': r['Stage'], 'role': r['Role'], 'agents': r['Agents'], 'result': r['Result'], 'notes': r['Notes']} for r in tasks]


if __name__ == '__main__':
    mode = sys.argv[1]
    if mode == 'reexpress':
        reexpress(sys.argv[2], sys.argv[3]); sys.exit(0)
    vals, rows = values_old(sys.argv[2]) if mode == 'old' else values_new(sys.argv[2])
    for k, v in vals: print('%s\t%s' % (k, v))
    if len(sys.argv) > 3:
        for i in sys.argv[3:]:
            print('gemba_pick_id%s\t%s' % (i, gemba(rows, int(i))))
