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

"""
Apply a single gate operation to the given state.
"""
function execute_gate(state::StabilizerState, op_name, op_qubits)
    len = length(op_qubits)
    if len == 1
        (gate_map[op_name](qubit_map[op_qubits[1]]))(state)
    elseif len == 2
        (gate_map[op_name](qubit_map[op_qubits[1]], qubit_map[op_qubits[2]]))(state)
    else
        error("Too many arguments to $op_name: $len")
    end
end
