# TODO: Id fails cause I deleted GetQubitLabel. Don't know how to fix it.

"""
Generates one-qubit states used for testing
"""
function generate_one_qubit_state(state_chr)

    state = zero_state(1)
    (state_chr == '1' || state_chr == '-') && X(1)(state)
    (state_chr == '+' || state_chr == '-') && H(1)(state)
    return state
end

"""
Returns the state  H_2^d H_1^c X_2^b X_1^a | 0 0 >, where arr = [a b c d].
for arr in {0,1}^4 this generates all the computational and conjugate basis
state combinations (e.g. |0 +> for [0 0 0 1] )

"""
function generate_two_qubit_state(arr)
    a, b, c, d = arr
    state = zero_state(2)

    Bool(a) && X(1)(state)
    Bool(b) && X(2)(state)
    Bool(c) && H(1)(state)
    Bool(d) && H(2)(state)

    return state
end

# TODO: Jabalizer.I is missing
const one_qubit_test_cases =
    (('0', P, [0 1 0]),
     ('0', X, [0 1 2]),
     ('0', Y, [0 1 2]),
     ('0', Z, [0 1 0]),
     ('0', H, [1 0 0]),
     ('1', P, [0 1 2]),
     ('1', X, [0 1 0]),
     ('1', Y, [0 1 0]),
     ('1', Z, [0 1 2]),
     ('1', H, [1 0 2]),
     ('+', P, [1 1 0]),
     ('+', X, [1 0 0]),
     ('+', Y, [1 0 2]),
     ('+', Z, [1 0 2]),
     ('+', H, [0 1 0]),
     ('-', P, [1 1 2]),
     ('-', X, [1 0 2]),
     ('-', Y, [1 0 0]),
     ('-', Z, [1 0 0]),
     ('-', H, [0 1 2]))

@testset "One qubit gates" begin
    for (state_chr, op, target_tableau) in one_qubit_test_cases
        @testset "Gate $op on state $state_chr" begin
            state = generate_one_qubit_state(state_chr)
            op(1)(state)
            @test target_tableau == to_tableau(state)
        end
    end
end

# Tableau dictionary contains result of applying CNOT to
# H_2^d H_1^c X_2^b X_1^a | 0 0 > with key [a b c d]

const cnot_output =
    Dict((0,0,0,0) => [0 0 1 0 0; 0 0 1 1 0], # |0 0> => |0 0>
         (0,0,0,1) => [0 0 1 0 0; 0 1 0 0 0], # |0 +> => |0 +>
         (0,0,1,0) => [1 1 0 0 0; 0 0 1 1 0], # |+ 0> => |00> + |11>
         (0,0,1,1) => [1 1 0 0 0; 0 1 0 0 0], # |+ +> => |++>
         (0,1,0,0) => [0 0 1 0 0; 0 0 1 1 2], # |0 1> => |0 1>
         (0,1,0,1) => [0 0 1 0 0; 0 1 0 0 2], # |0 -> => |0 1>
         (0,1,1,0) => [1 1 0 0 0; 0 0 1 1 2], # |0 -> => |0 ->
         (0,1,1,1) => [1 1 0 0 0; 0 1 0 0 2], # |+ -> => |- ->
         (1,0,0,0) => [0 0 1 0 2; 0 0 1 1 0], # |1 0> => |1 1>
         (1,0,0,1) => [0 0 1 0 2; 0 1 0 0 0], # |1 +> => |1 +>
         (1,0,1,0) => [1 1 0 0 2; 0 0 1 1 0], # |1 +> => |1 +>
         (1,0,1,1) => [1 1 0 0 2; 0 1 0 0 0], # |- +> => |- +>
         (1,1,0,0) => [0 0 1 0 2; 0 0 1 1 2], # |1 1> => |1 0>
         (1,1,0,1) => [0 0 1 0 2; 0 1 0 0 2], # |1 -> => -|1 ->
         (1,1,1,0) => [1 1 0 0 2; 0 0 1 1 2], # |- 1> => |0 1> - |10>
         (1,1,1,1) => [1 1 0 0 2; 0 1 0 0 2]) # |- -> => |+ ->

const cz_output =
    Dict((0,0,0,0) => [0 0 1 0 0; 0 0 0 1 0], # |0 0> => |0 0>
         (0,0,0,1) => [0 0 1 0 0; 0 1 1 0 0], # |0 +> => |0 +>
         (0,0,1,0) => [1 0 0 1 0; 0 0 0 1 0], # |+ 0> => |00> + |11>
         (0,0,1,1) => [1 0 0 1 0; 0 1 1 0 0], # |+ +> => |++>
         (0,1,0,0) => [0 0 1 0 0; 0 0 0 1 2], # |0 1> => |0 1>
         (0,1,0,1) => [0 0 1 0 0; 0 1 1 0 2], # |0 -> => |0 1>
         (0,1,1,0) => [1 0 0 1 0; 0 0 0 1 2], # |+ 1> => |0 1> + |10>
         (0,1,1,1) => [1 0 0 1 0; 0 1 1 0 2], # |+ -> => |- ->
         (1,0,0,0) => [0 0 1 0 2; 0 0 0 1 0], # |1 0> => |1 1>
         (1,0,0,1) => [0 0 1 0 2; 0 1 1 0 0], # |1 +> => |1 +>
         (1,0,1,0) => [1 0 0 1 2; 0 0 0 1 0], # |- 0> => |00> - |11>
         (1,0,1,1) => [1 0 0 1 2; 0 1 1 0 0], # |- +> => |- +>
         (1,1,0,0) => [0 0 1 0 2; 0 0 0 1 2], # |1 1> => |1 0>
         (1,1,0,1) => [0 0 1 0 2; 0 1 1 0 2], # |1 -> => -|1 ->
         (1,1,1,0) => [1 0 0 1 2; 0 0 0 1 2], # |- 1> => |0 1> - |10>
         (1,1,1,1) => [1 0 0 1 2; 0 1 1 0 2]) # |- -> => |+ ->

const swap_output =
    Dict((0,0,0,0) => [0 0 0 1 0; 0 0 1 0 0],
         (0,0,0,1) => [0 0 0 1 0; 1 0 0 0 0],
         (0,0,1,0) => [0 1 0 0 0; 0 0 1 0 0],
         (0,0,1,1) => [0 1 0 0 0; 1 0 0 0 0],
         (0,1,0,0) => [0 0 0 1 0; 0 0 1 0 2],
         (0,1,0,1) => [0 0 0 1 0; 1 0 0 0 2],
         (0,1,1,0) => [0 1 0 0 0; 0 0 1 0 2],
         (0,1,1,1) => [0 1 0 0 0; 1 0 0 0 2],
         (1,0,0,0) => [0 0 0 1 2; 0 0 1 0 0],
         (1,0,0,1) => [0 0 0 1 2; 1 0 0 0 0],
         (1,0,1,0) => [0 1 0 0 2; 0 0 1 0 0],
         (1,0,1,1) => [0 1 0 0 2; 1 0 0 0 0],
         (1,1,0,0) => [0 0 0 1 2; 0 0 1 0 2],
         (1,1,0,1) => [0 0 0 1 2; 1 0 0 0 2],
         (1,1,1,0) => [0 1 0 0 2; 0 0 1 0 2],
         (1,1,1,1) => [0 1 0 0 2; 1 0 0 0 2])

@testset "Two qubit gates" begin
    # Loop generates all arrays (a, b, c, d) with a,b,c,d in {0,1}
    for bitarr in Base.Iterators.product(0:1, 0:1, 0:1, 0:1)
        @testset "CNOT for array: $bitarr " begin
            state = generate_two_qubit_state(bitarr)
            CNOT(1, 2)(state)
            @test cnot_output[bitarr] == to_tableau(state)
        end

        @testset "CZ for array: $bitarr " begin
            state = generate_two_qubit_state(bitarr)
            CZ(1, 2)(state)
            @test cz_output[bitarr] == to_tableau(state)
        end

        @testset "SWAP for array: $bitarr " begin
            state = generate_two_qubit_state(bitarr)
            SWAP(1, 2)(state)
            @test swap_output[bitarr] == to_tableau(state)
        end
    end
end
