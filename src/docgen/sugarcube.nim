when defined(release):
  {.checks: off, optimization: speed.}

import
  std/[dirs, paths, strutils, tables],
  ../types

# @doc 5BNeumann
# @kind san
# @desc Great, this thing somehow works !!!
# @level 63

const
  PASSAGE_NAME: string = ":: $1\n"
  STANDARD_WIDGETS: string = slurp("widgets.twee")
  STATIC_PASSAGES: string = slurp("standard_passages.twee")
  STORY_INIT: string = PASSAGE_NAME % ["StoryInit"] & "<<set $funcs to []>><<set $types to []>><<set $sans to []>><<set $files to []>><<set $allsymbols to []>>\n"
  STORY_START: string = PASSAGE_NAME % ["Start"]
  STORY_TITLE: string = PASSAGE_NAME % ["StoryTitle"]
  FUNC_STRING: string = "\n<<registerfunc $1>>"
  TYPE_STRING: string = "\n<<registertype $1>>"
  SAN_STRING: string = "\n<<registersan $1>>"
  FILE_STRING: string = "\n<<registerfile $1>>"
  ALL_SYMBOLS: string = "\n<<listfuncs>><<listtypes>><<listfiles>><!--<<listsans>>-->\n"
  CODE_BLOCK: string = "<code>$1</code>\n"
  TITLE: string = "<h1>$1</h1>"
  SUBTITLE: string = "<h2>$1</h2>"
  FUNCALL: string = CODE_BLOCK % ["$1($2): $3"]
  NORET_FUNCALL: string = CODE_BLOCK % ["$1($2)"]
  PARAMDESC: string = CODE_BLOCK % ["$1: $2"] & "$3\n\n"
  INCLUDE: string = "<<include $1>>\n"


# @doc makeStandardPassage
# @kind func
# @desc This function dynamically generates the standard passages such as Start, StoryInit and StoryTitle
# @param project: [[ProjectDesc]], gives the name and description of the project
# @returns string
proc makeStandardPassage(project: ProjectDesc, files: Table[string, FileDocumentation]): string =
  let
    title: string = STORY_TITLE & "\n" & project.title
    start: string = STORY_START & "\n<h1>$1</h1>\n$2" % [project.title, project.desc] & ALL_SYMBOLS
  var
    init: string = STORY_INIT
  for filename, file in files:
    if file.functions.len != 0:
      for fun in file.functions:
        init &= FUNC_STRING % [fun.name]
    if file.types.len != 0:
      for typ in file.types:
        init &= TYPE_STRING % [typ.name]
    if file.sanities.len != 0:
      for san in file.sanities:
        init &= SAN_STRING % [san.name & "-" & $ Path(filename).splitFile[1]]
    init &= FILE_STRING % [$ Path(filename).splitFile[1]]
  return "$1\n$2\n$3\n$4\n$5\n" % [STANDARD_WIDGETS, STATIC_PASSAGES, title, start, init]


proc args(fun: Function): string =
  var t: seq[string] = @[]
  for i in fun.params:
    t.add(i[0] & " : " & i[1])
  return t.join(", ")


# @doc makeSingleFile
# @kind func
# @desc Generates the documentation for a single file (functions, types and sanity).
# @param docContent: JsonNode, The documentation in Json format.
# @param filename: string, The name of the documented file.
# @returns string, The raw sugarcube documentation for the file.
proc makeSingleFile(docContent: FileDocumentation, filename: string): string =
  var
    fileSection: string = ""
    functionSection: string = ""
    typesSection: string = ""
    sanitySection: string = ""
  fileSection &= PASSAGE_NAME % [filename & "-file"]
  if docContent.functions.len != 0:
    for fun in docContent.functions:
      fileSection &= INCLUDE % [fun.name]
      functionSection &= PASSAGE_NAME % [fun.name]
      functionSection &= SUBTITLE % [fun.name] & "\n"
      if fun.returns[0] != "":
        functionSection &= FUNCALL % [fun.name, args(fun), fun.returns[0]]
      else:
        functionSection &= NORET_FUNCALL % [fun.name, args(fun)]
      functionSection &= fun.desc & "\n"
      for param in fun.params:
        functionSection &= PARAMDESC % [param[0], param[1], param[2]]
      if fun.returns[0] != "":
        functionSection &= "returns : " & CODE_BLOCK % [fun.returns[0]]
        if fun.returns[1] != "":
          functionSection &= "$1\n\n" % [fun.returns[1]]
  if docContent.types.len != 0:
    for typ in docContent.types:
      fileSection &= INCLUDE % [typ.name]
      typesSection &= PASSAGE_NAME % [typ.name]
      typesSection &= typ.desc & "\n"
      typesSection &= INCLUDE % [typ.name & "-fields"]
      typesSection &= PASSAGE_NAME % [typ.name & "-fields"]
      if typ.inherits != "":
        typesSection &= INCLUDE % [typ.inherits & "-fields"] & "\n"
      for field in typ.fields:
        typesSection &= PARAMDESC % [field[0], field[1], field[2]]
  if docContent.sanities.len != 0:
    for san in docContent.sanities:
      fileSection &= INCLUDE % [san.name & "-" & filename]
      sanitySection &= PASSAGE_NAME % [san.name & "-" & filename]
      sanitySection &= SUBTITLE % [san.name] & "\n"
      sanitySection &= san.desc & "\n"
      sanitySection &= """<meter id="sanity" value="$1" min="-128" max="127">$1</meter>""" % [$ san.level] & "\n"
  return fileSection & functionSection & typesSection & sanitySection

# @doc makeSugarcube
# @kind func
# @desc Creates a sugarcube documentation from pre-processed data. Public.
# @param config: [[Config]], the project's config, mostly used to get the name and description fo the project
proc makeSugarcube*(config: Config, docList: Table[string, FileDocumentation]) =
  var
    stdFile: File
    docFiles: File
  createDir(Path("doc/sugarcube"))
  if stdfile.open("doc/sugarcube/00_story_info.twee", fmWrite):
    stdfile.write(makeStandardPassage(config.toProjectDesc, docList))
    stdfile.close()
  else:
    echo "An error occured, you probably fucked up something."
  for filename, node in docList:
    createDir(Path("doc/sugarcube") / Path(filename).splitFile.dir)
    if docFiles.open($ (Path("doc/sugarcube") / Path(filename).changeFileExt("twee")), fmWrite):
      docFiles.write(makeSingleFile(node, $ Path(filename).splitFile.name))
      docFiles.close()
#[
  for file in walkDirRec(Path("doc/")):
    if ($ file).endsWith(".json"):
      createDir(Path("doc/sugarcube") / file.splitFile.dir)
      if docFiles.open($ (Path("doc/sugarcube") / file.changeFileExt("twee")), fmWrite):
        docFiles.write(makeSingleFile(parseFile($ file), $ file.splitFile.name))
        docFiles.close()]#
