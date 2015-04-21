import macros, strutils

proc nimceptionTransform(input: string): string =
  var stack: seq[int] = @[]
  template top(): expr =
    if stack.len > 0: stack[stack.high]
    else: -1
  
  result = "proc nimceptionResult(): string ="
  template add(s: string): stmt =
    result.add "\n  " & repeat("  ", stack.len) & s
  add """result = """""
  
  for line in input.splitLines():
    let leading = line.len - line.strip(trailing = false).len
    while leading <= top():
      discard stack.pop()
    if line.strip().startsWith("%"):
      add line.substr(leading+1)
      if leading >= top():
        stack.add leading
    else:
      add """result.add "\n$1"""".format(line.substr(stack.len*2)
        .replace(r"\", r"\\").replace("\"", "\\\"")
        .replace("{{", """"& $(""").replace("}}", """) &""""))
  add "result = result.substr(1)"

macro exec*(s: static[string]): stmt =
  result = parseStmt(s)

template templ*(s: string): string =
  static: exec nimceptionTransform(s)
  nimceptionResult()

when isMainModule:
  static:
    const s1 = staticRead("1.nim")
    const s2 = nimceptionTransform(s1)
    writeFile("2.nim", s2)
    exec s2
    const s3 = nimceptionResult()
    writeFile("3.nim", s3)
    exec s3
