const ICMGate = Tuple{String,Vector{String}}

include("../pauli_tracker.jl")

function bit(qubit::String)::UInt
    parse(UInt, qubit)
end

function apply_gate(frames::Ptr{Frames}, gate::ICMGate)
    name = gate[1]
    bits = gate[2]
    if name == "H"
        frames_h(frames, bit(bits[1]))
    elseif name == "S"
        frames_s(frames, bit(bits[1]))
    elseif name == "CZ"
        frames_cz(frames, bit(bits[1]), bit(bits[2]))
    elseif name == "X" || gate[1] == "Y" || gate[1] == "Z"
    elseif name == "S_DAG"
        frames_sdg(frames, bit(bits[1]))
    elseif name == "SQRT_X"
        frames_sx(frames, bit(bits[1]))
    elseif name == "SQRT_X_DAG"
        frames_sxdg(frames, bit(bits[1]))
    elseif name == "SQRT_Y"
        frames_sy(frames, bit(bits[1]))
    elseif name == "SQRT_Y_DAG"
        frames_sydg(frames, bit(bits[1]))
    elseif name == "SQRT_Z"
        frames_sz(frames, bit(bits[1]))
    elseif name == "SQRT_Z_DAG"
        frames_szdg(frames, bit(bits[1]))
    elseif name == "CNOT"
        frames_cx(frames, bit(bits[1]), bit(bits[2]))
    elseif name == "SWAP"
        frames_swap(frames, bit(bits[1]), bit(bits[2]))
    else
        error("Unknown gate: $name")
    end
end

function t_teleportation(
    frames::Ptr{Frames},
    storage::Ptr{Storage},
    origin::UInt,
    new::UInt
)
    frames_new_qubit(frames, new)
    frames_cx(frames, origin, new)
    frames_move_z_to_z(frames, origin, new)
    frames_measure_and_store(frames, origin, storage)
    frames_track_z(frames, new)
end

"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004
"""
function compile(
    circuit::Vector{ICMGate},
    n_qubits::Int,
    gates_to_decompose::Vector{String},
    storage_file::String
)
    frames = frames_init(UInt(n_qubits))
    storage = storage_new()

    qubit_dict = Dict()  # mapping from qubit to it's compiled version
    compiled_circuit::Vector{ICMGate} = []
    ancilla_num = 0
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
                t_teleportation(frames, storage, origin_qubit, new_qubit)

                ancilla_num += 1

                qubit_dict[original_qubit] = new_qubit_name
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit_name]))
                push!(compiled_circuit,
                    ("$(gate[1])_measurement_sign_conditioned_on_pauli",
                        [compiled_qubit]))
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
    data_qubits_map = [i for i in 0:n_qubits-1]
    for (original_qubit, compiled_qubit) in qubit_dict
        original_qubit_num = parse(Int, original_qubit)
        compiled_qubit_num = n_qubits + parse(Int, compiled_qubit[5:end])
        # +1 here because julia vectors are indexed from 1
        data_qubits_map[original_qubit_num+1] = compiled_qubit_num
    end

    frames_measure_and_store_all(frames, storage)
    storage_serialize(storage, storage_file)
    storage_free(storage)
    frames_free(frames)

    return compiled_circuit, data_qubits_map
end

# const ICMGate = Tuple{String,Vector{String}}


# """
# Perfoms gates decomposition to provide a circuit in the icm format.
# Reference: https://arxiv.org/abs/1509.02004
# """
# function compile(circuit::Vector{ICMGate},
#                  n_qubits::Int,
#                  gates_to_decompose::Vector{String},
#                  with_measurements::Bool=false)
#     qubit_dict = Dict()  # mapping from qubit to it's compiled version
#     compiled_circuit::Vector{ICMGate} = []
#     ancilla_num = 0
#     for gate in circuit
#         compiled_qubits = [get(qubit_dict, qubit, qubit) for qubit in gate[2]]

#         if gate[1] in gates_to_decompose
#             for (original_qubit, compiled_qubit) in zip(gate[2], compiled_qubits)
#                 new_qubit_name = "anc_$(ancilla_num)"
#                 ancilla_num += 1

#                 qubit_dict[original_qubit] = new_qubit_name
#                 push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit_name]))
#                 if with_measurements
#                     push!(compiled_circuit,
#                           ("$(gate[1])_measurement", [compiled_qubit]))
#                     push!(compiled_circuit,
#                           ("Gate_Conditioned_on_$(compiled_qubit)_Measurement",
#                            [new_qubit_name]))
#                 end
#             end
#         else
#             push!(compiled_circuit, (gate[1], compiled_qubits))
#         end
#     end

#     # map qubits from the original circuit to the compiled one
#     data_qubits_map = [i for i in 0:n_qubits-1]
#     for (original_qubit, compiled_qubit) in qubit_dict
#         original_qubit_num = parse(Int, original_qubit)
#         compiled_qubit_num = n_qubits + parse(Int, compiled_qubit[5:end])
#         # +1 here because julia vectors are indexed from 1
#         data_qubits_map[original_qubit_num + 1] = compiled_qubit_num
#     end

#     return compiled_circuit, data_qubits_map
# end
