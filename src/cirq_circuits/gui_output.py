def build_circuit():
 from cirq import GridQubit, Circuit
 from cirq.circuits import InsertStrategy as strategy
 from cirq.ops import X, Y, Z, H, I, T, S, CNOT, CCNOT, SWAP
 moments = []
 circuit = Circuit()
 q0 = GridQubit(0, 0)
 q1 = GridQubit(1, 0)
 q2 = GridQubit(2, 0)
 moments.append([])
 moments.append([H(q0), Z(q1), ])
 moments.append([])
 moments.append([X(q0), ])
 moments.append([])
 moments.append([S(q0), Y(q2), ])
 moments.append([])
 moments.append([CNOT(q0, q1), ])
 moments.append([])
 moments.append([SWAP(q2, q1), ])
 for moment in moments:
    circuit.append(moment, strategy.NEW_THEN_INLINE)
 return circuit

if __name__ == '__main__':
 circuit = build_circuit()
 print(circuit)
 import os
 os.system('pause')
