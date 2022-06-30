@testset "E2E Jabalizer test" begin

    circuit = cirq_circuit.build_circuit()

    gates_to_decomp = [cirq.T, cirq.T^-1]

    iicm_circuit = icm.icm_circuit(circuit, gates_to_decomp)


    iicm_length = length(iicm_circuit.all_qubits())
    state = Jabalizer.ZeroState(iicm_length)


    Jabalizer.execute_cirq_circuit(state, iicm_circuit)


    (g, A, seq) = Jabalizer.ToGraph(state)
    Jabalizer.gplot(g)

    # TODO
    @test target_tab == Jabalizer.ToTableau(state)


end
