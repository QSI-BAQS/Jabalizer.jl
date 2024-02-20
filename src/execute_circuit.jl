"""
Executes circuit using stim simulator and applies it to a given state.
"""
function execute_circuit(
    state::StabilizerState,
    circuit::Vector{ICMGate};
    )

    for (op, qubits) in circuit
        gate = gate_map[op]([q for q in qubits]...) 
        gate(state)
    end
end
