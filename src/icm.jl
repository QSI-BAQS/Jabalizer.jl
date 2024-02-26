const ICMGate = Tuple{String,Vector{Int}}
export icmcompile

function icmcompile(qc::QuantumCircuit; universal, ptracking, teleport=["T", "T_Dagger", "RZ"], debug=false)
    # Register layout: [input, universal, teleport, state]
    input = copy(registers(qc)) # teleport state into these nodes
    allqubit = copy(registers(qc))
    state = zeros(Int, length(input)) # register storing input state
    mapping = Dict(zip(input, allqubit))
    debug && @info mapping
    circuit = Gate[]
    measure = Gate[]
    if ptracking
        # Pauli correction in this widget
        frames = Frames()
        frame_flags = Int[]
    end
    if universal
        debug && @info "Universal compilation..."
        allqubit, mapping = extend!!(allqubit, mapping, registers(qc)) # append universal register
        debug && @info mapping
        append!(circuit, Gate("H", nothing, [i]) for i in allqubit)
        append!(circuit, Gate("CZ", nothing, [i, mapping[i]]) for i in input)
        # Immediately before X measurement, needs CZ current state and input
        append!(measure, Gate("X", nothing, [i]) for i in input) # outcome t
        # The following has to be done but we dont write it in the circuit
        # push!(measure, Gate("X", nothing, [i]) for i in state) # outcome s
        if ptracking # to zero indexing
            # buffer frames are used to modify current frames, dont need buffer_flags
            buffer = Frames() # Pauli correction from previous widget
            buffer_flags = state # adjust zero indexing later # qubits of the PREVIOUS widget
            for i in input
                frames.new_qubit(mapping[i]-1)
                # Xᵗ correction on system mapping[i] from outcome t
                frames.track_x(mapping[i]-1)
                push!(frame_flags, i-1)
                # Zˢ correction on system mapping[i] from outcome s
                frames.track_z(mapping[i]-1)
                push!(frame_flags, state[i]) # adjust zero indexing later MUTABLE...
                # Potential correction on system mapping[i] from previous widget
                buffer.new_qubit(mapping[i]-1)
                buffer.track_z(mapping[i]-1)
                buffer.track_x(mapping[i]-1) # Q: use buffer to modify frame and pauli track?
            end
        end
    end
    debug && @info "Teleporting all non-Clifford gates..."
    for gate in gates(qc) # gate in the original circuit
        actingon = [mapping[q] for q in qargs(gate)]
        # with teleportation so far, the gate becomes
        currentgate = Gate(name(gate), cargs(gate), actingon)
        # previousmapping = copy(mapping) # would remove additional keys to mapping, modify extend!!
        if name(gate) in teleport
            # specific individual gate
            allqubit, mapping = extend!!(allqubit, mapping, actingon) # append teleport register
            debug && @info mapping
            append!(circuit, Gate("CNOT", nothing, [q, mapping[q]]) for q in actingon)
            # append!(circuit, Gate("CNOT", nothing, [previousmapping[q], mapping[q]]) for q in qargs(gate))
            push!(measure, Gate(name(gate), cargs(gate), actingon))
            if ptracking # to zero indexing
                frames.new_qubit(first(actingon)-1)
                frames.new_qubit(mapping[first(actingon)]-1)
                # could just call ptracking_apply_gate
                frames.cx(first(actingon)-1, mapping[first(actingon)]-1)
                push!(frame_flags, first(actingon)-1)
                frames.track_z(mapping[first(actingon)]-1) # e.g. for exp(iαZ) gates 
            end
        else
            push!(circuit, currentgate)
            # apply Clifford gates to the pauli tracker
            ptracking && pauli_tracking.apply_gate(frames, currentgate)
        end
    end
    debug && @info mapping
    output = [mapping[q] for q in input] # store output state
    state .= collect(length(allqubit)+1:length(allqubit)+length(state)) .- 1 # to zero indexing
    if ptracking
        universal && @assert length(frame_flags) == length(allqubits) - 2*length(input)
        universal || @assert length(frame_flags) == length(allqubits) - length(input)
    end
    if ptracking
        universal && return circuit, measure, Dict(zip(input, output)), frames, frame_flags, buffer, buffer_flags
        universal || return circuit, measure, Dict(zip(input, output)), frames, frame_flags
    end
    return circuit, measure, Dict(zip(input, output))
end

# Never call with registers = allqubits: infinite loop extension
function extend!!(
    allqubits::Vector{<:Integer},
    mapping::Dict{<:Integer, <:Integer},
    registers::Vector{<:Integer}
)
    @assert registers ⊆ allqubits
    nextinteger(v, i=1) = i ∈ v ? nextinteger(v, i+1) : i
    for reg in registers
        newqubit = nextinteger(allqubits)
        push!(allqubits, newqubit)
        # mapping[reg] = newqubit
        for key in keys(mapping)
            if mapping[key] == reg
                mapping[key] = newqubit
            end
        end
        mapping[reg] = newqubit
    end
    return allqubits, mapping
end

function ptracking_apply_gate(frames, gate::Gate)
    name = name(gate)
    bits = qargs(gate) # Vector{UInt}
    # name = gate[1]
    # bits = gate[2]
    if name == "H"
        frames.h(bits[1])
    elseif name == "S"
        frames.s(bits[1])
    elseif name == "CZ"
        frames.cz(bits[1], bits[2])
    elseif name == "X" || name == "Y" || name == "Z"
    elseif name == "S_DAG"
        frames.sdg(bits[1])
    elseif name == "SQRT_X"
        frames.sx(bits[1])
    elseif name == "SQRT_X_DAG"
        frames.sxdg(bits[1])
    elseif name == "SQRT_Y"
        frames.sy(bits[1])
    elseif name == "SQRT_Y_DAG"
        frames.sydg(bits[1])
    elseif name == "SQRT_Z"
        frames.sz(bits[1])
    elseif name == "SQRT_Z_DAG"
        frames.szdg(bits[1])
    elseif name == "CNOT"
        frames.cx(bits[1], bits[2])
    elseif name == "SWAP"
        frames.swap(bits[1], bits[2])
    else
        error("Unknown gate: $name")
    end
end


# BELOW WILL BE DELETED




"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004


compile expects qubits to be indexed as integers from 1:n_qubits. If the 
universal flag is set, input nodes are added which are indexed n+1:2n. 
Ancillas introduced for teleportation are indexed starting from 2n+1 onwards.

universal flag = false is not supported yet.

gates_to_decompose are expected to by RZ gates. Rx, Ry and single qubit unitary
support will be added soon. 
"""
function compile(circuit::Vector{ICMGate},
                 n_qubits::Int,
                 gates_to_decompose::Vector{String};
                 universal::Bool=true
                 )
    
    # Initialize dictionary to track teleported qubits
    qubit_dict = Dict{Int, Int}()  
    
    # Initialise measurement sequence
    mseq::Vector{ICMGate} = []

    if universal
        """
        Generate pairs of Bell states for every logical qubit. Gates on logical
        qubits will act on one qubit of the bell pair for that logical qubit. This
        allows for injecting arbitrary input states through teleportation using the
        other qubit of the Bell pair.
        """
        initialize::Vector{ICMGate} = []

        for i in 1:n_qubits
            # Initialise (graph) Bell states for every logical qubit"
            push!(initialize, ("H", [i]))
            push!(initialize, ("H", [i + n_qubits]))
            push!(initialize, ("CZ",[i, i + n_qubits]))

            # Add input measurements to mseq
            # This does not include the measurement on the incoming qubit!
            push!(mseq, ("X", [i + n_qubits]))
        end

        # Prepend input initialisation to circuit
        circuit = [initialize; circuit]
    end
        
   
    # Initalizse the compiled circuit
    compiled_circuit::Vector{ICMGate} = []
    ancilla_num = 1

    for (gate, qubits) in circuit
    
        # Get the teleported qubit index if qubit has been teleported.
        compiled_qubits = [get(qubit_dict, q, q) for q in qubits]

        if gate in gates_to_decompose
            for (original_qubit, compiled_qubit) in zip(qubits, compiled_qubits)
                
                # Generate index for new ancilla to telport to.
                new_qubit = 2 * n_qubits + ancilla_num
                # update ancilla count
                ancilla_num += 1
                
                # Update data qubit map
                qubit_dict[original_qubit] = new_qubit
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit]))
                
                # Update measuremnet sequence
                push!(mseq, (gate, [compiled_qubit]))
            end
        else
            push!(compiled_circuit, (gate, compiled_qubits))
        end
    end

    return compiled_circuit, qubit_dict, mseq
end

