"""Reader A of the gemba sample rule (hansei.md section 6, contracts/60-gemba-sample.md section 1), written from the contract.
Usage: python3 -I gemba_pick.py <log.md> <id>   prints  <row> <flag>   (flag is - when the row is eligible; 'none' when no stage is picked)"""
import re, sys

ROLES = ['product-owner', 'architect', 'developer', 'qa-engineer', 'security-reviewer', 'devops', 'docs-writer']


def cells(ln):
    return [c.strip() for c in ln.strip().strip('|').split('|')]


def rows(path):
    tbl = [ln for ln in open(path).read().split('\n') if ln.startswith('|')]
    hdr = [h.lower() for h in cells(tbl[0])]
    out = []
    for pos, ln in enumerate(tbl[2:]):
        c = cells(ln)
        g = lambda name: c[hdr.index(name)] if name in hdr and hdr.index(name) < len(c) else None
        agents = g('agents') if 'agents' in hdr else g('agent')
        out.append({'n': g('#') if '#' in hdr else str(pos), 'role': g('role'), 'agents': agents,
                    'result': g('result'), 'notes': g('notes'), 'has_result': 'result' in hdr})
    return out


def pick(path, ident):
    rs = [r for r in rows(path) if r['role'] in ROLES and r['agents'] not in (None, '-')]

    def flagged(r):
        if not r['has_result']:
            return True
        if not (r['result'] or '').strip().lower().startswith(('done', 'pass')):
            return True
        return bool(re.search(r'paused by A[0-9]', r['notes'] or ''))
    if not rs:
        return 'none', '-'
    el = [r for r in rs if not flagged(r)]
    if el:
        return el[ident % len(el)]['n'], '-'
    r = rs[ident % len(rs)]
    m = re.search(r'paused by A[0-9]+', r['notes'] or '')
    first = (r['result'] or '').split()[0] if (r['result'] or '').split() else '-'
    if (r['result'] or '').strip().lower().startswith(('done', 'pass')) and m:
        first = m.group(0)
    return r['n'], first


if __name__ == '__main__':
    for i in sys.argv[2:]:   # one line per id
        a, b = pick(sys.argv[1], int(i))
        print(a, b)
