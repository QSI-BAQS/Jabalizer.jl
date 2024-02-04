using Jabalizer
using Graphs
using GraphPlot

source_filename = "toffoli.qasm"
gates_to_decompose  = ["T", "T_Dagger"]

data = gcompile(
    source_filename,
    gates_to_decompose;
    universal=true,
    with_measurements=true,
    generate_qmap=true)

graph, loc_corr, mseq, input_nodes, output_nodes = data

# graph plot (requires plotting backend)
gplot(graph, nodelabel=1:nv(graph))

println("Input Nodes")
println(input_nodes)

println("Output Nodes")
println(output_nodes)

println("Local Corrections to internal nodes")
println(loc_corr)

println("Measurement order")
println(mseq[1])

println("Measurement basis")
println(mseq[2])
