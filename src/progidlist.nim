import winregistry
import strformat

proc getRegVal(keyPath: string): string =
  var sbKey: RegHandle
  try:
    sbKey = open(keyPath, samRead)
    result = sbKey.readString("")
  except OSError:
    discard "means no value defined, that's fine."
  finally:
    sbKey.close    

proc enumerate() =
  echo "Enumerating HKEY_CLASSES_ROOT:"
  var h: RegHandle
  try:
    h = open(r"HKEY_CLASSES_ROOT\", samRead)
    for sk in h.enumSubkeys:
      if sk[0] == '.':
        let
          progId = getRegVal(r"HKEY_CLASSES_ROOT\" & sk)
          openCmd = getRegVal(r"HKEY_CLASSES_ROOT\" & progid & r"\shell\open\command")
        if openCmd.len > 0: echo fmt"{sk}: {progId} - {openCmd}"
  except OSError:
    echo "Error: " & getCurrentExceptionMsg()
  finally:
    close(h)

when isMainModule:
  enumerate()