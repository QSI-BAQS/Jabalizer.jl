"""
    Graph state type

Type for a stabilizer state constrained to graph form.
"""
mutable struct GraphState
    qubits::Int64
    A::Array{Int64}
    labels::Array{String}
    lost::Array{Int64}

    GraphState() = new(0, [], [], [])
    GraphState(A::Array{Int64}) =
    new(length(A[:, 1]), A, [], zeros(length(A[:, 1])))
    GraphState(state::StabilizerState) =
        new(state.qubits, ToGraph(state)[2], state.labels)
end

"""
    GraphToState(graphState)

Convert GraphState to State.
"""
function GraphToState(graphState::GraphState)
    return (GraphToState(graphState.A))
end

"""
    GraphToState(A)

Convert adjacency matrix to state.
"""
function GraphToState(A::Array{Int64})
    qubits = length(A[:, 1])
    id = Array{Int64}(I, qubits, qubits)
    phase = zeros(Int64, qubits, 1)
    tab = hcat(id, A, phase)
    state = StabilizerState(tab)
    return (state)
end

"""
    gplot(graphState)

Plot the graph of a GraphState.
"""
function gplot(graphState::GraphState)
    gplot(Graph(graphState.A), nodelabel = 1:graphState.qubits)
end

"""
    print(graphState)

Print a GraphState to the terminal.
"""
function print(graphState::GraphState, info::Bool = false)
    if info == true
        println("Adjacency matrix for ", graphState.qubits, " qubits:\n")
    end

    display(graphState.A)

    if info == true
        println("\nQubit labels: ", graphState.labels)
    end
end
