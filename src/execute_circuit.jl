"""
Executes circuit using stim simulator and applies it to a given state.
"""
function execute_circuit(
    state::StabilizerState,
    circuit::Vector{ICMGate};
    )

    for (op, qubits) in circuit
        gate = gate_map[op]([q + index for q in qubits]...) 
        gate(state)
    end
end

# support QuantumCircuit
function execute_circuit(
    state::StabilizerState,
    circuit::QuantumCircuit)

    for gate in Jabalizer.gates(circuit)

        try
            state |> gate_map[gate.name](gate.qargs...)
        catch err
            if isa(err, KeyError)
                error(gate.name*" is not a known Stabilizer Gate.")
            end
        end

    end
end
