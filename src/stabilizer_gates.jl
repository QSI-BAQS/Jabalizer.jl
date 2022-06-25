# TODO: Wouldn't it be better if these:
# a) were returning a new stabilizer instead of modifying in place?
# A: it is easier to modify in place due to integration with stim.
# b) all have some common typing/interface?
# Maybe we want to create an abstract type later?


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
    state.updated = false
    state.simulator.s(qubit - 1)
end

"""
    X(state, qubit)

Apply X gate to a State.
"""
function X(state::StabilizerState, qubit)
    state.updated = false
    state.simulator.x(qubit - 1)
end

"""
    Y(state, qubit)

Apply Y gate to a State.
"""
function Y(state::StabilizerState, qubit)
    state.updated = false
    state.simulator.y(qubit - 1)
end

"""
    Z(state, qubit)

Apply Z gate to a State.
"""
function Z(state::StabilizerState, qubit)
    state.updated = false
    state.simulator.z(qubit - 1)
end

"""
    H(state, qubit)

Apply H gate to a State.
"""
function H(state::StabilizerState, qubit)
    state.updated = false
    state.simulator.h(qubit - 1)
end


"""
    CNOT(state, control, target)

Apply CNOT gate to a State.
"""
function CNOT(state::StabilizerState, control, target)
    state.updated = false
    state.simulator.cnot(control - 1, target - 1)
end

"""
    CZ(state, control, target)

Apply CZ gate to a State.
"""
function CZ(state::StabilizerState, control, target)
    state.updated = false
    state.simulator.cz(control - 1, target - 1)
end

"""
    SWAP(state, first, second)

Apply SWAP gate to a State.
"""
function SWAP(state::StabilizerState, qubit1, qubit2)
    state.updated = false
    state.simulator.swap(qubit1 - 1, qubit2 - 1)
end
