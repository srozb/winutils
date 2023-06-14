import std/[os, sha1, strtabs, json, strutils, httpclient]
import winim
import termstyle

const 
  ARRAY_SIZE = 1024  # Microsoft claims that's enough
  URI = "https://www.loldrivers.io/drivers/"
  JSON_URI = "https://www.loldrivers.io/api/drivers.json"

proc normalizePath(path: var string) {.inline.} =
  if path.startsWith(r"\SystemRoot\"): 
    path = getEnv("SystemRoot") & path[11..<path.len]

proc resolveDriver(imageBase: pointer): string {.inline.} =
  var lpFilename = newWideCString(ARRAY_SIZE)
  if GetDeviceDriverFileName(
    cast[LPVOID](imageBase), 
    cast[LPWSTR](addr lpFilename[0]), 
    ARRAY_SIZE.DWORD
  ) < 1: 
    echo "GetDeviceDriverFileName failed."
    quit()
  result = $lpFilename
  result.normalizePath()

proc loadFromFile(lolDb: var StringTableRef, filePath: string, update: bool) =
  if update:
    echo "Downloading " & JSON_URI
    var client = newHttpClient()
    filePath.writeFile(client.getContent(JSON_URI))
    quit()
  if not filePath.fileExists():  # TODO: auto download
    echo yellow "Unable to load " & filePath 
    echo "Run --update."
    quit()
  let lolJson = parseJson(filePath.readFile)
  for lolDriver in lolJson.items:
    let drvId = lolDriver["Id"].getStr
    for sample in lolDriver["KnownVulnerableSamples"].items:
      try:
        lolDb[sample["SHA1"].getStr] = drvId
      except KeyError:
        continue # echo "SHA1 sum is missing."  # TODO: sha256
  echo "Loldrivers.io database loaded: " & $lolDb.len & " samples."

proc main(driversFile = "drivers.json", verbose = false, update = false) =
  var 
    drivers: array[ARRAY_SIZE, pointer]
    cbNeeded: DWORD
    lolDb = newStringTable()

  lolDb.loadFromFile(driversFile, update)

  echo "Enumerating loaded drivers."
  if EnumDeviceDrivers(
    cast[ptr LPVOID](addr drivers), 
    sizeof(drivers).DWORD, 
    addr cbNeeded
  ) == 0 or cbNeeded >= sizeof(drivers):
    echo "EnumDeviceDrivers failed."
    quit()

  for imageBase in drivers:
    if imageBase.isNil: break
    let driverPath = resolveDriver(imageBase)
    try:
      let driverSha1 = ($secureHashFile(driverPath)).toLower
      if driverSha1 in lolDb:
        echo red driverPath & ": " & URI & lolDb[driverSha1]
      elif verbose:
        echo green driverPath & ": " & ($driverSha1).toLower
    except IOError:
      echo yellow driverPath & ": Not accessible."
      continue

when isMainModule:
  import cligen; dispatch main

