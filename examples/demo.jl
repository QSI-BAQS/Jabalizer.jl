using Jabalizer
# using Graphs, GraphPlot

# Prepare a 6-qubit GHZ state
n = 6
state = zero_state(n)
state |> H(1) |> CNOT(1,2) |> CNOT(1,3) |> CNOT(1,4) |> CNOT(1,5) |> CNOT(1,6)
# Display the stabilizer tableau
tab = to_tableau(state)
display(tab)

# Convert to graph state
graph_state = GraphState(state)
println("Graph adjacency matrix")
display(graph_state.A)
gplot(Graph(graph_state.A))

# Convert back to stabilizer state
stab_state = StabilizerState(graph_state)
tab = to_tableau(stab_state)
display(tab)
