include("jabalizer.jl")


state = Jabalizer.StabilizerState()
#state.simulator.h(0)
#state.simulator.cnot(0, 1)

# # GHZ state test
# Jabalizer.H(state, 1)
# Jabalizer.CNOT(state, 1,2)
# Jabalizer.CNOT(state, 2,3)

## All gates test
Jabalizer.H(state, 1)
Jabalizer.CNOT(state, 1, 2)
Jabalizer.P(state, 4)
Jabalizer.X(state, 5)
Jabalizer.Y(state, 6)
Jabalizer.Z(state, 1)
Jabalizer.CZ(state, 2, 4)
Jabalizer.SWAP(state, 3, 4)
Jabalizer.CNOT(state, 2, 4)

z = Jabalizer.MeasureZ(state, 3)
x = Jabalizer.MeasureX(state, 4)
#y = Jabalizer.MeasureY(state, 1) #This will cause an error
y = Jabalizer.MeasureY(state, 5)



print("", "MeasureZ qubit 1: ", z, "\n")
print("", "MeasureX qubit 4: ", x, "\n")
print("", "MeasureY qubit 5: ", y, "\n")

Jabalizer.update_tableau(state)

print(state)

graph_state, adj, local_ops = Jabalizer.ToGraph(state)
print(graph_state)

# print(graph_state.simulator.current_inverse_tableau()^-1)

Jabalizer.gplot(graph_state)
