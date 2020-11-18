include("jabalizer.jl")

using LightGraphs, GraphPlot

# t = [
#     1 1 0 0 1 1 0 0 0 0 0 0 0 0 0
#     1 1 1 1 0 0 0 0 0 0 0 0 0 0 0
#     1 0 1 0 1 0 1 0 0 0 0 0 0 0 0
#     0 0 0 0 0 0 0 1 1 0 0 1 1 0 0
#     0 0 0 0 0 0 0 1 1 1 1 0 0 0 0
#     0 0 0 0 0 0 0 1 0 1 0 1 0 1 0
#     0 0 0 0 0 0 0 1 1 1 1 1 1 1 0
# ]
#
# s = Jabalizer.StabilizerState(t)
# g = Jabalizer.GraphState(s)
# t = Jabalizer.StabilizerState(g)
# display(g.A)
# gplot(Graph(g.A))

t = [
    1 0 0 0 0 0 0 0 0 0 0
    0 1 0 0 0 0 0 0 0 0 0
    0 0 1 0 0 0 0 0 0 0 0
    0 0 0 1 0 0 0 0 0 0 0
    0 0 0 0 1 0 0 0 0 0 0
]

s = Jabalizer.StabilizerState(t)

# numq = 5
# dep = 5
#
# for n = 1:numq
#     if rand((0,1)) == 1
#         Jabalizer.H(s,n)
#     end
# end
#
# for n = 1:dep
#     control = rand(1:numq)
#     target = rand(1:numq)
#     if control != target
#         Jabalizer.CNOT(s,control,target)
#     end
# end
#

g = Jabalizer.GraphState(s)
<<<<<<< HEAD

println()
print(s)
print(g)
=======
print(g)

gplot(g)
>>>>>>> parent of 5aded4d... minor

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
