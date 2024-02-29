using Graphs
using PythonCall
export mbqccompile

mbqc_scheduling = pyimport("mbqc_scheduling")
SpacialGraph = pyimport("mbqc_scheduling").SpacialGraph
PartialOrderGraph = pyimport("mbqc_scheduling").PartialOrderGraph

"""
    Return MBQC instructions for a given QuantumCircuit
"""
function mbqccompile(
    circuit::QuantumCircuit;
    universal::Bool = true,
    ptracking::Bool = true,
    teleport        = ["T", "T_Dagger", "RZ"]
    filepath::String=nothing,
)
    icm, measure, labels, ptracker = icmcompile(circuit; universal=universal, ptracking = ptracking, teleport = teleport)
    state = zero_state(width(icm))
    Jabalizer.execute_circuit(state, icm)
    graphstate, correction = to_graph(state)[2:3]
    # Extract MBQC instructions
    fullgraph = Graph(graphstate)
    add_vertices!(fullgraph, length(labels[:state]))
    for (s, i) in zip(labels[:state], labels[:input]) # teleporting state into input registers
        add_edge!(fullgraph, s, i)
    end # extended graph state with state registers for scheduling
    spacialgraph = SpacialGraph([nb .- 1 for nb in SimpleGraphs.adj(fullgraph)]) # zero-based indexing
    ptracking && (order = PartialOrderGraph(ptracker[:frames].get_py_order(ptracker[:frameflags])))
    AcceptFunc = pyimport("mbqc_scheduling.probabilistic").AcceptFunc
    paths = mbqc_scheduling.run(spacialgraph, order)
    for path in paths.into_py_paths()
        @info "time: $(path.time); space: $(path.space); steps: $(path.steps)"
    end
    # Jabalizer output
end