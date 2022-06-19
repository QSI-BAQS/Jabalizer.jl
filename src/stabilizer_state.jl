# using PyCall
#
# stim = pyimport("stim")

"""
    Stabilizer state type.

qubits: number of qubits.
stabilizers: set of state stabilizers.
labels: qubit labels.

simulator: stim simulator
"""
mutable struct StabilizerState
    qubits::Int64
    stabilizers::Array{Stabilizer}
    labels::Array{String} # TODO: might not be needed anymore
    lost::Array{Int64} # TODO: might not be needed anymore
    simulator::PyObject

    StabilizerState() = new(0, [], [], [], stim.TableauSimulator())
    StabilizerState(n::Int64) = new(n, [], [], [], stim.TableauSimulator())
end
"""
    ZeroState(n::Int64)

Generates a state of n qubits in the +1 Z eigenstate.
"""

function ZeroState(n::Int64)
    state = StabilizerState(n)
    for i in 0:n-1
        state.simulator.z(i)
    end
    update_tableau(state)
    return (state)
    # return(TableauToState(hcat(zeros(Int64,n,n), Matrix(I,n,n), zeros(Int64,n,1))))
end



# This function is problematic with the the
# stim integration
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

# TODO: Are these still needed?

# """
# Get the index of a qubit by number.
# """
# function GetQubitLabel(state::StabilizerState, qubit::Int64)
#     return qubit
# end

# """
# Get the index of a qubit by label.
# """
# function GetQubitLabel(state::StabilizerState, qubit::String)
#     return findfirst(x -> x == qubit, state.labels)
# end

"""
    ToTableau(state)

Convert state to tableau form.
"""
function ToTableau(state::StabilizerState)::Array{Int64}
    tab = Int64[]
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
function print(state::StabilizerState, info::Bool=false, tab::Bool=false)
    update_tableau(state)
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
function gplot(state::StabilizerState; node_dist=5.0)
    graphState = GraphState(state)
    # Creates an anonymous function to allow changing the layout params
    # in gplot. The value of C determines distance between connected nodes.
    layout = (args...) -> spring_layout(args...; C=node_dist)
    gplot(Graph(graphState.A), nodelabel=1:state.qubits, layout=layout)
end


# TODO: This is confusing, as it takes adjacency matrix and not graph.
function GraphToState(A::Matrix{Int64})::StabilizerState
    n = size(A, 1)
    state = ZeroState(n)

    for i = 1:n
        H(state, i)
    end

    for i = 1:n
        for j = (i+1):n
            if A[i, j] == 1
                CZ(state, i, j)
            end
        end
    end
    Jabalizer.update_tableau(state)
    return state
end