# Run this file to install required packages for jabalizer
using Pkg

dependencies = [
"PyCall",
"LightGraphs",
"GraphPlot",
"Documenter",
"StatsBase",
"Debugger",
]

Pkg.add(dependencies)


# Installing cirq and stim support

Pkg.add(PackageSpec(name="Conda", rev="master"))

using Conda
Conda.pip_interop(true)

Conda.pip("install", "cirq")

Conda.pip("install", "stim>=1.2.1")
