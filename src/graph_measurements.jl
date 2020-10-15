
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
    Isolate(state, qubit)
    return 1
end

function MeasureX(state::GraphState, qubit::Int64)::Int64
    Nb = findfirst(x -> x==1, state.A[qubit,:])
    if Nb != nothing
        LC(state, Nb)
        outcome = MeasureY(state, qubit)
        LC(state, Nb)
    end
    Isolate(state, qubit)
    return outcome
end

function MeasureY(state::GraphState, qubit::Int64)::Int64
    LC(state, qubit)
    Isolate(state, qubit)
    return 1
end
