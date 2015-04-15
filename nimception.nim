import macros, strutils

proc nimceptionTransform(input: string): string =
  var stack: seq[int] = @[]
  template top(): expr =
    if stack.len > 0: stack[stack.high]
    else: 0
  
  result = "proc nimceptionResult(): string ="
  template echo(s: string): stmt =
    result.add "\n  " & repeat("  ", stack.len) & s
  echo "result = \"\""
  
  for line in input.splitLines():
    let leading = line.len - line.strip(trailing = false).len
    while stack.len > 0 and leading <= top():
      discard stack.pop()
    if line.strip().startsWith("%"):
      echo line.substr(leading+1)
      if stack.len == 0 or leading >= top():
        stack.add leading
    else:
      echo "result.add \"\\n" & line.substr(stack.len*2)
        .replace("\\", "\\\\").replace("\"", "\\\"")
        .replace("{{", "\"& $(").replace("}}", ") &\"") & "\""
  echo "result = result.substr(1)"

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
