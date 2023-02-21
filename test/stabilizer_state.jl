

@testset "StabilizerState initialization" begin
    state = StabilizerState()
    @test state.qubits == 0
    @test isempty(state.stabilizers)


    for i in 1:4
        state = StabilizerState(i)
        @test state.qubits == i
        @test isempty(state.stabilizers)
    end
end

@testset "zero_state initialization" begin
    for i in 1:4
        target_tableau = zeros(Int8, (i, 2 * i + 1))
        for j in 1:i
            target_tableau[j, i+j] = 1
        end
        state = zero_state(i)
        @test state.qubits == i
        @test to_tableau(state) == target_tableau
    end
end


@testset "Tableau <> State conversion" begin
    # TODO: Add the following tests:
    # 1. Checks whether the conversions both ways works well
    # TODO: come up with good test cases.
end


@testset "State to Tableau conversion" begin
    # TODO: Add the following tests:
    # 1. Checks whether the conversions works well
    # TODO: come up with good test cases.
end

@testset "StabilizerState to string conversion" begin
    # TODO: Add the following tests:
    # 1. Checks whether the conversions works well
end

@testset "Graph to StabilizerState conversion" begin
    # TODO: Add the following tests:
    # 1. Check if works
    # TODO: come up with some good test cases.
end
