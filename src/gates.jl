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
    CNOT(Stabilizer, control, target)

Apply CNOT gate to a Stabilizer.
"""
function CNOT(stabilizer::Stabilizer, control::Int64, target::Int64)
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
    CZ(state, control, target)

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
    P(state, qubit)

Apply P gate to a State on qubit.
"""
function P(state::StabilizerState, qubit)
    for s in state.stabilizers
        P(s, GetQubitLabel(state, qubit))
    end
end

"""
    X(state, qubit)

Apply X gate to a State.
"""
function X(state::StabilizerState, qubit)
    for s in state.stabilizers
        X(s, GetQubitLabel(state, qubit))
    end
end

"""
    Y(state, qubit)

Apply Y gate to a State.
"""
function Y(state::StabilizerState, qubit)
    for s in state.stabilizers
        Y(s, GetQubitLabel(state, qubit))
    end
end

"""
    Z(state, qubit)

Apply Z gate to a State.
"""
function Z(state::StabilizerState, qubit)
    for s in state.stabilizers
        Z(s, GetQubitLabel(state, qubit))
    end
end

"""
    H(state, qubit)

Apply H gate to a State.
"""
function H(state::StabilizerState, qubit)
    for s in state.stabilizers
        H(s, GetQubitLabel(state, qubit))
    end
end

"""
    CNOT(state, control, target)

Apply CNOT gate to a State.
"""
function CNOT(state::StabilizerState, control, target)
    for s in state.stabilizers
        CNOT(s, GetQubitLabel(state, control), GetQubitLabel(state, target))
    end
end

"""
    CZ(state, control, target)

Apply CZ gate to a State.
"""
function CZ(state::StabilizerState, control, target)
    for s in state.stabilizers
        CZ(s, GetQubitLabel(state, control), GetQubitLabel(state, target))
    end
end

"""
    SWAP(state, first, second)

Apply SWAP gate to a State.
"""
function SWAP(state::StabilizerState, qubit1, qubit2)
    for s in state.stabilizers
        SWAP(s, GetQubitLabel(state, qubit1), GetQubitLabel(state, qubit2))
    end
end

"""
    FusionI(state, first, second)

Apply type-I fusion gate to a state.
"""
function FusionI(state::StabilizerState, qubit1, qubit2)
    # for s in state.stabilizers
    #     SWAP(s, GetQubitLabel(state, qubit1), GetQubitLabel(state, qubit2))
    # end
end

"""
    FusionII(state, first, second)

Apply type-II fusion gate to a state.
"""
function FusionII(state::StabilizerState, qubit1, qubit2)
    # for s in state.stabilizers
    #     SWAP(s, GetQubitLabel(state, qubit1), GetQubitLabel(state, qubit2))
    # end
end
