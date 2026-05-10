import
  std/[
    dirs,
    strutils,
    paths,
    re,
    json,
    jsonutils,
    tables
  ],
  types,
  docgen/sugarcube

type
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
    params: seq[string] = @[]
    returns: string
  # @doc Type
  # @kind type
  # @desc The container for Type documentation
  # @field name: string, the name of the type
  # @field desc: string, the description of the type
  # @field fields: seq[string], the fields of the type
  Type = object
    name: string
    desc: string = "No description. Yet. I hope at least."
    fields: seq[string]
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
  docRegex: Regex = re"\s*(?:#|//|/\*)\s+@doc\s+([-\w\d_]+)"
  kindRegex: Regex = re"\s*(?:#|//|/\*)\s+@kind\s+(func|san|type)"
  descRegex: Regex = re"\s*(?:#|//|/\*)\s+@desc\s+([\w\d\s_:\[\],-]+(?:\w|\d|\.|!|\?))"
  paramRegex: Regex = re"\s*(?:#|//|/\*)\s+@param\s+([\w\d_]+((?:(?:\s\*+)?|\s)+[\w\d_-]+))"
  fieldRegex: Regex = re"\s*(?:#|//|/\*)\s+@field\s+([\w\d\s_:\[\],-]+(?:\w|\d|\.|!|\?))"
  returnRegex: Regex = re"\s*(?:#|\/\/|\/\*)\s+@returns\s+([\w\d_]+(\s\*+)?)"
  levelRegex: Regex = re"\s*(?:#|//|/\*)\s+@level\s+(\d+)"


# @doc parseConfig
# @kind func
# @desc Parses the config file
# @returns Config
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
# @param content: string, the content of the file to document.
# @returns JsonNode
proc fileDoc(content: string): JsonNode =
  var
    i: int32 = 0
    inDoc: bool = false
    lines: seq[string] = content.split("\n")
    subjectName: string
    functions: seq[Function] = @[]
    sanities: seq[Sanity] = @[]
    types: seq[Type] = @[]
    lastType: Kind
    res: Table[string, JsonNode]
  for l in lines:
    if l =~ docRegex:
      inDoc = true
      subjectName = matches[0]
    elif l =~ kindRegex and inDoc:
      if matches[0] == "func":
        functions.add(Function(
          name : subjectName
        ))
        lastType = FUN
      elif matches[0] == "san":
        sanities.add(Sanity(
          name : subjectName
        ))
        lastType = SAN
      elif matches[0] == "type":
        types.add(Type(
          name : subjectName
        ))
        lastType = TYP
    elif l =~ descRegex and inDoc:
      case lastType:
        of FUN:
          functions[functions.len - 1].desc = matches[0]
        of TYP:
          types[types.len - 1].desc = matches[0]
        of SAN:
          sanities[sanities.len - 1].desc = matches[0]
    elif l =~ paramRegex and inDoc:
      functions[functions.len - 1].params.add(matches[0])
    elif l =~ fieldRegex and inDoc:
      types[types.len - 1].fields.add(matches[0])
    elif l =~ returnRegex and inDoc:
      functions[functions.len - 1].returns = matches[0]
    elif l =~ levelRegex and inDoc:
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
# @desc Main documentation function, generates the Json and calls the sugarcube generator.
# @param config: Config, the project config
proc genDoc(config: Config) =
  for dir in config.srcDirs:
    for file in walkDirRec(dir):
      var
        cfile: File = open($ file)
        content: string
        docDir: Path = file.splitFile.dir
        doc: JsonNode
      content = cfile.readAll()
      cfile.close()
      doc = fileDoc(content)
      if doc.len != 0:
        createDir(Path("doc") / file.splitFile.dir)
        cfile = open($ (Path("doc") / file.changeFileExt("json")), fmWrite)
        cfile.write(doc)
        cfile.close()
  if config.sugarcube:
    makeSugarcube(config)


when isMainModule:
  var config: Config
  config = parseConfig()
  genDoc(config)
