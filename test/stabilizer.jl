
@testset "Stabilizer initialization" begin

    @testset "Empty stabilizer" begin
        stabilizer = Stabilizer()
        @test stabilizer.qubits == 0
        @test stabilizer.X == []
        @test stabilizer.Z == []
        @test stabilizer.phase == 0
    end

    for i in 1:5
        @testset "Empty stabilizer with n = $i" begin
            stabilizer = Stabilizer(i)
            @test stabilizer.qubits == i
            @test stabilizer.X == zeros(i)
            @test stabilizer.Z == zeros(i)
            @test stabilizer.phase == 0
        end
    end

    @testset "Stabilizer from tableau" begin
        tableau = [0 1 0]
        stabilizer = Stabilizer(tableau)
        @test stabilizer.qubits == 1
        @test stabilizer.X == [0]
        @test stabilizer.Z == [1]
        @test stabilizer.phase == 0

        tableau = [0 1 1 0 2; 1 0 0 1 2]
        stabilizer = Stabilizer(tableau)
        @test stabilizer.qubits == 2
        @test stabilizer.X == [0, 1]
        @test stabilizer.Z == [1, 0]
        @test stabilizer.phase == 2

    end
end

@testset "Stabilizer to Tableau conversion" begin
    # TODO: Add the following tests:
    # 1. Check if the conversion works (both ways?)
    # TODO: what are some good test cases?
end


@testset "Stabilizer operations" begin
    # TODO: This is failing
    # tableau = [0 0 1 0 0]
    # stabilizer = Stabilizer(tableau)
    # adjoint_stabilizer = adjoint(stabilizer)
    # @test adjoint_stabilizer.qubits == stabilizer.qubits
    # @test adjoint_stabilizer.X == stabilizer.X
    # @test adjoint_stabilizer.Z == stabilizer.Z
    # @test adjoint_stabilizer.phase == 0




    # TODO: Add the following tests:
    # 1. Check if adjoint operation works well
    # 2. Check if multiplication works well
    # TODO: come up with some test cases.

end
