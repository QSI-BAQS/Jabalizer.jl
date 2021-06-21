using Test
using Random

include("../src/jabalizer.jl")

function basis_state()
    """
    Returns a 4 qubit StabilizerState representation of | 0 1 + - >
    with Tableau

    +ZIII
    -IZZZ
    +IIXI
    -IIIX
    """
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
    Jabalizer.update_tableau(state)
    return state
end

function twoqubit_basis(arr)
    """
    Returns the state  H_2^d H_1^c X_2^b X_1^a | 0 0 >, where arr = [a b c d].
    for arr in {0,1}^4 this generates all the computational and conjugate basis
    state combinations (e.g. |0 +> for [0 0 0 1] )

    """
    a,b,c,d = arr
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
    Jabalizer.update_tableau(state)

    return state
end

function apply_cnot(tab, con, targ)
    """
    Applies the CNOT operation the given Tableau.
    """

    cnot = Dict([0 0 0 1] => [0 1 0 1],
                [0 0 1 1] => [0 1 1 1],
                [1 0 0 0] => [1 0 1 0],
                [1 0 0 1] => [1 1 1 1],
                [1 1 0 0] => [1 1 1 0],
                [1 1 0 1] => [1 0 1 1],

                [0 1 0 1] => [0 0 0 1],
                [0 1 1 1] => [0 0 1 1],
                [1 0 1 0] => [1 0 0 0],
                [1 1 1 1] => [1 0 0 1],
                [1 1 1 0] => [1 1 0 0],
                [1 0 1 1] => [1 1 0 1]
                )

    n = Int64((length(tab[1,:]) - 1) / 2)

    # generates the array [x_1 z_1 x_2 z_2] for the given tableau where
    # 1 and 2 are the control and target respectively

    for i in 1:n
        stab = [tab[i, con] tab[i, n + con] tab[i, targ] tab[i, n + targ]]

        # gen the updated stab (defaults to itself if not found)
        new_stab = get(cnot, stab, stab)

        #update stabilizer
        tab[i, con], tab[i, n + con], tab[i, targ], tab[i, n + targ] = new_stab

        # update phase
        if stab in [[1 1 1 1], [1 0 0 1]]
            tab[i, 2 * n + 1] = (tab[i, 2 * n + 1] + 2) % 4
        end
    end
    return tab
end




# using Main.Jabalizer



@testset "State Initialisation Test" begin
    n = 10
    state = Jabalizer.ZeroState(n)
    X = zeros(Int64, n, n)
    Z = copy(X)
    for i in 1:n
        Z[i,i] = 1
    end
    phase = zeros(Int64, n, 1)
    tab = hcat(X, Z, phase)
    @test tab == Jabalizer.ToTableau(state)
end

@testset "Single qubit gate tests" begin

# X tests
state = basis_state()

# apply X on all qubits
for i in 1:4
    Jabalizer.X(state, i)
end
Jabalizer.update_tableau(state)


target_tab = [0 0 0 0  1 0 0 0  2;
              0 0 0 0  0 1 0 0  0;
              0 0 1 0  0 0 0 0  0;
              0 0 0 1  0 0 0 0  2]

@test target_tab == Jabalizer.ToTableau(state)


# Y test
state = basis_state()
# Apply Y gate on all qubits
for i in 1:4
    Jabalizer.Y(state, i)
end
Jabalizer.update_tableau(state)

target_tab = [0 0 0 0  1 0 0 0  2;
              0 0 0 0  0 1 0 0  0;
              0 0 1 0  0 0 0 0  2;
              0 0 0 1  0 0 0 0  0]

@test target_tab == Jabalizer.ToTableau(state)

#Z test
state = basis_state()
# Apply Z gate on all qubits
for i in 1:4
    Jabalizer.Z(state, i)
end
Jabalizer.update_tableau(state)

target_tab = [0 0 0 0  1 0 0 0  0;
              0 0 0 0  0 1 0 0  2;
              0 0 1 0  0 0 0 0  2;
              0 0 0 1  0 0 0 0  0]

@test target_tab == Jabalizer.ToTableau(state)

# Hadamard test
state = basis_state()
# Apply H gate on all qubits
for i in 1:4
    Jabalizer.H(state, i)
end
Jabalizer.update_tableau(state)

target_tab = [1 0 0 0  0 0 0 0  0;
              0 1 0 0  0 0 0 0  2;
              0 0 0 0  0 0 1 0  0;
              0 0 0 0  0 0 0 1  2]

@test target_tab == Jabalizer.ToTableau(state)

# Phase gate test
state = basis_state()
# Apply P gate on all qubits
for i in 1:4
    Jabalizer.P(state, i)
end
Jabalizer.update_tableau(state)

target_tab = [0 0 0 0  1 0 0 0  0;
              0 0 0 0  0 1 0 0  2;
              0 0 1 0  0 0 1 0  0;
              0 0 0 1  0 0 0 1  2]

@test target_tab == Jabalizer.ToTableau(state)
end

@testset "Two qubit gate tests" begin

# CNOT gate

for bitarr in Base.Iterators.product(0:1,0:1,0:1,0:1)

    # Initialise to
    state = twoqubit_basis(bitarr)
    # State Tableau
    tab = Jabalizer.ToTableau(state)

    Jabalizer.CNOT(state, 1, 2)
    Jabalizer.update_tableau(state)

    # manually update tableau
    tab = apply_cnot(tab, 1, 2)

    @test tab == Jabalizer.ToTableau(state)
end

end
