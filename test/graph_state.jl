using Test
using Jabalizer


@testset "GraphState initialization" begin
    # Check if initialization of empty Graph state works
    graph_state = Jabalizer.GraphState() # Why simply GraphState() doesn't work?

    @test graph_state.qubits == 0
    @test graph_state.A isa AbstractMatrix{<:Integer}
    @test isempty(graph_state.A)

    # Check if initialization from an adjacency matrix works 
    A = [0 1; 1 0]
    graph_state = Jabalizer.GraphState(A)

    @test graph_state.qubits == 2
    @test graph_state.A == A

    stabilizer_state = Jabalizer.ZeroState(4)
    graph_state = Jabalizer.GraphState(stabilizer_state)
    A = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0]

    @test graph_state.qubits == 4
    @test graph_state.A == A

end