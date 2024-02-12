using Jabalizer
using Graphs
import Graphs.SimpleGraphs
using GraphPlot
using PythonCall

source_filename = "toffoli.qasm"
gates_to_decompose = ["T", "T_Dagger"]

data = gcompile(
    source_filename,
    gates_to_decompose;
)

graph, loc_corr, mseq, input_nodes, output_nodes, frames, buffer, frame_flags, buffer_flags = data

mbqc_scheduling = pyimport("mbqc_scheduling")
SpacialGraph = pyimport("mbqc_scheduling").SpacialGraph
PartialOrderGraph = pyimport("mbqc_scheduling").PartialOrderGraph
AcceptFunc = pyimport("mbqc_scheduling.probabilistic").AcceptFunc

# sparse graph representation; adj() is adjacency list = sparse representation; we need
# to shift the indices
sparse_graph = []
for node in SimpleGraphs.adj(graph)
    new_node = []
    for neighbor in node
        push!(new_node, neighbor - 1)
    end
    push!(sparse_graph, new_node)
end

sparse_graph = SpacialGraph(sparse_graph)

order = frames.get_py_order(frame_flags)

# we also need to shift the indices in the time ordering .. (why again are we adding +1 to
# them in icm.compile?); check out the println(shifted_order) below -> it looks like there
# might be a lot of python-julia interaction happening which might be slow ...
shifted_order = []
for layer in order
    shifted_layer = []
    for (node, dependencies) in layer
        shifted_node = node - 1
        shifted_dependencies = []
        for dependency in dependencies
            push!(shifted_dependencies, dependency - 1)
        end
        push!(shifted_layer, (shifted_node, shifted_dependencies))
    end
    push!(shifted_order, shifted_layer)
end
# println(order)
# println(shifted_order)

shifted_order = PartialOrderGraph(shifted_order)


# just the time optimal (trivial) path
paths = mbqc_scheduling.run(sparse_graph, shifted_order)

for path in paths.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end

# this takes some time; cf. docs of the run function for additional options, e.g., try out
# setting a timeout and/or a probabilistic layer onto it (when doing the latter, the
# results are of course just approximations, but it is faster)
full_search_path = mbqc_scheduling.run(
    sparse_graph, shifted_order; do_search=true, nthreads=3
    # timeout in seconds; only integers are possible; funny thing: with 1 second, it
    # already found the best paths, so as a showcase I set it to 0 (which effectively
    # means "take the first paths (more or less)") to see a difference
    , timeout=0
    # , timeout=1
    # cf. mbqc_scheduling.probabilistic docs
    , probabilistic = (AcceptFunc(), nothing)
)

nothing

for path in full_search_path.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end

# now one probably wants to serialize stuff to deserialize it later; the objects provided
# by the pauli_tracker and mbqc_scheduling library provide all (de)serialize methods (cf.
# their docs) which use proper (Rust) (de)serialization libraries; a warning regarding
# serializing stuff with julia libraries: unexpected things might happen when using some
# libraries, e.g., an unsigned int gets serialized as a signed int, (it might be possible
# to avoid that though, but using the right options, I don't know)

## other random println's; check them out

# println("frames: ", frames.into_py_dict_recursive())
# # println("buffer: ", buffer.into_py_dict_recursive())
# # println(frame_flags)
# # println(length(buffer.into_py_dict_recursive()))
# @assert length(buffer_flags) * 2 == length(buffer.stacked_transpose(100).into_py_matrix())
# @assert length(frame_flags) == length(frames.stacked_transpose(100).into_py_matrix())
# println("len frames: ", length(frame_flags))
# # println("len buffer: ", 2 * length(buffer_flags))

# # graph plot (requires plotting backend)
# gplot(graph, nodelabel=1:nv(graph))

# println("Input Nodes")
# println(input_nodes)

# println("Output Nodes")
# println(output_nodes)

# println("(remaining) local corrections")
# println(loc_corr)

# println("Measurement order")
# println(mseq[1])

# println("Measurement basis")
# println(mseq[2])
