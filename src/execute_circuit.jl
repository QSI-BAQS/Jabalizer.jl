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
