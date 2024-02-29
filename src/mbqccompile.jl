using Graphs
using PythonCall
using JSON
using PythonCall
export mbqccompile


# """
#     Return MBQC instructions for a given QuantumCircuit
# """
function mbqccompile(
    circuit::QuantumCircuit;
    universal = true,
    ptracking = true,
    teleport  = ["T", "T_Dagger", "RZ"],
    filepath  = nothing,
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
    # SEGFAULT ???
    spacialgraph = mbqc_scheduling.SpacialGraph([nb .- 1 for nb in Graphs.SimpleGraphs.adj(fullgraph)]) # zero-based indexing
    # ptracking && (order = PartialOrderGraph(ptracker[:frames].get_py_order(ptracker[:frameflags])))
    # AcceptFunc = pyimport("mbqc_scheduling.probabilistic").AcceptFunc
    # paths = mbqc_scheduling.run(spacialgraph, order)
    # path0 = paths.into_py_paths()[0]
    # ttime = pyconvert(Int, path0.time)
    # space = pyconvert(Int, path0.space)
    # steps = [pyconvert(Vector, step) for step in path0.steps]
    # Jabalizer output
    # measurements = append!(measure, Gate("X", nothing, [i]) for i in labels[:state])
    # jabalizer_out = Dict(
    #     :time => ttime,
    #     :space => space,
    #     :steps => steps,
    #     :correction => correction,
    #     :measurements => map(unpackGate, measurements),
    # )
    # if !nothing(filepath)
    #     @info "Jabalizer: writing to $(filepath)"
    #     open(filepath, "w") do f
    #         write(f, JSON.json(jabalizer_out))
    #     end
    # end
    return jabalizer_out = "I'm working"
end

function unpackGate(gate::Gate)
    return (Jabalizer.name(gate), Jabalizer.qargs(gate), Jabalizer.cargs(gate))
end