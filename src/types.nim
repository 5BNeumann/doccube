when defined(release):
  {.checks: off, optimization: speed.}

import std/paths

type
  # @doc Config
  # @kind type
  # @desc The object that holds a project's configuration
  # @field srcDirs: seq[Path], the list of paths containing sources
  # @field name: string, the project's name
  # @field desc: string, the project's description
  # @field sugarcube: bool, should sugarcube doc be generated ?
  # @field tex: bool, should tex doc be generated ? (unimplemented)
  Config* {.final.} = object
    srcDirs*: seq[Path] = @[]
    name*: string = "Unnamed"
    desc*: string = ""
    sugarcube*: bool
    tex*: bool
  # @doc ProjectDesc
  # @kind type
  # @desc Description of a project
  # @field title: string, the project's title
  # @field desc: string, the project's description
  ProjectDesc* = object
    title*: string
    desc*: string
  # @doc LanguageConfig
  # @kind type
  # @desc The container that describes a language.
  # @field extension: string, the extension correponding to the language.
  # @field starter_comment: string, the expression that starts a documentation comment.
  LanguageConfig* = object
    extention*: string
    starter_comment*: string
  # @doc Documentable
  # @kind type
  # @desc Base type for every documentation container type <<set $thing to "documented type">><!-- ah yes, tasty sugrcube injection -->
  # @field name: string, the name of the $thing.
  # @field desc: string, the description of the $thing.
  Documentable = object of RootObj
    name*: string
    desc*: string = ""
  # @doc Function
  # @kind type
  # @desc The container for Function documentation <<set $thing to "function">>
  # @inherits Documentable
  # @field params: seq[string], the parameters of the function.
  # @field returns: string, the return type of the function.
  Function* {.final.} = object of Documentable
    params*: seq[array[3, string]] = @[]
    returns*: array[2, string]
  # @doc Type
  # @kind type
  # @desc The container for Type documentation <<set $thing to "type">>
  # @inherits Documentable
  # @field fields: seq[string], the fields of the type.
  # @field inherits: string, type inherited from.
  Type* {.final.} = object of Documentable
    fields*: seq[array[3, string]] = @[]
    inherits*: string
  # @doc Sanity
  # @kind type
  # @desc The container for Sanity documentation <<set $thing to "sanity of the developer">>
  # @inherits Documentable
  # @field level: int8, the current estimated sanity level.
  Sanity* {.final.} = object of Documentable
    level*: int8
  # @doc FileDocumentation
  # @kind type
  # @desc Documentation for a single source file (originally implemented to save time on JSON)
  # @desc which was lost to my stupidity (marshalling to JSON, writing to a file, reading the file,
  # @desc unmarshalling the content, all of that in the same run).
  # @field functions: seq[[[Function]]], the list of functions in the file.
  # @field sanities: seq[[[Sanity]]], the list of developper sanities in the file. (wdym that doesn't make sense)
  # @field types: seq[[[Type]]], the list of types in the file.
  FileDocumentation* {.final.} = object
    functions*: seq[Function] = @[]
    sanities*: seq[Sanity] = @[]
    types*: seq[Type] = @[]


# @doc toProjectDesc
# @kind func
# @desc Converts a [[Config]] to a [[ProjectDesc]]
# @param a: [[Config]], the config to convert
# @returns [[ProjectDesc]]
proc toProjectDesc*(a: Config): ProjectDesc =
  return ProjectDesc(
    title : a.name,
    desc : a.desc
  )

proc len*(a: FileDocumentation): int =
  var len: int = 0
  if a.functions.len != 0:
    len += 1
  if a.sanities.len != 0:
    len += 1
  if a.types.len != 0:
    len += 1
  return len
