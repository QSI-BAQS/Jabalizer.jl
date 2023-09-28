const ICMGate = Tuple{String,Vector{String}}

import .pauli_tracker: Frames, Storage

function bit(qubit::String)::UInt
    parse(UInt, qubit)
end

function apply_gate(frames::Ptr{Frames}, gate::ICMGate)
    name = gate[1]
    bits = gate[2]
    if name == "H"
        pauli_tracker.frames_h(frames, bit(bits[1]))
    elseif name == "S"
        pauli_tracker.frames_s(frames, bit(bits[1]))
    elseif name == "CZ"
        pauli_tracker.frames_cz(frames, bit(bits[1]), bit(bits[2]))
    elseif name == "X" || name == "Y" || name == "Z"
    elseif name == "S_DAG"
        pauli_tracker.frames_sdg(frames, bit(bits[1]))
    elseif name == "SQRT_X"
        pauli_tracker.frames_sx(frames, bit(bits[1]))
    elseif name == "SQRT_X_DAG"
        pauli_tracker.frames_sxdg(frames, bit(bits[1]))
    elseif name == "SQRT_Y"
        pauli_tracker.frames_sy(frames, bit(bits[1]))
    elseif name == "SQRT_Y_DAG"
        pauli_tracker.frames_sydg(frames, bit(bits[1]))
    elseif name == "SQRT_Z"
        pauli_tracker.frames_sz(frames, bit(bits[1]))
    elseif name == "SQRT_Z_DAG"
        pauli_tracker.frames_szdg(frames, bit(bits[1]))
    elseif name == "CNOT"
        pauli_tracker.frames_cx(frames, bit(bits[1]), bit(bits[2]))
    elseif name == "SWAP"
        pauli_tracker.frames_swap(frames, bit(bits[1]), bit(bits[2]))
    else
        error("Unknown gate: $name")
    end
end

function rz_teleportation(
    frames::Ptr{Frames},
    _storage::Ptr{Storage},
    origin::UInt,
    new::UInt
)
    pauli_tracker.frames_new_qubit(frames, new)
    pauli_tracker.frames_cx(frames, origin, new)
    pauli_tracker.frames_move_z_to_z(frames, origin, new)
    # pauli_tracker.frames_measure_and_store(frames, origin, storage)
    pauli_tracker.frames_track_z(frames, new)
end

"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004
"""
function compile(
    circuit,
    n_qubits::Int,
    gates_to_decompose::Vector{String},
    frames::Ptr{Frames},
    storage::Ptr{Storage}
)
    qubit_dict = Dict()  # mapping from qubit to it's compiled version
    compiled_circuit = []
    ancilla_num = 0
    frames_map::Vector{Int} = []

    for gate in circuit
        compiled_qubits = [get(qubit_dict, qubit, qubit) for qubit in gate[2]]

        if gate[1] in gates_to_decompose
            for (original_qubit, compiled_qubit) in zip(gate[2], compiled_qubits)
                new_qubit_name = "anc_$(ancilla_num)"

                new_qubit = UInt(n_qubits + ancilla_num)
                if original_qubit == compiled_qubit
                    origin_qubit = bit(original_qubit)
                else
                    origin_qubit = n_qubits + bit(compiled_qubit[5:end])
                end
                rz_teleportation(frames, storage, origin_qubit, new_qubit)
                push!(frames_map, Int(origin_qubit))

                ancilla_num += 1

                qubit_dict[original_qubit] = new_qubit_name
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit_name]))
                if length(gate) == 2
                    additional = 0
                else
                    additional = gate[3]
                end
                push!(
                    compiled_circuit,
                    ("$(gate[1])_measurement", [compiled_qubit], additional)
                )
            end
        else
            push!(compiled_circuit, (gate[1], compiled_qubits))
            qubits::Vector{String} = []
            for (original_qubit, compiled_qubit) in zip(gate[2], compiled_qubits)
                if original_qubit == compiled_qubit
                    push!(qubits, original_qubit)
                else
                    push!(qubits, "$(n_qubits + bit(compiled_qubit[5:end]))")
                end
            end
            apply_gate(frames, ICMGate((gate[1], qubits)))
        end
    end

    # map qubits from the original circuit to the compiled one
    output_map = [i for i in 0:n_qubits-1]
    for (original_qubit, compiled_qubit) in qubit_dict
        original_qubit_num = parse(Int, original_qubit)
        compiled_qubit_num = n_qubits + parse(Int, compiled_qubit[5:end])
        # +1 here because julia vectors are indexed from 1
        output_map[original_qubit_num+1] = compiled_qubit_num
    end

    return compiled_circuit, output_map, frames_map
end
