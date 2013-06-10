import Machine.Specifications.Boo

import Boo.Hints
import Boo.Hints.Messages(Query, Hints)
import Boo.Hints.Test


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

    when 'completing in a class with static fields':
        resp = complete("""
            class Foo:
                static sfield = 10
                def foo():
                    |
        """)

        it 'should propose static fields':
            [x.name for x in resp.hints].ShouldContain('sfield')

    when 'completing in a static method':
        resp = complete("""
            class Foo:
                static sfield = 10
                field = 20
                def smethod():
                    |
        """)
        names = [x.name for x in resp.hints]

        # it 'should propose static fields': names.ShouldContain('sfield')
        # it 'should not propose instance fields': names.ShouldNotContain('field')

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

    when 'completing macros':
        resp = complete("""
            macro foo:
                a = 10
            |
        """)
        names = [x.name for x in resp.hints]

        it 'should contain macro type':
            names.ShouldContain('FooMacro')

    when 'extensions are defined':
        resp = complete("""
            [Extension]
            def foo(s as string):
                pass

            |
        """)

        it 'should contain extension method':
            [x.name for x in resp.hints].ShouldContain('foo')

        it 'should flag extension methods':
            h as duck, = [x for x in resp.hints if x.name == 'foo']
            h.info.ShouldEqual('extension')

    when 'completing extensions':
        src = code("""
        import Machine.Specifications

        [Extension]
        def foo(s as string):
            pass

        [Extension]
        def bar(i as int):
            pass

        'foo'.|
        """)
        query = Query(fname:'ext.boo', code:src, offset:src.IndexOf('|'))

        it 'should not contain extension methods if disabled':
            query.params = (of object: false, true)
            resp as Hints = run('complete', query)
            [x.name for x in resp.hints].ShouldNotContain('foo', 'ShouldStartWith')

        it 'should contain extension methods if not disabled':
            query.params = (of object: false, false)
            resp as Hints = run('complete', query)
            [x.name for x in resp.hints].ShouldContain('foo', 'ShouldStartWith')

        it 'should contain only extension methods matching the type':
            query.params = (of object: false, false)
            resp as Hints = run('complete', query)
            [x.name for x in resp.hints].ShouldNotContain('bar')

        #TODO: generics not supported yet
        # it 'should contain extension based on generics':
        #     query.params = (of object: false, false)
        #     resp as Hints = run('complete', query)
        #     [x.name for x in resp.hints].ShouldContain('ShouldEqual')



ifdef MAIN:
    RunSpecs()

