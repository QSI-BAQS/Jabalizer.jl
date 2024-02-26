using Jabalizer

input_file = "examples/mwe.qasm"
qc = parse_file(input_file)
result = icmcompile(qc; universal=true, ptracking=true, debug=true)
# # init frame
# frames = Jabalizer.Frames()
# frame_flags = []
# # add qubits to frames
# frames.new_qubit(0)
# frames.new_qubit(1)

# # print out current frame info
# println(frames.into_py_dict_recursive())

# # track z on qubit 0 and and x on qubit 1
# frames.track_z(0)
# frames.track_x(1)

# # lets say z on 0 is from meas(2) and x on 1 is from meas(3)
# push!(frame_flags, 2)
# push!(frame_flags, 3)

# # look at frames again
# println(frames.into_py_dict_recursive())

# # looking at each qubit individually
# q=0
# q0_python_int = frames.into_py_dict_recursive()[q][0][0]
# println(q0_python_int)
# # convert to julia integer
# q0_jint = pyconvert(Int, q0_python_int)

# qubits = 2
# println(bitstring(q0_jint)[end-qubits+1:end])

# q=1
# q1_python_int = frames.into_py_dict_recursive()[q][1][0]
# println(q1_python_int)
# # convert to julia integer
# q1_jint = pyconvert(Int, q1_python_int)

# println(bitstring(q1_jint)[end-qubits+1:end])


# # below call gives an error : mapping not defined
# # icmcompile(qc, universal=true, ptracking=true)