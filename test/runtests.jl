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

@testset "Gate Tests" begin

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

# Phase gate test
state = basis_state()
# Apply Y gate on all qubits
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
