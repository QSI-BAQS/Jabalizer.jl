include("jabalizer.jl")

state = Jabalizer.StabilizerState()

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

# Update simulator results into the state tableau
Jabalizer.update_tableau(state)

println()
println("State before measurement")
println()
print(state)

# # Apply measurements

# mz_qubit = 1
# z = Jabalizer.MeasureZ(state, mz_qubit)
# println("", "MeasureY on qubit $mz_qubit, Result: ", z, "\n")

# mx_qubit = 3
# x = Jabalizer.MeasureX(state, mx_qubit)
# println("", "MeasureX on qubit $mx_qubit, Result: ", x, "\n")
#

# my_qubit = 5 #This will cause an error (for all gates test)
my_qubit = 1
y = Jabalizer.MeasureY(state, my_qubit)
println("", "MeasureY on qubit $my_qubit, Result:", y, "\n")

# Update simulator results into the state tableau
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
