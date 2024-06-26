const ICMGate = Tuple{String,Vector{Int}}
export icmcompile

# Assume registers(qc) is of the form collect(1:n) for some n
function icmcompile(qc::QuantumCircuit; universal, ptracking, teleport=["T", "T_Dagger", "RZ"], debug=false)
    # Register layout: [input, universal, teleport, state]
    # We do not write part of the circuit involving state
    input = copy(registers(qc)) # teleport state into these nodes
    allqubit = copy(registers(qc))
    state = zeros(Int, length(input)) # register storing input state
    mapping = Dict(zip(input, allqubit))
    debug && @info mapping
    circuit = Gate[]
    measure = Gate[]
    if ptracking
        # Pauli correction in this widget
        frames = Frames(length(input))
        debug && @info frames.into_py_dict_recursive()
        frame_flags = Int[]
    end
    if universal
        debug && @info "Universal compilation..."
        allqubit, mapping = extend!!(allqubit, mapping, registers(qc)) # append universal register
        debug && @info mapping
        append!(circuit, Gate("H", nothing, [i]) for i in allqubit)
        append!(circuit, Gate("CZ", nothing, [i, mapping[i]]) for i in input)
        # Not written: immediately before X measurement, needs CZ current state and input
        
        # Add state and input measurements
        for i in input
            push!(measure, Gate("X", nothing, [-1])) # outcome s
            push!(measure, Gate("X", nothing, [i])) # outcome t
        end

        # append!(measure, Gate("X", nothing, [i]) for i in input) # outcome t
        # Not written: X measurement on state register
        # push!(measure, Gate("X", nothing, [i]) for i in state) # outcome s
        if ptracking # to zero indexing
            # buffer frames are used to modify current frames, dont need buffer_flags
            buffer = Frames() # Pauli correction from previous widget
            buffer_flags = state # adjust zero indexing later # qubits of the PREVIOUS widget?
            for i in input
                frames.new_qubit(mapping[i]-1)

                # Zˢ correction on system mapping[i] from outcome s
                frames.track_z(mapping[i]-1)
                push!(frame_flags, -1) # placeholder
                # push!(frame_flags, state[i]) # adjust zero indexing later MUTABLE...
                
                # Xᵗ correction on system mapping[i] from outcome t
                frames.track_x(mapping[i]-1)
                push!(frame_flags, i-1)
    
                
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
        # @info "Current gate: $currentgate"
        # previousmapping = copy(mapping) # would remove additional keys to mapping, modify extend!!
        if name(gate) in teleport
            # specific individual gate
            allqubit, mapping = extend!!(allqubit, mapping, actingon) # append teleport register
            debug && @info mapping
            append!(circuit, Gate("CNOT", nothing, [q, mapping[q]]) for q in actingon)
            # append!(circuit, Gate("CNOT", nothing, [previousmapping[q], mapping[q]]) for q in qargs(gate))
            push!(measure, Gate(name(gate), cargs(gate), actingon))
            if ptracking # to zero indexing
                # frames.new_qubit(first(actingon)-1)
                frames.new_qubit(mapping[first(actingon)]-1)
                
                frames.cx(first(actingon)-1, mapping[first(actingon)]-1) # could just call ptracking_apply_gate
                push!(frame_flags, first(actingon)-1)
                frames.track_z(mapping[first(actingon)]-1) # e.g. for exp(iαZ) gates 
            end
        else
            push!(circuit, currentgate)
            # apply Clifford gates to the pauli tracker
            ptracking && ptracking_apply_gate(frames, currentgate)
        end
    end
    debug && @info mapping
    output = [mapping[q] for q in input] # store output state
    # Calculate the state register and write to frame_flags
    state .= collect(length(allqubit)+1:length(allqubit)+length(state))
    # Initialise frames for state indices
    
    for i in state
        frames.new_qubit(i-1)
    end

    # add state qubit indices to measure
    # @info measure
    counter = 0
    for m in measure
        if qargs(m)[1] == -1
            counter += 1
            qargs(m)[1] = state[counter]
        end
    end
    # @info measure
    if universal && ptracking
        counter = 0
        for (idx, val) in enumerate(frame_flags)
            if val == -1
                counter += 1
                frame_flags[idx] = state[counter] - 1 # to zero indexing

            end
        end
        @assert counter == length(state)
    end

    # Check sizes
    if ptracking
        universal && @assert length(frame_flags) == length(allqubit)
        universal || @assert length(frame_flags) == length(allqubit) - length(input)
    end

    # Preparing return data
    circuit = QuantumCircuit(allqubit, circuit)
    # labels = (input = input, output = output, state = state)
    labels = Dict(:input => input, :output => output, :state => state)
    ptracker = (frames      = ptracking ? frames : nothing,
                frameflags  = ptracking ? frame_flags : nothing,
                buffer      = universal ? buffer : nothing,
                bufferflags = universal ? buffer_flags : nothing,
    )

    return (circuit, measure, labels, ptracker)
end

# Never call with registers = allqubits: infinite loop extension
# Assume allqubits is of the form collect(1:n) for some n
function extend!!(
    allqubits::Vector{<:Integer},
    mapping::Dict{<:Integer, <:Integer},
    registers::Vector{<:Integer}
)
    @assert registers ⊆ allqubits
    # nextinteger(v, i=1) = i ∈ v ? nextinteger(v, i+1) : i
    nextinteger(v) = length(v) + 1
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
    bits = qargs(gate) .-1 # Vector{UInt} # to zero indexing
    if name(gate) == "H"
        frames.h(bits[1])
    elseif name(gate) == "S"
        frames.s(bits[1])
    elseif name(gate) == "CZ"
        frames.cz(bits[1], bits[2])
    elseif name(gate) == "X" || name(gate) == "Y" || name(gate) == "Z"
        # commute or anticommute
    elseif name(gate) == "S_DAG"
        frames.sdg(bits[1])
    elseif name(gate) == "SQRT_X"
        frames.sx(bits[1])
    elseif name(gate) == "SQRT_X_DAG"
        frames.sxdg(bits[1])
    elseif name(gate) == "SQRT_Y"
        frames.sy(bits[1])
    elseif name(gate) == "SQRT_Y_DAG"
        frames.sydg(bits[1])
    elseif name(gate) == "SQRT_Z"
        frames.sz(bits[1])
    elseif name(gate) == "SQRT_Z_DAG"
        frames.szdg(bits[1])
    elseif name(gate) == "CNOT"
        frames.cx(bits[1], bits[2])
    elseif name(gate) == "SWAP"
        frames.swap(bits[1], bits[2])
    else
        error("Unknown gate: $(name(gate))")
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

