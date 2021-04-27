include("jabalizer.jl")


state = Jabalizer.StabilizerState()
#state.simulator.h(0)
#state.simulator.cnot(0, 1)

# GHZ state test
Jabalizer.H(state, 1)
Jabalizer.CNOT(state, 1,2)
Jabalizer.CNOT(state, 2,3)

# ## All gates test
# Jabalizer.H(state, 1)
# Jabalizer.CNOT(state, 1, 2)
# Jabalizer.P(state, 4)
# Jabalizer.X(state, 5)
# Jabalizer.Y(state, 6)
# Jabalizer.Z(state, 1)
# Jabalizer.CZ(state, 2, 4)
# Jabalizer.SWAP(state, 3, 4)
# Jabalizer.CNOT(state, 2, 4)

Jabalizer.update_tableau(state)

println()
println("State before measurement")
println()
print(state)


# z = Jabalizer.MeasureZ(state, 1)
# x = Jabalizer.MeasureX(state, 4)
y = Jabalizer.MeasureY(state, 1) #This will cause an error
# y = Jabalizer.MeasureY(state, 5)


#
# println("", "MeasureZ : ", z, "\n")
# println("", "MeasureX : ", x, "\n")
println("", "MeasureY : ", y, "\n")

Jabalizer.update_tableau(state)

println("State after measurement")
println()
print(state)

println("Converting to graph state ...")
println()
graph_state, adj, local_ops = Jabalizer.ToGraph(state)

println("Graph state : ")
println()

print(graph_state)


# print(graph_state.simulator.current_inverse_tableau()^-1)

Jabalizer.gplot(graph_state)
