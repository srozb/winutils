import winim
import streams
import strformat

import wahelper

## Manipulate Named Section Objects.

proc vSize(vAddr: ptr uint8): int =
  ## Returns size of memory region
  var memBasicInfo: MemoryBasicInformation
  VirtualQuery(vAddr, memBasicInfo, sizeof(memBasicInfo))
  result = memBasicInfo.RegionSize.int

template mapSection(sectName: string, readOnly=true, body: untyped) =
  let memAccess = FILE_MAP_READ or (FILE_MAP_WRITE and not readOnly)
  let lpName = (r"Global\" & sectName).cstring
  var hMapp = OpenFileMappingA(memAccess, FALSE, lpName)
  if not hMapp.bool: 
    printError "OpenFileMappingA"
    return
  let sectAddr {.inject.} = cast[ptr uint8](MapViewOfFile(hMapp, memAccess, 0.DWORD, 0.DWORD, 0.SIZE_T))
  if not cast[bool](sectAddr):
    printError "MapViewOfFile"
    return
  body
  CloseHandle(hMapp)
  UnmapViewOfFile(sectAddr)

proc showSection(numBytes=0, sections: seq[string]) =
  ## Shows the section contents.
  for sectName in sections:
    mapSection(sectName, readOnly=true):
      echo fmt"Global\\{sectName} ({sectAddr.vSize} bytes):"
      echo hexPrint(sectAddr, if numBytes == 0: sectAddr.vSize else: min(
        numBytes, sectAddr.vSize))

proc dumpSection(sections: seq[string]) =
  ## Dumps the section contents to file.
  for sectName in sections:
    mapSection(sectName, readOnly=true):
      let fileName = fmt"dump-{sectName}-{cast[uint](sectAddr):#x}.bin"
      var f = newFileStream(fileName, fmWrite)
      f.writeData(sectAddr, sectAddr.vSize)
      echo fmt"{sectName} dumped to {fileName} ({sectAddr.vSize} bytes)"
      f.close()

# proc writeSection(input: string, sectName: seq[string]) =
#   ## Map section and overwrite it's contents.
#   discard

# proc listSections(processName=""):
#   var pGlobal_SystemProcessInfo = GetSystemInformationBlock(SystemProcessInformation)
#   discard

when isMainModule:
  import cligen
  dispatchMulti(
    [showSection], 
    [dumpSection],
    # [listSections],
  )