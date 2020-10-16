
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
    outcome = MeasureX(state, qubit, Nb)
    return outcome
end

function MeasureX(state::GraphState, qubit::Int64, Nb::Int64)::Int64
    if Nb != nothing
        LC(state, Nb)
    end
    outcome = MeasureY(state, qubit)
    if Nb != nothing
        LC(state, Nb)
    end
    return outcome
end

function MeasureY(state::GraphState, qubit::Int64)::Int64
    LC(state, qubit)
    Isolate(state, qubit)
    return 1
end
