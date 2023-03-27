# Pauli-I no-op operation (normally named I, but that conflicts with a LinearAlgebra name)
function (g::Id)(state::StabilizerState) ; state ; end

# One qubit gates
for (nam, typ) in Gates.gate1_list
    typ == :Id && continue # already handled
    op = Symbol(lowercase(string(typ)))
    @eval function (g::$typ)(state::StabilizerState)
        state.is_updated = false
        state.simulator.$(op)(g.qubit - 1)
        state
    end
end

# Two qubit gates
for (nam, typ) in Gates.gate2_list
    op = Symbol(lowercase(string(typ)))
    @eval function (g::$typ)(state::StabilizerState)
        state.is_updated = false
        state.simulator.$(op)(g.qubit1 - 1, g.qubit2 - 1)
        state
    end
end
