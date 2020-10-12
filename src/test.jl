include("jabalizer.jl")

t = [
    1 1 0 0 1 1 0 0 0 0 0 0 0 0 0
    1 1 1 1 0 0 0 0 0 0 0 0 0 0 0
    1 0 1 0 1 0 1 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 1 1 0 0 1 1 0 0
    0 0 0 0 0 0 0 1 1 1 1 0 0 0 0
    0 0 0 0 0 0 0 1 0 1 0 1 0 1 0
    0 0 0 0 0 0 0 1 1 1 1 1 1 1 0
]

s = State(t)
print(s)
g = GraphState(s)
print(g)
gplot(g)

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
