namespace Boo.Hints

import System(Console, StringComparison)
import System.IO(Path, FileSystemWatcher, FileSystemEventArgs)
import System.Linq.Enumerable
import System.Diagnostics(Trace)

import Boo.Lang.Environments(my, ActiveEnvironment)
import Boo.Lang.Compiler(BooCompiler, CompilerContext, Steps)
import Boo.Lang.Compiler.IO(StringInput)
import Boo.Lang.Compiler.Pipelines as BooPipelines
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.TypeSystem
import Boo.Lang.Compiler.TypeSystem.Core
import Boo.Lang.PatternMatching


class ProjectIndex:

    [getter(Context)]
    _context as CompilerContext

    _symbolFinder as ISymbolFinder
    _references = List[of string]()
    _compiler as BooCompiler
    _parser as BooCompiler
    _implicitNamespaces as List


    static def Boo():
        compiler = BooCompiler()
        compiler.Parameters.Pipeline = BooPipelines.ResolveExpressions(BreakOnErrors: false)

        parser = BooCompiler()
        parser.Parameters.Pipeline = BooPipelines.Parse() { Steps.IntroduceModuleClasses() }
        implicitNamespaces = ["Boo.Lang", "Boo.Lang.Builtins"]

        return ProjectIndex(compiler, parser, implicitNamespaces)

    def constructor(compiler as BooCompiler, parser as BooCompiler, implicitNamespaces as List):
        _compiler = compiler
        _parser = parser
        _implicitNamespaces = implicitNamespaces

        # Instantiate the Cecil based symbol finder if available
        try:
            asm = System.Reflection.Assembly.Load('Boo.Hints.Cecil')
            Cecil as duck = asm.GetType('Boo.Hints.SymbolFinder.Cecil')
            _symbolFinder = Cecil()
            Trace.TraceInformation('Enabled Cecil symbol finder for external entities')
        except ex as System.IO.FileNotFoundException:
            Trace.TraceInformation('Cecil symbol finder not available')
            _symbolFinder = SymbolFinder.Dummy()
        except ex as System.TypeLoadException:
            Trace.TraceError('Error loading Cecil symbol finder. Make sure Mono.Cecil.dll, Mono.Cecil.Pdb.dll and Mono.Cecil.Mdb.dll are available')
            _symbolFinder = SymbolFinder.Dummy()

    virtual def AddReference(reference as string):
        _references.Add(Path.GetFullPath(reference))

    virtual def Init():
        def handler(sender, e as FileSystemEventArgs):
            return unless e.FullPath in _references

        paths = []
        for reference in _references:
            try:
                asm = _compiler.Parameters.LoadAssembly(reference, true)
                _compiler.Parameters.References.Add(asm)
                _symbolFinder.LoadAssembly(reference)
            except ex as System.Exception:
                Trace.TraceError("Error loading reference: '$reference'")
                continue

            # Monitor directory containing the reference
            path = Path.GetDirectoryName(reference)
            if path not in paths:
                paths.Add(path)
                Trace.TraceInformation("Setting up file system watcher for $path")
                fsw = FileSystemWatcher(path)
                fsw.EnableRaisingEvents = true
                fsw.Created += handler
                fsw.Changed += handler
                fsw.Deleted += handler

    virtual def WithParser(fname as string, code as string, action as System.Action[of Module]):
    """ Execute the given callback after processing the code with the parsing pipeline
    """
        input = _parser.Parameters.Input
        input.Add(StringInput(fname, code))
        try:
            _context = _parser.Run()
            ActiveEnvironment.With(_context.Environment) do:
                modules = [m for m in _context.CompileUnit.Modules if m.LexicalInfo.FileName == fname]
                action(modules[0])
        ensure:
            input.Clear()

    virtual def WithCompiler(fname as string, code as string, action as System.Action[of Module]):
    """ Execute the given callback after processing the code with the compiler pipeline
    """
        input = _compiler.Parameters.Input
        input.Add(StringInput(fname, code))
        try:
            _context = _compiler.Run()
            ActiveEnvironment.With(_context.Environment) do:
                modules = [m for m in _context.CompileUnit.Modules if m.LexicalInfo.FileName == fname]
                action(modules[0])
        ensure:
            input.Clear()

    virtual def GetSourceLocation(ent as IEntity) as string:
    """ Query the configured symbol finder for the source location of an entity
    """
        return _symbolFinder.GetSourceLocation(ent)

    virtual def MembersOf(node as Expression):
    """ Query the member entities for the given expression
    """
        match node.Entity:
            case ns=INamespace(EntityType: EntityType.Namespace):
                members = ns.GetMembers()
            case IType():
                members = StaticMembersOf(node.ExpressionType)
            otherwise:
                parent = node.GetAncestor[of TypeDefinition]()
                members = InstanceMembersOf(node.ExpressionType, parent.Entity)

        byName = members.GroupBy({ m | m.Name })
        for m in byName:
            yield Entities.EntityFromList(m.ToList())

    virtual def InstanceMembersOf(type as IType):
        for member in InstanceMembersOf(type, null):
            yield member

    virtual def InstanceMembersOf(type as IType, enclosing as IType):
        for member in AccessibleMembersOf(type, enclosing):
            match member:
                case IAccessibleMember(IsStatic):
                    yield member unless IsStatic
                otherwise:
                    yield member

    virtual def StaticMembersOf(type as IType):
        for member in AccessibleMembersOf(type, null):
            match member:
                case IAccessibleMember(IsStatic):
                    yield member if IsStatic
                otherwise:
                    yield member

    virtual def AccessibleMembersOf(type as IType):
        for m in AccessibleMembersOf(type, null):
            yield m

    virtual def AccessibleMembersOf(type as IType, enclosing as IType):
        current = type
        while current is not null:
            is_same = enclosing == current
            is_subclass = enclosing and enclosing.IsSubclassOf(current)
            for member in current.GetMembers():
                continue if IsSpecialName(member.Name)
                match member:
                    case IConstructor():
                        continue
                    case IEvent():
                        yield member
                    case IAccessibleMember(IsPublic, IsProtected):
                        if is_same or IsPublic or (IsProtected and is_subclass):
                            yield member
                    otherwise:
                        continue

            if current.IsInterface:
                # TODO: Walk thru all the interfaces
                current = (current.GetInterfaces() as IType*).FirstOrDefault() or \
                          null  # my(TypeSystemServices).ObjectType
            else:
                current = current.BaseType

    _specialPrefixes = ('get', 'set', 'add', 'remove', 'op')
    protected def IsSpecialName(name as string):
        index = name.IndexOf('_')
        return false if index < 0
        return name[:index] in _specialPrefixes

