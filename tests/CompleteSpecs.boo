import Machine.Specifications.Boo

import Boo.Lang.Runtime(RuntimeServices)
import Boo.Hints
import Boo.Hints.Messages(Query, Hints, Parse)
import Boo.Hints.Test


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