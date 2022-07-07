#TODO: modify these functions to use dispatching and singleton types

# implement the row reduction procedure as per Gottesman
# randomly choose outcome
# update the state
# return outcome

MeasureZ(state::StabilizerState, qubit::Int) =
    pyconvert(Int, state.simulator.measure(qubit - 1))

function MeasureX(state::StabilizerState, qubit::Int)
    # Convert to |+>, |-> basis
    H(qubit)(state)
    # Measure along z (now x)
    outcome = MeasureZ(state, qubit)
    # Return to computational basis
    H(qubit)(state)

    return outcome
end

function MeasureY(state::StabilizerState, qubit::Int)

    # Map Y eigenstates to X eigenstates
    # Note that P^dagger = ZP
    state |> Z(qubit) |> P(qubit) |> H(qubit)
    # Measure along z (now y)
    outcome = MeasureZ(state, qubit)
    # Return to original basis
    state |> H(qubit) |> P(qubit)

    return outcome
end
