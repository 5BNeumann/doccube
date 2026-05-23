import
  std/[
    dirs,
    strutils,
    paths,
#    re,
    pegs,
    json,
    jsonutils,
    tables,
    cmdline
  ],
  types,
  docgen/sugarcube

type
  # @doc LanguageConfig
  # @kind type
  # @desc The container that describes a language.
  # @field extension: string, the extension correponding to the language.
  # @field starter_comment: string, the expression that starts a documentation comment.
  LanguageConfig = object
    extention: string
    starter_comment: string
  # @doc Function
  # @kind type
  # @desc The container for Function documentation
  # @field name: string, the name of the function
  # @field desc: string, the description of the function
  # @field params: seq[string], the parameters of the function
  # @field returns: string, the return type of the function
  Function = object
    name: string
    desc: string = "No description. Yet. I hope at least."
    params: seq[array[3, string]] = @[]
    returns: string #array[2, string]
  # @doc Type
  # @kind type
  # @desc The container for Type documentation
  # @field name: string, the name of the type
  # @field desc: string, the description of the type
  # @field fields: seq[string], the fields of the type
  Type = object
    name: string
    desc: string = "No description. Yet. I hope at least."
    fields: seq[array[3, string]] = @[]
  # @doc Sanity
  # @kind type
  # @desc The container for Sanity documentation
  # @field name: string, the name of the developer
  # @field desc: string, the description of the current sanity
  # @field level: int8, the current estimated sanity level
  Sanity = object
    name: string
    desc: string = "No description. Yet. I hope at least."
    level: int8
  Kind = enum
    FUN,
    TYP,
    SAN


let
#  docRegex: Regex = re"@doc\s+([-\w\d_]+)"
  docPeg: Peg = peg"'@doc' \s+ {[-a-zA-Z0-9_]+}"
#  kindRegex: Regex = re"@kind\s+(func|san|type)"
  kindPeg: Peg = peg"'@kind' \s+ {func/type/san}"
#  descRegex: Regex = re"@desc\s+(.*)$"
  descPeg: Peg = peg"'@desc' \s+ {.*} $"
#  paramRegex: Regex = re"@param\s+(\w+)\s*:\s*([\w[\]]+)(?:,(.+))?$"
  paramPeg: Peg = peg"'@param' \s+ {\w+} \s* ':' \s* {[a-zA-Z0-9_[\]]+} (','{.+})?$"
#  fieldRegex: Regex = re"@field\s+(\w+)\s*:\s*([\w[\]]+)(?:,(.+))?$"
  fieldPeg: Peg = peg"'@field' \s+ {\w+} \s* ':' \s* {[a-zA-Z0-9_[\]]+} (','{.+})?$"
#  returnRegex: Regex = re"@returns\s+([[\]\w]+(?:\s\*+)?)"
  returnPeg: Peg = peg"'@returns' \s+ {[[\]a-zA-Z0-9_]+(\s\*+)? (','{.+})?$}"
#  levelRegex: Regex = re"@level\s+(\d+)"
  levelPeg: Peg = peg"'@level' \s+ {\d+}"

proc contains(lang: LanguageConfig, sub: string): bool =
  return sub == lang.extention

proc contains(langs: seq[LanguageConfig], sub: string): bool =
  for l in langs:
    if sub in l:
      return true
  return false

proc `[]`(a: seq[LanguageConfig], i: string): LanguageConfig =
  for l in a:
    if i in l:
      return l
  raise newException(KeyError, "Should be unreachable")

# @doc parseConfig
# @kind func
# @desc Parses the config file
# @returns [[Config]]
proc parseConfig(): Config =
  let configFile: File = open("doccube_config.txt")
  var
    config: Config = Config()
    line: string
  line = configFile.readLine()
  while line != "":
    if line.startsWith("source_dir:"):
      line.removePrefix("source_dir:")
      config.srcDirs.add(Path("./" & line))
    elif line.startsWith("name:"):
      line.removePrefix("name:")
      config.name = line
    elif line.startsWith("desc:"):
      line.removePrefix("desc:")
      config.desc = line
    elif line.startsWith("sugarcube_out:"):
      line.removePrefix("sugarcube_out:")
      config.sugarcube = line.parseBool
    elif line.startsWith("tex_out:"):
      line.removePrefix("tex_out:")
      config.tex = line.parseBool
    try:
      line = configFile.readLine()
    except IOError:
      line = ""
  return config

# @doc fileDoc
# @kind func
# @desc Documents a file
# @param content: string, The content of the file to document.
# @param lang: [[LanguageConfig]], The language configuration relevant to the file.
# @returns JsonNode
proc fileDoc(content: string, lang: LanguageConfig): JsonNode =
  var
    inDoc: bool = false
    lines: seq[string] = content.split("\n")
    subjectName: string
    functions: seq[Function] = @[]
    sanities: seq[Sanity] = @[]
    types: seq[Type] = @[]
    lastType: Kind
    res: Table[string, JsonNode]
    mutL: string
  for l in lines:
    mutL = l.strip()
    if mutL.startsWith(lang.starter_comment):
      mutL.removePrefix(lang.starter_comment)
      mutL = mutL.strip()
      if mutL =~ docPeg:
        subjectName = matches[0]
        inDoc = true
      elif mutL =~ kindPeg and inDoc:
        if matches[0] == "func":
          functions.add(Function(
            name : subjectName
          ))
          lastType = FUN
        elif matches[0] == "type":
          types.add(Type(
            name : subjectName
          ))
          lastType = TYP
        elif matches[0] == "san":
          sanities.add(Sanity(
            name : subjectName
          ))
          lastType = SAN
      elif mutL =~ descPeg and inDoc:
        case lastType:
          of FUN:
            functions[functions.len - 1].desc = matches[0]
          of TYP:
            types[types.len - 1].desc = matches[0]
          of SAN:
            sanities[sanities.len - 1].desc = matches[0]
      elif mutL =~ paramPeg and inDoc and lastType == FUN:
        functions[functions.len - 1].params.add([matches[0], matches[1], matches[2].strip()])
      elif mutL =~ fieldPeg and inDoc and lastType == TYP:
        types[types.len - 1].fields.add([matches[0], matches[1], matches[2].strip()])
      elif mutL =~ returnPeg and inDoc and lastType == FUN:
        functions[functions.len - 1].returns = matches[0] #, matches[1].strip()]
      elif mutL =~ levelPeg and inDoc and lastType == SAN:
        sanities[sanities.len - 1].level = matches[0].parseInt.int8
      else:
        inDoc = false
  if functions.len != 0:
    res["functions"] = functions.toJson
  if sanities.len != 0:
    res["sanity"] = sanities.toJson
  if types.len != 0:
    res["types"] = types.toJson
  return res.toJson

# @doc genDoc
# @kind func
# @desc Main documentation function, Generates the Json and calls the sugarcube generator.
# @param config: [[Config]], The project config
proc genDoc(config: Config, languages: seq[LanguageConfig]) =
  var docList: Table[string, JsonNode]
  for dir in config.srcDirs:
    for file in walkDirRec(dir):
      var
        cfile: File = open($ file)
        content: string
        docDir: Path = file.splitFile.dir
        doc: JsonNode
      if file.splitFile.ext in languages:
        content = cfile.readAll()
        cfile.close()
        doc = fileDoc(content, languages[file.splitFile.ext])
        docList[$(file.splitFile.dir / file.splitFile.name)] = doc
        if doc.len != 0:
          createDir(Path("doc") / docDir)
          cfile = open($ (Path("doc") / file.changeFileExt("json")), fmWrite)
          cfile.write(doc)
          cfile.close()
  if config.sugarcube:
    makeSugarcube(config, docList)

# @doc genLangConfig
# @kind func
# @desc Generates the list of language configurations from the command line.
# @param config: seq[[[LanguageConfig]]], List of configs that will be mutated in place.
proc genLangConfig(config: var seq[LanguageConfig]) =
  let cmdline: seq[string] = commandLineParams()
  for arg in cmdline:
    var
      line: string
      langFile: File = open(arg)
      lang: LanguageConfig = LanguageConfig()
    defer: langFile.close()
    line = langFile.readLine()
    while line != "":
      if line.startsWith("file_extension:"):
        line.removePrefix("file_extension:")
        lang.extention = line
      elif line.startsWith("starter_comment:"):
        line.removePrefix("starter_comment:")
        lang.starter_comment = line
      try:
        line = langFile.readLine()
      except IOError:
        break
    config.add(lang)


when isMainModule:
  var
    config: Config
    languages: seq[LanguageConfig] = @[]
  languages.genLangConfig()
  config = parseConfig()
  genDoc(config, languages)
