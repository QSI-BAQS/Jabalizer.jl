@testset "Graph conversion tests" begin

    state = zero_state(5)

    for i in 1:state.qubits
        H(i)(state)
    end

    CZ(1,2)(state)
    H(1)(state)
    CNOT(1,2)(state)
    CZ(2,3)(state)
    CNOT(3,4)(state)
    P(4)(state)
    Z(4)(state)
    CZ(4,5)(state)
    H(5)(state)

    gs, adj, mseq = Jabalizer.fast_to_graph(state)

    A = [0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 1; 0 0 0 1 0]
    M = [("H", 2), ("H", 5), ("Pdag", 4), ("Z", 4)]

    @test adj == A
    @test mseq == M

end
