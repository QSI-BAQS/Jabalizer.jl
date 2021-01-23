# God bless stackoverflow
# https://github.com/JuliaPy/PyCall.jl/issues/48
using PyCall

py"""
import sys
sys.path.insert(0, ".")
"""
icm = pyimport("icm")

include("jabalizer.jl")
include("execute_cirq.jl")

# circuit = cirq.Circuit()
# q0 = cirq.GridQubit(0, 0)
# q1 = cirq.GridQubit(1, 0)
# q2 = cirq.GridQubit(2, 0)
# circuit.append([cirq.H(q0), cirq.H(q1)])
# circuit.append([cirq.CNOT(q0,q1), cirq.CNOT(q1,q2)])


a = icm.SplitQubit("a")
b = icm.SplitQubit("b")
c = icm.SplitQubit("c")


mycircuit = cirq.Circuit(
    cirq.T.on(a), cirq.T.on(b),
    cirq.CNOT.on(a,b), cirq.S.on(a),
    cirq.CNOT.on(b,c), cirq.T.on(c),
)
icm.icm_flag_manipulations.add_op_ids(mycircuit, [cirq.T, cirq.S])

# print(mycircuit.__str__())

icm_circuit = cirq.Circuit(cirq.decompose(mycircuit,
                                          intercepting_decomposer=icm.decomp_to_icm,
                                          keep = icm.keep_icm))

# for op in icm_circuit.all_operations()
#     print(op.gate)
# end

println("\nApplying the circuit:\n")
# print(circuit.__str__())
print(icm_circuit.__str__())
println()
# execute_cirq_circuit(state, circuit)

# state = Jabalizer.ZeroState(length(icm_circuit.all_qubits()))
# println("\nInitial State : \n")
# print(state)
#
#
# execute_cirq_circuit(state, icm_circuit)
#
#
# println("\n\nFinal State :\n")
# print(state)
