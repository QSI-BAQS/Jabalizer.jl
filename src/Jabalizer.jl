module Jabalizer

using Graphs, LinearAlgebra
using JSON
using Documenter
using PythonCall


const stim = PythonCall.pynew() # initially NULL
const cirq = PythonCall.pynew() # initially NULL

function __init__()
    PythonCall.pycopy!(stim, pyimport("stim"))
    PythonCall.pycopy!(cirq, pyimport("cirq"))
end

include("pauli_tracker.jl")
include("ruby_slippers.jl")

end
