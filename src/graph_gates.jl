"""
    Id(state, qubit)

Apply I gate to a State on qubit.
"""
function Id(state::GraphState, qubit)
end

# """
#     P(state, qubit)
#
# Apply P gate to a state on qubit.
# """
# function P(state::GraphState, qubit)
# end
#
# """
#     X(state, qubit)
#
# Apply X gate to a State.
# """
# function X(state::GraphState, qubit)
# end
#
# """
#     Y(state, qubit)
#
# Apply Y gate to a State.
# """
# function Y(state::GraphState, qubit)
# end
#
# """
#     Z(state, qubit)
#
# Apply Z gate to a State.
# """
# function Z(state::GraphState, qubit)
# end
#
# """
#     H(state, qubit)
#
# Apply H gate to a State.
# """
# function H(state::GraphState, qubit)
# end
#
# """
#     CNOT(state, control, target)
#
# Apply CNOT gate to a State.
# """
# function CNOT(state::GraphState, control, target)
# end

"""
    Disconnect(state, qubit)

Disconnect an qubit from the graph by deleting all neighbouring edges.
"""
function Isolate(state::GraphState, qubit)
    state.A[qubit,:] = zeros(Int64,state.qubits,1)
    state.A[:,qubit] = zeros(Int64,1,state.qubits)
end

"""
    LC(state, qubit)

Perform local complementation on a qubit's neighbourhood.
"""
function LC(state::GraphState, qubit)
    neighbours = findall(x -> x==1, state.A[qubit,:])

    for i in neighbours
        for j in neighbours
            if i != j
                state.A[i,j] = 1 - state.A[i,j]
            end
        end
    end
end

"""
    CZ(state, control, target)

Apply CZ gate to a State.
"""
function CZ(state::GraphState, control, target)
    state.A[control, target] = 1 - state.A[control, target]
    state.A[target, control] = 1 - state.A[target, control]
end

"""
    SWAP(state, first, second)
Apply SWAP gate to a State.
"""
function SWAP(state::GraphState, qubit1, qubit2)
    state.A[qubit1,:], state.A[qubit2,:] = state.A[qubit2,:], stateA[qubit1,:]
    state.A[:,qubit1], state.A[:,qubit2] = state.A[:,qubit2], stateA[:,qubit1]
end
