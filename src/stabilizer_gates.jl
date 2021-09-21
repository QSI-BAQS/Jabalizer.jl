"""
Here's some inline maths: \$\\sqrt[n]{1 + x + x^2 + \\ldots}\$.

Here's an equation:

\$\\frac{n!}{k!(n - k)!} = \\binom{n}{k}\$

This is the binomial coefficient.
"""
function Id(stabilizer::Stabilizer, qubit::Int64)
end


"""
    P(stabilizer, qubit)

Apply the \$P=\\sqrt{Z}\$ gate to a stabilizer.
"""
function P(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 1 # PXP' = Y
        stabilizer.phase += 2
    end
end

"""
    X(stabilizer, qubit)

Apply Pauli-X gate to a stabilizer.
"""
function X(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if z == 1 # XZX = -Z
        stabilizer.phase += 2
    end
end

"""
    Y(stabilizer, qubit)

Apply Y gate to a stabilizer.
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
    Z(stabilizer, qubit)

Apply Z gate to a stabilizer.
"""
function Z(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 1 # ZXZ = -X
        stabilizer.phase += 2
    end
end

"""
    H(stabilizer, qubit)

Apply H gate to a stabilizer.
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
    H(stabilizer, target)
    CZ(stabilizer, control, target)
    H(stabilizer, target)

    # xc = stabilizer.X[control]
    # zc = stabilizer.Z[control]
    # xt = stabilizer.X[target]
    # zt = stabilizer.Z[target]
    #
    # if xc == 1
    #     stabilizer.Z[target] = 1 - stabilizer.Z[target]
    # end
    #
    # if zt == 1
    #     stabilizer.Z[control] = 1 - stabilizer.Z[control]
    # end
end

"""
    CZ(state, control, target)

Apply CZ gate to a Stabilizer.
"""
function CZ(stabilizer::Stabilizer, control::Int64, target::Int64)
    stabilizer.Z[target] = (stabilizer.X[control] + stabilizer.Z[target]) % 2
    stabilizer.Z[control] = (stabilizer.X[target] + stabilizer.Z[control]) % 2
end

"""
    SWAP(stabilizer, qubit1, qubit2)

Apply SWAP gate to a Stabilizer.
"""
function SWAP(stabilizer::Stabilizer, qubit1::Int64, qubit2::Int64)
    stabilizer.X[qubit1], stabilizer.X[qubit2] =
        stabilizer.X[qubit2], stabilizer.X[qubit1]
    stabilizer.Z[qubit1], stabilizer.Z[qubit2] =
        stabilizer.Z[qubit2], stabilizer.Z[qubit1]
end

"""
    Id(state, qubit)

Apply I gate to a State on qubit.
"""
function Id(state::StabilizerState, qubit)
    for s in state.stabilizers
        Id(s, GetQubitLabel(state, qubit))
    end
end


"""
    P(state, qubit)

Apply P gate to a state on qubit.
"""
function P(state::StabilizerState, qubit)
	state.simulator.s(qubit-1)
    # for s in state.stabilizers
    #     P(s, GetQubitLabel(state, qubit))
    # end
end

"""
    X(state, qubit)

Apply X gate to a State.
"""
function X(state::StabilizerState, qubit)
	state.simulator.x(qubit-1)
    # for s in state.stabilizers
    #     X(s, GetQubitLabel(state, qubit))
    # end
end

"""
    Y(state, qubit)

Apply Y gate to a State.
"""
function Y(state::StabilizerState, qubit)
	state.simulator.y(qubit-1)
    # for s in state.stabilizers
    #     Y(s, GetQubitLabel(state, qubit))
    # end
end

"""
    Z(state, qubit)

Apply Z gate to a State.
"""
function Z(state::StabilizerState, qubit)
	state.simulator.z(qubit-1)
    # for s in state.stabilizers
    #     Z(s, GetQubitLabel(state, qubit))
    # end
end

"""
    H(state, qubit)

Apply H gate to a State.
"""
function H(state::StabilizerState, qubit)
    state.simulator.h(qubit-1)
    # for s in state.stabilizers
    #     H(s, GetQubitLabel(state, qubit))
    # end
end


"""
    CNOT(state, control, target)

Apply CNOT gate to a State.
"""
function CNOT(state::StabilizerState, control, target)
    state.simulator.cnot(control-1, target-1)
    # for s in state.stabilizers
    #     CNOT(s, GetQubitLabel(state, control), GetQubitLabel(state, target))
    # end
end

"""
    CZ(state, control, target)

Apply CZ gate to a State.
"""
function CZ(state::StabilizerState, control, target)
    state.simulator.cz(control-1, target-1)
    # for s in state.stabilizers
    #     CZ(s, GetQubitLabel(state, control), GetQubitLabel(state, target))
    # end
end

"""
    SWAP(state, first, second)

Apply SWAP gate to a State.
"""
function SWAP(state::StabilizerState, qubit1, qubit2)
    state.simulator.swap(qubit1-1, qubit2-1)
    # for s in state.stabilizers
    #     SWAP(s, GetQubitLabel(state, qubit1), GetQubitLabel(state, qubit2))
    # end
end
