using Revise
using Jabalizer

frames = Jabalizer.Frames()
for i in 0:7
    frames.new_qubit(i)
end
frame_flags = []
frames.into_py_dict_recursive()
# frame_flags = collect(2:5)
qubits = collect(2:5)

# track
frames.track_z(2)
frames.track_x(2)
frames.track_z(3)
frames.track_x(3)

#update frame_flags
append!(frame_flags, [6, 0, 7, 1,2,4])

# Jabalizer.pauli_corrections(frames, frame_flags, qubits)

# apply gates
frames.cx(2,3)
frames.cx(2,4)
frames.cx(4,5)
frames.cx(3,5)

Jabalizer.pauli_corrections(frames, frame_flags, qubits)