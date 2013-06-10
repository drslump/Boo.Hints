"""
TODO: Check http://jolt.codeplex.com/wikipage?title=Jolt.XmlDocComments

Note: While fastJSON is much faster than JavaScriptSerializer the time spend 
      serializing is not much, thus we can probably avoid having an additional
      dependency.

"""
namespace boohints

import System.IO
import System(Console)
import System.Diagnostics(Stopwatch, Trace, TraceListener, TraceEventCache, TraceEventType)
import System.Web.Script.Serialization(JavaScriptSerializer) from "System.Web.Extensions"

import Boo.Lang.Useful.CommandLine

import Boo.Hints(ProjectIndex, Commands)
import Boo.Hints.Messages.Query as QueryMessage


internal class PrefixedTraceListener(TraceListener):
""" Dumps trace messages to the console using a prefix 
"""
    _prefix = '#'

    def constructor(prefix as string):
        _prefix = prefix

    protected def format(msg as string):
        lines = msg.Split(char('\n'))
        return _prefix + join(lines, '\n#')

    override def Write(msg as string):
        WriteLine(msg)

    override def WriteLine(msg as string):
        # HACK: I can't figure out how to obtain the trace as an object before it's formatted
        parts = msg.Split(char(':'))
        msg = join(parts[2:], ':').TrimStart()
        if parts[0].Contains('Information'):
            Console.Out.WriteLine(format(msg))
        else:
            Console.Error.WriteLine(format(msg))


class CommandLine(AbstractCommandLine):
    [getter(References)]
    _references = List[of string]() 

    def constructor(argv):
        Parse(argv)    

    [Option("Enables duck typing.", LongForm: "ducky")]
    public Ducky = false

    [Option("References the specified {assembly}", ShortForm: 'r', LongForm: "reference", MaxOccurs: int.MaxValue)]
    def AddReference(reference as string):
        if not reference:
            raise CommandLineException("No reference supplied (ie: -r:my.project.reference)")
        _references.AddUnique(Unquote(reference))

    [Option("Display this help and exit", ShortForm: "h", LongForm: "help")]
    public DoHelp = false        

    def Unquote(path as string):
        if path.StartsWith('"') or path.StartsWith("'"):
            return path[1:-1]
        return path        


def hints(cmdline as CommandLine):
    # Setup trace system to use our formatter 
    Trace.AutoFlush = true
    Trace.Listeners.Clear()
    Trace.Listeners.Add(PrefixedTraceListener('#'))

    System.AppDomain.CurrentDomain.AssemblyResolve += def(sender, args):
        Trace.TraceError('Unable to resolve assembly dependency: {0}, {1}', args.Name, args.RequestingAssembly)
        return null

    index = ProjectIndex.Boo(cmdline.Ducky)
    for refe in cmdline.References:
        index.AddReference(refe)

    # Complete index setup
    index.Init()

    # Register to get notified about modification to references
    index.ReferenceModified += def (reference):
        print '#!ReferenceModified:', reference

    # Initialize the commands
    commands = Commands(index)

    # Initialize the json serializer
    json = JavaScriptSerializer()

    stopwatch = Stopwatch()
    while true:   # Loop indefinitely
        stopwatch.Reset()

        line = gets()
        if line.ToLower() in ('q', 'quit', 'exit'):
            break

        try:
            stopwatch.Start()
            query = json.Deserialize[of QueryMessage](line)
            stopwatch.Stop()
        except ex:
            Console.Error.WriteLine('Malformed command')
            continue

        if query.code is null:
            try:
                stopwatch.Start()
                query.code = File.ReadAllText(query.codefile)
                stopwatch.Stop()
            except ex:
                Console.Error.WriteLine('Unable to read code file at ' + query.codefile)
                continue

        method = typeof(Commands).GetMethod(query.command)
        if not method:
            Console.Error.WriteLine('Unknown command')
            continue

        try:
            stopwatch.Start()

            result = method.Invoke(commands, (query,))
            Console.Out.WriteLine(json.Serialize(result))

            stopwatch.Stop()
            Trace.TraceInformation('Command <{0}(extra:{1})> took {2}ms for {3}' % (query.command, query.extra, stopwatch.ElapsedMilliseconds, query.fname))
        except ex:
            # Print stack trace as debug messages
            lines = ex.ToString().Split(char('\n'))
            Console.Error.WriteLine(join(lines, '\n#'))


cmdline = CommandLine(argv)
if cmdline.DoHelp:
    cmdline.PrintOptions()
    return

hints(cmdline)

