# TODO: Id fails cause I deleted GetQubitLabel. Don't know how to fix it.
# TODO: 

function two_qubit_basis_state(arr)
    """
    Returns the state  H_2^d H_1^c X_2^b X_1^a | 0 0 >, where arr = [a b c d].
    for arr in {0,1}^4 this generates all the computational and conjugate basis
    state combinations (e.g. |0 +> for [0 0 0 1] )

    """
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

"""
Generates one-qubit states used for testing
"""
function generate_one_qubit_state(state_str)
    if state_str == "0"
        return Jabalizer.ZeroState(1)
    elseif state_str == "1"
        one_state = Jabalizer.ZeroState(1)
        Jabalizer.X(one_state, 1)
        return one_state
    elseif state_str == "+"
        plus_state = Jabalizer.ZeroState(1)
        Jabalizer.H(plus_state, 1)
        return plus_state
    elseif state_str == "-"
        minus_state = Jabalizer.ZeroState(1)
        Jabalizer.X(minus_state, 1)
        Jabalizer.H(minus_state, 1)
        return minus_state
    end
end

function generate_two_qubit_state(arr)
    """
    Returns the state  H_2^d H_1^c X_2^b X_1^a | 0 0 >, where arr = [a b c d].
    for arr in {0,1}^4 this generates all the computational and conjugate basis
    state combinations (e.g. |0 +> for [0 0 0 1] )

    """
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

# TODO: Jabalizer.I is missing
one_qubit_test_cases = (
    ("0", Jabalizer.P, [0 1 0]),
    ("0", Jabalizer.X, [0 1 2]),
    ("0", Jabalizer.Y, [0 1 2]),
    ("0", Jabalizer.Z, [0 1 0]),
    ("0", Jabalizer.H, [1 0 0]),
    ("1", Jabalizer.P, [0 1 2]),
    ("1", Jabalizer.X, [0 1 0]),
    ("1", Jabalizer.Y, [0 1 0]),
    ("1", Jabalizer.Z, [0 1 2]),
    ("1", Jabalizer.H, [1 0 2]),
    ("+", Jabalizer.P, [1 1 0]),
    ("+", Jabalizer.X, [1 0 0]),
    ("+", Jabalizer.Y, [1 0 2]),
    ("+", Jabalizer.Z, [1 0 2]),
    ("+", Jabalizer.H, [0 1 0]),
    ("-", Jabalizer.P, [1 1 2]),
    ("-", Jabalizer.X, [1 0 2]),
    ("-", Jabalizer.Y, [1 0 0]),
    ("-", Jabalizer.Z, [1 0 0]),
    ("-", Jabalizer.H, [0 1 2]),
)

@testset "One qubit gates" begin
    for (state_str, op, target_tableau) in one_qubit_test_cases
        @testset "Gate $op on state $state_str" begin
            state = generate_one_qubit_state(state_str)
            op(state, 1)
            @test target_tableau == Jabalizer.ToTableau(state)
        end
    end
end


@testset "Two qubit gates" begin
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
    swap_output = Dict(
        [0 0 0 0] => [0 0 0 1 0; 0 0 1 0 0],
        [0 0 0 1] => [0 0 0 1 0; 1 0 0 0 0],
        [0 0 1 0] => [0 1 0 0 0; 0 0 1 0 0],
        [0 0 1 1] => [0 1 0 0 0; 1 0 0 0 0],
        [0 1 0 0] => [0 0 0 1 0; 0 0 1 0 2],
        [0 1 0 1] => [0 0 0 1 0; 1 0 0 0 2],
        [0 1 1 0] => [0 1 0 0 0; 0 0 1 0 2],
        [0 1 1 1] => [0 1 0 0 0; 1 0 0 0 2],
        [1 0 0 0] => [0 0 0 1 2; 0 0 1 0 0],
        [1 0 0 1] => [0 0 0 1 2; 1 0 0 0 0],
        [1 0 1 0] => [0 1 0 0 2; 0 0 1 0 0],
        [1 0 1 1] => [0 1 0 0 2; 1 0 0 0 0],
        [1 1 0 0] => [0 0 0 1 2; 0 0 1 0 2],
        [1 1 0 1] => [0 0 0 1 2; 1 0 0 0 2],
        [1 1 1 0] => [0 1 0 0 2; 0 0 1 0 2],
        [1 1 1 1] => [0 1 0 0 2; 1 0 0 0 2],
    )

    # Loop generates all arrays [a, b, c, d] with a,b,c,d in {0,1}
    for bitarr in Base.Iterators.product(0:1, 0:1, 0:1, 0:1)
        @testset "CNOT for array: $bitarr " begin
            state = generate_two_qubit_state(bitarr)
            Jabalizer.CNOT(state, 1, 2)
            a, b, c, d = bitarr
            @test cnot_output[[a b c d]] == Jabalizer.ToTableau(state)
        end

        @testset "CZ for array: $bitarr " begin
            state = generate_two_qubit_state(bitarr)
            Jabalizer.CZ(state, 1, 2)
            a, b, c, d = bitarr
            @test cz_output[[a b c d]] == Jabalizer.ToTableau(state)
        end

        @testset "SWAP for array: $bitarr " begin
            state = generate_two_qubit_state(bitarr)
            Jabalizer.SWAP(state, 1, 2)
            a, b, c, d = bitarr
            @test swap_output[[a b c d]] == Jabalizer.ToTableau(state)
        end

    end
end