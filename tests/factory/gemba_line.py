"""Validator of the gemba line grammar (contracts/60-gemba-line.md section 2), written from the contract.
Usage: python3 -I gemba_line.py <line>   exit 0 and prints OK, or exit 1 and prints REJECT: <why>.
It checks the form only; it never judges whether a walk was done well."""
import re, sys

ROLES = 'product-owner|architect|developer|qa-engineer|security-reviewer|devops|docs-writer'
PROC = ('brief', 'inputs', 'standard text', 'tooling', 'ownership table', 'order of stages')
ROW = re.compile(r'^row (\S+) (.+) \((%s)(?:, already flagged: ([^)]+))?\)$' % ROLES)


def check(line):
    if '\n' in line:
        return 'newline'
    if not line.startswith('- gemba: '):
        return 'not a gemba line'
    body = line[len('- gemba: '):]
    if body == 'not captured (no role stage ran)':
        return None
    parts = body.split('; ')
    if not ROW.match(parts[0]):
        return 'row part'
    if len(parts) == 2:
        m = re.match(r'^not captured \((.{1,80})\)$', parts[1])
        return None if m else 'not captured part'
    if len(parts) != 4:
        return 'parts: %d (a part holds ";" or a part is missing)' % len(parts)
    rd, fd, ch = parts[1:]
    m = re.match(r'^read (transcript|commits and result file) ([0-9]+) chars(, partial \(cap\))?$', rd)
    if not m:
        return 'read part'
    n = int(m.group(2)); partial = bool(m.group(3))
    if n > 30000:
        return 'n over 30000'
    if n < 1:
        return 'n is 0: a walk that read nothing is not a walk'
    if not fd.startswith('found '):
        return 'found part'
    f = fd[len('found '):]
    mn = re.match(r'^nothing \(([0-9]+) Done items and ([0-9]+) constraints checked\)$', f)
    mp = re.match(r'^nothing in the part read \(([0-9]+) chars of ([0-9]+)\)$', f)
    md = re.match(r'^difference: (.+)$', f)
    if mn:
        if partial:
            return 'partial walk reads plain nothing'
        outcome = 'nothing'
    elif mp:
        if not partial:
            return 'nothing in the part read without partial (cap)'
        if int(mp.group(1)) != n:
            return 'n chars of m: n differs from the read part'
        if int(mp.group(2)) <= n:
            return 'partial but m <= n'
        outcome = 'nothing'
    elif md:
        s = md.group(1)
        if len(s) > 200:
            return 'sentence over 200 characters'
        if not re.search(r', process object: (?:the )?(%s)$' % '|'.join(PROC), s):
            return 'sentence names no process object'
        outcome = 'difference'
    else:
        return 'found part'
    if not ch.startswith('changes '):
        return 'changes part'
    c = ch[len('changes '):]
    if outcome == 'nothing' and c != 'nothing':
        return 'found nothing must change nothing'
    if outcome == 'difference':
        if c == 'nothing':
            return 'a difference never changes nothing'
        if not (c == 'none: needs a plugin change' or re.match(r'^process item: .+ \(https://[^ )]+\)$', c)):
            return 'changes part'
    return None


if __name__ == '__main__':
    why = check(sys.argv[1])
    print('OK' if why is None else 'REJECT: ' + why)
    sys.exit(0 if why is None else 1)
