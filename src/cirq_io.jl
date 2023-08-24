"""
Parses cirq qubits to qubits in the format needed for icm.
Helper function.
"""
function parse_cirq_qubits(cirq_qubits::Vector{Any})
    output_qubits = Vector{String}()
    for qubit in cirq_qubits
        if qubit["cirq_type"] == "LineQubit"
            push!(output_qubits, string(qubit["x"]))
        else
            throw(DomainError(qubit["cirq_type"], "Only LineQubits are supported right now."))
        end
    end
    return output_qubits
end

"""
Loads cirq circuit from json into a format compatible with icm.
"""
function load_circuit_from_cirq_json(file_name::String)
    raw_circuit = JSON.parsefile(file_name)
    # Sometimes cirq saves to circuit as json with "\n" characters which require escaping
    if typeof(raw_circuit) == String
        raw_circuit = JSON.parse(replace(raw_circuit, "\n" => ""))
    end

    circuit = Vector{Tuple{String,Vector{String}}}()
    for moment in raw_circuit["moments"]
        for operation in moment["operations"]

            if not haskey(operation, "gate")
                # There are other types of gates such as PauliStrings which do not have in the json
                # the gate attribute
                throw(DomainError(cirq_gate_name, "Gate type not supported"))
            end

            cirq_gate_name = operation["gate"]["cirq_type"]
            qubits = parse_cirq_qubits(operation["qubits"])
            if cirq_gate_name == "ZPowGate" && operation["gate"]["exponent"] == 0.25
                gate_name = "T"
            elseif cirq_gate_name == "ZPowGate" && operation["gate"]["exponent"] == -0.25
                gate_name = "T^-1"
            elseif cirq_gate_name == "HPowGate" && operation["gate"]["exponent"] == 1.0
                gate_name = "H"
            elseif cirq_gate_name == "CXPowGate" && operation["gate"]["exponent"] == 1.0
                gate_name = "CNOT"
            else
                throw(DomainError(cirq_gate_name, "Gate type not supported"))
            end
            push!(circuit, (gate_name, qubits))
        end
    end
    return circuit
end

"""
Saves an icm-compatible circuit to CirQ-compatible json.
"""
function save_circuit_to_cirq_json(circuit, file_name::String)
    cirq_dict = Dict()
    cirq_dict["cirq_type"] = "Circuit"
    cirq_dict["moments"] = []

    for (gate, qubits) in circuit
        moment = Dict()
        moment["cirq_type"] = "Moment"
        operation = Dict()
        operation["cirq_type"] = "GateOperation"
        cirq_gate = Dict()
        if gate == "T"
            cirq_gate["cirq_type"] = "ZPowGate"
            cirq_gate["exponent"] = 0.25
        elseif gate == "T^-1"
            cirq_gate["cirq_type"] = "ZPowGate"
            cirq_gate["exponent"] = 0.25
        elseif gate == "H"
            cirq_gate["cirq_type"] = "HPowGate"
            cirq_gate["exponent"] = 1.0
        elseif gate == "CNOT"
            cirq_gate["cirq_type"] = "CXPowGate"
            cirq_gate["exponent"] = 1.0
        else
            throw(DomainError(gate, "Gate type not supported"))
        end
        cirq_gate["global_shift"] = 0.0
        cirq_qubits = []
        for qubit in qubits
            cirq_qubit = Dict()
            cirq_qubit["cirq_type"] = "NamedQubit"
            cirq_qubit["name"] = qubit
            push!(cirq_qubits, cirq_qubit)
        end
        operation["gate"] = cirq_gate
        operation["qubits"] = cirq_qubits
        moment["operations"] = [operation]
        push!(cirq_dict["moments"], moment)
    end
    json_string = JSON.json(cirq_dict)
    open(file_name, "w") do f
        write(f, json_string)
    end

end