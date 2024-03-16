using CondaPkg
using PythonCall
using Jabalizer
using Test

# add qiskit python backends for circuit simulation
# CondaPkg.add_pip("qiskit")
CondaPkg.add_pip("qiskit-aer")


qaer = pyimport("qiskit_aer")
qiskit = pyimport("qiskit")
Aer = qaer.Aer

"""
Simulate the compiled circuit + input_circuit.inverse() on
the computational basis. Returns the measured shots for each 
basis input for the outcome 0^n.
"""
function simulate(input_file, shots)
    graph, loc_corr, mseq, data_qubits, frames_array = gcompile(input_file;
                                                        universal=true,
                                                         ptracking=true
    )

    output_qubits =  data_qubits[:output] .- 1
    state_qubits = data_qubits[:state] .- 1
    # qubits = [q for q in frame_flags]
    # # we want to find pauli corrections for measured and output qubits
    # append!(qubits, outqubits)

    # write qasm instructions to outfile
    qasm_instruction(outfile, graph, loc_corr, mseq, data_qubits, frames_array);

    # load circuits into qiskit
    simulator = Aer.get_backend("aer_simulator")
    input_circ = qiskit.QuantumCircuit.from_qasm_file(input_file)
    compiled_circ = qiskit.QuantumCircuit.from_qasm_file(outfile)
    compiled_circ.barrier()

    #
    
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
    
    return meas_outcomes
end


input_files = ["test_circuits/mwe.qasm", "test_circuits/toffoli.qasm"]
outfile = "outfile.qasm"
shots = 1024

@testset "Graph compilation simulation with qiskit" begin

    for inp in input_files
        meas_outcomes = simulate(inp, shots)
        @test all(m == shots for m in meas_outcomes)
    end
end