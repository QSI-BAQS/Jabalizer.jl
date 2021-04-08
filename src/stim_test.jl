include("jabalizer.jl")

state = Jabalizer.StabilizerState()
state.simulator.h(0)
state.simulator.cnot(0, 1)

Jabalizer.update_tableau(state)
print(state)

graph_state, adj, local_ops = Jabalizer.ToGraph(state)
print(graph_state)

print(graph_state.simulator.current_inverse_tableau()^-1)

Jabalizer.gplot(graph_state)
