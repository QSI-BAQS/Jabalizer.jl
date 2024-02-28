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

# Commented code below shows how to use icmcompile. For graph 
# compilation icmcompile can be used directly instead

# qc = parse_file(input_file)

# # Display input circuit
# display(gates(qc))

# universal = true
# ptracking = true
# icm_circuit, mseq, qubit_map, frames_array  = icmcompile(qc;
#                                                         universal=universal,
#                                                         ptracking=ptracking
#                                                         )

# # Compiled icm circuit
# display(gates(icm_circuit))

# # Measurement sequence
# display(mseq)

# # input-output map, keys are input and values are output
# display(qubit_map)

# # Frames array is one of [], [frames, frame_flags], 
# # or [frames, frame_flags, buffer, buffer_flags] depending on whether universal
# # and ptracking flags are set
# if ptracking
#     if universal
#         frames, frame_flags, buffer, buffer_flags = frames_array
#     else
#         frames, frame_flags = frames_array
#     end
# end



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

# We now generate a spatial graph that includes nodes for incoming state;
# This could be the qubits holding the input state or qubits holding the
# output of a previous graph widget. The spatial graph is stored as 
# edge list

# mbqc_scheduling
sparse_rep = SimpleGraphs.adj(graph)

#add state nodes to sparse_rep, this is needed to properly schedule
for (s,i) in zip(data_qubits[:state], data_qubits[:input])
    insert!(sparse_rep, s, [i])   
end

# shift indices for mbqc_scheduling
sparse_rep = [e.-1 for e in sparse_rep]

# Convert to native types used by mbqc_scheduling
sparse_rep_py = SpacialGraph(sparse_rep)
order = frames.get_py_order(frame_flags)
py_order = PartialOrderGraph(order)
AcceptFunc = pyimport("mbqc_scheduling.probabilistic").AcceptFunc

paths = mbqc_scheduling.run(sparse_rep_py, py_order)
# Time optimal path
for path in paths.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end

# RRE output
# save path -> decide format

# Full search (only possible for very small graphs)
full_search_path = mbqc_scheduling.run(
    sparse_rep_py,
    py_order; 
    do_search=true, 
    nthreads=3,
    # ,timeout=0
    # timeout=1,
    # probabilistic = (AcceptFunc(), nothing)
)


for path in full_search_path.into_py_paths()
    println("time: $(path.time); space: $(path.space); steps: $(path.steps)")
end


