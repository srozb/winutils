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