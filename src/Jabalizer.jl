module Jabalizer

using Graphs, GraphPlot, LinearAlgebra
using Documenter
using PythonCall

import GraphPlot.gplot

const stim = PythonCall.pynew() # initially NULL
const cirq = PythonCall.pynew() # initially NULL
const gate_map = Dict()

function __init__()
    PythonCall.pycopy!(stim, pyimport("stim"))
    PythonCall.pycopy!(cirq, pyimport("cirq"))
    copy!(gate_map,
          Dict(cirq.I => Jabalizer.Id,
               cirq.H => Jabalizer.H,
               cirq.X => Jabalizer.X,
               cirq.Y => Jabalizer.Y,
               cirq.Z => Jabalizer.Z,
               cirq.CNOT => Jabalizer.CNOT,
               cirq.SWAP => Jabalizer.SWAP,
               cirq.S => Jabalizer.P,
               cirq.CZ => Jabalizer.CZ))
end

include("stabilizer.jl")
include("stabilizer_state.jl")
include("graph_state.jl")
include("util.jl")
include("stabilizer_gates.jl")
include("execute_cirq.jl")
include("stabilizer_measurements.jl")

end
