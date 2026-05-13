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

# @doc toProjectDesc
# @kind func
# @desc Converts a Config to a ProjectDesc
# @param a: Config, the config to convert
# @returns ProjectDesc
proc toProjectDesc*(a: Config): ProjectDesc =
  return ProjectDesc(
    title : a.name,
    desc : a.desc
  )
