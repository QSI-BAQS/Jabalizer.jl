using Revise
using Jabalizer
using GraphPlot
using Graphs
using PythonCall
import Graphs.SimpleGraphs

mbqc_scheduling = pyimport("mbqc_scheduling")
SpacialGraph = pyimport("mbqc_scheduling").SpacialGraph
PartialOrderGraph = pyimport("mbqc_scheduling").PartialOrderGraph

input_file = "examples/mwe.qasm"
qc = parse_file(input_file)

# Display input circuit
display(gates(qc))

universal = true
ptracking = true
icm_circuit, mseq, qubit_map, frames_array  = icmcompile(qc;
                                                        universal=universal,
                                                        ptracking=ptracking
                                                        )

# Compiled icm circuit
display(gates(icm_circuit))

# Measurement sequence
display(mseq)

# input-output map, keys are input and values are output
display(qubit_map)

# Frames array is one of [], [frames, frame_flags], 
# or [frames, frame_flags, buffer, buffer_flags] depending on whether universal
# and ptracking flags are set
if ptracking
    if universal
        frames, frame_flags, buffer, buffer_flags = frames_array
    else
        frames, frame_flags = frames_array
    end
end



# Using gcompile directly
ptracking = true
universal = true 

graph, loc_corr, mseq, data_qubits, frames_array = gcompile(input_file;
                                                        universal=universal,
                                                         ptracking=ptracking)

# unpack frames
if ptracking
    if universal
        frames, frame_flags, buffer, buffer_flags = frames_array
    else
        frames, frame_flags = frames_array
    end
end

index=1
gplot(graph,nodelabel=(1-index):(nv(graph)-index))

println(loc_corr)

frames.into_py_dict_recursive()

# mbqc_scheduling
sparse_rep = SimpleGraphs.adj(graph)

# shift indices for mbqc_scheduling
sparse_rep = [e.-1 for e in sparse_rep]

sparse_rep = SpacialGraph(sparse_rep)

order = frames.get_py_order(frame_flags)
forder = PartialOrderGraph(order)
paths = mbqc_scheduling.run(sparse_rep, order)
AcceptFunc = pyimport("mbqc_scheduling.probabilistic").AcceptFunc


# Time optimal path
for path in paths.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end



# Full search
full_search_path = mbqc_scheduling.run(
    sparse_rep,
    order; 
    do_search=true, 
    nthreads=3,
    # ,timeout=0
    # timeout=1,
    # probabilistic = (AcceptFunc(), nothing)
)


for path in full_search_path.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end
