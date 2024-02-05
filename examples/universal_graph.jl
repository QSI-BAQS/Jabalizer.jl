using Jabalizer
using Graphs
using GraphPlot

source_filename = "toffoli.qasm"
gates_to_decompose = ["T", "T_Dagger"]

data = gcompile(
    source_filename,
    gates_to_decompose;
    universal=true
)

graph, loc_corr, mseq, input_nodes, output_nodes, frames, buffer, frame_flags = data

println(frames.into_py_dict_recursive())
println(buffer.into_py_dict_recursive())
println(frame_flags)
println(length(buffer.into_py_dict_recursive()))
println(length(frame_flags))
@assert length(frame_flags) == length(buffer.stacked_transpose(100).into_py_matrix())

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
