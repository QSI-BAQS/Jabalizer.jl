"""
Apply Pauli-Z channel gate to a State.
"""
function ChannelZ(state::State, qubit, prob::Float64)
    if rand(Float64) < prob
        Z(state, qubit)
    end
end

"""
Apply Pauli-Z channel gate to a State.
"""
function ChannelZ(state::State, prob::Float64)
    for qubit = 1:state.qubits
        ChannelZ(state, qubit, prob)
    end
end

"""
Apply Pauli-X channel gate to a State.
"""
function ChannelX(state::State, qubit, prob::Float64)
    if rand(Float64) < prob
        X(state, qubit)
    end
end

"""
Apply Pauli-X channel gate to a State.
"""
function ChannelX(state::State, prob::Float64)
    for qubit = 1:state.qubits
        ChannelX(state, qubit, prob)
    end
end

"""
Apply Pauli-Y channel gate to a State.
"""
function ChannelY(state::State, qubit, prob::Float64)
    if rand(Float64) < prob
        Y(state, qubit)
    end
end

"""
Apply Pauli-Y channel gate to a State.
"""
function ChannelY(state::State, prob::Float64)
    for qubit = 1:state.qubits
        ChannelY(state, qubit, prob)
    end
end

"""
Apply depolarizing channel gate to a State.
"""
function ChannelDepol(state::State, qubit, prob::Float64)
    if rand(Float64) < ((1 - prob) / 3)
        X(state, qubit)
        Y(state, qubit)
        Z(state, qubit)
    end
end

"""
Apply depolarizing channel gate to a State.
"""
function ChannelDepol(state::State, prob::Float64)
    for qubit = 1:state.qubits
        ChannelDepol(state, qubit, prob)
    end
end

"""
Apply general Pauli channel gate to a State.
"""
function ChannelPauli(state::State, qubit, pXYZ::Array{Float64})
    r = rand(Float64)

    if r <= pXYZ[1]
        ChannelX(state, qubit, pXYZ[1])
    elseif r > pXYZ[1] && r <= pXYZ[2]
        ChannelY(state, qubit, pXYZ[2])
    elseif r > (pXYZ[1] + pXYZ[2]) && r <= (pXYZ[1] + pXYZ[2] + pXYZ[3])
        ChannelZ(state, qubit, pXYZ[3])
    end
end

"""
Apply general Pauli channel gate to a State.
"""
function ChannelPauli(state::State, pXYZ::Array{Float64})
    for qubit = 1:state.qubits
        ChannelPauli(state, qubit, pXYZ)
    end
end

"""
Apply loss channel gate to a State.
"""
function ChannelLoss(state::State, qubit, pLoss::Float64)
    r = rand(Float64)

    if r <= pLoss
        state.lost[qubit] = 1
    end
end

"""
Apply loss channel gate to a State.
"""
function ChannelLoss(state::State, pLoss::Float64)
    for qubit = 1:state.qubits
        ChannelLoss(state, qubit, pLoss)
    end
end
