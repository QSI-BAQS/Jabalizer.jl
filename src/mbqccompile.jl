# using Graphs, PythonCall, JSON # done in Jabalizer.jl
export mbqccompile

# """
#     Return MBQC instructions for a given QuantumCircuit
# """
function mbqccompile(
    circuit::QuantumCircuit;
    universal = true,
    ptracking = true,
    pcorrections=false,
    teleport  = ["T", "T_Dagger", "RZ"],
    filepath  = nothing,
    initializer = [],
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
    spacialgraph = mbqc_scheduling.SpacialGraph([zerobasing(nb) for nb in Graphs.SimpleGraphs.adj(fullgraph)])
    ptracking && (order = mbqc_scheduling.PartialOrderGraph(ptracker[:frames].get_py_order(ptracker[:frameflags]))) # already zero-based
    AcceptFunc = pyimport("mbqc_scheduling.probabilistic").AcceptFunc
    paths = mbqc_scheduling.run(spacialgraph, order)
    path0 = paths.into_py_paths()[0]
    time = pyconvert(Int, path0.time)
    space = pyconvert(Int, path0.space)
    steps = [pyconvert(Vector, step) for step in path0.steps]
    # Jabalizer output, converted to zero-based indexing
    # measurements = append!(measure, Gate("X", nothing, [i]) for i in labels[:state])
    # Generate pauli-tracker for all qubits
    if pcorrections
        allqubits = reduce(vcat, steps)
        pcorrs = pauli_corrections(ptracker[:frames],ptracker[:frameflags], allqubits)
    end

    jabalizer_out = Dict(
        "time" => time, # length(steps) how many time steps
        "space" => space, # maximum number of qubits required
        "steps" => steps, # actual MBQC instructions: for each step in steps init nodes and CZ based on spacialgraph
        "spatialgraph" => [zerobasing(nb) for nb in Graphs.SimpleGraphs.adj(fullgraph)], # description of CZ gates to be applied (edge = apply CZ gate)
        "correction" => [[g, zerobasing(q)] for (g, q) in correction], # potential local Clifford correction on each nodes right after CZ above
        "measurements" => map(unpackGate, measure), # list of measurements
        "statenodes" => zerobasing(labels[:state]), # nodes where the input state is currently in
        "outputnodes" => zerobasing(labels[:output]), # get the output state returned by the circuit from these nodes
        "frameflags" => ptracker[:frameflags], # already zero-based # used to be frame_maps
        "initializer" => initializer, # what was passed in from caller
    )
    
    if pcorrections
        jabalizer_out["pcorrs"] = pcorrs
    end
    js = JSON.json(jabalizer_out)
    if !isnothing(filepath)
        # @info "Jabalizer: writing to $(filepath)"
        open(filepath, "w") do f
            write(f, js)
        end
    end
    return jabalizer_out
end

function unpackGate(gate::Gate; tozerobased = true)
    gatename = name(gate)
    @assert !isnothing(qargs(gate)) "Error: $(gatename) must act on some qubits, got $(qargs(gate))."
    if length(qargs(gate)) == 1
        tozerobased ? (actingon = zerobasing(qargs(gate)[1])) : (actingon = qargs(gate)[1])
    else
        tozerobased ? (actingon = zerobasing(qargs(gate))) : (actingon = qargs(gate))
    end
    if !isnothing(cargs(gate)) && length(cargs(gate)) == 1
        params = cargs(gate)[1]
    else
        params = cargs(gate)
    end
    return [gatename, actingon, params]
end

function zerobasing(index)
    return index .- 1
end