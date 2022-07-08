using LinearAlgebra

const graph_state_test_cases = (
    ("star", [0 1 1 1 1; 1 0 0 0 0; 1 0 0 0 0; 1 0 0 0 0; 1 0 0 0 0]),
    ("diagonal", [1 0 0; 0 1 0; 0 0 1]),
    ("empty", [0 0 0; 0 0 0; 0 0 0]),
)

@testset "GraphState to State conversion" begin
    for (name, A) in graph_state_test_cases
        @testset "Graph $name" begin
            graph_state = GraphState(A)

            stabilizer_state = StabilizerState(graph_state)

            n_qubits = size(A)[1]
            target_x_matrix = Diagonal(ones(n_qubits))
            # Target Z matrix is the same as the adjacency matrix, but with diagonal elements ignored
            target_z_matrix = A
            target_z_matrix[diagind(A)] .= 0
            target_phase = zeros(n_qubits)


            intermediate_tableau = to_tableau(stabilizer_state)
            @test intermediate_tableau[:, 1:n_qubits] == target_x_matrix
            @test intermediate_tableau[:, n_qubits+1:2*n_qubits] == target_z_matrix
            @test intermediate_tableau[:, 2*n_qubits+1] == target_phase

            recovered_graph_state = GraphState(stabilizer_state)

            @test graph_state.qubits == recovered_graph_state.qubits
            @test graph_state.A == recovered_graph_state.A
            # # TODO: to be replaced with the following once the equality for GraphState works properly
            # @test graph_state == recovered_graph_state

        end
    end
end