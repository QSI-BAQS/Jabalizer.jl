
"""
    FusionI(state, first, second)

Apply type-I fusion gate to a state.
"""
function FusionI(state::StabilizerState, qubit1, qubit2)
     for s in state.stabilizers
         FusionI(s, GetQubitLabel(state, qubit1), GetQubitLabel(state, qubit2))
     end
end

"""
    FusionII(state, first, second)

Apply type-II fusion gate to a state.
"""
function FusionII(state::StabilizerState, qubit1, qubit2)
     for s in state.stabilizers
         FusionII(s, GetQubitLabel(state, qubit1), GetQubitLabel(state, qubit2))
     end
end

function MeasureZ(state::StabilizerState, qubit::Int64)::Int64
    # implement the row reduction procedure as per Gottesman
    # randomly choose outcome
    # update the state
    # return outcome
end

function MeasureX(state::StabilizerState, qubit::Int64)::Int64
    H(state, qubit)
    outcome = MeasureZ(state, qubit)
    return(outcome)
end

function MeasureY(state::StabilizerState, qubit::Int64)::Int64
    P(state, qubit)
    outcome = MeasureX(state, qubit)
    return(outcome)
end
