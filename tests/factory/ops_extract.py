"""Cut the operations of the Factory operations list out of a tracker doc: prints  <ids>\t<command>  per runnable gh command of a bullet that names ids in brackets.
Usage: python3 -I ops_extract.py <issue-tracker-github.factory.md>"""
import re, sys

text = open(sys.argv[1]).read()
sect = text[text.index('## Factory operations'):]
for bullet in re.split(r'\n(?=- \*\*)', sect):
    m = re.match(r'- \*\*([^*]+)\*\*\s*\[([^\]]+)\]', bullet)
    if not m:
        continue
    ids = re.findall(r'`([BT]-[a-z-]+)`', m.group(2))
    for code in re.findall(r'`([^`]+)`', bullet):
        if code.startswith('gh ') or code.startswith('me="$(gh '):
            print('%s\t%s\t%s' % (','.join(ids), m.group(1), code))
