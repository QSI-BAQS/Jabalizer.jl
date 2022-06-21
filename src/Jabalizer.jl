module Jabalizer

using Graphs, GraphPlot, LinearAlgebra
using Documenter, PyCall

import Base: *, print, string, isequal
import GraphPlot.gplot

export *

const stim = PyNULL()
const cirq = PyNULL()

function __init__()
    copy!(stim, pyimport("stim"))
    copy!(cirq, pyimport("cirq"))
end



include("stabilizer.jl")
include("stabilizer_state.jl")
include("graph_state.jl")
include("util.jl")
include("stabilizer_gates.jl")
include("execute_cirq.jl")

end
