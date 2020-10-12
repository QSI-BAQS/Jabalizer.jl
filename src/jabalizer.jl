# Jabalizer
# Quantum stabilizer circuit simulator
# by Peter P. Rohde

#__precompile__(true)

module Jabalizer

using LightGraphs, GraphPlot, LinearAlgebra

import Base: *, print, string
import GraphPlot.gplot

export State, Stabilizer, GraphState
export AddQubit, AddQubits, AddGraph, AddGHZ, AddBell
export P, X, Y, Z, H, CNOT, CZ, SWAP
export ChannelDepol, ChannelLoss, ChannelPauli, ChannelX, ChannelY, ChannelZ
export ExecuteCircuit
export GetQubitLabel, GraphToState, TableauToState
export gplot, print, string

"""
Stabilizer type
"""
mutable struct Stabilizer
    qubits::Int64
    X::Array{Int64}
    Z::Array{Int64}
    phase::Int64

    """
    Constructor for an empty stabilizer.
    """
    Stabilizer() = new(0, [], [], 0)

    """
    Constructor for an n-qubit identity stabilizer.
    """
    Stabilizer(n::Int64) = new(n, zeros(n), zeros(n), 0)

    """
    Constructor for a stabilizer from tableau form.
    """
    Stabilizer(tab::Array{Int64}) = new(
        Int64((length(tab) - 1) / 2),
        tab[1:Int64((length(tab) - 1) / 2)],
        tab[Int64((length(tab) - 1) / 2 + 1):Int64(length(tab) - 1)],
        last(tab),
    )
end

"""
Conjugate of a stabilizer.
"""
function adjoint(stabilizer::Stabilizer)::Stabilizer
    conj = deepcopy(stabilizer)
    conj.phase = (-conj.phase) % 4
    return conj
end

"""
Convert tableau form of single Pauli operator to char.
"""
function TabToPauli(X::Int64, Z::Int64)::Char
    if X == 0 && Z == 0
        return 'I'
    elseif X == 1 && Z == 0
        return 'X'
    elseif X == 0 && Z == 1
        return 'Z'
    elseif X == 1 && Z == 1
        return 'Y'
    else
        return 'I'
    end
end

"""
Convert Pauli operator from char to tableau form.
"""
function PauliToTab(pauli::Char)
    if pauli == 'I'
        return (0, 0)
    elseif pauli == 'X'
        return (1, 0)
    elseif pauli == 'Z'
        return (0, 1)
    elseif pauli == 'Y'
        return (1, 1)
    else
        return (0, 0)
    end
end

"""
Product of two Pauli operators.
"""
function PauliProd(left::Char, right::Char)
    if left == 'X' && right == 'Z'
        return ('Y', 3)
    elseif left == 'X' && right == 'Y'
        return ('Z', 1)
    elseif left == 'Z' && right == 'X'
        return ('Y', 1)
    elseif left == 'Z' && right == 'Y'
        return ('X', 3)
    elseif left == 'Y' && right == 'Z'
        return ('X', 1)
    elseif left == 'Y' && right == 'X'
        return ('Z', 3)
    elseif left == 'I'
        return (right, 0)
    elseif right == 'I'
        return (left, 0)
    else
        return ('I', 0)
    end
end

"""
    *(left,right)

Multiplication operator for stabilizers.
"""
function *(left::Stabilizer, right::Stabilizer)::Stabilizer
    if left.qubits != right.qubits
        return left
    end

    qubits = left.qubits
    prod = Stabilizer(qubits)
    prod.phase = (left.phase + right.phase) % 4

    for n = 1:qubits
        leftPauli = TabToPauli(left.X[n], left.Z[n])
        rightPauli = TabToPauli(right.X[n], right.Z[n])

        thisPauli = PauliProd(leftPauli, rightPauli)
        thisTab = PauliToTab(thisPauli[1])

        (prod.X[n], prod.Z[n]) = (thisTab[1], thisTab[2])
        prod.phase += thisPauli[2]
        prod.phase %= 4
    end

    return prod
end

"""
Stabilizer state type.
qubits: number of qubits.
stabilizers: set of state stabilizers.
labels: qubit labels.
"""
mutable struct State
    qubits::Int64
    stabilizers::Array{Stabilizer}
    labels::Array{String}
    lost::Array{Int64}

    State() = new(0, [], [], [])
    State(n::Int64) = new(n, [], [], zeros(n))
    State(tab::Array{Int64}) = TableauToState(tab)
    #State(graphState::GraphState) = GraphToState(graphState)
end

"""
Generate stabilizer from tableau
"""
function TableauToState(tab::Array{Int64})::State
    qubits = Int64((length(tab[1, :]) - 1) / 2)
    stabs = Int64(length(tab[:, 1]))
    state = State(qubits)

    for row = 1:stabs
        stab = Stabilizer(tab[row, :])
        push!(state.stabilizers, stab)
    end

    for n = 1:qubits
        push!(state.labels, string(n))
    end

    return state
end

"""
Get the index of a qubit by number.
"""
function GetQubitLabel(state::State, qubit::Int64)
    return qubit
end

"""
Get the index of a qubit by label.
"""
function GetQubitLabel(state::State, qubit::String)
    return findfirst(x -> x == qubit, state.labels)
end

"""
Convert stabilizer to tableau form.
"""
function ToTableau(stabilizer::Stabilizer)
    return vcat(stabilizer.X, stabilizer.Z, stabilizer.phase)
end

"""
Convert state to tableau form.
"""
function ToTableau(state::State)::Array{Int64}
    tab = Int64[]

    for s in state.stabilizers
        tab = vcat(tab, ToTableau(s))
    end

    tab = Array(transpose(reshape(
        tab,
        2 * state.qubits + 1,
        length(state.stabilizers),
    )))

    return tab
end

"""
Convert stabilizer to string.
"""
function string(stabilizer::Stabilizer)
    str = ""

    for i = 1:stabilizer.qubits
        if stabilizer.X[i] == 0 && stabilizer.Z[i] == 0
            thisPauli = 'I'
        elseif stabilizer.X[i] == 1 && stabilizer.Z[i] == 0
            thisPauli = 'X'
        elseif stabilizer.X[i] == 0 && stabilizer.Z[i] == 1
            thisPauli = 'Z'
        elseif stabilizer.X[i] == 1 && stabilizer.Z[i] == 1
            thisPauli = 'Y'
        end

        str = string(str, thisPauli)
    end

    return string(str, " (", (0 + 1im)^stabilizer.phase, ")")
end

"""
    print(Stabilizer)

Print a stabilizer to terminal.
"""
function print(stabilizer::Stabilizer, info::Bool = false, tab::Bool = false)
    if info == true
        println("Stabilizer for ", stabilizer.qubits, " qubits:")
    end

    if tab == false
        str = string(stabilizer)
    else
        str = ToTableau(stabilizer)
    end

    println(str)
end

"""
Convert state to string.
"""
function string(state::State)
    str = ""

    for s in state.stabilizers
        str = string(str, string(s), '\n')
    end

    return str
end

"""
    print(State)

Print the full stabilizer set of a state to the terminal.
"""
function print(state::State, info::Bool = false, tab::Bool = false)
    if info == true
        println(
            "Stabilizers (",
            length(state.stabilizers),
            " stabilizers, ",
            state.qubits,
            " qubits):\n")
    end

    if tab == false
        for s in state.stabilizers
            print(s)
        end
    else
        print(ToTableau(state))
    end

    println()

    if info == true
        println("Qubit labels: ", state.labels)
        println("Lost qubits: ", state.lost)
    end
end

"""
Graph state type.
"""
mutable struct GraphState
    qubits::Int64
    adjM::Array{Int64}
    labels::Array{String}

    GraphState() = new(0, [], [])
    GraphState(adjM::Array{Int64}) = new(length(adjM[:, 1]), adjM, [])
    GraphState(state::State) =
        new(state.qubits, ToGraph(state)[2], state.labels)
end

"""
Convert GraphState to State.
"""
function GraphToState(graphState::GraphState)
    return (GraphToState(graphState.adjM))
end

"""
Convert adjacency matrix to State.
"""
function GraphToState(adjM::Array{Int64})
    qubits = length(adjM[:, 1])
    id = Array{Int64}(I, qubits, qubits)
    phase = zeros(Int64, qubits, 1)
    tab = hcat(id, adjM, phase)
    state = State(tab)
    return (state)
end

"""
    gplot(GraphState)

Plot the graph of a GraphState.
"""
function gplot(graphState::GraphState)
    gplot(Graph(graphState.adjM), nodelabel = graphState.labels)
end

"""
    print(GraphState)

Print a GraphState to the terminal.
"""
function print(graphState::GraphState, info::Bool = false)
    if info == true
        println("Adjacency matrix for ", graphState.qubits, " qubits:\n")
    end

    display(graphState.adjM)

    if info == true
        println("\nQubit labels: ", graphState.labels)
    end
end

"""
Execute a gate sequence.
"""
function ExecuteCircuit(state::State, gates::Array{})
    for gate in gates
        if gate[1] == "X"
            X(state, gate[2])
        elseif gate[1] == "Y"
            Y(state, gate[2])
        elseif gate[1] == "Z"
            Z(state, gate[2])
        elseif gate[1] == "H"
            H(state, gate[2])
        elseif gate[1] == "P"
            P(state, gate[2])
        elseif gate[1] == "CNOT"
            CNOT(state, gate[2], gate[3])
        elseif gate[1] == "CZ"
            CZ(state, gate[2], gate[3])
        elseif gate[1] == "SWAP"
            SWAP(state, gate[2], gate[3])
        else
            println("Warning: unknown gate.")
        end
    end
end

"""
Plot the graph equivalent of a State.
"""
function gplot(state::State)
    graphState = GraphState(state)
    gplot(Graph(graphState.adjM),nodelabel=state.labels)
end

include("util.jl")
include("preparation.jl")
include("gates.jl")
include("channels.jl")

end
