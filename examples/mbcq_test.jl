using Revise
using Jabalizer
using JSON

input_file = "examples/mwe.qasm"
qc = parse_file(input_file)

# g, loc_corr, mseq, data_qubits, ptracker = gcompile(qc, 
#                                                     universal=true,
#                                                     ptracking=true) 



output = mbqccompile(qc, pcorrctions=true)

outfile = "examples/test.qasm"
qasm_instruction(outfile, output)

# output_dict = JSON.parse(output)

# output_dict["steps"]

