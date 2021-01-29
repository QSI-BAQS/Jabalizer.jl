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

# Prepare initial state
num_qubits = 3
icm_length = length(icm_circuit.all_qubits())
qubit_start = icm_length - num_qubits + 1
state = Jabalizer.ZeroState(icm_length)


# Prepare Ancillas qubits in the plus state
for qubit in 1:(qubit_start - 1)
    Jabalizer.H(state, qubit)
end

# Create a random input state

# Apply random Hadamards to state qubits
for qubit = qubit_start:icm_length
    if rand((0,1)) == 1
        Jabalizer.H(state, qubit)
    end
end

# Circuit depth
d = 5

# Apply random CNOT sequence of given circuit depth
# to state qubits
for i = 1:d
    control = rand(qubit_start:icm_length)
    target = rand(qubit_start:icm_length)
    if control != target
        Jabalizer.CNOT(state,control,target)
    end
end


println("\nInitial State : \n")
print(state)


execute_cirq_circuit(state, icm_circuit)


println("\n\nFinal State :\n")
print(state)

(g,A,seq) = Jabalizer.ToGraph(state)

using GraphPlot
gplot(g)
