"""
Apply P gate to a Stabilizer.
"""
function P(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 1 # PXP' = Y
        stabilizer.phase += 2
    end
end

"""
Apply X gate to a Stabilizer.
"""
function X(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if z == 1 # XZX = -Z
        stabilizer.phase += 2
    end
end

"""
Apply Y gate to a Stabilizer.
"""
function Y(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 0 && z == 1 # YZY =
        stabilizer.phase += 2
    elseif x == 1 && z == 1 # YXY = -X
        stabilizer.phase += 2
    end
end

"""
Apply Z gate to a Stabilizer.
"""
function Z(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 1 # ZXZ = -X
        stabilizer.phase += 2
    end
end

"""
Apply H gate to a Stabilizer.
"""
function H(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 1 && z == 0 # HXH = Z
        stabilizer.X[qubit] = 0
        stabilizer.Z[qubit] = 1
    elseif x == 0 && z == 1 # HZH = X
        stabilizer.X[qubit] = 1
        stabilizer.Z[qubit] = 0
    elseif x == 1 && z == 1 # HYH = -Y
        stabilizer.phase += 2
    end
end

"""
Apply CNOT gate to a Stabilizer.
"""
function CNOT(stabilizer::Stabilizer, control::Int64, target::Int64)
    # xc = stabilizer.X[control]
    # zc = stabilizer.Z[control]
    # xt = stabilizer.X[target]
    # zt = stabilizer.Z[target]

    # if xc == 1
    #     stabilizer.Z[target] = 1 - stabilizer.Z[target]
    # end
    #
    # if xt == 1
    #     stabilizer.Z[control] = 1 - stabilizer.Z[control]
    # end
end

"""
Apply CZ gate to a Stabilizer.
"""
function CZ(stabilizer::Stabilizer, control::Int64, target::Int64)
    xc = stabilizer.X[control]
    zc = stabilizer.Z[control]
    xt = stabilizer.X[target]
    zt = stabilizer.Z[target]

    if xc == 1
        stabilizer.Z[target] = 1 - stabilizer.Z[target]
    end

    if xt == 1
        stabilizer.Z[control] = 1 - stabilizer.Z[control]
    end
end

"""
Apply SWAP gate to a Stabilizer.
"""
function SWAP(stabilizer::Stabilizer, qubit1::Int64, qubit2::Int64)
    stabilizer.X[qubit1], stabilizer.X[qubit2] =
        stabilizer.X[qubit2], stabilizer.X[qubit1]
    stabilizer.Z[qubit1], stabilizer.Z[qubit2] =
        stabilizer.Z[qubit2], stabilizer.Z[qubit1]
end

"""
Apply P gate to a State.
"""
function P(state::State, qubit)
    for s in state.stabilizers
        P(s, GetQubitLabel(state, qubit))
    end
end

"""
Apply X gate to a State.
"""
function X(state::State, qubit)
    for s in state.stabilizers
        X(s, GetQubitLabel(state, qubit))
    end
end

"""
Apply Y gate to a State.
"""
function Y(state::State, qubit)
    for s in state.stabilizers
        Y(s, GetQubitLabel(state, qubit))
    end
end

"""
Apply Z gate to a State.
"""
function Z(state::State, qubit)
    for s in state.stabilizers
        Z(s, GetQubitLabel(state, qubit))
    end
end

"""
Apply H gate to a State.
"""
function H(state::State, qubit)
    for s in state.stabilizers
        H(s, GetQubitLabel(state, qubit))
    end
end

"""
Apply CNOT gate to a State.
"""
function CNOT(state::State, control, target)
    for s in state.stabilizers
        CNOT(s, GetQubitLabel(state, control), GetQubitLabel(state, target))
    end
end

"""
Apply CZ gate to a State.
"""
function CZ(state::State, control, target)
    for s in state.stabilizers
        CZ(s, GetQubitLabel(state, control), GetQubitLabel(state, target))
    end
end

"""
Apply SWAP gate to a State.
"""
function SWAP(state::State, qubit1, qubit2)
    for s in state.stabilizers
        SWAP(s, GetQubitLabel(state, qubit1), GetQubitLabel(state, qubit2))
    end
end
