# Boo.Hints

Autocompletion library for Boo with the following features:

  - Proposals for import statements
  - Proposals for locals, method parameters and closure symbols
  - Proposals for type references
  - Proposals for static and instance members (filtering by visibility)
  - Proposals for builtins, primitives and globals
  - Lint information based on syntax and actual type resolution
  - Outlines
  - Detailed entity information including source code location (Requires Mono.Cecil for external entities)


## Overview

Boo is a complex language to support properly on IDEs since it relies on type 
inference and macro expansions, thus it's not trivial to offer a solid auto 
completion mechanism for it. Boo.Hints embeds the Boo compiler to offers a
*hints server* to ease the development of IDE and editor addins.

[sublime-boo](https://github.com/drslump/sublime-boo) is a compatible addin for
Sublime Text 2 and 3 that serves to validate the integration of the Boo.Hints
server.


> In order to offer hints for different files in the current project too, make sure
  to explicitly define an output assembly file in the command line or include as a
  reference the last successful compilation of the project. Even if the assembly does
  not have the latest changes it usually works well enough to be useful.


## Protocol

Protocol is Json based, where each line to *stdin* is a Json message representing
a command query and every one to *stdout* is a Json message representing the
result. Errors are written to *stderr*.

The server is single threaded thus all queries are served in the order they are
received. You should not issue new commands to *stdin* until the whole results from 
the previous command has been consumed or an error has been reported via *stderr*.

> Debug information can be reported via *stdout* and *stderr* with lines prefixed 
  with a `#` character. Keep this in mind when processing the results from the
  hints server. A debug message does not terminate the previous command issued. If
  received via *stderr* it should be considered as a *warning*, while on *stdout*
  just provide additional information mostly used to help debug an integration.

> Even if in the examples below we have Json messages formated in multiple lines for
  readability, the actual protocol requires them to be serialized into a single line.

A query command is modeled as follows, not all fields are required, see each command
documentation to see an example of what is needed in each case.

    {
      "command": "parse",           # The command to run
      "fname": "/path/to/foo.boo",  # The name of the file
      "code": "import System\n..."  # The source code
      "codefile": "/tmp/file.tmp"   # If code is not given it tries to obtain it from this file
      "offset": 653,                # Byte based offset (0 based count)
      "line": 10,                   # Source code line (1 based count)
      "column": 10,                 # Source code column (1 based count)
      "extra": true,                # True to receive additional information for hints (location, docblock)
      "params": ["foo", 10]         # Additional params for the command              
    }


### Parse command

Parse the given file reporting back any errors or warnings found in the process.

> Query with `extra` set to `true` to use the more complex compiler pipeline to
  detect warnings and errors regarding type resolution and not only syntax.


    {
      "command": "parse",
      "fname": "/path/to/foo.boo",
      "codefile": "/path/to/foo.boo"
    }

    { 
      "errors": [{
        "code": "BCE0058",
        "message": "foo is not a valid method",
        "line": 26,   # Count is 1 based
        "column": 12  # Count is 1 based
      }],
      "warnings": []
    }


### Outline command

Generate an outline for the types and members contained in a file. The result is 
a node tree structure having the file module as root node.

    {
      "command": "outline", 
      "fname": "/path/to/foo.boo",
      "codefile": "/path/to/foo.boo"
    }

    {
      "type": "Module",
      "name": "foo",
      "line": 0,
      "length": 66,  # Number of lines this element spans
      "members": [{
        "type": "Import",
        "desc": "jQuery",
        "line": 10,
        "length": 1
      }, {
        "type": "ClassDefinition",
        "name": "Foo",
        "line": 13,
        "length": 42,
        "members": [{
          "type": "Method",
          "name": "bar",
          "line": 19,
          "length": 6,
          "members": []
        }]
      }]
    }


### Globals command

Obtain hints for all global symbols in a file, this includes the types and 
methods defined in the file and the ones imported via import statements.

> Top level namespaces from standard assemblies are not reported unless they
  are explicitly imported in the file (ie: System)

    {
      "command": "globals",
      "fname": "/path/to/foo.boo",
      "codefile": "/path/to/foo.boo"
    }

    { 
      "scope": 'globals',
      "hints": [{
        "node": "Class",
        "type": "Test.Foo",
        "name": "Foo",
        "info": "class, final"
      }, {
        "node": "Method",
        "type": "Test.bar",
        "name": "bar",
        "info": "Void alert(System.String)",
        "doc": "method docstring contents",
      }]
    }


### Namespaces command

Obtain hints for available top level namespaces in the current compiler.

    {
      "command": "namespaces",
      "fname": "",
      "code": ""
    }

Response follows the same format as Globals


### Builtins commad

Queries for available primitive types and builtin methods in the current compiler.

    {
      "command": "builtins",
      "fname": "",
      "code": ""
    }

Response follows the same format as Globals 


### Locals command

Obtain hints for local symbols available at a given line in the file, including
method parameters and symbols available via closures.

    {
      "command": "locals",
      "fname": "/path/to/foo.boo",
      "codefile": "/path/to/foo.boo",
      "line": 13  # Line number to check (count is 1 based)
    }

The response follows the same format as for the Globals command.


### Complete command

Obtain hints for all the possible candidates at a given position in the file. This 
command is scope sensitive, it will detect if we are in an import statement to provide
namespaces, writing parameter declarations, type references, ... The detected scope
is reported as part of the response.

> If you're developing an editor plugin and you're already caching global symbols
  to improve the performance, you can provide `true` as first parameter to skip
  collection of global candidates. This allows to use the reported scope to complete
  the list with your cached results.


    {
      "command": "members",
      "fname": "/path/to/foo.boo",
      "code": "...",
      "offset": 345  # Byte offset in the file
    }

The response follows the same format as for the Globals command, except that the scope field
is populated with the detected scope for the given offset (for example: members or import)

> The offset is byte based, make sure you account for the correct value if your file
  contains multi byte characters.


### Entity command

Obtain all the information about a given symbol, very useful to implement a "Go To" or
showing additional information when hovering over a symbol.

> It may not be possible for the compiler to know which exact entity is being referenced at
  compile time if there are multiple possibilities (overloads). The result is always a list
  which can contain zero or more elements.

> The compiler only reports back location information (file, line, column) for entities
  declared in the same file being analyzed. Support for external symbols require to have the
  optional Cecil assembly available and symbol files for your project (.pdb or .mdb files).

    {
      "command": "entity",
      "fname": "/path/to/foo.boo",
      "codefile": "/path/to/foo.boo",
      "line": 10,
      "column": 34  # Should match the start of the symbol
    }

    { 
      "hints": [{
        "node": "Method",
        "type": "Test.bar",
        "name": "bar",
        "info": "Void alert(System.String)",
        "doc": "method docstring contents",
        "file": "/path/to/foo.boo",
        "line": 33,
        "column": 10
      }]
    }

