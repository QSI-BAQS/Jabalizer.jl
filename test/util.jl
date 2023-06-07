

@testset "stim tableau to tableau" begin
    # TODO: Add the following tests:
    # 1. Check if the conversion works well.
    # TODO: What should the test cases be?
end


@testset "Update tableau" begin
    # TODO: Add the following tests:
    # 1. Check if update works correctly
    # TODO: What should the test cases be?
end

@testset "Generate random stabilizer state" begin
    # TODO:  Add more validity checks
    len = 5
    ss = rand(StabilizerState, len)
    @test ss.qubits == len
    @test length(ss.stabilizers) == len
    st = ss.stabilizers
    for i = 1:len
        stab = st[i]
        @test stab.qubits == len
        @test length(stab.X) == len
        @test length(stab.Z) == len
        @test 0 <= stab.phase <= 3
    end
end

@testset "Stabilizer State to Graph" begin
    # TODO: Add the following tests:
    # 1. Check if the conversion works back and forth
    # TODO: What should the test cases be?
end

@testset "Test Tab operations" begin
    # TODO: Add the following tests:
    # 1. Check if H works properly
    # 2. Check if RowAdd works properly
    # TODO: What should the test cases be?
end

@testset "Test Pauli - Tableau conversion" begin
    # TODO: Add the following tests:
    # 1. Check if the conversion works back and forth
    # TODO: What should the test cases be?
end

@testset "Test Pauli operations" begin
    # TODO: Add the following tests:
    # 1. Check if PauliProd works well
    # TODO: What should the test cases be?
end
