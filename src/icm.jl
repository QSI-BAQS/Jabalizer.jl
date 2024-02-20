const ICMGate = Tuple{String,Vector{Int}}
export icmcompile

# Convert QuantumCircuit to ICM form by teleportation
function icmcompile(qc::QuantumCircuit; universal::Bool=true)
    circuit, mapping = choistate(qc)
    return icmcompile(circuit; universal=false)
end

# Make circuit for (id⊗qc)|B⟩ starting from |0⟩ where B is a Bell state
function choistate(qc::QuantumCircuit)
    allqubits = copy(registers(qc))
    mapping = Dict(zip(allqubits, allqubits)) # identity mapping
    allqubits, mapping = extend!!(allqubits, mapping, registers(qc))
    circuit = [Gate("H", nothing, [i]) for i in allqubits]
    append!(circuit, [Gate("CZ", nothing, [i, mapping[i]]) for i in registers(qc)])
    for gate in gates(qc)
        newgate = Gate(name(gate), cargs(gate), [mapping[i] for i in qargs(gate)])
        push!(circuit, newgate)
    end
    return QuantumCircuit(new, circuit), mapping
end

function icmcompile(qc::QuantumCircuit; universal::Bool=false)
    allqubits = copy(registers(qc))
    mapping = Dict(zip(allqubits, allqubits)) # identity mapping
    measurements = Gate[]
    circuit = Gate[]
    for gate in gates(qc)
        regs = [mapping[reg] for reg in qargs(gate)]
        if name(gate) in ["T", "T_Dagger"]
            # teleporting regs to new qubits appended to allqubits
            allqubits, mapping = extend!!(allqubits, mapping, regs)
            append!(circuit, [Gate("CNOT", nothing, [r, mapping[r]]) for r in regs])
            push!(measurements, Gate(name(gate), cargs(gate), regs))
        else
            # just write gate
            push!(circuit, Gate(name(gate), cargs(gate), regs))
        end
    end
    return QuantumCircuit(allqubits, circuit), measurements
end



# Never call with registers = allqubits: infinite loop extension
function extend!!(
    allqubits::Vector{<:Integer},
    mapping::Dict{<:Integer, <:Integer},
    registers::Vector{<:Integer}
)
    @assert registers ⊆ allqubits
    nextinteger(v, i=1) = i ∈ v ? nextinteger(v, i+1) : i
    for reg in registers
        newqubit = nextinteger(allqubits)
        push!(allqubits, newqubit)
        mapping[reg] = newqubit
    end
    return allqubits, mapping
end




# BELOW WILL BE DELETED




"""
Perfoms gates decomposition to provide a circuit in the icm format.
Reference: https://arxiv.org/abs/1509.02004


compile expects qubits to be indexed as integers from 1:n_qubits. If the 
universal flag is set, input nodes are added which are indexed n+1:2n. 
Ancillas introduced for teleportation are indexed starting from 2n+1 onwards.

universal flag = false is not supported yet.

gates_to_decompose are expected to by RZ gates. Rx, Ry and single qubit unitary
support will be added soon. 
"""
function compile(circuit::Vector{ICMGate},
                 n_qubits::Int,
                 gates_to_decompose::Vector{String};
                 universal::Bool=true
                 )
    
    # Initialize dictionary to track teleported qubits
    qubit_dict = Dict{Int, Int}()  
    
    # Initialise measurement sequence
    mseq::Vector{ICMGate} = []

    if universal
        """
        Generate pairs of Bell states for every logical qubit. Gates on logical
        qubits will act on one qubit of the bell pair for that logical qubit. This
        allows for injecting arbitrary input states through teleportation using the
        other qubit of the Bell pair.
        """
        initialize::Vector{ICMGate} = []

        for i in 1:n_qubits
            # Initialise (graph) Bell states for every logical qubit"
            push!(initialize, ("H", [i]))
            push!(initialize, ("H", [i + n_qubits]))
            push!(initialize, ("CZ",[i, i + n_qubits]))

            # Add input measurements to mseq
            # This does not include the measurement on the incoming qubit!
            push!(mseq, ("X", [i + n_qubits]))
        end

        # Prepend input initialisation to circuit
        circuit = [initialize; circuit]
    end
        
   
    # Initalizse the compiled circuit
    compiled_circuit::Vector{ICMGate} = []
    ancilla_num = 1

    for (gate, qubits) in circuit
    
        # Get the teleported qubit index if qubit has been teleported.
        compiled_qubits = [get(qubit_dict, q, q) for q in qubits]

        if gate in gates_to_decompose
            for (original_qubit, compiled_qubit) in zip(qubits, compiled_qubits)
                
                # Generate index for new ancilla to telport to.
                new_qubit = 2 * n_qubits + ancilla_num
                # update ancilla count
                ancilla_num += 1
                
                # Update data qubit map
                qubit_dict[original_qubit] = new_qubit
                push!(compiled_circuit, ("CNOT", [compiled_qubit, new_qubit]))
                
                # Update measuremnet sequence
                push!(mseq, (gate, [compiled_qubit]))
            end
        else
            push!(compiled_circuit, (gate, compiled_qubits))
        end
    end

    return compiled_circuit, qubit_dict, mseq
end

