using Test

using Jabalizer


@testset "Executing cirq circuits" begin
    # TODO: Add the following tests:
    # 1. Check if it fails if the circuit has gates that are not allowed
    # 2. Check if it correctly transoforms all the different combinations of stabilizer state and gates
    # 3. Check if it correctly skips the measurement gate
    # 4. Check if it works correctly if the size of the state doesn't match the size of the circuit

    # Input Circuits -> generate canonical clifford circuits, e.g.: GHZ state, trivial circuits
    # Input states -> Zero states, 
    # Output states -> 
    # See cases in runtests.jl

    # gate_map = Dict(cirq.I => Jabalizer.Id,
    #     cirq.H => Jabalizer.H,
    #     cirq.X => Jabalizer.X,
    #     cirq.Y => Jabalizer.Y,
    #     cirq.Z => Jabalizer.Z,
    #     cirq.CNOT => Jabalizer.CNOT,
    #     cirq.SWAP => Jabalizer.SWAP,
    #     cirq.S => Jabalizer.P,
    #     cirq.CZ => Jabalizer.CZ


    # TEST CASE 1:
    # Input -> circuit(I(0))
    # Outputs -> Zero state
    # Compare ToTableau(state) == target_tableau

    # TEST CASE 2:
    # Input -> circuit(H(0))
    # Outputs -> STH

end
