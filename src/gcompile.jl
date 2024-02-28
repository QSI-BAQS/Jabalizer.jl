using Graphs
export gcompile

"""
Run a full graph compilation on an input circuit. 
"""
function gcompile(
    circuit::Vector{ICMGate},
    args...;
    kwargs...)

    icm_circuit, data_qubits, mseq = compile(
                                            circuit,
                                            args...;
                                            kwargs...
                                            )

    icm_qubits = Jabalizer.count_qubits(icm_circuit)

    state = zero_state(icm_qubits)
    Jabalizer.execute_circuit(state, icm_circuit)

    adj, op_seq = to_graph(state)[2:3]

    g = Graphs.SimpleGraph(adj)
    input_nodes = Dict{Int, Int}()

    logical_qubits = args[1]
    for i in 1:logical_qubits
        input_nodes[i] = i + logical_qubits
    end

    output_nodes = data_qubits
   
    # Add Hadamard corrections to boundry nodes.
    del=[]
    for (idx, corr) in enumerate(op_seq)
        # add H corrections to input nodes
        if (corr[1] == "H") && corr[2] in values(input_nodes)
            # add new node to graph
            add_vertex!(g)
            new_node = nv(g)
            add_edge!(g, corr[2], new_node)

            # add index for deletion
            push!(del, idx)

            # find the input label for the node
            for (k,v) in input_nodes
                if v == corr[2]
                    input_nodes[k] = new_node 
                    break
                end
            end

            # Add measurement to mseq to implement the Hadamard
            pushfirst!(mseq, ("X", [new_node] ))
            # qubit_map[string(new_node)] = new_node
            
        end

        # add H corrections to output nodes
        if (corr[1] == "H") && corr[2] in values(output_nodes)
            # add new node to graph
            add_vertex!(g)
            new_node = nv(g)
            add_edge!(g, corr[2], new_node)

            # add index for deletion from mseq
            push!(del, idx)
                    
            # find the output label for the node
            for (k,v) in output_nodes
                if v == corr[2]
                    push!(mseq, ("X", [corr[2]] ))
                    output_nodes[k] = new_node
                    break
                end
            end           
        end        
    end

    deleteat!(op_seq, del)

    # Measurement sequence
    meas_order = []
    meas_basis = []
    for (gate, qubit) in mseq
        push!(meas_order, qubit[1])
        push!(meas_basis, gate )
    end

    mseq = [meas_order, meas_basis]

    return g, op_seq, mseq, input_nodes, output_nodes    
end


"""
gcompile for QuantumCircuit
"""
function gcompile(
    circuit::QuantumCircuit;
    universal::Bool,
    ptracking::Bool,
    teleport=["T", "T_Dagger", "RZ"]
    )
    
    icm_circuit, mseq, data_qubits, frames_array = icmcompile(circuit; 
                                                            universal=universal,
                                                            ptracking = ptracking,
                                                            teleport = teleport
                                                            ) 

    icm_qubits = icm_circuit.registers |> length
    state = zero_state(icm_qubits)
    Jabalizer.execute_circuit(state, icm_circuit)

    adj, loc_corr = to_graph(state)[2:3]

    g = Graphs.SimpleGraph(adj)

    return g, loc_corr, mseq, data_qubits, frames_array 
end



"""
run gcompile on an input file
"""
function gcompile(
    filename::String;
    kwargs...
    )
 
    qc = parse_file(filename)
    # qubits, inp_circ = load_icm_circuit_from_qasm(filename)

    return gcompile(
        qc;
        kwargs...
        )

end