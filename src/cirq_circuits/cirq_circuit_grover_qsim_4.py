# Operations that did not call a primitive gate: MResetZ
# Example of how to definite a cirq circuit
# main code should import cirq
def build_circuit():
    '''Function that builds the cirq circuit'''
    import numpy as np
    from cirq.ops import H, X, Z, #MResetZ

    # initialise qubits
    qubits = [cirq.GridQubit(i, 0) for i in range(5)]

    # initialise moments (veritcal slices)
    moments = []

    # add vertical slices
    moments.append([H(qubits[0]), H(qubits[1]), H(qubits[2]), H(qubits[3])])
    moments.append([X(qubits[4])])
    moments.append([H(qubits[4])])
    moments.append([X(qubits[0]), X(qubits[2])])
    moments.append([X(qubits[4]).controlled_by(qubits[0], qubits[1], qubits[2], qubits[3])])
    moments.append([X(qubits[2]), X(qubits[0])])
    moments.append([H(qubits[4])])
    moments.append([X(qubits[4])])
    moments.append([H(qubits[3]), H(qubits[2]), H(qubits[1]), H(qubits[0])])
    moments.append([X(qubits[0]), X(qubits[1]), X(qubits[2]), X(qubits[3])])
    moments.append([Z(qubits[3]).controlled_by(qubits[0], qubits[1], qubits[2])])
    moments.append([X(qubits[3]), X(qubits[2]), X(qubits[1]), X(qubits[0])])
    moments.append([H(qubits[0]), H(qubits[1]), H(qubits[2]), H(qubits[3])])
    moments.append([X(qubits[4])])
    moments.append([H(qubits[4])])
    moments.append([X(qubits[0]), X(qubits[2])])
    moments.append([X(qubits[4]).controlled_by(qubits[0], qubits[1], qubits[2], qubits[3])])
    moments.append([X(qubits[2]), X(qubits[0])])
    moments.append([H(qubits[4])])
    moments.append([X(qubits[4])])
    moments.append([H(qubits[3]), H(qubits[2]), H(qubits[1]), H(qubits[0])])
    moments.append([X(qubits[0]), X(qubits[1]), X(qubits[2]), X(qubits[3])])
    moments.append([Z(qubits[3]).controlled_by(qubits[0], qubits[1], qubits[2])])
    moments.append([X(qubits[3]), X(qubits[2]), X(qubits[1]), X(qubits[0])])
    moments.append([H(qubits[0]), H(qubits[1]), H(qubits[2]), H(qubits[3])])
    moments.append([X(qubits[4])])
    moments.append([H(qubits[4])])
    moments.append([X(qubits[0]), X(qubits[2])])
    moments.append([X(qubits[4]).controlled_by(qubits[0], qubits[1], qubits[2], qubits[3])])
    moments.append([X(qubits[2]), X(qubits[0])])
    moments.append([H(qubits[4])])
    moments.append([X(qubits[4])])
    moments.append([H(qubits[3]), H(qubits[2]), H(qubits[1]), H(qubits[0])])
    moments.append([X(qubits[0]), X(qubits[1]), X(qubits[2]), X(qubits[3])])
    moments.append([Z(qubits[3]).controlled_by(qubits[0], qubits[1], qubits[2])])
    moments.append([X(qubits[3]), X(qubits[2]), X(qubits[1]), X(qubits[0])])
    moments.append([H(qubits[0]), H(qubits[1]), H(qubits[2]), H(qubits[3])])
    #MResetZ(qubits[]).controlled_by(qubits[0])
    #MResetZ(qubits[]).controlled_by(qubits[1])
    #MResetZ(qubits[]).controlled_by(qubits[2])
    #MResetZ(qubits[]).controlled_by(qubits[3])

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
