using Graphs
export gcompile


"""
Run a full graph compilation on an input circuit


"""
function gcompile(circuit::Vector{ICMGate}, args...; kwargs...)
    icm_circuit, data_qubits, mseq, qubit_map, frames =
        compile(circuit, args...; kwargs...)

    if mseq === nothing
        mseq = []
    end

    icm_qubits = Jabalizer.count_qubits(icm_circuit)

    state = zero_state(icm_qubits)
    Jabalizer.execute_circuit(state, icm_circuit, qubit_map=qubit_map)

    adj, op_seq = to_graph(state)[2:3]

    g = Graphs.SimpleGraph(adj)
    input_nodes = Dict{String,Int}()

    for i in eachindex(1:args[1])
        input_nodes["$(i-1)"] = qubit_map["i_$(i-1)"]
    end

    output_nodes = Dict{String,Int}()
    for (k, v) in data_qubits
        output_nodes[k] = qubit_map[v]
    end


    # Add Hadamard corrections to boundry nodes.
    del = []
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
            for (k, v) in input_nodes
                if v == corr[2]
                    input_nodes[k] = new_node
                    break
                end
            end

            # Add measurement to mseq to implement the Hadamard
            pushfirst!(mseq, ("X", [string(new_node)]))
            qubit_map[string(new_node)] = new_node
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
            for (k, v) in output_nodes
                if v == corr[2]
                    push!(mseq, ("X", [data_qubits[k]]))
                    output_nodes[k] = new_node
                    break
                end
            end
            # add new node to qubit_map
            qubit_map[string(new_node)] = new_node
        end
    end

    deleteat!(op_seq, del)

    # Measurement sequence
    meas_order = []
    meas_basis = []
    for (gate, qubit) in mseq
        push!(meas_order, qubit_map[qubit[1]])
        push!(meas_basis, gate)
    end


    mseq = [meas_order, meas_basis]

    return g, op_seq, mseq, input_nodes, output_nodes, frames


end

"""
run gcompile on an input file
"""
function gcompile(
    filename::String,
    args...;
    kwargs...
)
    qubits, inp_circ = load_icm_circuit_from_qasm(filename)

    return gcompile(
        inp_circ::Vector{ICMGate},
        qubits,
        args...;
        kwargs...
    )
end
