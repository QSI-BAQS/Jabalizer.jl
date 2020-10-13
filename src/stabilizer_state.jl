"""
    Stabilizer state type.

qubits: number of qubits.
stabilizers: set of state stabilizers.
labels: qubit labels.
"""
mutable struct StabilizerState
    qubits::Int64
    stabilizers::Array{Stabilizer}
    labels::Array{String}
    lost::Array{Int64}

    StabilizerState() = new(0, [], [], [])
    StabilizerState(n::Int64) = new(n, [], [], zeros(n))
    StabilizerState(tab::Array{Int64}) = TableauToState(tab)
end

# function StabilizerState(graphState::GraphState)
#     return(GraphToState(graphState))
# end

"""
Generate stabilizer from tableau
"""
function TableauToState(tab::Array{Int64})::StabilizerState
    qubits = Int64((length(tab[1, :]) - 1) / 2)
    stabs = Int64(length(tab[:, 1]))
    state = StabilizerState(qubits)

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
function GetQubitLabel(state::StabilizerState, qubit::Int64)
    return qubit
end

"""
Get the index of a qubit by label.
"""
function GetQubitLabel(state::StabilizerState, qubit::String)
    return findfirst(x -> x == qubit, state.labels)
end

"""
    ToTableau(state)

Convert state to tableau form.
"""
function ToTableau(state::StabilizerState)::Array{Int64}
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
    string(state)

Convert state to string.
"""
function string(state::StabilizerState)
    str = ""

    for s in state.stabilizers
        str = string(str, string(s), '\n')
    end

    return str
end

"""
    print(state)

Print the full stabilizer set of a state to the terminal.
"""
function print(state::StabilizerState, info::Bool = false, tab::Bool = false)
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
    gplot(state)

Plot the graph equivalent of a state.
"""
function gplot(state::StabilizerState)
    graphState = GraphState(state)
    gplot(Graph(graphState.adjM),nodelabel=1:state.qubits)
end
