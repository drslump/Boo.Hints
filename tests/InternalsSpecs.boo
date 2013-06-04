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



ifdef MAIN:
   RunSpecs()

