include("../src/Jabalizer.jl")

using LightGraphs, GraphPlot

# Prepare a 6-qubit GHZ state
n = 6
state = Jabalizer.ZeroState(n)
Jabalizer.H(state,1)
Jabalizer.CNOT(state,1,2)
Jabalizer.CNOT(state,1,3)
Jabalizer.CNOT(state,1,4)
Jabalizer.CNOT(state,1,5)
Jabalizer.CNOT(state,1,6)

# Display the stabilizer tableau
Jabalizer.update_tableau(state)
tab = Jabalizer.ToTableau(state)
display(tab)

# Convert to graph state
graphState = Jabalizer.GraphState(state)
println("Graph adjacency matrix")
display(graphState.A)
gplot(Graph(graphState.A))

# Convert back to stabilizer state
stabState = Jabalizer.StabilizerState(graphState)
Jabalizer.update_tableau(stabState)
tab = Jabalizer.ToTableau(stabState)
display(tab)
