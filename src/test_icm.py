import icm
import cirq

a = icm.SplitQubit("a")
b = icm.SplitQubit("b")
c = icm.SplitQubit("c")


mycircuit = cirq.Circuit(
    cirq.T.on(a), cirq.T.on(b),
    cirq.CNOT.on(a,b), cirq.S.on(a),
    cirq.CNOT.on(b,c), cirq.T.on(c),
)
icm.icm_flag_manipulations.add_op_ids(mycircuit, [cirq.T, cirq.S])

# print(mycircuit.__str__())

icm_circuit = cirq.Circuit(cirq.decompose(mycircuit,
                                          intercepting_decomposer=icm.decomp_to_icm,
                                          keep = icm.keep_icm))

print(icm_circuit)