using Jabalizer
using JSON

test_circuits = ["test_circuits/mwe.qasm", "test_circuits/toffoli.qasm"]
shots = 1024

@testset "gcompile simulation with Qiskit" begin

    for inp in test_circuits
        meas_outcomes = QiskitSim.simulate(inp, shots)
        @test all(m == shots for m in meas_outcomes)
    end
end

outfile = "mbqcoutfile.qasm"
json_filepath = "jsonout.json"
@testset "mbqccompile simulation with Qiskit" begin
    for inp in test_circuits
        qc = parse_file(inp)
        output = mbqccompile(qc; pcorrections=true, filepath=json_filepath)
        
        
        testjson = JSON.parsefile(json_filepath)
        # convert pcorrs keys from String to Int
        testjson["pcorrs"] = Dict(parse(Int, k) => v for (k,v) in testjson["pcorrs"])
        # check that saved JSON file is the same as output
        @test testjson == output
        qasm_instruction(outfile, output)

        dq = JSON.parsefile(splitext(outfile)[1]*"_dqubits.json")
        # Keeps data_qubits def consistent with gcompile output
        dq = Dict( Symbol(k) => v for (k,v) in dq)

        meas_id = [s == shots for s in QiskitSim.simulate(inp, shots, compiled_qasm=outfile, data_qubits=dq)]
        @test all(meas_id)
    end
end


# clean
if isfile(json_filepath)
    rm(json_filepath)
end
if isfile(splitext(outfile)[1]*"_dqubits.json")
    rm(splitext(outfile)[1]*"_dqubits.json")
end





