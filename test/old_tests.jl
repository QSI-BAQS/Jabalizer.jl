# TODO: Move some of these tests into more appropriate places.

"""
    Returns a 4 qubit StabilizerState representation of | 0 1 + - >
    with Tableau

    +ZIII
    -IZZZ
    +IIXI
    -IIIX
"""
function basis_state()
    # |0000>
    state = Jabalizer.ZeroState(4)

    # |0100>
    Jabalizer.X(state, 2)

    # |01+0>
    Jabalizer.H(state, 3)

    # |01+->
    Jabalizer.X(state, 4)
    Jabalizer.H(state, 4)

    # state = -|01+->

    return state
end

"""
    Returns the state  H_2^d H_1^c X_2^b X_1^a | 0 0 >, where arr = [a b c d].
    for arr in {0,1}^4 this generates all the computational and conjugate basis
    state combinations (e.g. |0 +> for [0 0 0 1] )

"""
function twoqubit_basis(arr)
    a, b, c, d = arr
    state = Jabalizer.ZeroState(2)

    if Bool(a)
        Jabalizer.X(state, 1)
    end

    if Bool(b)
        Jabalizer.X(state, 2)
    end

    if Bool(c)
        Jabalizer.H(state, 1)
    end

    if Bool(d)
        Jabalizer.H(state, 2)
    end


    return state
end

@testset "State initialisation" begin

    n = 10
    state = Jabalizer.ZeroState(n)
    X = zeros(Int64, n, n)
    Z = copy(X)
    for i in 1:n
        Z[i, i] = 1
    end
    phase = zeros(Int64, n, 1)
    tab = hcat(X, Z, phase)
    @test tab == Jabalizer.ToTableau(state)
end

@testset "Single qubit gates" begin

    # X tests
    state = basis_state()

    # apply X on all qubits
    for i in 1:4
        Jabalizer.X(state, i)
    end


    target_tab = [0 0 0 0 1 0 0 0 2
        0 0 0 0 0 1 0 0 0
        0 0 1 0 0 0 0 0 0
        0 0 0 1 0 0 0 0 2]

    @test target_tab == Jabalizer.ToTableau(state)


    # Y test
    state = basis_state()
    # Apply Y gate on all qubits
    for i in 1:4
        Jabalizer.Y(state, i)
    end

    target_tab = [0 0 0 0 1 0 0 0 2
        0 0 0 0 0 1 0 0 0
        0 0 1 0 0 0 0 0 2
        0 0 0 1 0 0 0 0 0]

    @test target_tab == Jabalizer.ToTableau(state)

    #Z test
    state = basis_state()
    # Apply Z gate on all qubits
    for i in 1:4
        Jabalizer.Z(state, i)
    end


    target_tab = [0 0 0 0 1 0 0 0 0
        0 0 0 0 0 1 0 0 2
        0 0 1 0 0 0 0 0 2
        0 0 0 1 0 0 0 0 0]

    @test target_tab == Jabalizer.ToTableau(state)

    # Hadamard test
    state = basis_state()
    # Apply H gate on all qubits
    for i in 1:4
        Jabalizer.H(state, i)
    end


    target_tab = [1 0 0 0 0 0 0 0 0
        0 1 0 0 0 0 0 0 2
        0 0 0 0 0 0 1 0 0
        0 0 0 0 0 0 0 1 2]

    @test target_tab == Jabalizer.ToTableau(state)

    # Phase gate test
    state = basis_state()
    # Apply P gate on all qubits
    for i in 1:4
        Jabalizer.P(state, i)
    end


    target_tab = [0 0 0 0 1 0 0 0 0
        0 0 0 0 0 1 0 0 2
        0 0 1 0 0 0 1 0 0
        0 0 0 1 0 0 0 1 2]

    @test target_tab == Jabalizer.ToTableau(state)
end

@testset "Two qubit gates" begin


    # CNOT test

    # Tableau dictionary contains result of applying CNOT to
    # H_2^d H_1^c X_2^b X_1^a | 0 0 > with key [a b c d]
    cnot_output = Dict(
        # |0 0> => |0 0>
        [0 0 0 0] => [0 0 1 0 0
            0 0 1 1 0],
        # |0 +> => |0 +>
        [0 0 0 1] => [0 0 1 0 0
            0 1 0 0 0],
        # |+ 0> => |00> + |11>
        [0 0 1 0] => [1 1 0 0 0
            0 0 1 1 0],
        # |+ +> => |++>
        [0 0 1 1] => [1 1 0 0 0
            0 1 0 0 0],
        # |0 1> => |0 1>
        [0 1 0 0] => [0 0 1 0 0
            0 0 1 1 2],
        # |0 -> => |0 1>
        [0 1 0 1] => [0 0 1 0 0
            0 1 0 0 2],
        # |0 -> => |0 ->
        [0 1 1 0] => [1 1 0 0 0
            0 0 1 1 2],
        # |+ -> => |- ->
        [0 1 1 1] => [1 1 0 0 0
            0 1 0 0 2],
        # |1 0> => |1 1>
        [1 0 0 0] => [0 0 1 0 2
            0 0 1 1 0],
        # |1 +> => |1 +>
        [1 0 0 1] => [0 0 1 0 2
            0 1 0 0 0],
        # |1 +> => |1 +>
        [1 0 1 0] => [1 1 0 0 2
            0 0 1 1 0],
        # |- +> => |- +>
        [1 0 1 1] => [1 1 0 0 2
            0 1 0 0 0],
        # |1 1> => |1 0>
        [1 1 0 0] => [0 0 1 0 2
            0 0 1 1 2],
        # |1 -> => -|1 ->
        [1 1 0 1] => [0 0 1 0 2
            0 1 0 0 2],
        # |- 1> => |0 1> - |10>
        [1 1 1 0] => [1 1 0 0 2
            0 0 1 1 2],
        # |- -> => |+ ->
        [1 1 1 1] => [1 1 0 0 2
            0 1 0 0 2],
    )


    # Loop generates all arrays [a, b, c, d] with a,b,c,d in {0,1}
    for bitarr in Base.Iterators.product(0:1, 0:1, 0:1, 0:1)
        # Initialise state
        state = twoqubit_basis(bitarr)

        Jabalizer.CNOT(state, 1, 2)

        a, b, c, d = bitarr

        # uncomment below block to see which bit sequence failed
        # println()
        # println([a,b,c,d])
        # println()

        @test cnot_output[[a b c d]] == Jabalizer.ToTableau(state)
    end

    # CZ test

    # Tableau dictionary contains result of applying CZ to
    # H_2^d H_1^c X_2^b X_1^a | 0 0 > with key [a b c d]
    cz_output = Dict(
        # |0 0> => |0 0>
        [0 0 0 0] => [0 0 1 0 0
            0 0 0 1 0],
        # |0 +> => |0 +>
        [0 0 0 1] => [0 0 1 0 0
            0 1 1 0 0],
        # |+ 0> => |00> + |11>
        [0 0 1 0] => [1 0 0 1 0
            0 0 0 1 0],
        # |+ +> => |++>
        [0 0 1 1] => [1 0 0 1 0
            0 1 1 0 0],
        # |0 1> => |0 1>
        [0 1 0 0] => [0 0 1 0 0
            0 0 0 1 2],
        # |0 -> => |0 1>
        [0 1 0 1] => [0 0 1 0 0
            0 1 1 0 2],
        # |+ 1> => |0 1> + |10>
        [0 1 1 0] => [1 0 0 1 0
            0 0 0 1 2],
        # |+ -> => |- ->
        [0 1 1 1] => [1 0 0 1 0
            0 1 1 0 2],
        # |1 0> => |1 1>
        [1 0 0 0] => [0 0 1 0 2
            0 0 0 1 0],
        # |1 +> => |1 +>
        [1 0 0 1] => [0 0 1 0 2
            0 1 1 0 0],
        # |- 0> => |00> - |11>
        [1 0 1 0] => [1 0 0 1 2
            0 0 0 1 0],
        # |- +> => |- +>
        [1 0 1 1] => [1 0 0 1 2
            0 1 1 0 0],
        # |1 1> => |1 0>
        [1 1 0 0] => [0 0 1 0 2
            0 0 0 1 2],
        # |1 -> => -|1 ->
        [1 1 0 1] => [0 0 1 0 2
            0 1 1 0 2],
        # |- 1> => |0 1> - |10>
        [1 1 1 0] => [1 0 0 1 2
            0 0 0 1 2],
        # |- -> => |+ ->
        [1 1 1 1] => [1 0 0 1 2
            0 1 1 0 2],
    )


    # Loop generates all arrays [a, b, c, d] with a,b,c,d in {0,1}
    for bitarr in Base.Iterators.product(0:1, 0:1, 0:1, 0:1)
        # Initialise state
        state = twoqubit_basis(bitarr)

        Jabalizer.CZ(state, 1, 2)

        a, b, c, d = bitarr

        # uncomment below block to see which bit sequence failed
        # println()
        # println([a,b,c,d])
        # println()

        @test cz_output[[a b c d]] == Jabalizer.ToTableau(state)
    end


end


@testset "Measurements" begin

    # Z measurement test

    # Test Mz on |0>
    state = Jabalizer.ZeroState(1)
    z = Jabalizer.MeasureZ(state, 1)

    # expected outout tableau
    tab = [0 1 0]

    @test z == 0
    @test Jabalizer.ToTableau(state) == tab

    # test Mz on |1>
    Jabalizer.X(state, 1)
    z = Jabalizer.MeasureZ(state, 1)

    # expected outout tableau
    tab = [0 1 2]

    @test z == 1
    @test Jabalizer.ToTableau(state) == tab


    # Xmeasurement test

    # test Mx on |+>
    state = Jabalizer.ZeroState(1)
    Jabalizer.H(state, 1)
    x = Jabalizer.MeasureX(state, 1)


    # expected outout tableau
    tab = [1 0 0]

    @test x == 0
    @test Jabalizer.ToTableau(state) == tab

    # test Mx on |->
    state = Jabalizer.ZeroState(1)
    Jabalizer.X(state, 1)
    Jabalizer.H(state, 1)
    x = Jabalizer.MeasureX(state, 1)

    # expected outout tableau
    tab = [1 0 2]

    @test x == 1
    @test Jabalizer.ToTableau(state) == tab


    # Y measurement test

    # test My on |+>_y
    state = Jabalizer.ZeroState(1)
    Jabalizer.H(state, 1)
    Jabalizer.P(state, 1)

    y = Jabalizer.MeasureY(state, 1)


    # expected outout tableau
    tab = [1 1 0]

    @test y == 0
    @test Jabalizer.ToTableau(state) == tab

    # test My on |->_y
    state = Jabalizer.ZeroState(1)
    Jabalizer.X(state, 1)
    Jabalizer.H(state, 1)
    Jabalizer.P(state, 1)

    y = Jabalizer.MeasureY(state, 1)


    # expected outout tableau
    tab = [1 1 2]

    @test y == 1
    @test Jabalizer.ToTableau(state) == tab


end

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

    #Jabalizer.update_tableau(state_2)
    @test Jabalizer.isequal(state_1, state_2)

    # Test converting state -> graph -> state
    # Prepare a 6 qubit GHZ state
    n = 6
    state = Jabalizer.ZeroState(n)
    Jabalizer.H(state, 1)
    for i in 1:n-1
        Jabalizer.CNOT(state, i, i + 1)
    end
    Jabalizer.update_tableau(state)

    # Convert to graph state using ToGraph
    gstate, adj, lops = Jabalizer.ToGraph(state)

    # Generated expected Adjacency matrix
    expected_adj = zeros(Int64, n, n)
    for i in 2:n
        expected_adj[i, 1] = 1
        expected_adj[1, i] = 1
    end

    # test that adjacency arrays match
    @test adj == expected_adj

    # test that the graph state generated from adjacency matrix matches
    # the orginal state

    new_gstate = Jabalizer.GraphToState(expected_adj)
    @test Jabalizer.isequal(new_gstate, gstate)
end
