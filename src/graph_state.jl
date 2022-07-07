"""
    Graph state type

Type for a stabilizer state constrained to graph form.
"""
mutable struct GraphState
    qubits::Int
    A::Matrix{Int} # TODO: Rename "A" to something more verbose, e.g. "adj_matrix".

    GraphState() = new(0, Matrix{Int}(undef, 0, 0))
    GraphState(A::AbstractMatrix{<:Integer}) = new(size(A, 1), A)
    GraphState(state::StabilizerState) = new(state.qubits, to_graph(state)[2])
end

StabilizerState(graphState::GraphState) = graph_to_state(graphState.A)

"""
    gplot(graphState)

Plot the graph of a GraphState.
"""
function GraphPlot.gplot(graphState::GraphState; node_dist=5.0)

    # Creates an anonymous function to allow changing the layout params
    # in gplot. The value of C determines distance between connected nodes.
    layout = (args...) -> spring_layout(args...; C=node_dist)
    gplot(Graph(graphState.A), nodelabel=1:graphState.qubits)
end

function Base.display(graphState::GraphState)
    println("Adjacency matrix for ", graphState.qubits, " qubits:\n")
    display(graphState.A)
end

Base.print(io::IO, graphState::GraphState) = print(io, graphState.A)
