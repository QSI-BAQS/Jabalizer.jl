include("jabalizer.jl")

using LightGraphs, GraphPlot

# # number of qubits
# n = 5
#
# # initialize all zero state
# s = Jabalizer.ZeroState(n)
#
# # apply random Hadamards
# for i = 1:n
#     if rand((0,1)) == 1
#         Jabalizer.H(s,i)
#     end
# end
#
# # circuit depth
# d = 5
#
# # apply random CNOT sequence of given circuit depth
# for i = 1:d
#     control = rand(1:n)
#     target = rand(1:n)
#     if control != target
#         Jabalizer.CNOT(s,control,target)
#     end
# end
#
# Jabalizer.update_tableau(s)
#
# display("Stabilizers for the random state:")
# display(Jabalizer.ToTableau(s))
#
# display("Convert to graph form:")
# (g,A,seq) = Jabalizer.ToGraph(s)
# display(Jabalizer.ToTableau(g))
#
# display("Adjacency matrix:")
# display(A)
#
# display("Local operation sequence used to convert to graph form:")
# display(seq)
#
# gplot(g)

println("GraphToState demo")
A = [0 1 0;
     1 0 1;
     0 1 0]
display(A)
gs = Jabalizer.GraphToState(A)
display(Jabalizer.ToTableau(gs))
gplot(gs)
