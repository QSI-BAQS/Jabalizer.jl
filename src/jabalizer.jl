# Jabalizer
# Quantum stabilizer circuit simulator
# by Peter P. Rohde

#__precompile__(true)

#module Jabalizer

using LightGraphs, GraphPlot, LinearAlgebra
# using Crayons, Crayons.Box

import Base: *, print, string
import GraphPlot.gplot

export *

# export State, Stabilizer, GraphState
# export AddQubit, AddQubits, AddGraph, AddGHZ, AddBell
# export P, X, Y, Z, H, CNOT, CZ, SWAP
# export ChannelDepol, ChannelLoss, ChannelPauli, ChannelX, ChannelY, ChannelZ
# export ExecuteCircuit
# export GetQubitLabel, GraphToState
# export gplot, print, string

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
Multiplication operator for stabilizer type.
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
Print stabilizer to terminal.
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

    # for char in str
    #     if char == 'X'
    #         print(BLUE_FG, char)
    #     elseif char == 'Z'
    #         print(RED_FG, char)
    #     elseif char == 'Y'
    #         print(GREEN_FG, char)
    #     else
    #         print(DEFAULT_FG, char)
    #     end
    # end

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
Print state to terminal.
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
Plot the graph of a GraphState.
"""
function gplot(graphState::GraphState)
    gplot(Graph(graphState.adjM), nodelabel = graphState.labels)
end

"""
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
Row addition operation for tableaus.
"""
function RowAdd(tab::Array{Int64}, source::Int64, dest::Int64)
    prod = Stabilizer(tab[source, :]) * Stabilizer(tab[dest, :])
    tab[dest, :] = ToTableau(prod)
    return tab
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
Convert a State to its graph state equivalent under local operations.
"""
function ToGraph(state::State)
    newState = deepcopy(state)
    qubits = state.qubits
    stabs = length(state.stabilizers)
    LOseq = [] # Sequence of local operations performed

    # Make X-block full rank
    tab = sortslices(ToTableau(newState), dims = 1, rev = true)
    for n = 1:stabs
        if (sum(tab[n:stabs, n]) == 0)
            H(newState, n)
            push!(LOseq, ("H", n))
        end
        tab = sortslices(ToTableau(newState), dims = 1, rev = true)
    end

    # Make upper-triangular X-block
    for n = 1:qubits
        for m = (n+1):stabs
            if tab[m, n] == 1
                tab = RowAdd(tab, n, m)
            end
        end
        tab = sortslices(tab, dims = 1, rev = true)
    end

    # Make diagonal X-block
    for n = (stabs-1):-1:1
        for m = (n+1):stabs
            if tab[n, m] == 1
                tab = RowAdd(tab, m, n)
            end
        end
    end

    newState = State(tab)

    # Reduce all stabilizer phases to +1

    # Adjacency matrix
    adjM = tab[:, (qubits+1):(2*qubits)]

    if (adjM != adjM') || (tr(adjM) != 0)
        println("Error: invalid graph conversion.")
    end

    return (newState, adjM, Tuple(LOseq))
end

"""
Plot the graph equivalent of a State.
"""
function gplot(state::State)
    graphState = GraphState(state)
    gplot(Graph(graphState.adjM),nodelabel=state.labels)
end

include("preparation.jl")
include("gates.jl")
include("channels.jl")

# end
