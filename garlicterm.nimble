# Package

version       = "0.0.1"
author        = "Henrique Dias"
description   = "Another Vte Terminal"
license       = "MIT"
bin           = @["garlicterm"]
srcDir        = "src"

skipExt       = @["nim"]

# Deps

requires "nim >= 0.19.0", "oldgtk3 >= 0.1.0", "gintro >= 0.4.7"
