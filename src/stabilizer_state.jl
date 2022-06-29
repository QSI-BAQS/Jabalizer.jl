"""
    Stabilizer state type

qubits:      number of qubits
stabilizers: set of state stabilizers
labels:      qubit labels
simulator:   simulator state
is_updated:  flag for whether or not Julia state has
             been updated to match Stim simulator state
"""
mutable struct StabilizerState
    qubits::Int
    stabilizers::Vector{Stabilizer}
    labels::Vector{String} # TODO: might not be needed anymore
    lost::Vector{Int} # TODO: might not be needed anymore
    simulator::Py
    is_updated::Bool

    StabilizerState(n::Int) = new(n, Stabilizer[], String[], Int[], stim.TableauSimulator(), true)
    StabilizerState() = StabilizerState(0)
end

const Tableau = Matrix{Int}

"""
    ZeroState(n::Int)

Generates a state of n qubits in the +1 Z eigenstate.
"""
function ZeroState(n::Int)
    state = StabilizerState(n)
    for i in 0:n-1
        state.simulator.z(i)
    end
    state.is_updated = false
    update_tableau(state)
    return state
end

# This function is problematic with the stim integration
# This doesn't seem to affect the simulator state at all
"""
Generate stabilizer from tableau
"""
function TableauToState(tab::AbstractArray{<:Integer})::StabilizerState
    qubits = Int((length(@view tab[1, :]) - 1) / 2)
    stabs = length(@view tab[:, 1])
    state = StabilizerState(qubits)

    for row = 1:stabs
        stab = Stabilizer(@view tab[row, :])
        push!(state.stabilizers, stab)
    end

    for n = 1:qubits
        push!(state.labels, string(n))
    end

    return state
end

"""
    ToTableau(state)

Convert state to tableau form.
"""
function ToTableau(state::StabilizerState)::Tableau
    tab = Int[]
    update_tableau(state)
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

function Base.print(io::IO, state::StabilizerState)
    update_tableau(state)
    for s in state.stabilizers
        println(io, s)
    end
    nothing
end

function Base.display(state::StabilizerState)
    update_tableau(state)
    println("Stabilizers (", length(state.stabilizers), ") stabilizers, ",
            state.qubits, ") qubits):")
    println(state)
    println("Qubit labels: ", state.labels)
    println("Lost qubits: ", state.lost)
end

"""
    gplot(state)

Plot the graph equivalent of a state.
"""
function GraphPlot.gplot(state::StabilizerState; node_dist=5.0)
    graphState = GraphState(state)
    # Creates an anonymous function to allow changing the layout params
    # in gplot. The value of C determines distance between connected nodes.
    layout = (args...) -> spring_layout(args...; C=node_dist)
    gplot(Graph(graphState.A), nodelabel=1:state.qubits, layout=layout)
end


# TODO: This is confusing, as it takes adjacency matrix and not graph.
function GraphToState(A::AbstractArray{<:Integer})::StabilizerState
    n = size(A, 1)
    state = ZeroState(n)
    for i = 1:n
        H(state, i)
    end
    for i = 1:n, j = (i+1):n
        A[i, j] == 1 && CZ(state, i, j)
    end
    update_tableau(state)
    return state
end


"""
    isequal(state_1::StabilizerState, state_2::StabilizerState)

Checks if two stabilizer states are equal.
"""
function Base.isequal(state_1::StabilizerState, state_2::StabilizerState)
    # Make sure the Julia representation matches the simulator state
    update_tableau(state_1)
    update_tableau(state_2)
    for (stab1, stab2) in zip(state_1.stabilizers, state_2.stabilizers)
        (stab1.X == stab2.X && stab1.Z == stab2.Z && stab1.phase == stab2.phase) ||
            return false
    end
    return true
end
