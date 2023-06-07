const ICMGate = Tuple{String,Vector{String}}


"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004
"""
function compile(circuit::Vector{ICMGate},
                 n_qubits::Int,
                 gates_to_decompose::Vector{String},
                 with_measurements::Bool=false)
    qubit_dict = Dict()  # mapping from qubit to it's compiled version
    compiled_circuit::Vector{ICMGate} = []
    ancilla_num = 0
    for gate in circuit
        compiled_qubits = [get(qubit_dict, qubit, qubit) for qubit in gate[2]]

        if gate[1] in gates_to_decompose
            for (original_qubit, compiled_qubit) in zip(gate[2], compiled_qubits)
                new_qubit_name = "anc_$(ancilla_num)"
                ancilla_num += 1

                qubit_dict[original_qubit] = new_qubit_name
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit_name]))
                if with_measurements
                    push!(compiled_circuit,
                          ("$(gate[1])_measurement", [compiled_qubit]))
                    push!(compiled_circuit,
                          ("Gate_Conditioned_on_$(compiled_qubit)_Measurement",
                           [new_qubit_name]))
                end
            end
        else
            push!(compiled_circuit, (gate[1], compiled_qubits))
        end
    end

    # map qubits from the original circuit to the compiled one
    data_qubits_map = [i for i in 0:n_qubits-1]
    for (original_qubit, compiled_qubit) in qubit_dict
        original_qubit_num = parse(Int, original_qubit)
        compiled_qubit_num = n_qubits + parse(Int, compiled_qubit[5:end])
        # +1 here because julia vectors are indexed from 1
        data_qubits_map[original_qubit_num + 1] = compiled_qubit_num
    end

    return compiled_circuit, data_qubits_map
end
