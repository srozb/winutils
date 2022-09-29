# Package

version       = "0.1.0"
author        = "srozb"
description   = "Windows offensive utils"
license       = "MIT"
srcDir        = "src"
bin           = @["hs", "np_servefile", "pebtamper", "progidlist", "privs"]


# Dependencies

requires "nim >= 1.6.6, winim >= 3.9.0, cligen >= 1.5.28, winregistry >= 1.0.0"
