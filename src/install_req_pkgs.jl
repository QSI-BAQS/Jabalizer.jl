# Run this file to install required packages for jabalizer
using Pkg

dependencies = [
"PyCall"
"LightGraphs",
"GraphPlot",
"Documenter",
"StatsBase"
]

Pkg.add(dependencies)
