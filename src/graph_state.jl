"""
    Graph state type

Type for a stabilizer state constrained to graph form.
"""
mutable struct GraphState
    qubits::Int64
    A::Array{Int64} # TODO: Rename "A" to something more verbose, e.g. "adj_matrix".
    labels::Array{String} #TODO: might not be needed anymore (lost as well)
    lost::Array{Int64} # TODO: Class attributes should be described in the docstring

    GraphState() = new(0, [], [], [])
    GraphState(A::Array{Int64}) =
        new(length(A[:, 1]), A, [], zeros(length(A[:, 1])))
    GraphState(state::StabilizerState) =
        new(state.qubits, ToGraph(state)[2], state.labels)
end

# TODO: rename to GraphStateToState (or just to_state, even better idea!)
"""
    GraphToState(graphState)

Convert GraphState to State.
"""
GraphToState(graphState::GraphState) = GraphToState(graphState.A)

# NOTE: this is identical to GraphToState, only one should be needed
StabilizerState(graphState::GraphState) = GraphToState(graphState)

"""
    gplot(graphState)

Plot the graph of a GraphState.
"""
function gplot(graphState::GraphState; node_dist=5.0)

    # Creates an anonymous function to allow changing the layout params
    # in gplot. The value of C determines distance between connected nodes.
    layout = (args...) -> spring_layout(args...; C=node_dist)
    gplot(Graph(graphState.A), nodelabel=1:graphState.qubits)
end

"""
    print(graphState)

Print a GraphState to the terminal.
"""
function Base.print(graphState::GraphState, info::Bool=false)
    if info == true
        println("Adjacency matrix for ", graphState.qubits, " qubits:\n")
    end

    display(graphState.A)

    if info == true
        println("\nQubit labels: ", graphState.labels)
    end
end
