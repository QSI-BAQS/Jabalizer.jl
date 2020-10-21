__precompile__(true)

module Jabalizer

using LightGraphs, GraphPlot, LinearAlgebra
using Documenter

import Base: *, print, string
import GraphPlot.gplot

export *

include("stabilizer.jl")
include("stabilizer_state.jl")
include("graph_state.jl")
include("util.jl")
include("preparation.jl")
include("stabilizer_gates.jl")
include("graph_gates.jl")
include("stabilizer_measurements.jl")
include("graph_measurements.jl")
include("channels.jl")

end

# export State, Stabilizer, GraphState
# export AddQubit, AddQubits, AddGraph, AddGHZ, AddBell
# export P, X, Y, Z, H, CNOT, CZ, SWAP
# export ChannelDepol, ChannelLoss, ChannelPauli, ChannelX, ChannelY, ChannelZ
# export ExecuteCircuit
# export GetQubitLabel, GraphToState, TableauToState
# export gplot, print, string
