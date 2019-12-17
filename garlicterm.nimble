# Package

version       = "0.0.2"
author        = "Henrique Dias"
description   = "Another Vte Terminal"
license       = "MIT"
bin           = @["garlicterm"]
srcDir        = "src"

skipExt       = @["nim"]

# Deps

requires "nim >= 1.0.4", "oldgtk3 >= 0.1.0", "gintro >= 0.6.1"
