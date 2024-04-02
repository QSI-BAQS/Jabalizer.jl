using Jabalizer
using JSON


test_circuits = ["test_circuits/mwe.qasm", "test_circuits/toffoli.qasm"]
outfile = "mbqcout.qasm"

@testset "mbqccompile simulation with Qiskit" begin
    for input_file in test_circuits
        qc = parse_file(input_file)
        output = mbqccompile(qc, pcorrctions=true)
        qasm_instruction(outfile, output)

        dq = JSON.parsefile(splitext(outfile)[1]*"_dqubits.json")
        # Keeps data_qubits def consistent with gcompile output
        dq = Dict( Symbol(k) => v for (k,v) in dq)
        shots = 1024

        meas_id = [s == shots for s in QiskitSim.simulate(input_file, shots, compiled_qasm=outfile, data_qubits=dq)]
        @test all(meas_id)
    end
end
# clean
if isfile(outfile)
    rm(outfile)
end
if isfile(splitext(outfile)[1]*"_dqubits.json")
    rm(splitext(outfile)[1]*"_dqubits.json")
end



