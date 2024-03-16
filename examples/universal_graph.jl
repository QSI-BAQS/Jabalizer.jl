using Revise
using Jabalizer
using Graphs
using GraphPlot
using PythonCall
import Graphs.SimpleGraphs

mbqc_scheduling = pyimport("mbqc_scheduling")
SpacialGraph = pyimport("mbqc_scheduling").SpacialGraph
PartialOrderGraph = pyimport("mbqc_scheduling").PartialOrderGraph

source_filename = "examples/mwe.qasm"
# source_filename = "examples/toffoli.qasm"
# gates_to_decompose  = ["T", "T_Dagger"]

# Some commented code accessing internal functions that gcompile uses.
# uncomment to play with these methods. 

# qubits, inp_circ = load_icm_circuit_from_qasm(source_filename)
# data = compile(
#     inp_circ,
#     qubits,
#     gates_to_decompose;
#     ptrack=false
# )

# icm_circuit, data_qubits, mseq, frames, frame_flags  = data

# icm_q = Jabalizer.count_qubits(icm_circuit)
# state = zero_state(icm_q)
# Jabalizer.execute_circuit(state, icm_circuit)


universal=true
ptracking=true
data = gcompile(
    source_filename;
    universal=universal,
    ptracking=ptracking
    )

graph, loc_corr, mseq, data_qubits, frames_array = data

# unpack frames
if ptracking
    if universal
        frames, frame_flags, buffer, buffer_flags = frames_array
    else
        frames, frame_flags = frames_array
    end
end

# graph plot (requires plotting backend)
gplot(graph, nodelabel=0:nv(graph)-1)

sparse_rep = SimpleGraphs.adj(graph)

# shift indices for mbqc_scheduling
sparse_rep = [e.-1 for e in sparse_rep]

for (s,i) in zip(data_qubits[:state], data_qubits[:input])
    insert!(sparse_rep, s, [i])   
end

sparse_rep = SpacialGraph(sparse_rep)

order = frames.get_py_order(frame_flags)
order = PartialOrderGraph(order)
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

# println("Input Nodes")
# println(input_nodes)

# println("Output Nodes")
# println(output_nodes)

# println("Local Corrections to internal nodes")
# println(loc_corr)

# println("Measurement order")
# println(mseq[1])

# println("Measurement basis")
# println(mseq[2])
