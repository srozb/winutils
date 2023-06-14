import winim/lean
import macros

proc resolveErrMsg*(errCode: DWORD): string =
  let strCap = 512
  var msg = newWString(strCap)
  FormatMessageW(
      FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS, 
      NULL,
      errCode,
      cast[DWORD](MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT)),
      msg,
      strCap.DWORD,
      NULL
  )
  result = $msg

proc printError*(callee: string) =
  echo `callee` & " failed with code: " & $GetLastError()
  echo "Description: " & resolveErrMsg(GetLastError())

macro handleRes*(res: DWORD): untyped =
  ## Callee returns zero on failure
  let callee = res.toStrLit
  result = quote do:
    if bool(`res`) == false: 
      printError(`callee`)
      return

macro handleResZ*(res: typed): untyped =
  ## Callee returns zero on success
  let callee = res.toStrLit
  result = quote do:
    if bool(`res`) == true: 
      printError(`callee`)


# template handleRes*(name: string, body: untyped) =
#     if bool(body) == false:
#         let strCap = 512
#         var 
#             msg = newWString(strCap)
#         FormatMessageW(
#             FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS, 
#             NULL,
#             GetLastError(),
#             cast[DWORD](MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT)),
#             msg,
#             strCap.DWORD,
#             NULL
#         )
#         echo name & " failed with: " & $GetLastError() & " - " & $msg
#         return

proc hexPrint*(p: ptr uint8, len: int, startAddress = 0): string =
  ## Helper function to dump hexadecimal representation of bytes.
  ## Code by treeform: https://github.com/treeform/flatty/blob/master/LICENSE
  ## Thanks
  var i = 0
  while i < len:
    result.add(toHex(i + startAddress, 16))
    result.add(": ")

    for j in 0 ..< 16:
      if i + j < len:
        let b = cast[ptr uint8](cast[int](p) + i + j)[]
        result.add(toHex(b.int, 2))
      else:
        result.add("..")
      if j == 7:
        result.add("-")
      else:
        result.add(" ")

    for j in 0 ..< 16:
      if i + j < len:
        let b = cast[ptr uint8](cast[int](p) + i + j)[]
        if ord(b) >= 32 and ord(b) <= 126:
          result.add(b.char)
        else:
          result.add('.')
      else:
        result.add(' ')

    i += 16
    result.add("\n")

proc hexPrint*(buf: string, startAddress = 0): string =
  hexPrint(cast[ptr uint8](buf[0].unsafeAddr), buf.len, startAddress)