if !isinteractive()
    import Pkg
    Pkg.activate(".")
end

import Jabalizer
import JSON

struct BitMapping
    input::Vector{Int}
    output::Vector{Int}
    frames::Vector{Int}
end

function bit(qubit::String)::Int
    parse(Int, qubit)
end

function apply_gate(state::Jabalizer.StabilizerState, gate::Tuple{String,Vector{Int}})
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


function run(name, n_input, circuit)
    gates_to_decompose = ["T", "TD"]

    circ, map = Jabalizer
        .compile( circuit, n_input, gates_to_decompose, "output/$(name)_frames.json")

    compatible_circ_description::Vector{Tuple{String,Vector{Int}}} = []
    for gate in circ
        qubits = []
        for qubit in gate[2]
            if startswith(qubit, "anc")
                push!(qubits, n_input + bit(qubit[5:end]))
            else
                push!(qubits, bit(qubit))
            end
        end
        push!(compatible_circ_description, (gate[1], qubits))
    end

    input::Vector{Int} = []
    for i in range(0, n_input - 1)
        push!(input, i)
    end

    frames_map::Vector{Int} = []
    for i in range(0, 9)
        if !(i in map)
            push!(frames_map, Int(i))
        end
    end

    open("output/$(name)_bitmapping.json", "w") do file
        write(file, JSON.json(BitMapping(input, map, frames_map)))
    end

    # for gate in compatible_circ_description
    #     println(gate)
    # end

    jabalizer_input = Vector{Tuple{String,Vector{Int}}}()
    for gate in compatible_circ_description
        if !(length(gate[1]) > 20)
            push!(jabalizer_input, (gate[1], gate[2] .+ 1))
        end
    end

    n_total = 10
    state = Jabalizer.zero_state(n_total)


    for gate in jabalizer_input
        apply_gate(state, gate)
    end

    Jabalizer.update_tableau(state)
    graphState = Jabalizer.GraphState(state)

    nodes = []
    for i in range(0, n_total - 1)
        node = []
        for (j, e) in enumerate(graphState.A[i+1, :])
            if e == 1 && j != i
                push!(node, j)
            end
        end
        push!(nodes, node)
    end

    open("output/$(name)_graph.json", "w") do file
        write(file, JSON.json(nodes))
    end
end

function run_inits(
    inits::Vector{Tuple{String,Vector{Jabalizer.ICMGate}}},
    name::String,
    gate::Vector{Jabalizer.ICMGate}
)
    for (init_name, init) in inits
        run("$(name)_$(init_name)", 3, [init; gate])
    end
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

    run_inits(
        [
            ("ppo",
                [
                    ("H", ["0"]), ("H", ["1"])
                ]
            )
            ("poo",
                [
                    ("H", ["0"])
                ]
            )
        ],
        name, gate)
end

toffoli()

nothing
