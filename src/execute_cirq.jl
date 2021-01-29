using PyCall
cirq = pyimport("cirq")

function execute_cirq_circuit(state::Jabalizer.StabilizerState, circuit::PyObject)
"""
Takes a stabilizer state and cirq circuit as input and applying the
circuit to the stabilizer state.
"""
    # Mapping of cirq gates to Jabalizer gates.
    gate_map = Dict(cirq.I => Jabalizer.Id,
                       cirq.H => Jabalizer.H,
                       cirq.X => Jabalizer.X,
                       cirq.Y => Jabalizer.Y,
                       cirq.Z => Jabalizer.Z,
                       cirq.CNOT => Jabalizer.CNOT,
                       cirq.SWAP => Jabalizer.SWAP,
                       cirq.S => Jabalizer.P,
                       cirq.CZ => Jabalizer.CZ)

    # get ordered array of qubits
    qubits = sort([q for q in circuit.all_qubits()])

    # loops over all operations (read gates) in the circuit
    for op in circuit.all_operations()

        # Skips if op is a MeasurementGate
        if !py"isinstance($op.gate,  $cirq.ops.measurement_gate.MeasurementGate)"
            # Checks if the gate is supported
            if !haskey(gate_map, op.gate)
                throw(error("Unsupported operation $(op.gate)"))
            else
                # determines indicies of the qubit the gate is acting on
                qindex = [findfirst(isequal(q), qubits) for q in op.qubits]
                # Applies the Jabilizer gate corresponding to the Cirq gate.
                gate_map[op.gate](state, qindex...)
            end
        end
    end
end
