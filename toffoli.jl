#!/usr/bin/env julia

using Jabalizer
include("src/icm.jl")

function bit_plus(qubit::String)::UInt
    parse(UInt, qubit) + 1
end

function apply_gate(state::StabilizerState, gate::ICMGate)
    name = gate[1]
    bits = gate[2]
    if name == "H"
        Jabalizer.H(bit_plus(bits[1]))(state)
    elseif name == "S"
        Jabalizer.S(bit_plus(bits[1]))(state)
    elseif name == "CZ"
        Jabalizer.CZ(bit_plus(bits[1]), bit_plus(bits[2]))(state)
    elseif name == "X"
        Jabalizer.X(bit_plus(bits[1]))(state)
    elseif name == "Y"
        Jabalizer.Y(bit_plus(bits[1]))(state)
    elseif name == "Z"
        Jabalizer.Z(bit_plus(bits[1]))(state)
    elseif name == "S_DAG"
        Jabalizer.S_DAG(bit_plus(bits[1]))(state)
    elseif name == "SQRT_X"
        Jabalizer.SQRT_X(bit_plus(bits[1]))(state)
    elseif name == "SQRT_X_DAG"
        Jabalizer.SQRT_X_DAG(bit_plus(bits[1]))(state)
    elseif name == "SQRT_Y"
        Jabalizer.SQRT_Y(bit_plus(bits[1]))(state)
    elseif name == "SQRT_Y_DAG"
        Jabalizer.SQRT_Y_DAG(bit_plus(bits[1]))(state)
    elseif name == "CNOT"
        Jabalizer.CNOT(bit_plus(bits[1]), bit_plus(bits[2]))(state)
    elseif name == "SWAP"
        Jabalizer.SWAP(bit_plus(bits[1]), bit_plus(bits[2]))(state)
    else
        error("Unknown gate: $name")
    end
end

function toffoli()
    circuit = [
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
    n_qubits = 3
    gates_to_decompose = ["T", "TD"]

    circ, map =
        compile(circuit, n_qubits, gates_to_decompose, "output/toffoli.json")

    compatible_circ_description = []
    for gate in circ
        qubits::Vector{String} = []
        for qubit in gate[2]
            if startswith(qubit, "anc")
                push!(qubits, "$(n_qubits + parse(UInt, qubit[5:end]))")
            else
                push!(qubits, qubit)
            end
        end
        push!(compatible_circ_description, (gate[1], qubits))
    end

    frames_map::Vector{Int} = []
    for i in range(0, 9)
        if !(i in map)
            push!(frames_map, Int(i))
        end
    end

    println()
    for gate in compatible_circ_description
        println(gate)
    end
    input = []
    for i in range(0, n_qubits)
        push!(input, i)
    end
    println("input_bits: $input")
    println("output_bits: $map")
    println("frames_map: $frames_map")

    measurements_removed = Vector{Tuple{String,Vector{String}}}()
    for gate in compatible_circ_description
        if !(length(gate[1]) > 20)
            push!(measurements_removed, gate)
        end
    end

    n = 10
    state = zero_state(n)

    Jabalizer.H(1)(state)
    Jabalizer.H(2)(state)

    for gate in measurements_removed
        apply_gate(state, gate)
    end

    Jabalizer.update_tableau(state)
    # tab = Jabalizer.to_tableau(state)
    # display(tab)
    graphState = GraphState(state)
    # display(graphState.A)
    stabState = StabilizerState(graphState)

end

toffoli()
