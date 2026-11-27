#!/usr/bin/env python3
"""QA's reading of the baseline's Runs section (contract 286-a3-v4-and-runs section 4; references/baseline.md section 9). Nothing here ships.

  runs <a3s.jsonl> <series,series...>   -> for each series block on the page: `### Series <M.N>` and its two Runs headings with their lines,
                                           then `### Skipped and excluded` with the A3s skipped for runs, when any

a3s.jsonl is what *Find A3s* returns: one JSON object per line {html_url, created_at, body}, any marker version.
It reads, from each v4 A3, the five lines `run`, `series and release`, `run timing`, `discipline`, `guardrails` and nothing else (AC-C3).
Where the contract is silent the choice is marked  # READING:
Run as: python3 -I runs_replay.py ...
"""
import json, re, sys
from fractions import Fraction

KINDS = ['person', 'limits', 'stalled', 'interrupted']
DUR = r'(?:[0-9]|[1-5][0-9])m|[1-9][0-9]*h[0-5][0-9]m'
NC = r'not captured \(([^()]{1,80})\)'
SLOT = '(?:%s|%s)' % (DUR, NC)
MEASURED = re.compile(r'^raw (%s); adjusted (%s); blocked: person (%s), limits (%s), stalled (%s), interrupted (%s)$' % (DUR, SLOT, SLOT, SLOT, SLOT, SLOT))
WHOLE = re.compile('^' + NC + '$')
FPY = re.compile(r'^first-pass yield (?:([0-9]+) of ([0-9]+) items passed first time(?:, ([0-9]+) not captured)?|not captured \(([0-9]+) of ([0-9]+) items\))$')
RW = re.compile(r'^rework per item (?:([0-9]+(?:, [0-9]+)*) \(([0-9]+) of ([0-9]+) items(?:, ([0-9]+) not captured)?\)|not captured \(([0-9]+) of ([0-9]+) items\))$')


def mins(d):
    m = re.fullmatch(r'(?:(\d+)h(\d\d)m|(\d+)m)', d)
    return int(m.group(1)) * 60 + int(m.group(2)) if m.group(1) else int(m.group(3))


def dur(n):
    return '%dh%02dm' % (n // 60, n % 60) if n >= 60 else '%dm' % n


def median(vals):
    v = sorted(Fraction(x) for x in vals)
    n = len(v)
    return v[n // 2] if n % 2 else (v[n // 2 - 1] + v[n // 2]) / 2


def half_up(f):
    return int(f + Fraction(1, 2)) if f >= 0 else -int(-f + Fraction(1, 2))


def num(f):
    # READING: a half kept as .5 (contract 4.2, <G2>); a whole number without a decimal point
    return str(f.numerator) if f.denominator == 1 else '%d.5' % (f.numerator // 2) if f.denominator == 2 else str(float(f))


def five(body):
    lines = body.replace('\r', '').split('\n')
    m = re.match(r'^<!-- factory:a3 v([0-9]+) -->$', lines[0])
    if not m:
        return None, None
    got = {}
    for ln in lines[1:]:
        for k in ('run', 'series and release', 'run timing', 'discipline', 'guardrails'):
            if ln.startswith('- %s: ' % k) and k not in got:
                got[k] = ln[len('- %s: ' % k):].strip()
    return m.group(1), got


def parse(url, f):
    """returns (record, None) or (None, skip line)"""
    run = re.match(r'^#([0-9]+) — (closed|run stopped)$', f.get('run', ''))
    ser = re.match(r'^([0-9]+\.[0-9]+); ', f.get('series and release', ''))
    rt = f.get('run timing', '')
    disc = f.get('discipline', '')
    g = f.get('guardrails', '')
    gp = g.split('; ', 1)
    for key, ok in (('run', run), ('series and release', ser), ('run timing', MEASURED.match(rt) or WHOLE.match(rt)), ('discipline', disc in ('off', 'on')),
                    ('guardrails', len(gp) == 2 and FPY.match(gp[0]) and RW.match(gp[1]))):
        if not ok:
            return None, 'skipped: A3 %s (%s line not in its grammar)' % (url, key)
    rec = {'url': url, 'map': run.group(1), 'stopped': run.group(2) == 'run stopped', 'series': ser.group(1), 'disc': disc}
    w = WHOLE.match(rt)
    if w:
        rec['whole'] = w.group(1)
    else:
        parts = re.match(r'^raw (.*); adjusted (.*); blocked: person (.*), limits (.*), stalled (.*), interrupted (.*)$', rt).groups()
        rec['slots'] = dict(zip(['raw', 'adjusted'] + KINDS, parts))
    f1 = FPY.match(gp[0])
    if f1.group(1) is not None:
        rec['fpy'] = (int(f1.group(1)), int(f1.group(2)), int(f1.group(3) or 0))
    else:
        rec['fpy'] = (0, int(f1.group(5)), int(f1.group(4)))
    r1 = RW.match(gp[1])
    if r1.group(1) is not None:
        rec['rw'] = ([int(x) for x in r1.group(1).split(', ')], int(r1.group(3)), int(r1.group(4) or 0))
    else:
        rec['rw'] = ([], int(r1.group(6)), int(r1.group(5)))
    return rec, None


def slot_fig(runs, key):
    j = len(runs)
    vals, reasons = [], []
    for r in runs:
        s = r['slots'][key]
        if re.fullmatch(DUR, s):
            vals.append(mins(s))
        else:
            reasons.append(re.match(NC, s).group(1))
    k, m = len(vals), len(reasons)
    if k == 0:
        # READING: the reasons of a k = 0 slot, each once, in run order, joined by '; ' (the contract names no separator: QA-286 open question Q2)
        seen = []
        for x in reasons:
            if x not in seen:
                seen.append(x)
        return 'not captured (%d of %d runs: %s)' % (m, j, '; '.join(seen))
    tail = ', %d not captured' % m if m else ''
    return '%s (%d of %d runs%s)' % (dur(half_up(median(vals))), k, j, tail)


def half(runs_all, disc):
    rs = [r for r in runs_all if r['disc'] == disc]
    if not rs:
        return ['- none (no run in series)']
    counted = [r for r in rs if not r['stopped'] and 'whole' not in r]
    nc = []
    for r in rs:
        if r['stopped']:
            nc.append('run stopped #%s %s' % (r['map'], r['url']))
        elif 'whole' in r:
            nc.append('run timing not captured (`%s`) #%s %s' % (r['whole'], r['map'], r['url']))
    j = len(counted)
    out = ['- runs: %d runs%s' % (j, (': ' + '; '.join('#%s %s' % (r['map'], r['url']) for r in counted)) if j else '')]
    out.append('- not counted: ' + ('; '.join(nc) if nc else 'none'))
    if j == 0:
        out.append('- run timing: raw not captured (no counted run); adjusted not captured (no counted run); blocked: ' +
                   ', '.join('%s not captured (no counted run)' % k for k in KINDS))
        out.append('- guardrails: not captured (no counted run)')
        return out
    out.append('- run timing: raw %s; adjusted %s; blocked: %s' % (slot_fig(counted, 'raw'), slot_fig(counted, 'adjusted'),
                                                                 ', '.join('%s %s' % (k, slot_fig(counted, k)) for k in KINDS)))
    P = sum(r['fpy'][0] for r in counted); N = sum(r['fpy'][1] for r in counted); C = sum(r['fpy'][2] for r in counted)
    if P == 0 and C == N:
        g1 = 'not captured (%d of %d items; %d runs)' % (C, N, j)
    else:
        g1 = '%d of %d items passed first time%s (%d runs)' % (P, N, ', %d not captured' % C if C else '', j)
    vals = sum((r['rw'][0] for r in counted), [])
    M = sum(r['rw'][2] for r in counted); NI = sum(r['rw'][1] for r in counted)
    if not vals:
        g2 = 'not captured (%d of %d items; %d runs)' % (M, NI, j)
    else:
        g2 = '%s (%d of %d items%s; %d runs)' % (num(median(vals)), len(vals), NI, ', %d not captured' % M if M else '', j)
    out.append('- guardrails: first-pass yield %s; rework per item %s' % (g1, g2))
    return out


def main(path, series_list):
    blocks = series_list.split(',')
    recs, skipped = [], []
    a3s = sorted((json.loads(l) for l in open(path) if l.strip()), key=lambda c: c['created_at'])
    for c in a3s:
        ver, f = five(c['body'])
        if ver != '4':
            continue  # v1 to v3 are never read for runs (no backfill); an unknown version is section 6's business
        rec, skip = parse(c['html_url'], f)
        if skip:
            skipped.append(skip)
        elif rec['series'] not in blocks:
            skipped.append('skipped: A3 %s (series %s has no block)' % (c['html_url'], rec['series']))
        else:
            recs.append(rec)
    out = []
    for s in blocks:
        rs = [r for r in recs if r['series'] == s]
        out.append('### Series %s' % s)
        out.append('#### Runs — discipline: off')
        out += half(rs, 'off')
        out.append('')
        out.append('#### Runs — discipline: on')
        out += half(rs, 'on')
    if skipped:
        out.append('### Skipped and excluded')
        out += ['- ' + x for x in skipped]
    print('\n'.join(out))


if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'runs':
        main(sys.argv[2], sys.argv[3])
    else:
        raise SystemExit('usage: runs_replay.py runs <a3s.jsonl> <series,...>')
