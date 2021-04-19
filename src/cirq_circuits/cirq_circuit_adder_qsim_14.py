# Example of how to definite a cirq circuit
# main code should import cirq
def build_circuit():
    '''Function that builds the cirq circuit'''
    import numpy as np
    from cirq.ops import X

    # initialise qubits
    qubits = [cirq.GridQubit(i, 0) for i in range(29)]

    # initialise moments (veritcal slices)
    moments = []

    # add vertical slices
    moments.append([X(qubits[0]).controlled_by(qubits[14])])
    moments.append([X(qubits[16]).controlled_by(qubits[2])])
    moments.append([X(qubits[17]).controlled_by(qubits[3])])
    moments.append([X(qubits[18]).controlled_by(qubits[4])])
    moments.append([X(qubits[19]).controlled_by(qubits[5])])
    moments.append([X(qubits[20]).controlled_by(qubits[6])])
    moments.append([X(qubits[21]).controlled_by(qubits[7])])
    moments.append([X(qubits[22]).controlled_by(qubits[8])])
    moments.append([X(qubits[23]).controlled_by(qubits[9])])
    moments.append([X(qubits[24]).controlled_by(qubits[10])])
    moments.append([X(qubits[25]).controlled_by(qubits[11])])
    moments.append([X(qubits[26]).controlled_by(qubits[12])])
    moments.append([X(qubits[27]).controlled_by(qubits[13])])
    moments.append([X(qubits[28]).controlled_by(qubits[14])])
    moments.append([X(qubits[14]).controlled_by(qubits[13]), X(qubits[13]).controlled_by(qubits[12]), X(qubits[12]).controlled_by(qubits[11]), X(qubits[11]).controlled_by(qubits[10]), X(qubits[10]).controlled_by(qubits[9]), X(qubits[9]).controlled_by(qubits[8]), X(qubits[8]).controlled_by(qubits[7]), X(qubits[7]).controlled_by(qubits[6]), X(qubits[6]).controlled_by(qubits[5]), X(qubits[5]).controlled_by(qubits[4]), X(qubits[4]).controlled_by(qubits[3]), X(qubits[3]).controlled_by(qubits[2])])
    moments.append([X(qubits[2]).controlled_by(qubits[1], qubits[15])])
    moments.append([X(qubits[3]).controlled_by(qubits[2], qubits[16])])
    moments.append([X(qubits[4]).controlled_by(qubits[3], qubits[17])])
    moments.append([X(qubits[5]).controlled_by(qubits[4], qubits[18])])
    moments.append([X(qubits[6]).controlled_by(qubits[5], qubits[19])])
    moments.append([X(qubits[7]).controlled_by(qubits[6], qubits[20])])
    moments.append([X(qubits[8]).controlled_by(qubits[7], qubits[21])])
    moments.append([X(qubits[9]).controlled_by(qubits[8], qubits[22])])
    moments.append([X(qubits[10]).controlled_by(qubits[9], qubits[23])])
    moments.append([X(qubits[11]).controlled_by(qubits[10], qubits[24])])
    moments.append([X(qubits[12]).controlled_by(qubits[11], qubits[25])])
    moments.append([X(qubits[13]).controlled_by(qubits[12], qubits[26])])
    moments.append([X(qubits[14]).controlled_by(qubits[13], qubits[27])])
    moments.append([X(qubits[0]).controlled_by(qubits[14], qubits[28])])
    moments.append([X(qubits[28]).controlled_by(qubits[14])])
    moments.append([X(qubits[14]).controlled_by(qubits[13], qubits[27])])
    moments.append([X(qubits[27]).controlled_by(qubits[13])])
    moments.append([X(qubits[13]).controlled_by(qubits[12], qubits[26])])
    moments.append([X(qubits[26]).controlled_by(qubits[12])])
    moments.append([X(qubits[12]).controlled_by(qubits[11], qubits[25])])
    moments.append([X(qubits[25]).controlled_by(qubits[11])])
    moments.append([X(qubits[11]).controlled_by(qubits[10], qubits[24])])
    moments.append([X(qubits[24]).controlled_by(qubits[10])])
    moments.append([X(qubits[10]).controlled_by(qubits[9], qubits[23])])
    moments.append([X(qubits[23]).controlled_by(qubits[9])])
    moments.append([X(qubits[9]).controlled_by(qubits[8], qubits[22])])
    moments.append([X(qubits[22]).controlled_by(qubits[8])])
    moments.append([X(qubits[8]).controlled_by(qubits[7], qubits[21])])
    moments.append([X(qubits[21]).controlled_by(qubits[7])])
    moments.append([X(qubits[7]).controlled_by(qubits[6], qubits[20])])
    moments.append([X(qubits[20]).controlled_by(qubits[6])])
    moments.append([X(qubits[6]).controlled_by(qubits[5], qubits[19])])
    moments.append([X(qubits[19]).controlled_by(qubits[5])])
    moments.append([X(qubits[5]).controlled_by(qubits[4], qubits[18])])
    moments.append([X(qubits[18]).controlled_by(qubits[4])])
    moments.append([X(qubits[4]).controlled_by(qubits[3], qubits[17])])
    moments.append([X(qubits[17]).controlled_by(qubits[3])])
    moments.append([X(qubits[3]).controlled_by(qubits[2], qubits[16])])
    moments.append([X(qubits[16]).controlled_by(qubits[2])])
    moments.append([X(qubits[2]).controlled_by(qubits[1], qubits[15])])
    moments.append([X(qubits[3]).controlled_by(qubits[2]), X(qubits[4]).controlled_by(qubits[3]), X(qubits[5]).controlled_by(qubits[4]), X(qubits[6]).controlled_by(qubits[5]), X(qubits[7]).controlled_by(qubits[6]), X(qubits[8]).controlled_by(qubits[7]), X(qubits[9]).controlled_by(qubits[8]), X(qubits[10]).controlled_by(qubits[9]), X(qubits[11]).controlled_by(qubits[10]), X(qubits[12]).controlled_by(qubits[11]), X(qubits[13]).controlled_by(qubits[12]), X(qubits[14]).controlled_by(qubits[13])])
    moments.append([X(qubits[28]).controlled_by(qubits[14])])
    moments.append([X(qubits[27]).controlled_by(qubits[13])])
    moments.append([X(qubits[26]).controlled_by(qubits[12])])
    moments.append([X(qubits[25]).controlled_by(qubits[11])])
    moments.append([X(qubits[24]).controlled_by(qubits[10])])
    moments.append([X(qubits[23]).controlled_by(qubits[9])])
    moments.append([X(qubits[22]).controlled_by(qubits[8])])
    moments.append([X(qubits[21]).controlled_by(qubits[7])])
    moments.append([X(qubits[20]).controlled_by(qubits[6])])
    moments.append([X(qubits[19]).controlled_by(qubits[5])])
    moments.append([X(qubits[18]).controlled_by(qubits[4])])
    moments.append([X(qubits[17]).controlled_by(qubits[3])])
    moments.append([X(qubits[16]).controlled_by(qubits[2])])
    moments.append([X(qubits[15]).controlled_by(qubits[1])])

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
