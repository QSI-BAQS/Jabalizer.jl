

@testset "StabilizerState initialization" begin
    state = Jabalizer.StabilizerState()
    @test state.qubits == 0
    @test state.stabilizers == []


    for i in 1:4
        state = Jabalizer.StabilizerState(i)
        @test state.qubits == i
        @test state.stabilizers == []
    end

    # TODO: Jabalizer.ToTableau(state) doesn't work here, not sure if that's intentional?
end

@testset "ZeroState initialization" begin
    for i in 1:4
        target_tableau = zeros(Int8, (i, 2 * i + 1))
        for j in 1:i
            target_tableau[j, i+j] = 1
        end
        state = Jabalizer.ZeroState(i)
        @test state.qubits == i
        @test Jabalizer.ToTableau(state) == target_tableau
    end
end


@testset "Tableau <> State conversion" begin
    # TODO: Add the following tests:
    # 1. Checks whether the conversions both ways works well
    # TODO: come up with good test cases.
end


@testset "State to Tablue conversion" begin
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