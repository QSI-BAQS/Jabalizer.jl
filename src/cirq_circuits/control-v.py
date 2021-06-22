# Example of how to definite a cirq circuit
# main code should import cirq
import cirq
def build_circuit():
    '''Function that builds the cirq circuit'''
    import numpy as np
    from cirq.ops import CNOT, CCNOT, H, T

    # initialise qubits
    q = [cirq.GridQubit(i, 0) for i in range(2)]

    # initialise moments (veritcal slices)
    moments = []

    # add vertical slices
    moments.append([(cirq.T**-1).on(q[0]), cirq.H(q[1])])
    moments.append([cirq.CNOT(q[1], q[0])])
    moments.append([cirq.T(q[0]), (cirq.T**-1)(q[1])])
    moments.append([cirq.CNOT(q[1], q[0])])
    moments.append([cirq.H(q[1])])

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
