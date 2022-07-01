using Test
using Jabalizer


@testset "GraphState initialization" begin
    # Check if initialization of empty Graph state works
    graph_state = GraphState() # Why simply GraphState() doesn't work?

    @test graph_state.qubits == 0
    @test graph_state.A isa AbstractMatrix{<:Integer}
    @test isempty(graph_state.A)

    # Check if initialization from an adjacency matrix works 
    A = [0 1; 1 0]
    graph_state = GraphState(A)

    @test graph_state.qubits == 2
    @test graph_state.A == A

    stabilizer_state = Jabalizer.ZeroState(4)
    graph_state = GraphState(stabilizer_state)
    A = [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0]
    @test graph_state.qubits == 4
    @test graph_state.A == A
end


@testset "GraphState to State conversion" begin
    A = [0 1 1 1 1; 1 0 0 0 0; 1 0 0 0 0; 1 0 0 0 0; 1 0 0 0 0]
    graph_state = GraphState(A)    # TODO: Add the following tests

    stabilizer_state = StabilizerState(graph_state)

    # TODO: test whether StabilizerState is what we expect it to be

    recovered_graph_state = GraphState(stabilizer_state)

    @test graph_state.qubits == recovered_graph_state.qubits
    @test graph_state.A == recovered_graph_state.A
    # TODO: to be replaced with the following once "labels" and "lost" are removed
    # @test graph_state == recovered_graph_state


    # 1. Check if the conversion works
    # TODO: what should be some test cases here?
    # E.g. star graph -> GHZ state
    @test graph_state.qubits == 5
    @test graph_state.A == A

end
