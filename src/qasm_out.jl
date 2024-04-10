# write graph compilation to qasm file

using Graphs
using JSON


const qasm_inversemap = Dict(map(reverse,collect(qasm_map)))
qasm_inversemap["RZ"] = "rz"

export qasm_instruction

function correction_controls(frame_bitvector, frame_flags)
    corr = []    
    if sum(frame_bitvector) != 0
            for idx in reverse(findall(frame_bitvector .== 1))
                push!(corr, frame_flags[idx])
            end
        end
        return corr
end

"""
    frame_bitvector(frame_vec, frames_length)

Return a bitvector of Pauli corrections given a vector of python integers

It is assumed that each integer in `frames_vec` represents a 64 bit chunk of the
full bitvector. 
"""
function frame_bitvector(frame_vec, frames_length)
    intvec = [pyconvert(UInt, pint) for pint in frame_vec]
    bitvec = [digits(jint, base=2, pad=64) for jint in intvec]
    
    # concatenate all bitvector chunks and return frame_length bits
    return vcat(bitvec...)[1:frames_length]
end

"""
    pauli_corrections(frames, frame_flags, qubits)

Returns a dictionary of Pauli correction for every qubit in the vector `qubits`.

`frames` are expected to be `pauli_tracker.frames.map.Frames` class.

"""
function pauli_corrections(frames, frame_flags, qubits)
    corr = Dict()

    frame_dict = frames.into_py_dict_recursive()
    flen = frame_flags |> length
    for q in qubits
        qcorr = []
        z_bitvector = frame_bitvector(frame_dict[q][0], flen)
        x_bitvector = frame_bitvector(frame_dict[q][1], flen)
        
        zcontrol = correction_controls(z_bitvector, frame_flags)
        xcontrol = correction_controls(x_bitvector, frame_flags)

        for mq in reverse(frame_flags)
            for z in zcontrol
                if z == mq
                    push!(qcorr, ["z", z])
                end
            end
            for x in xcontrol
                if x == mq
                    push!(qcorr, ["x", x])
                end
            end
            
        end
        
        if ! isempty(qcorr)
            corr[q] = qcorr
        end
        
    end

    return corr 

end


"""
export qasm file given a graph compilation
"""
function qasm_instruction(outfile, 
                          graph::SimpleGraph{Int},
                          loc_corr,
                          mseq,
                          data_qubits,
                          frames_array)
    
    # open output file
    file = open(outfile, "w")
    # unpack frames
    frames, frame_flags = frames_array
    # initialise qasm file
    println(file, "OPENQASM 2.0;\ninclude \"qelib1.inc\";" )
    # qasm_str = "OPENQASM 2.0;\ninclude qelib1.inc;\n"

    # # initialise qregs and cregs
    qregs = nv(graph)
    qregs_total = qregs + length(data_qubits[:state])
    println(file, "\nqreg q[$qregs_total];")

    for i in 0:qregs_total-1
        println(file, "creg c$(i)[1];")
    end

    # Graph state generation
    println(file, "\n// Graph state generation")
    for i in 0:qregs-1
        println(file, "h q[$i];")
    end

    for e in edges(graph)
        s = src(e) - 1
        d = dst(e) - 1
        println(file, "cz q[$s], q[$d];")
    end

    println(file)
    # state input edges
    println(file, "// state input edges")
    for (s,i) in zip(data_qubits[:state], data_qubits[:input])
        println(file, "cz q[$(s-1)], q[$(i-1)];")
    end

    # local correction
    println(file, "\n// Local Clifford correction")
    for gate in loc_corr
        if gate[1] == "H"
            println(file, "h q[$(gate[2]-1)];")
        end

        if gate[1] == "Z"
            println(file, "z q[$(gate[2]-1)];")
        end

        # inverting local clifford corrections applies the inverse gate
        if gate[1] == "Pdag"
            println(file, "s q[$(gate[2]-1)];")
        end
    end

    println(file)
    println(file, "// Measurement sequence")
    
    # Generate Pauli Corrections 
    outqubits =  data_qubits[:output] .- 1
    qubits = [q for q in frame_flags]
    append!(qubits, outqubits)
    pc = pauli_corrections(frames, frame_flags, qubits)
    for m in mseq
        gate = qasm_inversemap[m.name]
        qargs = m.qargs .- 1 
        
        # Add pauli correction
        if haskey(pc, qargs[1])
            pcorr = pc[qargs[1]]
            for p in pcorr
                println(file, "if(c$(p[2]) == 1) $(p[1]) q$qargs;")
            end
        end

        if gate == "x"
            println(file, "h q$(qargs);")
            println(file, "measure q$(qargs) -> c$(qargs[1])[0];")
        elseif gate in ["t", "tdg"]
            println(file, "$gate q$(qargs);" )
            println(file, "h q$(qargs);")
            println(file, "measure q$(qargs) -> c$(qargs[1])[0];")
        elseif gate == "rz"
            println(file, "$(gate)($(m.cargs[1])) q$(qargs);" )
            println(file, "h q$qargs;")
            println(file, "measure q$(qargs) -> c$(qargs[1])[0];")
        end
        println(file)
    end

    # Add pauli corrections to output qubits
    println(file, "// Pauli correct output qubits")
    for q in outqubits
        if haskey(pc, q)
            pcorr = pc[q]
            for p in pcorr
                println(file, "if(c$(p[2]) == 1) $(p[1]) q[$q];")
            end
        end
    end
    close(file)

    
    # convert data_qubits to 0 index
    d = Dict()
    for k in keys(data_qubits)
        d[k] = data_qubits[k] .-1
    end
    data_file = splitext(outfile)[1]*"_dqubits.json"
    
    open(data_file,"w") do f
        JSON.print(f, d)
    end

    return nothing
end

"""
memory allocation helper function
"""
function alloc(logicalq, physicalmap, ram)
    if !(logicalq in keys(physicalmap))
        physicalmap[logicalq] = pop!(ram)
    end
end

"""
memory deallocation helper function
"""
function dealloc(logicalq, physicalmap, ram)
    if (logicalq in keys(physicalmap))
       freeq = pop!(physicalmap, logicalq)
       push!(ram, freeq)
    end
end



"""
Generates a qasm file implementing the mbqc instruction
"""
function qasm_instruction(outfile,
                          mbqc_inst::Dict)

    # open output file
    file = open(outfile, "w")
    
    # unpack data dictionary
    qphysical = mbqc_inst["space"]
    mlayers = mbqc_inst["steps"]
    pc = mbqc_inst["pcorrs"]
    outqubits = mbqc_inst["outputnodes"]
    statequbits = mbqc_inst["statenodes"]
    # @info statequbits
    loc_corr = mbqc_inst["correction"]
    measurements = mbqc_inst["measurements"]
    graph = mbqc_inst["spatialgraph"]

    # initialise map to phyiscal qubits for memory management
    mq = Dict{Int, Int}()
    # Convert measurement sequence to a dictionary. 
    # the sequence is now decided by layers
    mdict = Dict()
    for m in measurements
      mdict[m[2]] = (m[1], m[3]) 
    end

    # initialise qasm file
    println(file, "OPENQASM 2.0;\ninclude \"qelib1.inc\";" )
   
    # # initialise qregs and cregs
    # qregs = nv(graph)
    # qregs_total = qregs + length(data_qubits[:state])
    qlogical = length(measurements) + length(outqubits)
    
    # println(file, "\nqreg q[$qlogical];")
    println(file, "\nqreg q[$qphysical];")

    # defining a classical register for every logical qubit 
    for i in 0:qlogical-1
        println(file, "creg c$(i)[1];")
    end

    
    # keep track of initialised qubits
    # init = copy(statequbits)
    init = []
    # keep track of qubit connections
    connection_graph = SimpleGraph(qlogical)
    # initialise available physical qubits
    ram = collect(qphysical-1:-1:0)
    # tracker for state qubit assignment
    state_physical = Dict()
    state_layer = Dict()
    # Generate and measure layers
    for (idx,lr) in enumerate(mlayers)
        # initialise qubits and neighbors if not initialised
        for q in lr
            if !(q in init)
                # allocate qubit in memory if unallocated
                alloc(q, mq, ram)
                # skip hadamard for incoming state qubits
                if !(q in statequbits)
                    println(file, "h q[$(mq[q])];")
                else
                    # store state input physical qubit and layer
                    state_physical[q] = mq[q]
                    state_layer[q] = idx-1
                    # @info state_physical
                end
                push!(init, q)
            end
            for n in graph[q+1]
                if !(n in init)
                    alloc(n, mq, ram)
                    # skip hadamard for incoming state qubits
                    if !(n in statequbits)
                        println(file, "h q[$(mq[n])];")
                    else
                        # store state input physical qubit and layer
                        state_physical[n] = mq[n]
                        state_layer[n] = idx-1
                    end
                    push!(init, n)
                end
            end

        end
        # conect all neighbors of qubits in measurement layer
        for q in lr
            for n in graph[q+1]
                # check if already connected
                if !(n+1 in neighbors(connection_graph, q+1))
                    println(file, "cz q[$(mq[q])], q[$(mq[n])];")
                    add_edge!(connection_graph, q+1, n+1) 
                end
            end
        end

        # apply local corrections
        for gate in loc_corr
            if gate[2] in lr
                if gate[1] == "H"
                    println(file, "h q[$(mq[gate[2]])];")
                end
        
                if gate[1] == "Z"
                    println(file, "z q[$(mq[gate[2]])];")
                end
        
                # inverting local clifford corrections applies the inverse gate
                if gate[1] == "Pdag"
                    println(file, "s q[$(mq[gate[2]])];")
                end
            end
        end

        # measurement
        for q in lr
            # apply Pauli corrections.
            if haskey(pc, q)
                for p in pc[q]
                    println(file, "if(c$(p[2]) == 1) $(p[1]) q[$(mq[q])];")
                end
            end

            # skip measurement for output qubits
            (q in outqubits) && continue
            # perform measurements
            gate = qasm_inversemap[mdict[q][1]]

            if gate == "x"
                println(file, "h q[$(mq[q])];")
                println(file, "measure q[$(mq[q])] -> c$q[0];")
            elseif gate in ["t", "tdg"]
                println(file, "$gate q[$(mq[q])];" )
                println(file, "h q[$(mq[q])];")
                println(file, "measure q[$(mq[q])] -> c$q[0];")
            elseif gate == "rz"
                # @info mdict[q]
                println(file, "$gate($(mdict[q][2])) q[$(mq[q])];" )
                println(file, "h q[$(mq[q])];")
                println(file, "measure q[$(mq[q])] -> c$q[0];")
            else
                error("unsupported gate teleportation: ", gate)
            end

            # reset qubit
            println(file, "reset q[$(mq[q])];")
            # release measured physical qubit back to ram
            dealloc(q, mq, ram)

        end




    end 

    close(file)
    data_qubits = Dict()
    data_qubits[:state] = [state_physical[s] for s in statequbits]
    data_qubits[:output] = [mq[o] for o in outqubits]
    data_qubits[:state_layer] = [state_layer[s] for s in statequbits]

    data_file = splitext(outfile)[1]*"_dqubits.json"
    open(data_file,"w") do f
        JSON.print(f, data_qubits)
    end

    return nothing    
end
