import Machine.Specifications.Boo

import Boo.Hints
import Boo.Hints.Messages(Query, Parse)
import Boo.Hints.Test


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


ifdef MAIN:
   RunSpecs()