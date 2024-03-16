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


function pauli_corrections(frames, frame_flags, qubits)
    corr = Dict()

    frame_dict = frames.into_py_dict_recursive()
    flen = frame_flags |> length
    for q in qubits
        qcorr = []
        z_int = pyconvert(Int, frame_dict[q][0][0])
        x_int = pyconvert(Int, frame_dict[q][1][0])
        z_bitvector = digits(z_int, base=2, pad=flen)
        x_bitvector = digits(x_int, base=2, pad=flen)

        zcontrol = correction_controls(z_bitvector, frame_flags)
        xcontrol = correction_controls(x_bitvector, frame_flags)

        for mq in reverse(frame_flags)
            for z in zcontrol
                if z == mq
                    push!(qcorr, ("z", z))
                end
            end
            for x in xcontrol
                if x == mq
                    push!(qcorr, ("x", x))
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
function qasm_instruction(outfile, graph, loc_corr, mseq, data_qubits, frames_array)
    
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