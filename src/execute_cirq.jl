const gate_map = Dict()

# This is called by the Jabalizer package's __init__ function
function _init_gate_map()
    copy!(gate_map,
          Dict(cirq.I => Id,
               cirq.H => H,
               cirq.X => X,
               cirq.Y => Y,
               cirq.Z => Z,
               cirq.CNOT => CNOT,
               cirq.SWAP => SWAP,
               cirq.S => P,
               cirq.CZ => CZ))
end

"""
Takes a stabilizer state and cirq circuit as input and applying the
circuit to the stabilizer state.
"""
function execute_cirq_circuit(state::StabilizerState, circuit::Py)
    # Mapping of cirq gates to Jabalizer gates.
    # TODO: this seems to be inefficient, there is probably a better way to do that.
    # get ordered array of qubits
    qubits = sort([q for q in circuit.all_qubits()])

    # loops over all operations (read gates) in the circuit
    for op in circuit.all_operations()

        # Skips if op is a MeasurementGate
        if !PythonCall.pyisinstance(op.gate,  cirq.ops.measurement_gate.MeasurementGate)
            # Checks if the gate is supported
            haskey(gate_map, op.gate) || throw(error("Unsupported operation $(op.gate)"))
            # determines indicies of the qubit the gate is acting on
            qindex = [findfirst(isequal(q), qubits) for q in op.qubits]
            # Applies the Jabilizer gate corresponding to the Cirq gate.
            gate_map[op.gate](qindex...)(state)
        end
    end
end
