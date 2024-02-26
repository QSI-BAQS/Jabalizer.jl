"""
Executes circuit using stim simulator and applies it to a given state.
"""
function execute_circuit(
    state::StabilizerState,
    circuit::Vector{ICMGate};
    index=0)

    for (op, qubits) in circuit
        gate = gate_map[op]([q + index for q in qubits]...) 
        gate(state)
    end
end

function execute_circuit(ss::StabilizerState,qc::QuantumCircuit)
    for gate in gates(qc)
        op = name(gate)
        # this won't work due to definition of gate_map
        gate_map[op](qargs(gate)...)(ss)
        # I suggest removing the gates.jl completely
        # and move stabilizer_gate logic directly here?
    end
end