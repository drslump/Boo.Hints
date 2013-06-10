import Machine.Specifications.Boo

import Boo.Hints
import Boo.Hints.Messages(Query, Hints)
import Boo.Hints.Test
import Boo.Lang.Interpreter


subject 'imports' [hints, complete, imports]:

    when 'import with no prefix':
        src as string = 'import |'
        resp as Hints = run('complete', Query(fname:'ns.boo', code:src, offset:src.IndexOf('|')))

        it 'should have the correct scope':
            resp.scope.ShouldEqual('import')

        it 'should complete with root namespaces':
            [x.name for x in resp.hints].ShouldContain('System')

    when 'import with namespace prefix':
        src as string = 'import System.|'
        resp as Hints = run('complete', Query(fname:'ns.boo', code:src, offset:src.IndexOf('|')))

        it 'should have the correct scope':
            resp.scope.ShouldEqual('import')

        it 'should contain member namespaces':
            [x.name for x in resp.hints].ShouldContain('IO', 'Math', 'Reflection')

    when 'import with namespace and types':
        src as string = 'import System.IO.|'
        resp as Hints = run('complete', Query(fname:'ns.boo', code:src, offset:src.IndexOf('|')))

        it 'should have the correct scope':
            resp.scope.ShouldEqual('import')

        it 'should contain member types':
            [x.name for x in resp.hints].ShouldContain('File', 'Directory')

    when 'import with explicit symbols':
        src as string = 'import System.IO(|)'
        resp as Hints = run('complete', Query(fname:'ns.boo', code:src, offset:src.IndexOf('|')))

        it 'should have the correct scope':
            resp.scope.ShouldEqual('import')

        it 'should contain member types':
            [x.name for x in resp.hints].ShouldContain('File', 'Directory')

    when 'import with explicit symbols after a comma':
        src as string = 'import System.IO(File, |)'
        resp as Hints = run('complete', Query(fname:'ns.boo', code:src, offset:src.IndexOf('|')))

        it 'should have the correct scope':
            resp.scope.ShouldEqual('import')

        it 'should contain member types':
            [x.name for x in resp.hints].ShouldContain('File', 'Directory')

    when 'import using python syntax':
        src as string = 'from System.IO import |'
        resp as Hints = run('complete', Query(fname:'ns.boo', code:src, offset:src.IndexOf('|')))

        it 'should have the correct scope':
            resp.scope.ShouldEqual('import')

        it 'should contain member types':
            [x.name for x in resp.hints].ShouldContain('File', 'Directory')

    when 'import using python syntax after comma':
        src as string = 'from System.IO import File, |'
        resp as Hints = run('complete', Query(fname:'ns.boo', code:src, offset:src.IndexOf('|')))

        it 'should have the correct scope':
            resp.scope.ShouldEqual('import')

        it 'should contain member types':
            [x.name for x in resp.hints].ShouldContain('File', 'Directory')



ifdef MAIN:
    RunSpecs()
