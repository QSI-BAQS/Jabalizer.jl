const gate_map = Dict()


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
Executes circuit using stim simulator and applies it to a given state.
"""
function execute_circuit(state::StabilizerState, circuit::Vector{ICMGate})
    n_qubits = 0
    qubit_map = Dict{String,Int}()
    for op in circuit
        qindices = Vector{Int}()
        for qindex in op[2]
            if !haskey(qubit_map, qindex)
                n_qubits += 1
                qubit_map[qindex] = n_qubits
            end
            push!(qindices, qubit_map[qindex])

        end
        gate = gate_map[op[1]](qindices...)
        gate(state)
    end
end