
"""
    FusionI(state, first, second)

Apply type-I fusion gate to a state.
"""
function FusionI(state::GraphState, qubit1, qubit2)
end

"""
    FusionII(state, first, second)

Apply type-II fusion gate to a state.
"""
function FusionII(state::GraphState, qubit1, qubit2)
end

function MeasureZ(state::GraphState, qubit::Int64)::Int64
    Disconnect(state, qubit)
    return 1
end

function MeasureX(state::GraphState, qubit::Int64)::Int64
    return 1
end

function MeasureY(state::GraphState, qubit::Int64)::Int64
    LC(state, qubit)
    Disconnect(state, qubit)
    return 1
end
