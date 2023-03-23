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
     # Should really add all the new one-qubit gates here

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

@testset "Gate Aliases" begin
    @test gate_map["H_XZ"] == H
    @test gate_map["P"] == S
    @test gate_map["PHASE"] == S
    @test gate_map["SQRT_Z"] == S
    @test gate_map["SQRT_Z_DAG"] == S_DAG
    @test gate_map["S^-1"] == S_DAG
    @test gate_map["S_Dagger"] == S_DAG
    @test gate_map["CX"] == CNOT
    @test gate_map["ZCX"] == CNOT
    @test gate_map["ZCY"] == CY
    @test gate_map["ZCZ"] == CZ
end

const gate1_decomp =
    [(C_XYZ, "SSSH"),
     (C_ZYX, "HS"),
     (H_XY,  "HSSHS"),
     (H_YZ,  "HSHSS"),
     (S_DAG, "SSS"),
     (SQRT_X, "HSH"),
     (SQRT_X_DAG, "SHS"),
     (SQRT_Y,     "SSH"),
     (SQRT_Y_DAG, "HSS")]

@testset "Single qubit operations" begin
    for (gate, oplist) in gate1_decomp, state_chr in ('0', '1', '+', '-')
        @testset "Gate $gate on state $state_chr" begin
            state1 = generate_one_qubit_state(state_chr)
            state2 = generate_one_qubit_state(state_chr)
            for op in oplist
                (op == 'H' ? H : S)(1)(state1)
            end
            gate(1)(state2)
            @test state1 == state2
        end
    end
end

const gate2_decomp =
    [(CY,     (S(2), S(2), S(2), CNOT(1,2), S(2))),
     (CZ,     (H(2), CNOT(1,2), H(2))),
     (XCX,    (H(1), CNOT(1,2), H(1))),
     (XCY,    (H(1), S(2), S(2), S(2), CNOT(1,2), H(1), S(2))),
     (XCZ,    (CNOT(2,1),)),
     (YCX,    (S(1), S(1), S(1), H(2), CNOT(2,1), S(1), H(2))),
     (YCY,    (S(1), S(1), S(1), S(2), S(2), S(2),  H(1), CNOT(1,2), H(1), S(1), S(2))),
     (YCZ,    (S(1), S(1), S(1), CNOT(2, 1), S(1))),
     # stim ops that don't have function calls
     #(CXSWAP, (CNOT(2,1), CNOT(1,2))),
     #(SWAPCX, (CNOT(1,2), CNOT(2,1))),
     (ISWAP,  (H(1), S(1), S(1), S(1), CNOT(1,2), S(1), CNOT(2,1), H(2), S(2), S(1))),
     (ISWAP_DAG,
              (S(1), S(1), S(1), S(2), S(2), S(2),  H(2), CNOT(2,1),
               S(1), S(1), S(1), CNOT(1,2), S(1), H(1))),
#=
     # stim ops that don't have function calls
     (SQRT_XX,
              (H(1), CNOT(1,2), H(2), S(1), S(2),  H(1), H(2))),
     (SQRT_XX_DAG,
              (H(1), CNOT(1,2), H(2), S(1), S(1), S(1), S(2), S(2), S(2),  H(1), H(2))),
     (SQRT_YY,
              (S(1), S(1), S(1), S(2), S(2), S(2),  H(1), CNOT(1,2),
               H(2), S(1), S(2), H(1), H(2), S(1), S(2))),
     (SQRT_YY_DAG,
              (S(1), S(1), S(1), S(2), H(1), CNOT(1,2),
               H(2), S(1), S(2),  H(1), H(2), S(1), S(2), S(2), S(2))),
     (SQRT_ZZ,
              (H(2), CNOT(1,2), H(2), S(1), S(2))),
     (SQRT_ZZ_DAG,
              (H(2), CNOT(1,2), H(2), S(1), S(1), S(1), S(2), S(2), S(2)))
=#
     ]

@testset "Two qubit operations" begin
    # Loop generates all arrays (a, b, c, d) with a,b,c,d in {0,1}
    for (gate, oplist) in gate2_decomp
        @testset "Gate $gate:" begin
            for bitarr in Base.Iterators.product(0:1, 0:1, 0:1, 0:1)
                state1 = generate_two_qubit_state(bitarr)
                state2 = generate_two_qubit_state(bitarr)
                for op in oplist
                    op(state1)
                end
                gate(1, 2)(state2)
                @test state1 == state2
            end
        end
    end
end
