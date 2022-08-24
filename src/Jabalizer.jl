module Jabalizer

using Graphs, GraphPlot, LinearAlgebra
using Documenter
using PythonCall

export Stabilizer, StabilizerState, GraphState, Gates
export zero_state, to_tableau, tableau_to_state, to_graph, graph_to_state
export measure_x, measure_y, measure_z

include("gates.jl")
using .Gates

const stim = PythonCall.pynew() # initially NULL
const cirq = PythonCall.pynew() # initially NULL

function __init__()
    PythonCall.pycopy!(stim, pyimport("stim"))
    PythonCall.pycopy!(cirq, pyimport("cirq"))
    _init_gate_map()
end

include("icm.jl")
include("stabilizer.jl")
include("stabilizer_state.jl")
include("graph_state.jl")
include("util.jl")
include("stabilizer_gates.jl")
include("execute_cirq.jl")
include("stabilizer_measurements.jl")

end
