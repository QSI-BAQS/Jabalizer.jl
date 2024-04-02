
module QiskitSim

using CondaPkg
using PythonCall
using Jabalizer
using JSON

# add qiskit python backends for circuit simulation
if !(haskey(CondaPkg.current_pip_packages(), "qiskit-aer"))
    CondaPkg.add_pip("qiskit-aer")
end

qaer = pyimport("qiskit_aer")
qiskit = pyimport("qiskit")
Aer = qaer.Aer

"""
Simulate the compiled circuit + input_circuit.inverse() on
the computational basis. Returns the measured shots for each 
basis input for the outcome 0^n.
"""
function simulate(input_qasm, shots; compiled_qasm="", data_qubits=Dict())
    
    # flag to cleanup generated files
    clean = false
    if compiled_qasm == ""
        clean = true        
        compiled_qasm = "outfile.qasm"
        graph, loc_corr, mseq, data_qubits, frames_array = gcompile(input_qasm;
                                                            universal=true,
                                                            ptracking=true
        )

        # write qasm instructions to outfile
        qasm_instruction(compiled_qasm, graph, loc_corr, mseq, data_qubits, frames_array);
        data_qubits[:output] =  data_qubits[:output] .- 1
        data_qubits[:state] = data_qubits[:state] .- 1    
    end

    output_qubits =  data_qubits[:output] 
    state_qubits = data_qubits[:state] 
    
    # check that for mbqccompile, path is time optimal
    sl = get(data_qubits, :state_layer, [0])
    all([i ==0 for i in sl]) || error("Only time optimal paths are supported")
    # @info state_qubits
    # @info output_qubits
    # load circuits into qiskit

    simulator = Aer.get_backend("aer_simulator")
    input_circ = qiskit.QuantumCircuit.from_qasm_file(input_qasm)
    # @info compiled_qasm
    compiled_circ = qiskit.QuantumCircuit.from_qasm_file(compiled_qasm)
    compiled_circ.barrier()
    # println(compiled_circ)
    
    qtot = length(output_qubits)
    meas_outcomes = []
    for i in 0:2^qtot-1
        new_circ = compiled_circ.compose(input_circ.inverse(), output_qubits)
        x_locs = digits(i, base=2, pad=qtot)
        # input state
        local input_state = qiskit.QuantumCircuit(length(output_qubits))
        
        x_locs = findall(!iszero, x_locs) .- 1
        if ! isempty(x_locs)
            input_state.x(x_locs)
        end
        
        # append input state and invert at output
        new_circ = new_circ.compose(input_state, qubits=state_qubits, front=true)
        new_circ = new_circ.compose(input_state.inverse(), qubits=output_qubits)

        for q in output_qubits
            new_circ.measure(q,q)
        end

        # might need a transpile step
        
        job = simulator.run(new_circ, shots=shots)  
        result = job.result()
        measured_statistics = qiskit.result.marginal_counts(result, indices=output_qubits).get_counts()
        # println(measured_statistics)

        # Obtain statisics of 0^n
        meas_0 = measured_statistics[repeat("0 ", length(output_qubits)) |> rstrip]
        meas_0 = pyconvert(Int,meas_0) 
        push!(meas_outcomes, meas_0)

    end
    
    # clean generated output files
    if clean
        rm(compiled_qasm)
        rm(splitext(compiled_qasm)[1]*"_dqubits.json")
    end
    return meas_outcomes

end



end