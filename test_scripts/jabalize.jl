#!/usr/bin/env julia
if !isinteractive()
    import Pkg
    Pkg.activate(".")
end

import Jabalizer: Jabalizer, StabilizerState, GraphState, ICMGate
import Jabalizer.pauli_tracker: pauli_tracker, Frames, Storage
import JSON

function run()
    mkpath("output")
    # toffoli()
    fourier()
end

function toffoli()
    name = "toffoli"
    gate = [
        ("T", ["0"]),
        ("T", ["1"]),
        ("H", ["2"]),
        ("T", ["2"]),
        ("CNOT", ["0", "1"]),
        ("CNOT", ["1", "2"]),
        ("TD", ["1"]),
        ("T", ["2"]),
        ("CNOT", ["0", "1"]),
        ("CNOT", ["1", "2"]),
        ("TD", ["2"]),
        ("CNOT", ["0", "1"]),
        ("CNOT", ["1", "2"]),
        ("TD", ["2"]),
        ("CNOT", ["0", "1"]),
        ("CNOT", ["1", "2"]),
        ("H", ["2"]),
    ]
    # alternative decomposition
    # gate = [
    #     ("H", ["2"]),
    #     ("CNOT", ["1", "2"]),
    #     ("TD", ["2"]),
    #     ("CNOT", ["0", "2"]),
    #     ("T", ["2"]),
    #     ("CNOT", ["1", "2"]),
    #     ("TD", ["2"]),
    #     ("CNOT", ["0", "2"]),
    #     ("T", ["2"]),
    #     ("H", ["2"]),
    #     ("TD", ["1"]),
    #     ("CNOT", ["0", "1"]),
    #     ("TD", ["1"]),
    #     ("CNOT", ["0", "1"]),
    #     ("S", ["1"]),
    #     ("T", ["0"]),
    # ]

    jabalize_inits(
        [
            # ("ooo", []),
            # ("xoo", [("X", ["0"])]),
            # ("oxo", [("X", ["1"])]),
            # ("oox", [("X", ["2"])]),
            # ("xxo", [("X", ["0"]), ("X", ["1"])]),
            # ("xox", [("X", ["0"]), ("X", ["2"])]),
            # ("oxx", [("X", ["1"]), ("X", ["2"])]),
            # ("xxx", [("X", ["0"]), ("X", ["1"]), ("X", ["2"])]),
            # ("poo", [("H", ["0"])]),
            ("ppo", [("H", ["0"]), ("H", ["1"])]),
            # ("ppp", [("H", ["0"]), ("H", ["1"]), ("H", ["2"])]),
        ],
        name, gate, 3)
end

# qft
function fourier()
    num = 4
    name = "fourier_$(num)"
    gate = []
    for i in range(start=num - 1, stop=0, step=-1)
        push!(gate, rotate(i)...)
    end

    jabalize_inits(
        [
            ("oooo", []),
            ("pppp", [("H", ["0"]), ("H", ["1"]), ("H", ["2"]), ("H", ["3"])]),
        ],
        name, gate, num)
end

# controlled rotation with cnot and rotation
function control_rz(c, t, angle_divisor)
    return [
        ("CNOT", [c, t], 0),
        ("RZ", [t], -angle_divisor - 1),
        ("CNOT", [c, t], 0),
        ("RZ", [t], angle_divisor + 1),
    ]
end

# a qft rotation sequence on one target bit
function rotate(t)
    b = "$t"
    ret = [("H", [b], 0)]
    for i in range(0, t - 1)
        # the t-i is the encoded rotation parameter which is decoded in check.py
        push!(ret, control_rz("$i", b, t - i)...)
    end
    return ret
end


# shortcut to jabalize a circuit with different input states; compare, for example, how
# it is used in the toffoli function
function jabalize_inits(
    inits,
    name,
    gate,
    num_bits,
)
    for (init_name, init) in inits
        if length(init) == 0
            circuit = gate
        else
            circuit = [init; gate]
        end
        jabalize("$(name)_$(init_name)", num_bits, circuit, init)
    end
end

# the output produced by Jabalizer; the other output will be the Pauli frames from the
# Pauli tracker
struct Output
    # the "spacial" graph
    graph::Vector{Vector{Int}}
    # local corrections on the spacial graph from the Gauß-like elimination
    local_ops::Vector{Tuple{String,Int}}
    # which qubits are the input qubits
    input_map::Vector{Int}
    # which qubits are the output qubits
    output_map::Vector{Int}
    # which Pauli frames belong to which measurements
    frames_map::Vector{Int}
    # a sequence of initialize gates (currently only H, X; can be any Clifford in
    # theory, but would need other type for that
    initializer::Vector{Tuple{String,Int}}
    # the kinds of measurements, (gate_name, qubit, additional information encoded in
    # one integer (cf. qft rotations))
    measurements::Vector{Tuple{String,Int,Int}}
end

# that is the main function
function jabalize(
    name, # circuit file name
    n_input, # number of input qubits
    circuit, # circuit gate sequence
    init # gate sequence for initial state
)
    gates_to_decompose = ["T", "TD", "RZ"]

    # initialize the stuff needed for the pauli tracking; note that they are basically
    # opaque pointers, which we have to free manually (one should probably write a
    # wrapper for that, when the pauli tracker is properly injected into jabalizer (or
    # graph_sim, ...); the storage can actually be ignored currently, that's only
    # interesting for large circuits because one could do some kind of streaming (cf.
    # pauli_tracker docs)
    frames = pauli_tracker.frames_init(UInt(n_input))
    storage = pauli_tracker.storage_new()

    # teleport T, TD, RZ and do the pauli tracking
    circ, output_map, frames_map = Jabalizer.compile(
        circuit, n_input, gates_to_decompose, frames, storage)

    # dump the frames into json files and free the pointers
    # pauli_tracker.frames_measure_and_store_all(frames, storage)
    pauli_tracker.storage_serialize(storage, "output/$(name)_frames.json")
    pauli_tracker.frames_serialize(frames, "output/$(name)_frames.json")
    pauli_tracker.storage_free(storage)
    pauli_tracker.frames_free(frames)

    # getting a proper circuit description compatible with stim, i.e., integers for
    # qubits and not strings,
    compatible_circ_description = []
    for gate in circ
        qubits = []
        for qubit in gate[2]
            if startswith(qubit, "anc")
                push!(qubits, n_input + get_bit(qubit[5:end]))
            else
                push!(qubits, get_bit(qubit))
            end
        end
        if length(gate) == 2
            additional = 0
        else
            additional = gate[3]
        end
        push!(compatible_circ_description, (gate[1], qubits, additional))
    end

    # for gate in circ
    #     println(gate)
    # end

    # the input map, assuming the first qubits are the input qubits
    input_map::Vector{Int} = []
    for i in range(0, n_input - 1)
        push!(input_map, i)
    end

    # println(input_map)
    # println(output_map)
    # println(frames_map)


    # for gate in compatible_circ_description
    #     println(gate)
    # end

    # split into clifford and measurements
    jabalizer_input = Vector{Tuple{String,Vector{Int}}}()
    measurements = []
    for gate in compatible_circ_description
        if !(length(gate[1]) > 11 && (gate[1][end-11:end] == "_measurement"))
            # stims requires 1 indexed..?
            push!(jabalizer_input, (gate[1], gate[2] .+ 1))
        else
            gate_name = gate[1][1:end-12]
            if gate_name == "RZ"
                push!(measurements, (gate_name, gate[2][1], gate[3]))
            else
                push!(measurements, (gate_name, gate[2][1], 0))
            end
        end
    end
    # println(measurements)

    n_total = length(output_map) + length(frames_map)

    # do the stim and gauß-like elimination
    state = Jabalizer.zero_state(n_total)
    for gate in jabalizer_input
        apply_gate(state, gate)
    end
    Jabalizer.update_tableau(state)
    # display(state)
    local_ops::Vector{Tuple{String,Int}} = []
    for op in Jabalizer.to_graph(state)[3]
        push!(local_ops, (op[1], op[2] - 1))
    end
    graphState = Jabalizer.GraphState(state)

    # display(graphState)

    # sparse graph representation
    graph::Vector{Vector{Int}} = []
    for i in range(1, n_total)
        node = []
        for (j, e) in enumerate(graphState.A[i, :])
            if e == 1 && j != i
                push!(node, j - 1)
            end
        end
        push!(graph, node)
    end

    # println(graph)

    # init gates compatible with the output I want
    initializer::Vector{Tuple{String,Int}} = []
    for (gate, bit) in init
        push!(initializer, (gate, get_bit(bit[1])))
    end

    # println(initializer)
    # println(local_ops)

    # println(local_ops)
    # println(initializer)
    # println(measurements)

    output = Output(
        graph, local_ops, input_map, output_map, frames_map, initializer, measurements)
    open("output/$(name)_jabalize.json", "w") do file
        write(file, JSON.json(output))
    end
end


# I can't manage to use the gate_map from Jabalizer.gates to do something like
# what is done Jabalizer.execute_circuit; it should be possible though, I think, it just
# annoyed; anyway, this function updates the state fed into stim and the gaussian
# elimination
function apply_gate(state::StabilizerState, gate::Tuple{String,Vector{Int}})
    name = gate[1]
    bits = gate[2]
    if name == "H"
        Jabalizer.H(bits[1])(state)
    elseif name == "S"
        Jabalizer.S(bits[1])(state)
    elseif name == "CZ"
        Jabalizer.CZ(bits[1], bits[2])(state)
    elseif name == "X"
        Jabalizer.X(bits[1])(state)
    elseif name == "Y"
        Jabalizer.Y(bits[1])(state)
    elseif name == "Z"
        Jabalizer.Z(bits[1])(state)
    elseif name == "S_DAG"
        Jabalizer.S_DAG(bits[1])(state)
    elseif name == "SQRT_X"
        Jabalizer.SQRT_X(bits[1])(state)
    elseif name == "SQRT_X_DAG"
        Jabalizer.SQRT_X_DAG(bits[1])(state)
    elseif name == "SQRT_Y"
        Jabalizer.SQRT_Y(bits[1])(state)
    elseif name == "SQRT_Y_DAG"
        Jabalizer.SQRT_Y_DAG(bits[1])(state)
    elseif name == "CNOT"
        Jabalizer.CNOT(bits[1], bits[2])(state)
    elseif name == "SWAP"
        Jabalizer.SWAP(bits[1], bits[2])(state)
    else
        error("Unknown gate: $name")
    end
end

# why is jabalizer using strings to represent bits ...
function get_bit(qubit::String)::Int
    parse(Int, qubit)
end

run()
nothing

