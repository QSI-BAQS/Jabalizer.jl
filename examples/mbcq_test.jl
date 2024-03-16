using Revise
using Jabalizer

input_file = "examples/mwe.qasm"
qc = parse_file(input_file)

mbqccompile(qc)