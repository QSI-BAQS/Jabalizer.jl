# Pauli-I no-op operation (normally named I, but that conflicts with a LinearAlgebra name)
function (g::Id)(state::StabilizerState) ; state ; end

# One qubit gates

function (g::P)(s::StabilizerState) ; s.is_updated = false ; s.simulator.s(g.qubit - 1) ; s ; end
function (g::X)(s::StabilizerState) ; s.is_updated = false ; s.simulator.x(g.qubit - 1) ; s ; end
function (g::Y)(s::StabilizerState) ; s.is_updated = false ; s.simulator.y(g.qubit - 1) ; s ; end
function (g::Z)(s::StabilizerState) ; s.is_updated = false ; s.simulator.z(g.qubit - 1) ; s ; end
function (g::H)(s::StabilizerState) ; s.is_updated = false ; s.simulator.h(g.qubit - 1) ; s ; end

# Two qubit gates
for typ in (:CNOT, :CZ, :SWAP)
    op = Symbol(lowercase(string(typ)))
    @eval function (g::$typ)(state::StabilizerState)
        state.is_updated = false
        state.simulator.$(op)(g.qubit1 - 1, g.qubit2 - 1)
        state
    end
end
