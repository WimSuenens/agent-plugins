#!/usr/bin/env python3
"""A reading of the written rules of references/baseline.md and references/a3.md, run on records.

QA's replay tool for #57 (nothing here ships). It follows the standard's text step by step:
  body     <records.jsonl> <session-release> [main-factory.md] [a3.jsonl]   -> the baseline body (baseline.md section 7)
  a3problem <ledger.json>      -> a3.md section 4 (the run's one problem)
  a3classify <ledger.json>     -> a3.md section 6 (before, during, after)
  a3change <ledger.json>       -> a3.md sections 6 and 7 (the change line)
records.jsonl is the output of the template's Find records command: one JSON object per line {id, html_url, created_at, body}.
Where the text is silent or ambiguous the choice made is marked  # READING:  so the verdict can list it.
Run as: python3 -I baseline_replay.py ...
"""
import json, re, sys
from fractions import Fraction

ROLES = ['product-owner', 'architect', 'developer', 'qa-engineer', 'security-reviewer', 'devops', 'docs-writer']
LT = ['total', 'agent working', 'waiting for the person', 'waiting on limits', 'stalled', 'interrupted', 'andon']
TOUCH = ['decision cards', 'demos', 'approvals', 'overturns', 'other']
SEMVER = re.compile(r'^factory (0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$')
MARK = re.compile(r'^<!-- factory:hansei v([0-9]+) -->\r?$')


def split_top(s, sep):
    """split on sep outside parentheses"""
    out, depth, cur, i = [], 0, '', 0
    while i < len(s):
        ch = s[i]
        if ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        if depth == 0 and s.startswith(sep, i):
            out.append(cur)
            cur = ''
            i += len(sep)
            continue
        cur += ch
        i += 1
    out.append(cur)
    return out


# ---------------------------------------------------------------- values
# a state is ('v', number) | ('na',) | ('nc', reason)
def dur(s):
    m = re.fullmatch(r'(?:(\d+)h(\d\d)m|(\d+)m)', s)
    if not m:
        return None
    return int(m.group(1)) * 60 + int(m.group(2)) if m.group(1) is not None else int(m.group(3))


def state(s, kind):
    s = s.strip()
    if s.startswith('n/a'):
        return ('na',)
    m = re.match(r'not captured \((.*)\)$', s)
    if m:
        return ('nc', m.group(1))
    if s == 'pending resurvey':
        return ('nc', 'pending resurvey')  # READING (O1: the reason text is the words themselves, spanned like any reason): no reason text exists for 'pending resurvey'; the words themselves
    if kind == 'dur':
        d = dur(s)
        return ('v', d) if d is not None else ('nc', 'unparsed')
    m = re.match(r'(\d+)', s)  # a count, or a token total (the number before the bracket)
    return ('v', int(m.group(1))) if m else ('nc', 'unparsed')


def fmt_dur(x):
    m = int((Fraction(x) + Fraction(1, 2)) // 1)  # rounded half up to the whole minute
    return '%dh%02dm' % (m // 60, m % 60) if m >= 60 else '%dm' % m


def median(vals):
    v = sorted(vals)
    n = len(v)
    if n % 2:
        return Fraction(v[n // 2])
    return Fraction(v[n // 2 - 1] + v[n // 2], 2)


def fmt_num(x):
    return str(int(x)) if x.denominator == 1 else '%d.5' % (x.numerator // x.denominator)


def cut(r):
    return r if len(r) <= 120 else r[:120] + '…'  # READING: 120 characters, then the ellipsis


def span(r):
    """baseline.md section 1: cut first, then neutralise (newline to a space, backtick to ', @ to (at), < to (lt)), then a code span.
    READING: each reason is its own code span; the fixed 'unreadable <key> line' text is the standard's own and is not spanned."""
    if r.startswith('unreadable ') and r.endswith(' line'):
        return r
    r = cut(r).replace('\n', ' ').replace('`', "'").replace('@', '(at)').replace('<', '(lt)')
    return '`' + r + '`'


def reasons(sts):
    out = []
    for s in sts:
        if s[0] == 'nc':
            r = span(s[1])
            if r not in out:
                out.append(r)
    return '; '.join(out)


def r1(sts, kind, scope):
    """R1: the reading of a quantity over the item states of one section"""
    n = len(sts)
    if n == 0:
        return 'not captured (no items in %s)' % scope
    vs = [s[1] for s in sts if s[0] == 'v']
    k = len(vs)
    m = sum(1 for s in sts if s[0] == 'nc')
    a = sum(1 for s in sts if s[0] == 'na')
    if k >= 1:
        med = median(vs)
        txt = fmt_dur(med) if kind == 'dur' else fmt_num(med)
        return '%s (%d of %d items%s%s)' % (txt, k, n, ', %d not captured' % m if m else '', ', %d n/a' % a if a else '')
    if m >= 1:
        return 'not captured (%d of %d items: %s%s)' % (m, n, reasons(sts), ', %d n/a' % a if a else '')
    return 'n/a (did not run in any of %d items)' % n


FPY_ORDER = ['pass first time', 'pass first time (low)', 'failed first time', 'n/a', 'not captured']
DOOR_ORDER = ['confirmed', 'contradicted', 'not exercised', 'not captured']


def fpy_outcome(s):
    s = s.strip()
    if s.startswith('not captured'):
        m = re.match(r'not captured \((.*)\)$', s)
        return 'not captured', m.group(1) if m else ''
    if s.startswith('n/a'):
        return 'n/a', ''
    m = re.match(r'pass first time \((\d+) low\)$', s)
    if m:
        return 'pass first time (low)', ''
    return s, ''


def r2(entries, order, unit, scope):
    """entries: list of (outcome, reason)"""
    L = len(entries)
    if L == 0:
        return 'not captured (no items in %s)' % scope  # READING: R2 says nothing for an empty section; 'every field likewise'
    parts = []
    for o in order:
        hit = [e for e in entries if e[0] == o]
        if not hit:
            continue
        if o == 'not captured':
            rs = []
            for e in hit:
                r = span(e[1])
                if r not in rs:
                    rs.append(r)
            parts.append('not captured %d (%d of %d %s: %s)' % (len(hit), len(hit), L, unit, '; '.join(rs)))
        else:
            parts.append('%s %d' % (o, len(hit)))
    return ', '.join(parts)


# ---------------------------------------------------------------- records
class Rec:
    pass


def parse(c):
    body = c['body']
    lines = body.split('\n')
    r = Rec()
    r.id, r.url, r.created = c['id'], c['html_url'], c['created_at']
    r.body = body
    m = MARK.match(lines[0])
    r.version = int(m.group(1))
    m = re.match(r'^## Hansei: #(\d+) ', lines[1]) if len(lines) > 1 else None
    r.item = int(m.group(1)) if m else None
    head = {}
    for ln in lines:
        mm = re.match(r'^- ([a-z -]+): (.*)$', ln)
        if mm and mm.group(1) not in head:
            head[mm.group(1)] = mm.group(2)
    r.series = head.get('series')
    r.plugin = head.get('plugin')
    r.standard = head.get('standard')
    r.tooling = head.get('tooling')
    r.ovr = head.get('active overrides', 'none')
    r.f = {}  # field -> (kind, state)
    if r.version not in (3, 4, 5):
        return r
    mm = re.search(r'^1\. lead time: (.*)$', body, re.M)
    if mm:
        for part in split_top(mm.group(1), '; '):
            for lab in LT:
                if part.startswith(lab + ' '):
                    r.f[('lt', lab)] = state(part[len(lab) + 1:], 'dur')
    mm = re.search(r'^2\. first-pass yield: (.*)$', body, re.M)
    if mm:
        for part in split_top(mm.group(1), '; '):
            for lab in ['qa', 'security', 'acceptance demo']:
                if part.startswith(lab + ' '):
                    r.f[('fpy', lab)] = fpy_outcome(part[len(lab) + 1:])
    mm = re.search(r'^3\. rework: (.*)$', body, re.M)
    if mm:
        txt = mm.group(1)
        txt = txt.replace('feedback briefs ', '', 1)
        for part in split_top(txt, '; '):
            for sub in split_top(part, ', '):
                sub = sub.strip()
                for lab in ROLES + ['overturned two-way decisions']:
                    if sub.startswith(lab + ' '):
                        r.f[('rw', lab)] = state(sub[len(lab) + 1:], 'cnt')
    # baseline.md section 1: a measure line that matches none of the forms of section 4 reads `not captured (unreadable <key> line)`
    def unread(key, labs, mk):
        for lab in labs:
            if lab not in [k[1] for k in r.f if k[0] == mk] or any(k[0] == mk and k[1] == lab and v == ('nc', 'unparsed') for k, v in r.f.items()):
                r.f[(mk, lab)] = ('nc', 'unreadable %s line' % key)
    if re.search(r'^1\. lead time: ', body, re.M):
        unread('lead time', LT, 'lt')
    if re.search(r'^3\. rework: ', body, re.M):
        unread('rework', ROLES + ['overturned two-way decisions'], 'rw')
    if re.search(r"^6\. person's touches: ", body, re.M):
        unread("person's touches", TOUCH, 'tc')
    mm = re.search(r'^4\. escaped defects: (.*)$', body, re.M)
    r.escaped = mm.group(1) if mm else ''
    for role in ['lead'] + ROLES:
        mm = re.search(r'^   - %s: (.*)$' % re.escape(role), body, re.M)
        if mm:
            for part in split_top(mm.group(1), '; '):
                if part.startswith('spend '):
                    r.f[('tok', role, 'spend')] = state(part[6:], 'cnt')
                elif part.startswith('peak context '):
                    r.f[('tok', role, 'peak context')] = state(part[13:], 'cnt')
    mm = re.search(r"^6\. person's touches: (.*)$", body, re.M)
    if mm:
        for part in split_top(mm.group(1), '; '):
            for lab in TOUCH:
                if part.startswith(lab + ' '):
                    r.f[('tc', lab)] = state(part[len(lab) + 1:], 'cnt')
    mm = re.search(r'^7\. doors:(.*)$', body, re.M)
    r.doors = []
    if mm:
        rest = mm.group(1).strip()
        if rest:
            o, rs = fpy_outcome(rest) if not rest.startswith('pending') else ('not captured', 'pending resurvey')
            r.doors.append((o, rs))
        else:
            tail = body.split(mm.group(0), 1)[1]
            for ln in tail.split('\n'):
                m2 = re.match(r'^   - .*: (confirmed|contradicted|not exercised)$', ln)
                if m2:
                    r.doors.append((m2.group(1), ''))
    # overrides: name -> extent
    r.ov = {}
    r.ov_list_v3 = False
    if r.ovr.strip() != 'none':
        for e in split_top(r.ovr, '; '):
            m2 = re.match(r'^([a-z0-9-]+) \(since \d{4}-\d\d-\d\d; (whole item|from [^)]*|until [^)]*)\)$', e.strip())
            if m2:
                r.ov[m2.group(1)] = m2.group(2).split(' ')[0] if m2.group(2) != 'whole item' else 'whole'
            else:
                r.ov_list_v3 = True
    return r


# ---------------------------------------------------------------- baseline
def main_overrides(path):
    out = []
    if not path or path == '-':
        return out
    name = None
    for ln in open(path).read().split('\n'):
        m = re.match(r'^### ([a-z0-9-]+)$', ln)
        if m:
            name = m.group(1)
            out.append({'name': name, 'status': None, 'order': len(out)})
        m = re.match(r'^- status: (.*)$', ln)
        if m and name:
            out[-1]['status'] = m.group(1)
    return out


def baseline(records, session, mainpath, a3s):
    notes_drop = {}
    for a in a3s:
        for ln in a['body'].split('\n'):
            m = re.match(r'^- answer: (.*)$', ln)
            if m:
                for e in m.group(1).split('; '):
                    mm = re.match(r'^([a-z0-9]+(?:-[a-z0-9]+)*)(?: \(experiment\))?: drop (\d{4}-\d\d-\d\d)$', e)
                    if mm:
                        notes_drop[mm.group(1)] = (mm.group(2), a['html_url'])
    recs = sorted([parse(c) for c in records], key=lambda r: (r.created, r.item or 0))
    skipped, excluded, ignored, calib = [], [], [], []
    seen_items = set()
    items = []  # included, readable, series-bound
    series_std = {}
    readable_rel = []  # all readable release records (series M.N) for the "replaced by" rule
    for r in recs:
        if r.version not in (3, 4, 5):
            skipped.append('skipped: #%s %s (schema v%d)' % (r.item if r.item else '?', r.url, r.version) if r.item else 'skipped: #? %s (schema v%d)' % (r.url, r.version))
            continue
        if r.item is None:
            skipped.append('skipped: #? %s (no item number)' % r.url)
            continue
        if r.item in seen_items:
            ignored.append('ignored: #%d %s (second record for the item)' % (r.item, r.url))
            continue
        seen_items.add(r.item)
        if r.series and r.series.startswith('calibration'):
            # baseline.md section 1: the plugin text is a reason text: cut, neutralised, one code span; `factory ` stays outside
            ptxt = (r.plugin or '')[len('factory '):] if (r.plugin or '').startswith('factory ') else r.plugin
            calib.append('- #%d %s — factory %s' % (r.item, r.url, span(ptxt or '')))
            continue
        m = SEMVER.match(r.plugin or '')
        if r.series != 'release' or not m:
            skipped.append('skipped: #%d %s (series and plugin disagree)' % (r.item, r.url))
            continue
        r.mn = '%s.%s' % (m.group(1), m.group(2))
        r.semver = (r.plugin or '')[len('factory '):]
        readable_rel.append(r)
        if r.mn not in series_std:
            series_std[r.mn] = r.standard
        elif r.standard != series_std[r.mn]:
            excluded.append('excluded: #%d %s (standard differs under %s; the declared release step was skipped, see andon kind 6)' % (r.item, r.url, r.mn))
            continue
        if r.version in (4, 5) and r.ov_list_v3:
            # S3: an `active overrides` line outside the extent grammar is skipped and named; the key it carried is not used
            skipped.append('skipped: #%d %s (active overrides line not in its grammar)' % (r.item, r.url))
            continue
        if r.version == 3 and r.ov_list_v3:
            excluded.append('excluded: #%d %s (override extent not recorded, schema v3)' % (r.item, r.url))
            continue
        if r.version == 5:
            # #60 baseline.md section 3 item 7: exactly one `- gemba: ` line in the header block; the content is never read
            hdr = r.body.split('\n### Measures', 1)[0].split('\n')
            ng = len([ln for ln in hdr if ln.startswith('- gemba: ')])
            if ng == 0:
                skipped.append('skipped: #%d %s (gemba line missing)' % (r.item, r.url))
                continue
            if ng > 1:
                skipped.append('skipped: #%d %s (gemba line repeated)' % (r.item, r.url))
                continue
        r.key = frozenset(n for n, e in r.ov.items() if e == 'whole')
        r.partial = [n for n, e in r.ov.items() if e != 'whole']
        items.append(r)
    ov = main_overrides(mainpath)
    pat = re.compile(r'^(kept (\d{4}-\d\d-\d\d) for (next run|#\d+)|promote chosen (\d{4}-\d\d-\d\d))$')
    adopted = []
    for o in ov:
        m = pat.match(o['status'] or '')
        if m:
            o['kind'] = 'kept' if o['status'].startswith('kept') else 'promote chosen'
            o['date'] = m.group(2) or m.group(4)
            adopted.append(o)
    adopted.sort(key=lambda o: (o['date'], o['order']))
    adopted_names = [o['name'] for o in adopted]
    active = set(o['name'] for o in ov if o['status'] == 'active')
    sm = re.match(r'^(\d+)\.(\d+)\.(\d+)$', session)
    cur = '%s.%s' % (sm.group(1), sm.group(2)) if sm else None
    all_series = sorted(set(r.mn for r in items) | ({cur} if cur else set()), key=lambda s: tuple(int(x) for x in s.split('.')), reverse=True)
    out = ['<!-- factory:baseline v1 -->', '# Factory baseline', '', '(intro)', '']

    def fields(its, scope):
        L = []
        n = len(its)
        def get(key, kind):
            return [r.f.get(key, ('nc', 'absent')) for r in its]
        L.append('- lead time: ' + '; '.join('%s %s' % (lab, r1(get(('lt', lab), 'dur'), 'dur', scope)) for lab in LT))
        L.append("  the parts are read on their own: their medians need not add up to the total's")
        L.append('- first-pass yield: ' + '; '.join('%s %s' % (lab, r2([r.f.get(('fpy', lab), ('not captured', 'absent')) for r in its], FPY_ORDER, 'items', scope)) for lab in ['qa', 'security', 'acceptance demo']))
        L.append('- rework: ' + '; '.join('%s %s' % (lab, r1(get(('rw', lab), 'cnt'), 'cnt', scope)) for lab in ROLES + ['overturned two-way decisions']))
        if n == 0:
            L.append('- escaped defects: not captured (no items in %s)' % scope)
        else:
            rs = []
            for r in its:
                m = re.match(r'not captured \((.*)\)$', r.escaped)
                x = m.group(1) if m else r.escaped
                if x not in rs:
                    rs.append(x)
            L.append('- escaped defects: not captured (%s)' % '; '.join(span(x) for x in rs))
        L.append('- tokens:')
        for role in ['lead'] + ROLES:
            L.append('  - %s: spend %s; peak context %s' % (role, r1(get(('tok', role, 'spend'), 'cnt'), 'cnt', scope), r1(get(('tok', role, 'peak context'), 'cnt'), 'cnt', scope)))
        L.append("- person's touches: " + '; '.join('%s %s' % (lab, r1(get(('tc', lab), 'cnt'), 'cnt', scope)) for lab in TOUCH))
        ents = []
        for r in its:
            ents += r.doors if r.doors else [('not captured', 'absent')]
        L.append('- doors: ' + r2(ents, DOOR_ORDER, 'entries', scope))
        return L

    def items_line(its):
        if not its:
            return '- items: 0 items'
        return '- items: %d items: ' % len(its) + '; '.join('#%d %s' % (r.item, r.url) for r in its)

    def series_block(mn, role, heading, cur_flag):
        its = [r for r in items if r.mn == mn]
        L = ['### Series %s — %s' % (mn, heading)]
        if its:
            rel = []
            tools = []
            for r in its:
                if r.semver not in rel:
                    rel.append(r.semver)
                if r.tooling not in tools:
                    tools.append(r.tooling)
            L.append('- releases: factory ' + ', '.join(rel))
            L.append('- standard: ' + series_std[mn])
            L.append('- tooling: ' + ', '.join(tools))
        else:
            L.append("- releases: factory %s (the session's release)" % session)
            L.append('- standard: not captured (no items in series)')
            L.append('- tooling: not captured (no items in series)')
        nis = []
        for r in its:
            for nme in r.partial:
                nis.append('#%d %s (%s in force for part of the item)' % (r.item, r.url, nme))
        L.append('- not in any section: ' + ('; '.join(nis) if nis else 'none'))
        vs = sorted({r.version for r in its})
        if len(vs) > 1:
            # #60 baseline.md section 7: every schema the series holds, ascending; one form per set (v3 and v5 alone: READING, the text shows three forms)
            L.append('- records: schema ' + ', '.join('v%d' % v for v in vs[:-1]) + ' and v%d' % vs[-1] + ' read together')
        keys = []
        for r in its:
            if not r.partial and r.key not in keys:
                keys.append(r.key)
        refkey = frozenset(adopted_names)
        if cur_flag:
            if refkey in keys:
                keys.remove(refkey)
            keys.insert(0, refkey)  # the reference section is written first, even with no item
        for k in keys:
            sits = [r for r in its if not r.partial and r.key == k]
            kn = ', '.join(sorted(k, key=lambda x: (x not in adopted_names, adopted_names.index(x) if x in adopted_names else 0, x))) if k else 'none'
            if not cur_flag:
                lab = 'history (series replaced)'
            elif k == refkey:
                lab = 'reference'
            else:
                labs = []
                if k:
                    names = sorted(k)
                    for i, o in enumerate(adopted):
                        before = frozenset(adopted_names[:i])
                        if k == before:
                            labs.append('before %s (%s %s)' % (o['name'], o['kind'], o['date']))
                    for nme in names:
                        if nme in notes_drop:
                            labs.append('%s dropped %s' % (nme, notes_drop[nme][0]))
                elif adopted:
                    o = adopted[0]
                    labs.append('before %s (%s %s)' % (o['name'], o['kind'], o['date']))
                if labs:
                    ds = []
                    for o in labs:
                        pass
                    dur_names = []
                    for l in labs:
                        mm = re.match(r'^(?:before )?([a-z0-9-]+)', l)
                        dur_names.append(mm.group(1))
                    during = [r.item for r in its if any(p in dur_names for p in r.partial)]
                    lab = 'history: ' + ' / '.join(labs) + ''.join('; during-item #%d' % d for d in sorted(during))
                else:
                    if any(x in active for x in k):
                        lab = 'other: %s (answer pending)' % sorted(x for x in k if x in active)[0]
                    else:
                        lab = 'other'
            L.append('')
            L.append('#### Section — whole-item overrides: %s — %s' % (kn, lab))
            L.append(items_line(sits))
            L += fields(sits, 'series' if (not sits and cur_flag and k == refkey and not its) else 'section')
        return L

    out.append('## Current')
    out.append('')
    if cur:
        out += series_block(cur, 'cur', 'current', True)
    out.append('')
    out.append('## History')
    out.append('')
    hist = [s for s in all_series if s != cur]
    if not hist:
        out.append('- none')
    for mn in hist:
        mine = [r for r in readable_rel if r.mn == mn]
        last = max((r.created for r in mine), default='')
        later = [r for r in readable_rel if r.created > last and r.mn != mn]
        if later:
            head = 'replaced %s by %s' % (later[0].created[:10], later[0].mn)
        else:
            head = 'replaced by %s (first item pending)' % cur
        out += series_block(mn, 'hist', head, False)
        out.append('')
    out.append('## Calibration (pre-baseline)')
    out += calib if calib else ['- none']
    out.append('')
    out.append('## Skipped and excluded')
    se = ['- ' + x for x in skipped + excluded + ignored]
    out += se if se else ['- none']
    out.append('')
    out.append('## Notes')
    nl = ['- %s dropped %s (A3 %s)' % (k, v[0], v[1]) for k, v in sorted(notes_drop.items())]
    out += nl if nl else ['- none']
    return '\n'.join(out) + '\n'


# ---------------------------------------------------------------- A3 rules
def target(line):
    for tok in line.split():
        if re.fullmatch(r'[A-Za-z0-9_./-]+\.(md|sh|json)', tok):
            return tok
    m = re.search(r'(## [^,.;]+)', line)  # READING: a heading token; the text says 'the first token that begins ## '
    if m:
        return m.group(1)
    return re.sub(r' +', ' ', line.lower())


def a3problem(L):
    if not L.get('closed_items', 1):
        return {'problem': 'none chosen (no closed item)'}
    if L.get('andons'):
        cand = {}
        for a in L['andons']:
            t = target(a['process_item'])
            c = cand.setdefault(t, {'items': set(), 'first': a['raised']})
            c['items'].add(a['item'])
            c['first'] = min(c['first'], a['raised'])
        order = sorted(cand.items(), key=lambda kv: (-len(kv[1]['items']), kv[1]['first']))
        p = order[0]
        rest = ['%s: %d item%s' % (t, len(c['items']), 's' if len(c['items']) != 1 else '') for t, c in order[1:]]  # READING: '(s)' written out as a plural
        return {'problem': p[0], 'count': str(len(p[1]['items'])), 'other': '; '.join(rest)}
    cands = []
    for i, f in enumerate(L.get('fields', [])):
        if f['k_base'] >= 1 and f['base'] > 0 and f['k_run'] >= 1:
            cands.append((Fraction(f['run']) / Fraction(f['base']), i, f['field']))
    if not cands:
        return {'problem': 'none chosen (no baseline reading to compare with)'}
    cands.sort(key=lambda c: (-c[0], c[1]))
    top = cands[0]
    r = float(top[0])
    prob = '%s ×%.2f' % (top[2], r + 1e-9)
    if top[0] <= 1:
        prob += ' not above baseline'
    above = ['%s ×%.2f' % (c[2], float(c[0]) + 1e-9) for c in cands[1:] if c[0] > 1]
    at = len([c for c in cands[1:] if c[0] <= 1])
    parts = above + (['%d others at or below baseline' % at] if at else [])
    return {'problem': prob, 'other': '; '.join(parts)}


def a3classify(L):
    X, series, R0 = L['experiment']['name'], L['experiment']['series'], set(L['experiment']['reference'])
    res = {'before': [], 'during': [], 'after': [], 'neither': []}
    for r in L['records']:
        ov = r.get('overrides', {})
        partial = [n for n, e in ov.items() if e != 'whole']
        key = set(n for n, e in ov.items() if e == 'whole')
        # a3.md section 6, first rule that holds decides: 1 calibration or excluded, 2 during-item (any series),
        # 3 after-item (run list + X whole item, any series), 4 before-item (the series is tested only here), 5 rest
        if r.get('calibration') or r.get('excluded'):
            res['neither'].append(r['item'])
        elif ov.get(X) in ('from', 'until'):
            res['during'].append(r['item'])
        elif r.get('in_run') and ov.get(X) == 'whole':
            res['after'].append(r['item'])
        elif r['series'] == series and X not in ov and not partial and key == R0:
            res['before'].append(r['item'])
        else:
            res['neither'].append(r['item'])
    return res


def reading(vals_by_item, items, kind):
    sts = []
    for i in items:
        v = vals_by_item[str(i)]
        sts.append(('na',) if v == 'na' else ('nc', v[3:]) if v.startswith('nc:') else ('v', int(v)))
    return sts


def a3change(L):
    X = L['experiment']['name']
    cl = a3classify(L)
    R0 = set(L['experiment']['reference'])
    recs = {r['item']: r for r in L['records']}
    unit = L['unit']  # 'min' | 'count'
    direction = L['direction']
    vals = L['values']
    after = cl['after']
    out = {}
    if not after:
        out['after'] = 'not captured (no after-item: no item closed in this run with %s in force for the whole of it)' % X
        out['change'] = 'not captured (no after-item)'
        return out
    ser = [recs[i]['series'] for i in after]
    if any(s != L['experiment']['series'] for s in ser):
        out['change'] = 'not comparable (release moved from %s to %s)' % (L['experiment']['series'], ', '.join(sorted(set(ser))))
        return out
    probs = []
    for i in after:
        key = set(n for n, e in recs[i]['overrides'].items() if e == 'whole') - {X}
        if key != R0:
            for y in sorted(key - R0):
                probs.append('override %s in force for the after-items only' % y)
            for y in sorted(R0 - key):
                probs.append('override %s not in force for the after-items' % y)
    if probs:
        out['change'] = 'not comparable (%s)' % '; '.join(dict.fromkeys(probs))
        return out
    ast = reading(vals, after, unit)
    if all(s[0] == 'na' for s in ast):
        out['change'] = 'not comparable (the role did not run in the after-items)'
        return out
    vs = [s[1] for s in ast if s[0] == 'v']
    if not vs:
        out['change'] = 'not captured (%s)' % reasons(ast)
        return out
    bst = reading(vals, cl['before'], unit)
    bv = [s[1] for s in bst if s[0] == 'v']
    d = median(vs) - median(bv)
    if d == 0:
        out['change'] = '0 — no change'
        return out
    sign = '+' if d > 0 else '-'
    mag = fmt_num(abs(d)) + ('m' if unit == 'min' else '')
    toward = (d < 0) == (direction == 'down')
    out['change'] = '%s%s — %s the intended direction (%s)' % (sign, mag, 'toward' if toward else 'against', direction)
    return out


def main(argv):
    cmd = argv[1]
    if cmd == 'body':
        recs = [json.loads(l) for l in open(argv[2]) if l.strip()]
        main_path = argv[4] if len(argv) > 4 else None
        a3s = [json.loads(l) for l in open(argv[5]) if l.strip()] if len(argv) > 5 else []
        sys.stdout.write(baseline(recs, argv[3], main_path, a3s))
    elif cmd in ('a3problem', 'a3classify', 'a3change'):
        L = json.load(open(argv[2]))
        r = {'a3problem': a3problem, 'a3classify': a3classify, 'a3change': a3change}[cmd](L)
        print(json.dumps(r, ensure_ascii=False, sort_keys=True))
    else:
        sys.exit('unknown command')


if __name__ == '__main__':
    main(sys.argv)
