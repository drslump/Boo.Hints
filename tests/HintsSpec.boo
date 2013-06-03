import Machine.Specifications.Boo

import Boo.Lang.Runtime(RuntimeServices)
import Boo.Hints
import Boo.Hints.Messages(Query, Hints, Parse)


def code(code as string):
    lines = code.Replace('\t', '    ').Split(char('\n'))
    lines = lines[1:-1]
    indent = 1000
    for line in lines:
        if len(line.Trim()):
            indent = System.Math.Min(indent, len(/^\s*/.Match(line).Value))
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



subject 'parse' [parse]:

    when 'parsing an empty string':
        resp as Parse = run('parse', Query(fname:'parse.boo', code:''))

        it 'should contain no errors or warnings':
            resp.errors.ShouldBeEmpty()
            resp.warnings.ShouldBeEmpty()

    when 'parsing code with syntax errors':
        resp as Parse = run('parse', Query(fname:'parse.boo', code:code("""
            namespace Foo.Bar

            print!
        """)))

        it 'should report the error':
            len(resp.errors).ShouldEqual(1)
            err = resp.errors[0]
            err.code.ShouldEqual('BCE0044')
            err.line.ShouldEqual(3)
            err.column.ShouldEqual(6)

    when 'parsing code with warnings':
        resp as Parse = run('parse', Query(fname:'parse.boo', code:code("""
            if a=10:
                pass
        """)))

        it 'should report the warning':
            len(resp.warnings).ShouldEqual(1)
            err = resp.warnings[0]
            err.code.ShouldEqual('BCW0007')
            err.line.ShouldEqual(1)
            err.column.ShouldEqual(5)


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
            namespace foo
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


subject 'internals' [hints, complete, internals]:

    when 'completing in a class with a property':
        resp = complete("""
            class Foo:
                property prop as int
                def bar():
                    |
        """)

        it 'should propose the property':
            [x.name for x in resp.hints].ShouldContain('prop')

    when 'completing in a class with methods':
        resp = complete("""
            class Foo:
                def foo():
                    pass
                def bar():
                    |
        """)

        it 'should propose all methods':
            [x.name for x in resp.hints].ShouldContain('foo', 'bar')

    when 'completing in a class with private fields':
        resp = complete("""
            class Foo:
                private _field as int
                def foo():
                    |
        """)

        it 'should propose the private field':
            [x.name for x in resp.hints].ShouldContain('_field')

    when 'completing in a class inheriting protected methods':
        resp = complete("""
            class Foo:
                protected def foo():
                    pass

            class Bar(Foo):
                def bar():
                    |
        """)

        it 'should propose the inherited protected method':
            [x.name for x in resp.hints].ShouldContain('foo')

    when 'completing an instance':
        resp = complete("""
            class Foo:
                property prop as int
                _field as int
                def foo():
                    pass
                protected def bar():
                    pass

            foo = Foo()
            foo.|
        """)
        names = [x.name for x in resp.hints]

        it 'should propose the property': names.ShouldContain('prop')
        it 'should propose public methods': names.ShouldContain('foo')
        it 'should not propose non-public fields': names.ShouldNotContain('_field')
        it 'should not propose non-public methods': names.ShouldNotContain('bar')


    when 'completing after self.':
        resp = complete("""
            class Foo:
                field as int
                def foo():
                    self.|
        """)

        it 'should have the correct scope': resp.scope.ShouldEqual('members')
        it 'should report private fields': [x.name for x in resp.hints].ShouldContain('field')
        it 'should report methods': [x.name for x in resp.hints].ShouldContain('foo')


    when 'completing globals':
        resp = complete("""
            class Foo:
                pass

            |
        """)

        it 'should have the correct scope': resp.scope.ShouldEqual('complete')
        it 'should report the class': [x.name for x in resp.hints].ShouldContain('Foo')

    when 'completing type':
        resp = complete("""
            class Foo:
                static public sf_pub = 10
                static sf_priv = 10
                public if_pub = 20
                static def foo():
                    pass
                def bar():
                    pass

            Foo.|
        """)
        names = [x.name for x in resp.hints]

        it 'should have the correct scope': resp.scope.ShouldEqual('members')
        it 'should report static public fields': names.ShouldContain('sf_pub')
        it 'should report static methods': names.ShouldContain('foo')
        it 'should not report static private fields': names.ShouldNotContain('sf_priv')
        it 'should not report instance fields': names.ShouldNotContain('if_pub')
        it 'should not report instance methods': names.ShouldNotContain('bar')


subject 'complete syntax' [hints, complete, syntax]:

    when 'completing in a method call':
        resp = complete("""
            a = 10
            foo(|)
        """)

        it 'should have the correct scope': resp.scope.ShouldEqual('complete')
        it 'should report variables': [x.name for x in resp.hints].ShouldContain('a')

    when 'completing in a method call after a param':
        resp = complete("""
            a = 10
            foo(10, |)
        """)

        it 'should have the correct scope': resp.scope.ShouldEqual('complete')
        it 'should report variables': [x.name for x in resp.hints].ShouldContain('a')

    when 'completing in nested calls':
        resp = complete("""
            a = 10
            foo(10, bar([true, baz('foo', |
        """)

        it 'should have the correct scope': resp.scope.ShouldEqual('complete')
        it 'should report variables': [x.name for x in resp.hints].ShouldContain('a')

    when 'completing in param name':
        resp = complete("""
            def foo(name as string, |
        """)
        it 'should have the correct scope': resp.scope.ShouldEqual('name')
        it 'should not report hints': resp.hints.ShouldBeEmpty()

    when 'naming a method':
        resp = complete("""
            def |
        """)
        it 'should have the correct scope': resp.scope.ShouldEqual('name')
        it 'should not report hints': resp.hints.ShouldBeEmpty()

    when 'naming a type':
        resp = complete("""
            class |
        """)
        it 'should have the correct scope': resp.scope.ShouldEqual('name')
        it 'should not report hints': resp.hints.ShouldBeEmpty()

    when 'completing in param type':
        resp = complete("""
            class Foo:
                pass

            def foo(name as string, age as |
        """)
        it 'should have the correct scope': resp.scope.ShouldEqual('type')
        it 'should report types': [x.name for x in resp.hints].ShouldContain('int', 'string', 'Foo')

    when 'completing in type reference':
        resp = complete("""
            class Foo:
                x as |
        """)
        it 'should have the correct scope': resp.scope.ShouldEqual('type')
        it 'should report types': [x.name for x in resp.hints].ShouldContain('int', 'string', 'Foo')

    when 'extending a type':
        resp = complete("""
            class Foo(|)
        """)
        it 'should have the correct scope': resp.scope.ShouldEqual('type')
        it 'should report types': [x.name for x in resp.hints].ShouldContain('int', 'string', 'Foo')


ifdef MAIN:
    RunSpecs()

