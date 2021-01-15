include("jabalizer.jl")
include("execute_cirq.jl")


state = Jabalizer.ZeroState(3)

println("\nInitial State : \n")

print(state)

circuit = cirq.Circuit()

q0 = cirq.GridQubit(0, 0)
q1 = cirq.GridQubit(1, 0)
q2 = cirq.GridQubit(2, 0)


circuit.append([cirq.H(q0), cirq.H(q1)])
circuit.append([cirq.CNOT(q0,q1), cirq.CNOT(q1,q2)])

println("\nApplying the circuit:\n")
print(circuit.__str__())
println()
execute_cirq_circuit(state, circuit)

println("\n\nFinal State :\n")
print(state)
