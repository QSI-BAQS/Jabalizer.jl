include("jabalizer.jl")

state = Jabalizer.StabilizerState()
state.simulator.h(0)
state.simulator.cnot(0, 1)

Jabalizer.update_tableau(state)

graph_state = Jabalizer.ToGraph(state)


print(state)
print(graph_state)
