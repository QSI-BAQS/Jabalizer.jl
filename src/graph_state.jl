"""
    Graph state type

Type for a stabilizer state constrained to graph form.
"""
mutable struct GraphState
    qubits::Int
    A::Matrix{Int} # TODO: Rename "A" to something more verbose, e.g. "adj_matrix".
    labels::Vector{String} #TODO: might not be needed anymore (lost as well)
    lost::Vector{Int} # TODO: Class attributes should be described in the docstring

    GraphState() = new(0, Matrix{Int}(undef,0,0), String[], Int[])
    GraphState(state::StabilizerState) =
        new(state.qubits, ToGraph(state)[2], state.labels)
    function GraphState(A::AbstractArray{<:Integer})
        qubits = size(A, 1)
        new(qubits, A, String[], zeros(Int, qubits))
    end
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
function GraphPlot.gplot(graphState::GraphState; node_dist=5.0)

    # Creates an anonymous function to allow changing the layout params
    # in gplot. The value of C determines distance between connected nodes.
    layout = (args...) -> spring_layout(args...; C=node_dist)
    gplot(Graph(graphState.A), nodelabel=1:graphState.qubits)
end

function Base.display(graphState::GraphState)
    println("Adjacency matrix for ", graphState.qubits, " qubits:\n")
    display(graphState.A)
    println("\nQubit labels: ", graphState.labels)
end

Base.print(io::IO, graphState::GraphState) = print(io, graphState.A)
