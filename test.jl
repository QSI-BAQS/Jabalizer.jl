using LightGraphs
using GraphPlot

G = Graph(4) # graph with 3 vertices

# make a triangle
add_edge!(G, 1, 2)
add_edge!(G, 1, 3)
add_edge!(G, 2, 3)
add_edge!(G, 3, 4)

gplot(G)
