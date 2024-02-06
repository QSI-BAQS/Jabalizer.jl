using Jabalizer
using Graphs
using GraphPlot

source_filename = "toffoli.qasm"
gates_to_decompose = ["T", "T_Dagger"]

data = gcompile(
    source_filename,
    gates_to_decompose;
)

graph, loc_corr, mseq, input_nodes, output_nodes, frames, buffer, frame_flags, buffer_flags = data



println("frames: ", frames.into_py_dict_recursive())
# println("buffer: ", buffer.into_py_dict_recursive())
# println(frame_flags)
# println(length(buffer.into_py_dict_recursive()))
@assert length(buffer_flags) * 2 == length(buffer.stacked_transpose(100).into_py_matrix())
@assert length(frame_flags) == length(frames.stacked_transpose(100).into_py_matrix())
println("len frames: ", length(frame_flags))
# println("len buffer: ", 2 * length(buffer_flags))

# graph plot (requires plotting backend)
gplot(graph, nodelabel=1:nv(graph))

println("Input Nodes")
println(input_nodes)

println("Output Nodes")
println(output_nodes)

println("(remaining) local corrections")
println(loc_corr)

println("Measurement order")
println(mseq[1])

println("Measurement basis")
println(mseq[2])
