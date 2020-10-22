# Run this file from terminal to install packages used by jabalizer
using Pkg

dependencies = [
"LightGraphs",
"GraphPlot"
]

Pkg.add(dependencies)
