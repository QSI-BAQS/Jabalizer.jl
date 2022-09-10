const ICMGate = Tuple{String,Vector{String}}


"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004
"""
function compile(circuit::Vector{ICMGate}, gates_to_decompose::Vector{String}, with_measurements::Bool=false)
    qubit_dict = Dict()  # mapping from qubit to it's compiled version
    compiled_circuit::Vector{ICMGate} = []
    ancilla_num = 0
    for gate in circuit
        compiled_qubits = [get(qubit_dict, qubit, qubit) for qubit in gate[2]]

        if gate[1] in gates_to_decompose
            for qubit in compiled_qubits
                new_qubit_name = "anc_$(ancilla_num)"
                ancilla_num += 1

                qubit_dict[qubit] = new_qubit_name
                push!(compiled_circuit, ("CNOT", [qubit, new_qubit_name]))
                if with_measurements
                    push!(compiled_circuit, ("$(gate[1])_measurement", [qubit]))
                    push!(compiled_circuit, ("Gate_Conditioned_on_$(qubit)_Measurement",
                        [new_qubit_name]))
                end
            end
        else
            push!(compiled_circuit, (gate[1], compiled_qubits))
        end
    end
    return compiled_circuit
end
