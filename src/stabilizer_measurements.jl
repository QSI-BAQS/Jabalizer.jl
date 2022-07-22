# implement the row reduction procedure as per Gottesman
# randomly choose outcome
# update the state
# return outcome

measure_z(state::StabilizerState, qubit::Int) =
    pyconvert(Int, state.simulator.measure(qubit - 1))

function measure_x(state::StabilizerState, qubit::Int)
    # Convert to |+>, |-> basis
    H(qubit)(state)
    # Measure along z (now x)
    outcome = measure_z(state, qubit)
    # Return to computational basis
    H(qubit)(state)

    return outcome
end

function measure_y(state::StabilizerState, qubit::Int)

    # Map Y eigenstates to X eigenstates
    # Note that P^dagger = ZP
    state |> Z(qubit) |> P(qubit) |> H(qubit)
    # Measure along z (now y)
    outcome = measure_z(state, qubit)
    # Return to original basis
    state |> H(qubit) |> P(qubit)

    return outcome
end
