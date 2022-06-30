@testset "Graph conversion" begin

    # Test GraphToState function
    adjacency = [0 1 0 0 0
        1 0 0 1 0
        0 0 0 1 0
        0 1 1 0 0
        0 0 0 0 0]

    state_1 = Jabalizer.GraphToState(adjacency)

    state_2 = Jabalizer.ZeroState(5)
    for i in 1:5
        Jabalizer.H(state_2, i)
    end
    Jabalizer.CZ(state_2, 1, 2)
    Jabalizer.CZ(state_2, 2, 4)
    Jabalizer.CZ(state_2, 3, 4)

    @test isequal(state_1, state_2)

    # Test converting state -> graph -> state
    # Prepare a 6 qubit GHZ state
    n = 6
    state = Jabalizer.ZeroState(n)
    Jabalizer.H(state, 1)
    for i in 1:n-1
        Jabalizer.CNOT(state, i, i + 1)
    end

    # Convert to graph state using ToGraph
    gstate, adj, lops = Jabalizer.ToGraph(state)

    # Generated expected Adjacency matrix
    expected_adj = falses(n, n)
    for i in 2:n
        expected_adj[i, 1] = 1
        expected_adj[1, i] = 1
    end

    # test that adjacency arrays match
    @test adj == expected_adj

    # test that the graph state generated from adjacency matrix matches
    # the orginal state

    new_gstate = Jabalizer.GraphToState(expected_adj)
    @test isequal(new_gstate, gstate)
end
