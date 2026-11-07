"""Generates a synthetic agent transcript (JSONL, the shape cut-offs.sh and token-spend.sh read) for the gemba walk tests. No project data.
Usage: python3 -I gemba_transcript.py <pairs> <out.jsonl> [--edit PATH ...] [--final TEXT] [--string-user] [--array-result]
  <pairs> filler tool_use/tool_result pairs (each about 520 characters in the walk's view); each --edit PATH adds an Edit call on PATH."""
import json, sys

args = sys.argv[1:]
pairs = int(args[0]); out = args[1]
edits, final, string_user, array_result = [], 'Done: everything is written.', False, False
i = 2
while i < len(args):
    if args[i] == '--edit': edits.append(args[i + 1]); i += 2
    elif args[i] == '--final': final = args[i + 1]; i += 2
    elif args[i] == '--string-user': string_user = True; i += 1
    elif args[i] == '--array-result': array_result = True; i += 1
    else: raise SystemExit('bad arg ' + args[i])
L = []
n = 0
def mid():
    global n; n += 1; return 'msg_%06d' % n
if string_user:
    L.append({'type': 'user', 'message': {'role': 'user', 'content': 'Do the work in the brief.'}})
def pair(name, inp, res):
    tid = 'toolu_%06d' % len(L)
    L.append({'type': 'assistant', 'message': {'id': mid(), 'role': 'assistant', 'content': [{'type': 'text', 'text': 'working'}, {'type': 'tool_use', 'id': tid, 'name': name, 'input': inp}]}})
    content = [{'type': 'text', 'text': res}] if array_result else res
    L.append({'type': 'user', 'message': {'role': 'user', 'content': [{'type': 'tool_result', 'tool_use_id': tid, 'content': content}]}})
for k in range(pairs):
    pair('Bash', {'command': 'echo step %d ' % k + 'x' * 400, 'description': 'filler'}, 'line one of result %d ' % k + 'y' * 160 + '\nsecond line that the view drops\nthird')
for p in edits:
    pair('Edit', {'file_path': p, 'old_string': 'a', 'new_string': 'b'}, 'The file ' + p + ' has been updated.')
L.append({'type': 'assistant', 'message': {'id': mid(), 'role': 'assistant', 'content': [{'type': 'text', 'text': final}]}})
open(out, 'w').write('\n'.join(json.dumps(x) for x in L) + '\n')
