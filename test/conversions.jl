
# A -> B -> A'
# A == A'
# B is correct
# TODO: multiple inputs to loop through


@testset "GraphState to State conversion" begin
    A = [0 1 1 1 1; 1 0 0 0 0; 1 0 0 0 0; 1 0 0 0 0; 1 0 0 0 0]
    graph_state = GraphState(A)

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

    # Zero state 
    # GHZ state ~5 qubits
    # adjacency matrix with diagonal elements -> probably should ignore it, but we should see what happens :D 
    # error correction code words ?
    # Circuit for Stean code 
end


@testset "StabilizerState to GraphState conversion" begin
    # TODO: 
end
