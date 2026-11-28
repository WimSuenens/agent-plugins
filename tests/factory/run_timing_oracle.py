#!/usr/bin/env python3
"""QA's independent reading of contracts/286-run-timing.md sections 4.2 and 4.3 (nothing here ships).

  line --run-body <file> --close <UTC> [--ledger <file>]...   -> the `- run timing:` line, measured form only
  gen <dir> <seed>                                            -> writes a random run body and ledgers to <dir>, prints the line's arguments

It shares no code with plugins/factory/scripts/run-timing.sh: a minute-by-minute replay, the slow and obvious way.
Not-captured cases and --lite are not read here (the shell tests pin those from the contract's own texts).
Run as: python3 -I run_timing_oracle.py ...
"""
import random, re, sys, os
from datetime import datetime, timezone

KINDS = ['person', 'limits', 'stalled', 'interrupted']
TIME = re.compile(r'^~?(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d)(?::\d\d(?:\.\d+)?)?Z$')


def minute(s):
    m = TIME.match(s.strip())
    if not m:
        raise SystemExit('oracle: not a time: ' + s)
    y, mo, d, h, mi = (int(x) for x in m.groups())
    return int(datetime(y, mo, d, h, mi, tzinfo=timezone.utc).timestamp()) // 60


def dur(n):
    return '%dh%02dm' % (n // 60, n % 60) if n >= 60 else '%dm' % n


def section(text):
    out, on = [], False
    for ln in text.splitlines():
        if ln.startswith('## '):
            on = ln.rstrip() == '## Factory run'
            continue
        if on:
            out.append(ln)
    return out


def table(lines, heading):
    rows, on = [], False
    for ln in lines:
        if ln.startswith('### '):
            on = ln.strip() == heading
            continue
        if on and ln.startswith('|'):
            cells = [c.strip() for c in ln.strip().strip('|').split('|')]
            if cells and not set(cells[0]) <= set('-') and cells[0] not in ('#', 'Id', 'Time (UTC)'):
                rows.append(cells)
    return rows


def compute(body, close, ledgers):
    sec = section(open(body).read())
    S = minute(next(l for l in sec if l.startswith('- started: '))[len('- started: '):])
    C = minute(close)
    run_rows = [(r[1], minute(r[3]), minute(r[4])) for r in table(sec, '### Run waits')]
    items = []
    for f in ledgers:
        lines = open(f).read().splitlines()
        a = minute(next(l for l in lines if l.startswith('- started: '))[len('- started: '):])
        appr = [minute(r[0]) for r in table(lines, "### Person's touches") if r[1] == 'approval']
        b = appr[-1] if appr else C
        held = [(r[1], minute(r[3]), minute(r[4])) for r in table(lines, '### Waits') if r[5] == 'yes' and r[1] in KINDS]
        items.append((max(a, S), min(b, C), held))
    count = dict((k, 0) for k in KINDS)
    for m in range(S, C):
        F = [it for it in items if it[0] <= m < it[1]]
        if F:
            union = set()
            blocked = True
            for it in F:
                K = set(k for k, s, e in it[2] if s <= m < e)
                if not K:
                    blocked = False
                union |= K
            if not blocked:
                continue
        else:
            union = set(k for k, s, e in run_rows if s <= m < e)
            if not union:
                continue
        count[next(k for k in KINDS if k in union)] += 1
    raw = C - S
    return raw, count


def line(args):
    body, close, ledgers, i = None, None, [], 0
    while i < len(args):
        if args[i] == '--run-body':
            body = args[i + 1]
        elif args[i] == '--close':
            close = args[i + 1]
        elif args[i] == '--ledger':
            ledgers.append(args[i + 1])
        else:
            raise SystemExit('oracle: usage')
        i += 2
    raw, c = compute(body, close, ledgers)
    adj = raw - sum(c.values())
    print('- run timing: raw %s; adjusted %s; blocked: %s' % (dur(raw), dur(adj), ', '.join('%s %s' % (k, dur(c[k])) for k in KINDS)))


def hhmm(base, m):
    return datetime.fromtimestamp((base + m) * 60, tz=timezone.utc).strftime('%Y-%m-%dT%H:%MZ')


def gen(d, seed):
    r = random.Random(int(seed))
    base = minute('2026-12-01T09:00Z')
    raw = r.randint(60, 360)
    nitems = r.randint(0, 4)
    ids = [100 + j for j in range(nitems)]
    closed, inflight, ledger_files = [], [], []
    for n in ids:
        a = r.randint(-20, raw - 10)
        approved = r.random() < 0.8
        b = a + r.randint(5, raw)
        waits = []
        for w in range(r.randint(0, 5)):
            s = r.randint(a - 10, b)
            waits.append((r.choice(KINDS + ['andon']), s, s + r.randint(1, 60), r.choice(['yes', 'yes', 'no'])))
        f = os.path.join(d, 'l%d.md' % n)
        with open(f, 'w') as fh:
            fh.write('<!-- factory:ledger v1 -->\n## Ledger: #%d Item %d\n\n- started: %s\n\n### Waits\n\n' % (n, n, hhmm(base, a)))
            fh.write('| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |\n|---|---|---|---|---|---|---|\n')
            for j, (k, s, e, h) in enumerate(waits):
                fh.write('| W%d | %s | - | %s | %s | %s | wait %d |\n' % (j + 1, k, hhmm(base, s), hhmm(base, e), h, j + 1))
            fh.write("\n### Person's touches\n\n| Time (UTC) | Kind | What |\n|---|---|---|\n")
            if approved:
                fh.write('| %s | approval | merge and clean up |\n' % hhmm(base, b))
                closed.append(n)
            else:
                inflight.append(n)
        ledger_files.append(f)
    runrows = []
    for j in range(r.randint(0, 4)):
        s = r.randint(-10, raw)
        runrows.append((r.choice(KINDS), s, s + r.randint(1, 40)))
    body = os.path.join(d, 'run.md')
    with open(body, 'w') as fh:
        fh.write('# Map: generated %s\n\n## Factory run\n\n- started: %s\n- step: 9\n' % (seed, hhmm(base, 0).replace('Z', ':00Z')))
        fh.write('- in flight: %s\n' % (', '.join('#%d (item/%d)' % (n, n) for n in inflight) or 'none'))
        fh.write('- FREEZE: 1a2b3c4 (3.10.0)\n- lead sessions: s%s\n' % seed)
        fh.write('- closed in this run: %s\n' % (', '.join('#%d https://example.invalid/issues/%d#issuecomment-1' % (n, n) for n in closed) or 'none'))
        fh.write('- baseline: not yet\n\n### Run waits\n\n| # | Kind | Agent | Start | End | What |\n|---|---|---|---|---|---|\n')
        for j, (k, s, e) in enumerate(runrows):
            fh.write('| R%d | %s | lead | %s | %s | generated %d |\n' % (j + 1, k, hhmm(base, s), hhmm(base, e), j + 1))
        fh.write('\n## Destination\n')
    close = datetime.fromtimestamp((base + raw) * 60 + r.randint(0, 59), tz=timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    print(' '.join(['--run-body', body, '--close', close] + sum([['--ledger', f] for f in ledger_files], [])))


if __name__ == '__main__':
    if len(sys.argv) >= 2 and sys.argv[1] == 'line':
        line(sys.argv[2:])
    elif len(sys.argv) == 4 and sys.argv[1] == 'gen':
        gen(sys.argv[2], sys.argv[3])
    else:
        raise SystemExit('usage: run_timing_oracle.py line ... | gen <dir> <seed>')
