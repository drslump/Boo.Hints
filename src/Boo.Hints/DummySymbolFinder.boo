namespace Boo.Hints

import Boo.Lang.Compiler.TypeSystem(IEntity)


class DummySymbolFinder(ISymbolFinder):

    def LoadAssembly(fname as string) as bool:
        return false

    def Reset():
        pass

    def GetSourceLocation(entity as IEntity) as string:
        return null
