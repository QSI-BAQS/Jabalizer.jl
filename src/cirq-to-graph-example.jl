# God bless stackoverflow
# https://github.com/JuliaPy/PyCall.jl/issues/48
using PyCall

# Adds script location to python search path
# This is required to import the icm module
source = @__FILE__
circ_dir =  "cirq_circuits"

py"""
import os, sys
dirname = os.path.dirname($source)
sys.path.insert(0, dirname)
sys.path.insert(0, os.path.join(dirname, $circ_dir))
"""
icm = pyimport("icm")

include("jabalizer.jl")
include("execute_cirq.jl")

# cirq_circuit  = pyimport("cirq_circuit_adder_qct_8")
cirq_circuit  = pyimport("control-v")

circuit = cirq_circuit.build_circuit()

println("\nInitial circuit:\n")
print(circuit.__str__())
println()

ct_circ = cirq.Circuit(cirq.decompose(circuit, keep=icm.keep_clifford))

println("\nClifford + T circuit:\n")
print(ct_circ.__str__())
println()


gates_to_decomp = [cirq.T, cirq.T^-1, cirq.H, cirq.S, cirq.S^-1]
icm_circuit = icm.icm_circuit(ct_circ, gates_to_decomp, inverse=true)

println("\nICM circuit:\n")
print(icm_circuit.__str__())
println()


icm_length = length(icm_circuit.all_qubits())
state = Jabalizer.ZeroState(icm_length)

println("\nInitial State : \n")
print(state)


execute_cirq_circuit(state, icm_circuit)


println("\n\nFinal State :\n")
print(state)

(g,A,seq) = Jabalizer.ToGraph(state)

using GraphPlot
gplot(g)
