using PyCall
cirq = pyimport("cirq")

# Add icm directory to import path
source = @__FILE__
py"""
import os, sys
sys.path.insert(0, os.path.dirname($source))
"""
icm = pyimport("icm")

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


"""
    repalce_qubits(PyObject)
Takes a cirq circuit as input and replaces the qubits by icm.SplitQubits

Parameters
----------
circuit :: PyObject
        a cirq circuit

Returns
--------
pre_icm_circuit :: PyObject
        a cirq circuit with icm.Splitqubits
"""
function replace_qubits(circuit::PyObject)

    # Build ordered array of qubits
    qubits = sort([q for q in circuit.all_qubits()])

    # Build qubit map
    qubit_map = Dict(string(qubit) => icm.SplitQubit(string(i)) for (i, qubit) in  enumerate(qubits) )

    # Initialise new circuit
    new_circ = cirq.Circuit()

    # Add ops from circut to new circuit with icm.SplitQubits
    for moment in circuit
        for op in moment
            new_qubits = [get(qubit_map, string(q), "qubit not found") for q in op.qubits]
            new_op = op.gate.on(new_qubits...)
            new_circ.append(new_op)
        end
    end

    return new_circ
end

"""
    ToGraph(PyObject)
Takes a cirq circuit as input and return the graph of it's ICM form

Parameters
----------
circuit :: PyObject
        a cirq circuit

Returns
--------
graph_state :: StabilizerState
    The stabilizer state of the final graph
adj_matrix :: Array{Int64}
    The adjaceny matrix of the graph
local_ops :: Array
    Array containing sequance of local operations used to convert
    the icm_stabilziers to graph form
"""
function ToGraph(circuit::PyObject)

    # Replace the circuit qubits with SplitQubits
    pre_icm_circuit = replace_qubits(circuit)


    # Gates to be decomposed
    decompose_arr = [cirq.T,
                    cirq.CCNOT
    ]
    icm.icm_flag_manipulations.add_op_ids(pre_icm_circuit, decompose_arr)

    icm_circuit = cirq.Circuit(cirq.decompose(pre_icm_circuit,
                                              intercepting_decomposer=icm.decomp_to_icm,
                                              keep = icm.keep_icm))

    # Initialise qubit inputs to plus states

    # ordered array of qubits
    icm_qubits = sort([q.__str__() for q in icm_circuit.all_qubits()])

    # Find position of first ancilla
    anc_position = findfirst(x -> x[1] == '_', icm_qubits)

    # Check if there are no ancilla qubits
    if anc_position == Nothing
        qubit_length = length(icm_circuit.all_qubits())
    else
        qubit_length = anc_position - 1
    end

    icm_qubits = sort([q for q in icm_circuit.all_qubits()])
    logical_qubits = icm_qubits[1:qubit_length]

    # Create a moment initalising logical_qubits to plus states
    moment = cirq.Moment([cirq.H.on(q) for q in icm_qubits[1:qubit_length]])

    icm_circuit.insert(0, moment)

    # print ICM circuit
    println()
    println()
    println("ICM Circuit")
    print(icm_circuit.__str__())
    println()

    # Prepare initial state
    icm_length = length(icm_circuit.all_qubits())
    state = ZeroState(icm_length)

    execute_cirq_circuit(state, icm_circuit)

    return Jabalizer.ToGraph(state)

end
