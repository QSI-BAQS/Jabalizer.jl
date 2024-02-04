const ICMGate = Tuple{String,Vector{String}}


"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004
"""
function compile(circuit::Vector{ICMGate},
                 n_qubits::Int,
                 gates_to_decompose::Vector{String};
                 with_measurements::Bool=false,
                 universal::Bool=false,
                 ptrack=false,
                 generate_qmap=false
                 )

    qubit_dict = Dict()  # mapping from qubit to it's compiled version
    
    # Initialise measurement sequence
    if with_measurements
        mseq::Vector{ICMGate} = []
    end
    
    # Generate a dictionary mapping qubit names to integers
    if generate_qmap
        qmap = Dict()
    end


    if universal
        # Add input nodes
        initialize::Vector{ICMGate} = []
        
        # Populate qdict and add it's mapping to integers in qmap
        for gate in circuit
            for q in gate[2]
                if haskey(qubit_dict, q)
                    continue
                end
                qubit_dict[q] = q
                if generate_qmap
                    qint  = parse(Int, q)
                    qmap[q] = qint + 1
                    qmap["i_"*q] = n_qubits + qint + 1
                end

                # Initialise (graph) Bell states in registers "input_q" and "q"
                push!(initialize, ("H", ["i_"*q]) )
                push!(initialize, ("H", [q]) )
                push!(initialize, ("CZ", [ q, "i_"*q]) )

                # Add input measurements to mseq
                # This does not include the measurement on the incoming qubit!
                push!(mseq, ("X", ["i_"*q]))

            end

            
        end
        # Prepend input initialisation to circuit
        circuit = [initialize; circuit]
    end

    
    
    compiled_circuit::Vector{ICMGate} = []
    ancilla_num = 0

    for gate in circuit
        compiled_qubits = [get(qubit_dict, qubit, qubit) for qubit in gate[2]]

        if gate[1] in gates_to_decompose
            for (original_qubit, compiled_qubit) in zip(gate[2], compiled_qubits)
                new_qubit_name = "anc_$(ancilla_num)"
                ancilla_num += 1

                if generate_qmap
                    qmap[new_qubit_name] = 2 * n_qubits + ancilla_num
                end
               

                qubit_dict[original_qubit] = new_qubit_name
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit_name]))
                if with_measurements
                    push!(mseq,
                          (gate[1], [compiled_qubit]))
                    # push!(compiled_circuit,
                    #       ("Gate_Conditioned_on_$(compiled_qubit)_Measurement",
                    #        [new_qubit_name]))
                end
            end
        else
            push!(compiled_circuit, (gate[1], compiled_qubits))
        end
    end

    if universal
        data_qubits_map = qubit_dict
    else

        # map qubits from the original circuit to the compiled one
        data_qubits_map = [i for i in 0:n_qubits-1]
        for (original_qubit, compiled_qubit) in qubit_dict
            original_qubit_num = parse(Int, original_qubit)
            compiled_qubit_num = n_qubits + parse(Int, compiled_qubit[5:end])
            # +1 here because julia vectors are indexed from 1
            data_qubits_map[original_qubit_num + 1] = compiled_qubit_num
        end
    end

    rt = [compiled_circuit, data_qubits_map]
    if with_measurements
        push!(rt, mseq)
    end

    if generate_qmap
        push!(rt, qmap)
    end

    return Tuple(rt)
end
