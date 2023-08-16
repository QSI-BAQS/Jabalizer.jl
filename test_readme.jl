using Jabalizer

function main()

# Prepare a 6-qubit GHZ state
n = 6
state = zero_state(n)
Jabalizer.H(1)(state)
Jabalizer.CNOT(1, 2)(state)
Jabalizer.CNOT(1, 3)(state)
Jabalizer.CNOT(1, 4)(state)
Jabalizer.CNOT(1, 5)(state)
Jabalizer.CNOT(1, 6)(state)

# Display the stabilizer tableau
Jabalizer.update_tableau(state)
tab = Jabalizer.to_tableau(state)
display(tab)

# Convert to graph state
graphState = GraphState(state)

# Display graph adjacency matrix
display(graphState.A)

# Plot graph
Jabalizer.gplot(Jabalizer.Graph(graphState.A))

# Convert back to stabilizer state
stabState = StabilizerState(graphState)

end

main()
