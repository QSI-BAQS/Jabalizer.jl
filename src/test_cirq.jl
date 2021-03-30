include("jabalizer.jl")
include("execute_cirq.jl")


circuit = cirq.Circuit()
q0 = cirq.GridQubit(0, 0)
q1 = cirq.GridQubit(1, 0)
q2 = cirq.GridQubit(2, 0)
circuit.append([cirq.H(q0), cirq.H(q1)])
circuit.append([cirq.CNOT(q0,q1), cirq.CNOT(q1,q2)])
#circuit.append([cirq.measure(q0)])

state = Jabalizer.ZeroState(3)
println("Initial State")
print(state)
println("\nApplying the circuit:\n")
print(circuit.__str__())
println()
execute_cirq_circuit(state, circuit)
println("\nFinal State\n")
print(state)

(g,A,seq) = Jabalizer.ToGraph(state)

using GraphPlot
gplot(g)

# circuit_2 = cirq.Circuit()
# circuit_2.append([cirq.X(q0), cirq.X(q1), cirq.X(q2) ])
#
# print(circuit_2.__str__())
# println()
#
# simulator = cirq.Simulator()
# result = simulator.simulate(circuit)
# final_state_1 = result.final_state
#
#
# println(length(final_state_1))
#
# check_circuit = circuit + circuit_2
# print(check_circuit.__str__())
#
# result = simulator.simulate(circuit)
# final_state_2 = result.final_state
#
# println(final_state_1 == final_state_2)
