__precompile__(true)

module Jabalizer

using LightGraphs, GraphPlot, LinearAlgebra
using Documenter, PyCall

import Base: *, print, string
import GraphPlot.gplot

export *

const stim = PyNULL()
    function __init__()
        copy!(stim, pyimport("stim"))
end

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
include("execute_cirq.jl")

end

# export State, Stabilizer, GraphState
# export AddQubit, AddQubits, AddGraph, AddGHZ, AddBell
# export P, X, Y, Z, H, CNOT, CZ, SWAP
# export ChannelDepol, ChannelLoss, ChannelPauli, ChannelX, ChannelY, ChannelZ
# export ExecuteCircuit
# export GetQubitLabel, GraphToState, TableauToState
# export gplot, print, string
