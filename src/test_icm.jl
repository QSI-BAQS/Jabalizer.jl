# God bless stackoverflow
# https://github.com/JuliaPy/PyCall.jl/issues/48
using PyCall

# Adds script location to python search path
# This is required to import the icm module
source = @__FILE__
py"""
import os, sys
sys.path.insert(0, os.path.dirname($source))
"""
icm = pyimport("icm")

include("jabalizer.jl")
include("execute_cirq.jl")

a = icm.SplitQubit("a")
b = icm.SplitQubit("b")
c = icm.SplitQubit("c")

mycircuit = cirq.Circuit(
    cirq.T.on(a), cirq.T.on(b),
    cirq.CNOT.on(a,b), cirq.S.on(a),
    cirq.CNOT.on(b,c), cirq.T.on(c),
)
icm.icm_flag_manipulations.add_op_ids(mycircuit, [cirq.T, cirq.S])

println("Initial circuit\n")
print(mycircuit.__str__())
println()
icm_circuit = cirq.Circuit(cirq.decompose(mycircuit,
                                          intercepting_decomposer=icm.decomp_to_icm,
                                          keep = icm.keep_icm))


println("\nICM circuit:\n")
print(icm_circuit.__str__())
println()

# Prepare initial plus state
state = Jabalizer.ZeroState(length(icm_circuit.all_qubits()))
for qubit in 1:state.qubits
    Jabalizer.H(state, qubit)
end

println("\nInitial State : \n")
print(state)


execute_cirq_circuit(state, icm_circuit)


println("\n\nFinal State :\n")
print(state)

(g,A,seq) = Jabalizer.ToGraph(state)

using GraphPlot
gplot(g)
