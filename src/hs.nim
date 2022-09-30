import winim/lean
import wahelper

const 
  PROCESS_CREATION_MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALLOW_STORE = 0x00000003 shl 44
  PROCESS_CREATION_MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON = 0x00000001 shl 36

proc createStartupInfoEx(): STARTUPINFOEX =
  var lpSize: SIZE_T

  InitializeProcThreadAttributeList(NULL, 2, 0, addr lpSize)
  result.lpAttributeList = cast[LPPROC_THREAD_ATTRIBUTE_LIST](HeapAlloc(GetProcessHeap(), 0, lpSize))
  InitializeProcThreadAttributeList(result.lpAttributeList, 2, 0, addr lpSize)

  result.StartupInfo.cb = sizeof(result).cint

proc updateThreadAttr[T](si: var STARTUPINFOEX, tAttr: int, tVal: var T) = 
  var res = UpdateProcThreadAttribute(
    si.lpAttributeList, 
    0,
    cast[DWORD_PTR](tAttr),
    addr tVal,
    sizeof(tVal),
    NULL,
    NULL
  )
  
  if res == 0: echo "Unable to adjust process attributes."  

proc spawnProc*(blockDlls = false, prohibitDynamic = false, parentPid = 0, suspended = false, impersonatePid = 0, targetExec: string): bool =
  var 
    si = createStartupInfoEx()
    ps: SECURITY_ATTRIBUTES
    ts: SECURITY_ATTRIBUTES
    pi: PROCESS_INFORMATION
    dwCreationFlags: DWORD
    policy: DWORD64
    res: DWORD

  ps.nLength = sizeof(ps).cint
  ts.nLength = sizeof(ts).cint

  if parentPid > 0:
    echo "Spoofing Parent PID: " & $parentPid
    var parentHandle = OpenProcess(MAXIMUM_ALLOWED, FALSE, parentPid.DWORD)
    if bool(parentHandle) == false:
      echo "Unable to get the parent process handle"
    updateThreadAttr(si, PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, parentHandle)
    dwCreationFlags = dwCreationFlags or EXTENDED_STARTUPINFO_PRESENT

  if blockDlls:
    echo "BlockDlls enabled."
    policy = policy or PROCESS_CREATION_MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALLOW_STORE

  if prohibitDynamic:
    echo "Prohibit Dynamic Code enabled."
    policy = policy or PROCESS_CREATION_MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON
      
  if bool(policy):
    echo "Applying mitigation policy"
    updateThreadAttr(si, PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY, policy)
    dwCreationFlags = dwCreationFlags or EXTENDED_STARTUPINFO_PRESENT

  if suspended:
    echo "Process create in suspended state."
    dwCreationFlags = dwCreationFlags or CREATE_SUSPENDED

  if impersonatePid > 0:
    echo "Primary Access Token Impersonation from PID: " & $impersonatePid
    var 
      hToken, hDuplicatedToken: HANDLE
      hImpersonated = OpenProcess(MAXIMUM_ALLOWED, TRUE, impersonatePid.DWORD)
    if bool(hImpersonated) == false:
      echo "Unable to obtain process handle."
      return
    handleRes OpenProcessToken(hImpersonated, TOKEN_ALL_ACCESS, addr hToken)
    handleRes DuplicateTokenEx(hToken, TOKEN_ALL_ACCESS, NULL, SecurityImpersonation, tokenPrimary, addr hDuplicatedToken)
    
    handleRes CreateProcessWithTokenW(
      hDuplicatedToken, 
      LOGON_WITH_PROFILE, 
      NULL, 
      newWideCString(targetExec),
      dwCreationFlags,
      NULL,
      NULL,
      addr si.StartupInfo,
      addr pi
    )
  else:
    handleRes CreateProcess(
      NULL,
      newWideCString(targetExec),
      addr ps,
      addr ts,
      FALSE,
      dwCreationFlags,
      NULL,
      NULL,
      addr si.StartupInfo,
      addr pi
    )

  result = res.bool

proc main*(blockDlls = false, prohibitDynamic = false, parentPid = 0, suspended = false, impersonatePid = 0, targets: seq[string]): bool =
  ## Spawn processes according to parameters.
  if targets.len == 0:
    echo "Provide at least one filename/path to run. type `--help` for usage."
  for t in targets:
    echo "Spawning " & t & "..."
    discard spawnProc(blockDlls, prohibitDynamic, parentPid, suspended, impersonatePid, t)

when isMainModule:
  import cligen
  dispatch(main, short={
    "blockDlls": 'b',
    "parentPid": 'p',
    "prohibitDynamic": 'd',
    "suspended": 's',
    "impersonatePid": 'i'
  })
