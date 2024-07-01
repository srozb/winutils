# Package

version       = "0.2.0"
author        = "srozb"
description   = "Windows offensive utils"
license       = "MIT"
srcDir        = "src"
binDir        = "release/"
bin           = @[
  "driversCheck",
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

requires "nim >= 2.0.0, winim >= 3.9.0, cligen >= 1.6.0, winregistry >= 1.0.0, nancy >= 0.1.0, termstyle >= 0.1.0"
