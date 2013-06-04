namespace Boo.Hints.Test

import System(Math)
import Boo.Lang.Runtime(RuntimeServices)
import Boo.Hints
import Boo.Hints.Messages


def code(code as string):
    lines = code.Replace('\t', '    ').Split(char('\n'))
    lines = lines[1:-1]
    indent = 1000
    for line in lines:
        if len(line.Trim()):
            indent = Math.Min(indent, len(/^\s*/.Match(line).Value))
    code = join([line[indent:] for line in lines], '\n')
    return code

def run(command as string, query as Query):
    index = ProjectIndex.Boo()
    commands = Commands(index)
    return RuntimeServices.Invoke(commands, command, (query,))

def complete(src as string) as Hints:
    src = code(src)
    q = Query(fname:'complete.boo', code:src)
    if src.IndexOf('|') >= 0:
        q.offset = src.IndexOf('|')
    else:
        q.offset = len(src)
    return run('complete', q)