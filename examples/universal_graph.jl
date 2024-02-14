using Revise
using Jabalizer
using Graphs
using GraphPlot

source_filename = "examples/toffoli.qasm"
gates_to_decompose  = ["T", "T_Dagger"]

# Some commented code accessing internal functions that gcompile uses.
# uncomment to play with these methods. 

# qubits, inp_circ = load_icm_circuit_from_qasm(source_filename)
# data = compile(
#     inp_circ,
#     qubits,
#     gates_to_decompose
# )

# icm_circuit, data_qubits, mseq  = data

# icm_q = Jabalizer.count_qubits(icm_circuit)
# state = zero_state(icm_q)
# Jabalizer.execute_circuit(state, icm_circuit)

data = gcompile(
    source_filename,
    gates_to_decompose;
    universal=true,
    )

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
