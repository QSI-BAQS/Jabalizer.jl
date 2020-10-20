include("jabalizer.jl")

using LightGraphs, GraphPlot

t1 = [
    1 1 0 0 1 1 0 0 0 0 0 0 0 0 0
    1 1 1 1 0 0 0 0 0 0 0 0 0 0 0
    1 0 1 0 1 0 1 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 1 1 0 0 1 1 0 0
    0 0 0 0 0 0 0 1 1 1 1 0 0 0 0
    0 0 0 0 0 0 0 1 0 1 0 1 0 1 0
    0 0 0 0 0 0 0 1 1 1 1 1 1 1 0
]

print("c")

t = [
    1 0 0 0 0 0 0
    0 1 0 0 0 0 0
    0 0 0 0 0 1 0
]

stab_state = Jabalizer.StabilizerState(t)
print(typeof(s))
println()
print(s)

println()
Jabalizer.H(stab_state, 2)

Jabalizer.X(stab_state, 2)

Jabalizer.CNOT(stab_state, 2, 3)

print(stab_state)

a = Jabalizer.MeasureZ(stab_state, 2)
print(a)
println()
print(stab_state)

# println("---")

# println("GHZ state:")
# state = State()
# # graph = [0 1 0;1 0 1; 0 1 0]
# AddGHZ(state,6)
# tab=ToTableau(state)
# print(state)
#
# (state,A,LOseq) = ToGraph(state)
# display(gplot(Graph(A)))
#
# println("LO graph state:")
# print(state)
#
# println("LOs = ", LOseq)
#
# println("Adjacency matrix:")
# display(A)
#
