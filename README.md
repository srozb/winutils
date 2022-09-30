# Winutils

Bunch of apps to play with winapi and test the detection rules (EDR etc.).
All developed in Nim programming language. 

## Installation

Ensure Nim installed on your system. 

`nimble install https://github.com/srozb/winutils.git`

### Crosscompile to Windows

`nimble build -d:mingw`

## Contents

| Filename         | Description   |
| ---------------- | ------------- |
| hs.nim           | HackerSpawner - run another process with some neat features |
| np_servefile.nim | Serve file over named pipe |
| pebtamper.nim    | Run process with spoofed cmdline |
| privs.nim        | Manipulate Windows Privileges |
| progidlist.nim   | Show registry shell open for extensions |
| wahelper.nim     | Some common helper procs to be imported by above |


