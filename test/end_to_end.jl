@testset "E2E Jabalizer test" begin

    circuit = cirq_circuit.build_circuit()

    gates_to_decomp = [cirq.T, cirq.T^-1]

    iicm_circuit = icm.icm_circuit(circuit, gates_to_decomp)


    iicm_length = length(iicm_circuit.all_qubits())
    state = zero_state(iicm_length)


    Jabalizer.execute_cirq_circuit(state, iicm_circuit)


    (g, A, seq) = to_graph(state)
    Jabalizer.gplot(g)

    @test target_tab == to_tableau(state)


end
