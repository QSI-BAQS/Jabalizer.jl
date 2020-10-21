
"""
    FusionI(state, first, second)

Apply type-I fusion gate to a state.
"""
function FusionI(state::StabilizerState, qubit1::Int64, qubit2::Int64)::Int64
    CNOT(state, qubit1, qubit2)
    phase = MeasureX(state, qubit1)
    return phase
end

"""
    FusionII(state, first, second)

Apply type-II fusion gate to a state.
"""
function FusionII(state::StabilizerState, qubit1::Int64, qubit2::Int64)
     H(state, qubit1)
     H(state, qubit2)
     CNOT(state, qubit1, qubit2)
     parity = MeasureZ(state, qubit2)
     if parity == 1
         H(state, qubit1)
     end
     phase = MeasureX(state, qubit1)
     return (parity, phase)
end

function MeasureZ(state::StabilizerState, qubit::Int64)::Int64
    # implement the row reduction procedure as per Gottesman
    # randomly choose outcome
    # update the state
    # return outcome
    return 0
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
