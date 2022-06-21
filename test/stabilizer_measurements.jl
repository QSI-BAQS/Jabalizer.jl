# TODO: write tests
function MeasureZ(state::StabilizerState, qubit::Int64)::Int64
    # implement the row reduction procedure as per Gottesman
    # randomly choose outcome
    # update the state
    # return outcome
    outcome = state.simulator.measure(qubit - 1)
    return outcome
end

function MeasureX(state::StabilizerState, qubit::Int64)::Int64
    # Convert to |+>, |-> basis
    H(state, qubit)
    # Measure along z (now x)
    outcome = MeasureZ(state, qubit)
    # Return to computational basis
    H(state, qubit)

    return (outcome)
end

function MeasureY(state::StabilizerState, qubit::Int64)::Int64

    # Map Y eigenstates to X eigenstates
    # Note that P^dagger = ZP
    Z(state, qubit)
    P(state, qubit)
    H(state, qubit)
    # Measure along z (now y)
    outcome = MeasureZ(state, qubit)

    # Return to original basis
    H(state, qubit)
    P(state, qubit)

    return (outcome)
end