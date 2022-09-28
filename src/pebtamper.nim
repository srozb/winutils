import winim/lean

const PBI = 0

var 
    hProc: HANDLE
    pInfo: PROCESS_BASIC_INFORMATION
    pLen: DWORD

hProc = GetCurrentProcess()

var res = NtQueryInformationProcess(hProc, cast[PROCESSINFOCLASS](PBI), addr pInfo, sizeof(pInfo).DWORD, addr pLen)
echo "Result: " & res.repr
# echo pInfo.repr
pInfo.PebBaseAddress.ProcessParameters.ImagePathName.Buffer = r"C:\windows\notepad.exe"
pInfo.PebBaseAddress.ProcessParameters.CommandLine.Buffer = "🦄 totally legit"

discard readLine(stdin)
