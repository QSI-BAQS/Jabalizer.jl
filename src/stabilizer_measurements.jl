#TODO: modify these functions to use dispatching and singleton types

# implement the row reduction procedure as per Gottesman
# randomly choose outcome
# update the state
# return outcome

MeasureZ(state::StabilizerState, qubit::Int) =
    pyconvert(Int, state.simulator.measure(qubit - 1))

function MeasureX(state::StabilizerState, qubit::Int)
    # Convert to |+>, |-> basis
    H(state, qubit)
    # Measure along z (now x)
    outcome = MeasureZ(state, qubit)
    # Return to computational basis
    H(state, qubit)

    return outcome
end

function MeasureY(state::StabilizerState, qubit::Int)

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

    return outcome
end
