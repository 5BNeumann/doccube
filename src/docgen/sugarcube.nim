import
  std/[dirs, paths, strutils, json],
  ../types

# @doc 5BNeumann
# @kind san
# @desc Great, this thing somehow works !!!
# @level 63

const
  PASSAGE_NAME: string = ":: $1\n"
  STANDARD_WIDGETS: string = slurp("widgets.twee")
  STATIC_PASSAGES: string = slurp("standard_passages.twee")
  STORY_INIT: string = PASSAGE_NAME % ["StoryInit"] & "<<set $funcs to []>><<set $types to []>><<set $sans to []>><<set $files to []>>\n"
  STORY_START: string = PASSAGE_NAME % ["Start"]
  STORY_TITLE: string = PASSAGE_NAME % ["StoryTitle"]
  FUNC_STRING: string = "\n<<registerfunc $1>>"
  TYPE_STRING: string = "\n<<registertype $1>>"
  SAN_STRING: string = "\n<<registersan $1>>"
  FILE_STRING: string = "\n<<registerfile $1>>"
  ALL_SYMBOLS: string = "\n<<listfuncs>><<listtypes>><<listfiles>><<listsans>>\n"


# @doc makeStandardPassage
# @kind func
# @desc This function dynamically generates the standard passages such as Start, StoryInit and StoryTitle
# @param project: ProjectDesc, gives the name and description of the project
# @returns string
proc makeStandardPassage(project: ProjectDesc): string =
  let
    title: string = STORY_TITLE & "\n" & project.title
    start: string = STORY_START & "\n<h1>$1</h1>\n$2" % [project.title, project.desc] & ALL_SYMBOLS
  var
    init: string = STORY_INIT
  for file in walkDirRec(Path("doc/")):
    if ($ file).endsWith(".json"):
      var
        jsonContent: JsonNode = parseFile($ file)
        functionsNode: JsonNode
        typesNode: JsonNode
        sanityNode: JsonNode
      if jsonContent.hasKey("functions"):
        functionsNode = jsonContent["functions"]
        for fun in functionsNode:
          init &= FUNC_STRING % [fun["name"].getStr]
      if jsonContent.hasKey("types"):
        typesNode = jsonContent["types"]
        for typ in typesNode:
          init &= TYPE_STRING % [typ["name"].getStr]
      if jsonContent.hasKey("sanity"):
        sanityNode = jsonContent["sanity"]
        for san in sanityNode:
          init &= SAN_STRING % [san["name"].getStr]
      init &= FILE_STRING % [$ file.splitFile.name]
  return "$1\n$2\n$3\n$4\n$5\n" % [STANDARD_WIDGETS, STATIC_PASSAGES, title, start, init]

# @doc makeSingleFile
# @kind func
# @desc Generates the documentation for a single file (functions, types and sanity)
# @param docContent: JsonNode, the documentation in Json format
# @returns string
proc makeSingleFile(docContent: JsonNode): string =
  var
    functionSection: string = ""
    typesSection: string = ""
    sanitySection: string = ""
  if docContent.hasKey("functions"):
    for fun in docContent["functions"]:
      functionSection &= PASSAGE_NAME % [fun["name"].getStr]
      functionSection &= fun["desc"].getStr & "\n"
      functionSection &= "params : " & $ fun["params"].getElems & "\n"
      functionSection &= "returns : " & fun["returns"].getStr & "\n"
  if docContent.hasKey("types"):
    for typ in docContent["types"]:
      typesSection &= PASSAGE_NAME % [typ["name"].getStr]
      typesSection &= typ["desc"].getStr & "\n"
      typesSection &= "fields : " & $ typ["fields"].getElems & "\n"
  if docContent.hasKey("sanity"):
    for san in docContent["sanity"]:
      sanitySection &= PASSAGE_NAME % [san["name"].getStr]
      sanitySection &= san["desc"].getStr & "\n"
      sanitySection &= """<meter id="sanity" value="$1" min="-128" max="127">$1</meter>""" % [$ san["level"].getInt] & "\n"
  return functionSection & typesSection & sanitySection

# @doc makeSugarcube
# @kind func
# @desc Creates a sugarcube documentation from pre-processed data. Public.
# @param config: Config, the project's config, mostly used to get the name and description fo the project
proc makeSugarcube*(config: Config) =
  var
    stdFile: File
    docFiles: File
  createDir(Path("doc/sugarcube"))
  if stdfile.open("doc/sugarcube/00_story_info.twee", fmWrite):
    stdfile.write(makeStandardPassage(config.toProjectDesc))
    stdfile.close()
  else:
    echo "An error occured, you probably fucked up something."
  for file in walkDirRec(Path("doc/")):
    if ($ file).endsWith(".json"):
      createDir(Path("doc/sugarcube") / file.splitFile.dir)
      if docFiles.open($ (Path("doc/sugarcube") / file.changeFileExt("twee")), fmWrite):
        docFiles.write(makeSingleFile(parseFile($ file)))
        docFiles.close()
