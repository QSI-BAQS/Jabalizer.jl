module Jabalizer

using Graphs, GraphPlot, LinearAlgebra
using JSON
using Documenter
using PythonCall
# using CondaPkg

export Stabilizer, StabilizerState, GraphState, Gates
export zero_state, to_tableau, tableau_to_state, to_graph, graph_to_state
export measure_x, measure_y, measure_z

include("gates.jl")
using .Gates

const stim = PythonCall.pynew() # initially NULL
const cirq = PythonCall.pynew() # initially NULL
const Frames = PythonCall.pynew()
const mbqc_scheduling = PythonCall.pynew()


function __init__()
    PythonCall.pycopy!(stim, pyimport("stim"))
    PythonCall.pycopy!(cirq, pyimport("cirq"))
    PythonCall.pycopy!(Frames, pyimport("pauli_tracker.frames.map").Frames)
    PythonCall.pycopy!(mbqc_scheduling, pyimport("mbqc_scheduling"))
end

include("cirq_io.jl")
include("qasm.jl")
include("icm.jl")
include("stabilizer.jl")
include("stabilizer_state.jl")
include("stabilizer_gates.jl")
include("graph_state.jl")
include("util.jl")
include("fast_tograph.jl")
include("execute_circuit.jl")
include("stabilizer_measurements.jl")
include("gcompile.jl")
include("mbqccompile.jl")
include("qasm_out.jl")

end
