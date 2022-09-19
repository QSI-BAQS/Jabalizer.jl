using Jabalizer

# Prepare a 6-qubit GHZ state
n = 6
state = zero_state(n)
println("\nInitial State")
print(state)

state |> Jabalizer.H(1) |> Jabalizer.CNOT(1,2) |> Jabalizer.CNOT(1,3) |> Jabalizer.CNOT(1,4) |> Jabalizer.CNOT(1,5) |> Jabalizer.CNOT(1,6)

println("\nGHZ state")
print(state)

# Convert to graph state
graph_state = GraphState(state)
println("\nGraph adjacency matrix")
display(graph_state.A)

# This requires some kind of plotting backend.
# Tested with plot pane in Atom.
display(Jabalizer.gplot(graph_state))

# Convert back to stabilizer state
stab_state = StabilizerState(graph_state)
println("\nStabilizer State")
print(stab_state)
