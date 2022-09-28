import winim
import os

proc readFile(filename: string): seq[char] = 
  var f_src: File
  if not open(f_src, filename):
    raise newException(OSError, "Unable to open " & filename)
  var buffer = newSeq[char](getFileSize(f_src))
  let bytes_read = readBuffer(f_src, addr buffer[0], buffer.len)
  close(f_src)
  echo "File read (" & filename & "): " & $bytes_read & " bytes."
  return buffer

proc createPipe(pipeName: string): HANDLE =
  let fPipeName = r"\\.\pipe\" & pipeName
  result = CreateNamedPipe(
    fPipeName,
    PIPE_ACCESS_DUPLEX,
    # PIPE_ACCESS_OUTBOUND,
    PIPE_TYPE_BYTE,
    255,
    0,
    0,
    0,
    NULL
  )

  if not bool(result) or result == INVALID_HANDLE_VALUE:
    echo "Server pipe creation failed."
    quit(1)

  echo "Pipe: " & fPipeName & " created..."

proc serveFile(pipe: HANDLE, data: var seq[char]) =
  var bytesWritten: DWORD

  var result: BOOL = ConnectNamedPipe(pipe, NULL)
  if not bool(result):
    echo "ConnectNamedPipe failed."
    return
  echo "Client connected." 

  WriteFile(
    pipe,
    cast [LPCVOID](addr data[0]),
    (DWORD) data.len,
    addr bytesWritten,
    NULL
  )
  echo "Done, bytes written: " & $bytesWritten

proc serveInfinite(data: var seq[char]) = 
  while true:
    var pipe = createPipe(paramStr(1))
    try:
      serveFile(pipe, data)
      echo "Client disconnected."
    finally:
      CloseHandle(pipe)

when isMainModule:
  import std/os
  if paramCount() != 2:
    echo "usage: nptool.exe <pipename> <filename>"
    quit(-1)
  var data = readFile(paramStr(2))
  serveInfinite(data)

