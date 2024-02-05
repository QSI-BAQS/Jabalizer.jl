const ICMGate = Tuple{String,Vector{String}}

import .pauli_tracking


"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004
"""
function compile(
    circuit::Vector{ICMGate},
    n_qubits::Int,
    gates_to_decompose::Vector{String};
    universal::Bool=false
)
    qubit_dict = Dict()  # mapping from qubit to it's compiled version

    # Initialise measurement sequence
    mseq::Vector{ICMGate} = []

    # Generate a dictionary mapping qubit names to integers
    qmap = Dict()

    # NOTE: we are assuming here that the input qubits go from 0 to n_qubits-1 

    # the incoming qubit from the previous widget is identified with "ii_"*q

    buffer = Frames()
    for i in range(0, n_qubits - 1)
        idx = i + 1 + 2 * n_qubits
        qmap["ii_$i"] = idx
        buffer.new_qubit(idx)
        buffer.track_z(idx)
        buffer.track_x(idx)
    end

    frames = Frames()
    frame_flags = []

    # BUG: when universal is false, we are not populating qmap, so when doing something
    # like qmap[compiled_qubit] below, it can fail
    # EDIT: the same is now true for the tracker initializations
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
                qint = parse(Int, q)
                qmap[q] = qint + 1
                qmap["i_"*q] = n_qubits + qint + 1

                # Initialise (graph) Bell states in registers "input_q" and "q"
                push!(initialize, ("H", ["i_" * q]))
                buffer.new_qubit(UInt(qmap["i_"*q]))
                frames.new_qubit(UInt(qmap["i_"*q]))
                push!(initialize, ("H", [q]))
                buffer.new_qubit(UInt(qmap[q]))
                frames.new_qubit(UInt(qmap[q]))
                push!(initialize, ("CZ", [q, "i_" * q]))
                # empty on those, so unnecessary
                # buffer.cz(UInt(qmap[q]), UInt(qmap["i_"*q]))
                # frames.cz(UInt(qmap[q]), UInt(qmap["i_"*q]))

                # when stitching, we do cnot("ii_"*q, "i_"*q) and the an X measurement on
                # "ii_"*q; the cnot is the equivalent to all the edges in the graph,
                # especially when measuring "i_"*q, "ii_"*q has to be initialized and the
                # cnot has to be done (and vice versa)
                push!(mseq, ("Z", ["i_" * q]))
                push!(mseq, ("X", ["ii_" * q]))
                push!(frame_flags, UInt(qmap["i_"*q]))
                push!(frame_flags, UInt(qmap["ii_"*q]))
                frames.track_x(UInt(qmap[q]))
                frames.track_z(UInt(qmap[q]))
                buffer.move_x_to_z(UInt(qmap["i_"*q]), UInt(qmap[q]))
                buffer.cx(UInt(qmap["ii_"*q]), UInt(qmap["i_"*q]))
                buffer.move_z_to_x(UInt(qmap["i_"*q]), UInt(qmap[q]))
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

                qmap[new_qubit_name] = 3 * n_qubits + ancilla_num
                frames.new_qubit(UInt(qmap[new_qubit_name]))
                buffer.new_qubit(UInt(qmap[new_qubit_name]))

                # NOTE: Isn't the teleportation with a cnot and an ancilla in |0> specific
                # to z-rotations? If so, then gates_to_decompose should be restricted to
                # those gates
                qubit_dict[original_qubit] = new_qubit_name
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit_name]))
                source = UInt(qmap[compiled_qubit])
                destination = UInt(qmap[new_qubit_name])
                frames.cx(source, destination)
                buffer.cx(source, destination)
                if gate[1] == "T" || gate[1] == "T_Dagger"
                    frames.move_z_to_z(source, destination)
                    buffer.move_z_to_z(source, destination)
                    frames.track_z(destination)
                else
                    # NOTE: cf. note above + the current gate representation (strings) do
                    # not support parameters, so I'm not checking for something like "RZ"
                    # (I'm not going to do the same hack I did before on the track_pauli*
                    # branches, because it is ugly and only works with the according
                    # check.py script there); instead another gate representation would be
                    # needed
                    error("only support T and T_Dagger decomposition")
                end
                push!(mseq,
                    (gate[1], [compiled_qubit]))
                # push!(compiled_circuit,
                #       ("Gate_Conditioned_on_$(compiled_qubit)_Measurement",
                #        [new_qubit_name]))
            end
        else
            push!(compiled_circuit, (gate[1], compiled_qubits))
            pauli_tracking.apply_gate!(
                frames, (gate[1], [UInt(qmap[q]) for q in compiled_qubits])
            )
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
            data_qubits_map[original_qubit_num+1] = compiled_qubit_num
        end
    end


    return compiled_circuit, data_qubits_map, mseq, qmap, frames, buffer, frame_flags
end
