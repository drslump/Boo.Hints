namespace specs

import Machine.Specifications.Boo

import Boo.Hints
import Boo.Hints.Messages(Query, Hints)
import Boo.Hints.Test


subject 'locals' [hints, locals]:

    when 'querying an empty method':
        resp as Hints
        query as Query = Query(fname:'test.boo', line:2, code:code("""
            namespace foo
            def foo():

                return false
        """))

        because:
            resp = run('locals', query)

        it 'should report the scope as "locals"':
            resp.scope.ShouldEqual('locals')

        it 'should give an empty list of hints':
            resp.hints.ShouldBeEmpty()

    when 'querying a method':
        resp as Hints
        query as Query = Query(fname:'test.boo', line:2, code:code("""
            namespace foo
            def foo():
                x = 10
                y = 20
                z = 30
                return false
        """))

        it 'should only report variables declared above the line':
            resp = run('locals', query)
            resp.hints.ShouldBeEmpty()

            for idx as int, varname in enumerate('xyz'):
                query.line = 3 + idx
                resp = run('locals', query)
                [h.name for h in resp.hints].ShouldContain(varname.ToString())

    when 'querying a method with params':
        resp as Hints
        query as Query = Query(fname:'test.boo', line:3, code:code("""
            def foo(x, y):
                x = 10
                z = 20
                
        """))

        it 'should report params':
            resp = run('locals', query)
            [h.name for h in resp.hints].ShouldContain('x', 'y', 'z')

    when 'querying a closure':
        resp as Hints
        query as Query = Query(fname:'test.boo', code:code("""
            a = 10
            def foo(x, y):
                z = 20
                return z
        """))

        it 'should report closure variables':
            query.line = 1
            resp = run('locals', query)
            [h.name for h in resp.hints].ShouldContain('argv', 'a')

            query.line = 4
            resp = run('locals', query)
            [h.name for h in resp.hints].ShouldContain('argv', 'a', 'foo', 'x', 'y', 'z')

    when 'querying a block expression':
        resp as Hints
        query as Query = Query(fname:'test.boo', code:code("""
            def foo(x, y):
                bar() do (z):
                    return z
                return true
        """))

        it 'should report locals outside the block':
            query.line = 1
            resp = run('locals', query)
            [h.name for h in resp.hints].ShouldContain('x', 'y')

        it 'should report block params':
            query.line = 2
            resp = run('locals', query)
            [h.name for h in resp.hints].ShouldContain('x', 'y', 'z')



ifdef MAIN:
    RunSpecs()