const gate_map = Dict()

"""
TODO
"""
function load_circuit_from_json(file_name::String)
    raw_circuit = JSON.parsefile(file_name)
    circuit = Vector{Tuple{String,Vector{String}}}()

    for gate in raw_circuit
        gate_to_add = (gate[1], Vector{String}(gate[2]))
        append!(circuit, [gate_to_add])
    end

    return circuit
end



# This is called by the Jabalizer package's __init__ function
function _init_gate_map()
    copy!(gate_map,
        Dict("I" => Jabalizer.Id,
            "H" => Jabalizer.H,
            "X" => Jabalizer.X,
            "Y" => Jabalizer.Y,
            "Z" => Jabalizer.Z,
            "CNOT" => Jabalizer.CNOT,
            "SWAP" => Jabalizer.SWAP,
            "S" => Jabalizer.P,
            "PHASE" => Jabalizer.P, # TODO: IS IT?!?!?!
            "CZ" => Jabalizer.CZ))

end

"""
TODO
"""
function execute_circuit(state::StabilizerState, circuit::Vector{ICMGate})
    n_qubits = count_qubits(circuit)
    qubits = collect(1:n_qubits)

    qubit_map = Dict{String,Int}()
    for qubit in qubits
        qubit_map[string(qubit - 1)] = qubit
    end

    for op in circuit
        qindices = Vector{Int}()
        for qindex in op[2]
            if !haskey(qubit_map, qindex)
                global n_qubits += 1
                qubit_map[qindex] = n_qubits
            end
            push!(qindices, qubit_map[qindex])

        end
        gate = gate_map[op[1]](qindices...)
        gate(state)
    end
end