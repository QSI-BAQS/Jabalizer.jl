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
)
    # NOTE: here, and in gcompile, we're relying on that the qubits are labeled from 0 to
    # n_qubits-1; this should be documented

    # mapping from the original qubit name to it's compiled name
    qubit_dict = Dict()
    # mapping qubit names (which are strings) to integers (needed for actually
    # calculations)
    qubit_to_integer::Dict{String,UInt} = Dict()
    # the compiled widget circuit, but only the gates
    compiled_circuit::Vector{ICMGate} = []
    # the measurements on the widget
    measurement_sequence::Vector{ICMGate} = []

    # - the incoming qubit from the previous widget is identified with "ii_"*q
    # - the intermediate qubit is identified with "i_"*q
    # - we want to keep q on q(+1), so we push "ii_"*q onto q(+1)+2n_qubits
    #   and "i_"*q onto q(+1)+n_qubits; according to that, any other qubit is
    #   pushed with (+1)+3n_qubits


    # this here is the main tracker which will track all the new pauli corrections induced
    # by the according measurement (caputered by frame_flags) (which will later on define
    # the time order of the measurements)
    frames = Frames()
    frame_flags = []

    # there might be incoming pauli corrections; this buffers tracks all of those
    # potential incoming pauli corrections (which are all directly "moved" from iiq to q)
    buffer = Frames()
    # if z correction on qubit iiq get correction frame at buffer_flags.index(iiq)
    # if x correction on qubit iiq get correction frame at buffer_flags.index(iiq) + 1
    buffer_flags = []

    # populate qubit_dict, add it's mapping to integers in qmap and do the initialisation
    # for the bell teleportation (i.e., everything before the actual circuit), cf.
    # (handwritten notes -> TODO: add them to paper draft)
    #
    # if the qubits were just numbered from 0 to n_qubits-1, we could just
    # loop over this range, however, since we don't have this guarantee, we have to get
    # all the qubits from the circuit and just skip the ones we already have
    for gate in circuit
        for q in gate[2]
            if haskey(qubit_dict, q)
                continue
            end
            iq = "i_" * q
            iiq = "ii_" * q
            qint::UInt = parse(UInt, q) + 1 # why + 1?
            iqint::UInt = n_qubits + qint
            iiqint::UInt = 2 * n_qubits + qint
            qubit_dict[q] = q
            qubit_to_integer[q] = qint
            qubit_to_integer[iq] = iqint
            qubit_to_integer[iiq] = iiqint
            frames.new_qubit(qint)
            # the next two will not capture any pauli corrections (usually, cf. comment
            # below regarding cz(iiq, iq) and the input Hadamard corrections (cf.
            # gcompile)), but add them to easily get the time order later on
            frames.new_qubit(iqint)
            frames.new_qubit(iiqint)
            buffer.new_qubit(qint)
            # buffer.new_qubit(iqint)

            push!(compiled_circuit, ("H", [iq]))
            push!(compiled_circuit, ("CZ", [iq, q]))
            push!(compiled_circuit, ("H", [iq]))

            # those are the "moved" potential corrections" from the previous widget
            buffer.track_z(qint)
            buffer.track_x(qint)
            push!(buffer_flags, iiqint)
            # those are the induced corrections from the teleportation
            frames.track_x(qint)
            push!(frame_flags, iqint)
            frames.track_z(qint)
            push!(frame_flags, iiqint)

            # the teleportation measurements; however, note that we are not tracking the
            # cz(iiq, iq) here, because it does not belong solely to the widget (it's the
            # stitching process) ( we don't have to track the cz(iiq, iq) when stitching
            # because there are no corrections on iq (or iiq); everything is on q; except
            # if we decide to teleport the input Hadamard corrections (cf. gcompile))
            push!(measurement_sequence, ("X", [iq]))
            push!(measurement_sequence, ("X", [iiq]))
        end
    end

    ancilla_num = 0

    for gate in circuit
        compiled_qubits = [get(qubit_dict, qubit, qubit) for qubit in gate[2]]

        if gate[1] in gates_to_decompose
            for (original_qubit, compiled_qubit) in zip(gate[2], compiled_qubits)
                ancilla_num += 1

                # NOTE: Isn't the teleportation with a cnot and an ancilla in |0> specific
                # to z-rotations? If so, then gates_to_decompose should be restricted to
                # those gates or it should be atleast documented

                source = UInt(qubit_to_integer[compiled_qubit])
                destination = 3 * n_qubits + ancilla_num

                new_qubit_name = "anc_$(ancilla_num)"
                qubit_dict[original_qubit] = new_qubit_name
                qubit_to_integer[new_qubit_name] = destination

                frames.new_qubit(destination)
                buffer.new_qubit(destination)

                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit_name]))
                frames.cx(source, destination)
                buffer.cx(source, destination)
                if gate[1] == "T" || gate[1] == "T_Dagger"
                    frames.move_z_to_z(source, destination)
                    buffer.move_z_to_z(source, destination)
                    frames.track_z(destination)
                    push!(frame_flags, source)
                else
                    # NOTE: cf. note above + the current gate representation (strings) do
                    # not support parameters, so I'm not checking for something like "RZ"
                    # (I'm not going to do the same hack I did before on the track_pauli*
                    # branches, because it is ugly and only works with the according
                    # check.py script there); instead another gate representation would be
                    # needed
                    error("only support T and T_Dagger decomposition")
                end
                push!(measurement_sequence,
                    (gate[1], [compiled_qubit]))
            end
        else
            push!(compiled_circuit, (gate[1], compiled_qubits))
            pauli_tracking.apply_gate!(
                frames, (gate[1], [qubit_to_integer[q] for q in compiled_qubits])
            )
        end
    end

    return compiled_circuit, qubit_dict, measurement_sequence, qubit_to_integer, frames, buffer, frame_flags, buffer_flags
end
