# Example of how to definite a cirq circuit
# main code should import cirq
def build_circuit():
    '''Function that builds the cirq circuit'''
    import numpy as np

    from cirq import GridQubit, Circuit
    from cirq.circuits import InsertStrategy as strategy
    from cirq.ops import CNOT, CCNOT

    # initialise qubits
    qubits = [GridQubit(i, 0) for i in range(31)]

    # initialise moments (veritcal slices)
    moments = []

    # add vertical slices
    moments.append([CNOT(qubits[15], qubits[0])])
    moments.append([CNOT(qubits[2], qubits[17]), CNOT(qubits[3], qubits[18]), CNOT(qubits[4], qubits[19]), CNOT(qubits[5], qubits[20]), CNOT(qubits[6], qubits[21]), CNOT(qubits[7], qubits[22]), CNOT(qubits[8], qubits[23]), CNOT(qubits[9], qubits[24]), CNOT(qubits[10], qubits[25]), CNOT(qubits[11], qubits[26]), CNOT(qubits[12], qubits[27]), CNOT(qubits[13], qubits[28]), CNOT(qubits[14], qubits[29]), CNOT(qubits[15], qubits[30]), CNOT(qubits[14], qubits[15]), CNOT(qubits[13], qubits[14]), CNOT(qubits[12], qubits[13]), CNOT(qubits[11], qubits[12]), CNOT(qubits[10], qubits[11]), CNOT(qubits[9], qubits[10]), CNOT(qubits[8], qubits[9]), CNOT(qubits[7], qubits[8]), CNOT(qubits[6], qubits[7]), CNOT(qubits[5], qubits[6]), CNOT(qubits[4], qubits[5]), CNOT(qubits[3], qubits[4]), CNOT(qubits[2], qubits[3]), CCNOT(qubits[1], qubits[16], qubits[2]), CCNOT(qubits[2], qubits[17], qubits[3]), CCNOT(qubits[3], qubits[18], qubits[4]), CCNOT(qubits[4], qubits[19], qubits[5]), CCNOT(qubits[5], qubits[20], qubits[6]), CCNOT(qubits[6], qubits[21], qubits[7]), CCNOT(qubits[7], qubits[22], qubits[8]), CCNOT(qubits[8], qubits[23], qubits[9]), CCNOT(qubits[9], qubits[24], qubits[10]), CCNOT(qubits[10], qubits[25], qubits[11]), CCNOT(qubits[11], qubits[26], qubits[12]), CCNOT(qubits[12], qubits[27], qubits[13]), CCNOT(qubits[13], qubits[28], qubits[14]), CCNOT(qubits[14], qubits[29], qubits[15]), CCNOT(qubits[15], qubits[30], qubits[0]), CNOT(qubits[15], qubits[30]), CCNOT(qubits[14], qubits[29], qubits[15]), CNOT(qubits[14], qubits[29]), CCNOT(qubits[13], qubits[28], qubits[14]), CNOT(qubits[13], qubits[28]), CCNOT(qubits[12], qubits[27], qubits[13]), CNOT(qubits[12], qubits[27]), CCNOT(qubits[11], qubits[26], qubits[12]), CNOT(qubits[11], qubits[26]), CCNOT(qubits[10], qubits[25], qubits[11]), CNOT(qubits[10], qubits[25]), CCNOT(qubits[9], qubits[24], qubits[10]), CNOT(qubits[9], qubits[24]), CCNOT(qubits[8], qubits[23], qubits[9]), CNOT(qubits[8], qubits[23]), CCNOT(qubits[7], qubits[22], qubits[8]), CNOT(qubits[7], qubits[22]), CCNOT(qubits[6], qubits[21], qubits[7]), CNOT(qubits[6], qubits[21]), CCNOT(qubits[5], qubits[20], qubits[6]), CNOT(qubits[5], qubits[20]), CCNOT(qubits[4], qubits[19], qubits[5]), CNOT(qubits[4], qubits[19]), CCNOT(qubits[3], qubits[18], qubits[4]), CNOT(qubits[3], qubits[18]), CCNOT(qubits[2], qubits[17], qubits[3]), CNOT(qubits[2], qubits[17]), CCNOT(qubits[1], qubits[16], qubits[2]), CNOT(qubits[2], qubits[3]), CNOT(qubits[3], qubits[4]), CNOT(qubits[4], qubits[5]), CNOT(qubits[5], qubits[6]), CNOT(qubits[6], qubits[7]), CNOT(qubits[7], qubits[8]), CNOT(qubits[8], qubits[9]), CNOT(qubits[9], qubits[10]), CNOT(qubits[10], qubits[11]), CNOT(qubits[11], qubits[12]), CNOT(qubits[12], qubits[13]), CNOT(qubits[13], qubits[14]), CNOT(qubits[14], qubits[15]), CNOT(qubits[15], qubits[30]), CNOT(qubits[14], qubits[29]), CNOT(qubits[13], qubits[28]), CNOT(qubits[12], qubits[27]), CNOT(qubits[11], qubits[26]), CNOT(qubits[10], qubits[25]), CNOT(qubits[9], qubits[24]), CNOT(qubits[8], qubits[23]), CNOT(qubits[7], qubits[22]), CNOT(qubits[6], qubits[21]), CNOT(qubits[5], qubits[20]), CNOT(qubits[4], qubits[19]), CNOT(qubits[3], qubits[18]), CNOT(qubits[2], qubits[17])])
    moments.append([CNOT(qubits[1], qubits[16])])

    circuit = Circuit()

    # cirq will flush gates left, the strategy argument given will
    #prevent this. If this is not desired remove the strategy argument.
    for moment in moments:
        circuit.append(moment, strategy=strategy.NEW_THEN_INLINE)

    return circuit

    # # Convert moments to a circuit and return it
    # return cirq.Circuit(moments)

if __name__ == '__main__':
    ''' This bit will only run if this file is executed.
    This allows you to import the function to other files ignoring
    whatever is below. This part isn't needed for the gui '''


    circuit = build_circuit()
    print(circuit)
