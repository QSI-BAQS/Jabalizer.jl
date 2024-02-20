const ICMGate = Tuple{String,Vector{Int}}

import .pauli_tracking

export compile
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
                 universal::Bool=true,
                 ptrack=true
                 )
    
    # Initialize dictionary to track teleported qubits
    qubit_dict = Dict{Int, Int}()  
    
    # Initialise measurement sequence
    mseq::Vector{ICMGate} = []

    # Initialise pauli tracker frames to track internal qubits
    frames = ptrack ? Frames() : nothing
    frame_flags = ptrack ? [] : nothing
    

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
            
            # track Z correction from measuring input nodes n+1:2n
            # adjust for 0 indexing in tracker
            frames.track_z(i-1)
            push!(frame_flags, n_qubits + i - 1)

            # Add input measurements to mseq
            # This does not include the measurement on the incoming qubit!
            push!(mseq, ("X", [i + n_qubits]))

            # add all qubit to the tracker excluding inputs
            if ptrack
                frames.new_qubit(n_qubits + i - 1)
                frames.new_qubit(i-1)
            end
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

                if ptrack
                    # add a new qubit to the pauli tracker.
                    # adjust for 0 indexing in tracker
                    frames.new_qubit(new_qubit-1)
                end
                
                # Update data qubit map
                qubit_dict[original_qubit] = new_qubit

                # add teleportation CNOT
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit]))
                
                # apply the teleportation cnot to the tracker
                # adjusting for 0 indexing
                if ptrack
                    frames.cx(compiled_qubit-1, new_qubit-1)
                    push!(frame_flags, compiled_qubit-1)
                    # This assumes the teleportation induces a z corrections
                    # which holds for Rz teleporations.
                    frames.track_z(new_qubit-1)
                end
                
                # Update measurement sequence
                push!(mseq, (gate, [compiled_qubit]))
                
            end
        else
            push!(compiled_circuit, (gate, compiled_qubits))
            if ptrack
                # apply Clifford gates to the pauli tracker
                # adjust for 1 indexing in tracker
                pauli_tracking.apply_gate(
                    frames, 
                    (gate, [UInt(q-1) for q in compiled_qubits]))
            end
        end
    end

    return compiled_circuit, qubit_dict, mseq, frames, frame_flags
end
