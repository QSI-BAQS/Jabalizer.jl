import cirq

import icm

from cirq_circuits.cirq_circuit_adder_qct_8 import build_circuit


#Circuit with just a Toffoli gate
# def build_circuit():
#     """
#     build a simple circuit
#     """
#     circuit = cirq.Circuit()
#     q = [cirq.GridQubit(i, 0) for i in range(3)]
#     circuit.append([cirq.CCNOT.on(*q)])
#
#     return circuit


# # 3 qubit circuit with Hadamards, cnots and T gates.
# def build_circuit():
#     """
#     build a simple circuit
#     """
#     circuit = cirq.Circuit()
#     q = [cirq.GridQubit(i, 0) for i in range(3)]
#     # q = [icm.SplitQubit('q' + str(i)) for i in range(3)]
#     circuit.append([cirq.H(q[0])])
#     circuit.append([cirq.H(q[1]), cirq.H(q[2])])
#     circuit.append([cirq.T(q[2]) ])
#     circuit.append([cirq.CNOT(q[0],q[1]), cirq.CNOT(q[1],q[2])])
#
#     return circuit

def replace_circuit(cirq_circuit):

    qubit_map = {}
    for i, q in enumerate(cirq_circuit.all_qubits()):
        q_split = icm.SplitQubit('q' + str(i))
        qubit_map[str(q)] = q_split

    # print(qubit_map)

    new_circ = cirq.Circuit()
    for moment in cirq_circuit:
        for op in moment:

            new_qubits = [qubit_map[str(q)] for q in list(op.qubits)]

            new_op = op.gate.on(*new_qubits)
            new_circ.append(new_op)

    return new_circ

circuit = build_circuit()
print(circuit)
print("\n\n\n")

pre_icm_circuit = replace_circuit(circuit)
#
# print(pre_icm_circuit)

icm.icm_flag_manipulations.add_op_ids(pre_icm_circuit, [cirq.T, cirq.H, cirq.CCNOT])

icm_circuit = cirq.Circuit(cirq.decompose(pre_icm_circuit,
                                          intercepting_decomposer=icm.decomp_to_icm,
                                          keep = icm.keep_icm))
print(icm_circuit)
