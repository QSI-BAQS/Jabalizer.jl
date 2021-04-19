# Example of how to definite a cirq circuit
# main code should import cirq
import cirq
def build_circuit():
    '''Function that builds the cirq circuit'''
    import numpy as np
    from cirq.ops import CNOT, CCNOT

    # initialise qubits
    qubits = [cirq.GridQubit(i, 0) for i in range(17)]

    # initialise moments (veritcal slices)
    moments = []

    # add vertical slices
    moments.append([CNOT(qubits[8], qubits[0])])
    moments.append([CNOT(qubits[2], qubits[10])])
    moments.append([CNOT(qubits[3], qubits[11])])
    moments.append([CNOT(qubits[4], qubits[12])])
    moments.append([CNOT(qubits[5], qubits[13])])
    moments.append([CNOT(qubits[6], qubits[14])])
    moments.append([CNOT(qubits[7], qubits[15])])
    moments.append([CNOT(qubits[8], qubits[16])])
    moments.append([CNOT(qubits[7], qubits[8]), CNOT(qubits[6], qubits[7]), CNOT(qubits[5], qubits[6]), CNOT(qubits[4], qubits[5]), CNOT(qubits[3], qubits[4]), CNOT(qubits[2], qubits[3])])
    moments.append([CCNOT(qubits[1], qubits[9], qubits[2])])
    moments.append([CCNOT(qubits[2], qubits[10], qubits[3])])
    moments.append([CCNOT(qubits[3], qubits[11], qubits[4])])
    moments.append([CCNOT(qubits[4], qubits[12], qubits[5])])
    moments.append([CCNOT(qubits[5], qubits[13], qubits[6])])
    moments.append([CCNOT(qubits[6], qubits[14], qubits[7])])
    moments.append([CCNOT(qubits[7], qubits[15], qubits[8])])
    moments.append([CCNOT(qubits[8], qubits[16], qubits[0])])
    moments.append([CNOT(qubits[8], qubits[16])])
    moments.append([CCNOT(qubits[7], qubits[15], qubits[8])])
    moments.append([CNOT(qubits[7], qubits[15])])
    moments.append([CCNOT(qubits[6], qubits[14], qubits[7])])
    moments.append([CNOT(qubits[6], qubits[14])])
    moments.append([CCNOT(qubits[5], qubits[13], qubits[6])])
    moments.append([CNOT(qubits[5], qubits[13])])
    moments.append([CCNOT(qubits[4], qubits[12], qubits[5])])
    moments.append([CNOT(qubits[4], qubits[12])])
    moments.append([CCNOT(qubits[3], qubits[11], qubits[4])])
    moments.append([CNOT(qubits[3], qubits[11])])
    moments.append([CCNOT(qubits[2], qubits[10], qubits[3])])
    moments.append([CNOT(qubits[2], qubits[10])])
    moments.append([CCNOT(qubits[1], qubits[9], qubits[2])])
    moments.append([CNOT(qubits[2], qubits[3]), CNOT(qubits[3], qubits[4]), CNOT(qubits[4], qubits[5]), CNOT(qubits[5], qubits[6]), CNOT(qubits[6], qubits[7]), CNOT(qubits[7], qubits[8])])
    moments.append([CNOT(qubits[8], qubits[16])])
    moments.append([CNOT(qubits[7], qubits[15])])
    moments.append([CNOT(qubits[6], qubits[14])])
    moments.append([CNOT(qubits[5], qubits[13])])
    moments.append([CNOT(qubits[4], qubits[12])])
    moments.append([CNOT(qubits[3], qubits[11])])
    moments.append([CNOT(qubits[2], qubits[10])])
    moments.append([CNOT(qubits[1], qubits[9])])

    circuit = cirq.Circuit()

    # cirq will flush gates left, the strategy argument given will
    #prevent this. If this is not desired remove the strategy argument.
    for moment in moments:
        circuit.append(moment, strategy=cirq.circuits.InsertStrategy.NEW_THEN_INLINE)

    return circuit

    # # Convert moments to a circuit and return it
    # return cirq.Circuit(moments)

if __name__ == '__main__':
    ''' This bit will only run if this file is executed.
    This allows you to import the function to other files ignoring
    whatever is below. This part isn't needed for the gui '''

    import cirq

    circuit = build_circuit()
    print(circuit)
