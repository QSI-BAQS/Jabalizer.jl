# Run this file to install required packages for jabalizer
using Pkg

dependencies = [
"LightGraphs",
"GraphPlot",
"Documenter",
"StatsBase"
]

Pkg.add(dependencies)
