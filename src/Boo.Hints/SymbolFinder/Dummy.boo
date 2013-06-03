namespace Boo.Hints.SymbolFinder

# import Boo.Hints(ISymbolFinder)
import Boo.Lang.Compiler.TypeSystem(IEntity)


class Dummy(ISymbolFinder):

    def LoadAssembly(fname as string) as bool:
        return false

    def Reset():
        pass

    def GetSourceLocation(entity as IEntity) as string:
        return null
