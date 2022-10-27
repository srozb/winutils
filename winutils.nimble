# Package

version       = "0.1.4"
author        = "srozb"
description   = "Windows offensive utils"
license       = "MIT"
srcDir        = "src"
binDir        = "release/"
bin           = @[
  "dumper", 
  "hs",
  "injector",
  "np_servefile",
  "pebtamper", 
  "privs",
  "progidlist",
  "sections",
  "wevent"
]


# Dependencies

requires "nim >= 1.6.6, winim >= 3.9.0, cligen >= 1.5.28, winregistry >= 1.0.0"
