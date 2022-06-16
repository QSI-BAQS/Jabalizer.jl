import cirq
from . import SplitQubit


def split_wires(qubit, n, opid):
    """
    Split a qubit n times

    This will return a list of qubits [q, anc_0, anc_1,...,anc_n-2],
    where q is split into q and anc_0, anc_0 is split into anc_0 and anc_1 and so on.

    """

    wires = [qubit]

    for i in range(n - 1):
        new_wires = wires[-1].split_this_wire(opid)
        wires[-1] = new_wires[0]
        wires.append(new_wires[1])

    return wires


def initialise_circuit(cirq_circuit):
    """
    Converts qubits to SplitQubits and ensures that all operations are unique

    Parameters
    ----------
    cirq_circuit : cirq.Circuit
        input circuit

    Returns
    -------
    new_cirq : cirq.Circuit
        circuit with  qubits replaced and unique gate operations
    """

    qubit_map = {}
    for q in cirq_circuit.all_qubits():
        q_split = SplitQubit(str(q))
        qubit_map[str(q)] = q_split

    # print(qubit_map)
    new_circ = cirq.Circuit()
    for moment in cirq_circuit:
        for op in moment:
            new_qubits = [qubit_map[str(q)] for q in list(op.qubits)]
            new_op = op.gate.on(*new_qubits)
            new_circ.append(new_op)

    return new_circ


def correction_seq(meas_outcome):
    """
    Returns the measurement sequence for Z and X after measuring qubit i.

    X = 0
    Z = 1

    seq (0, 1, 1, 0) means the followings gates should be applied
    X(i + 1) Z(i + 2) Z(i + 3) X(i + 4)
    """
    if meas_outcome:
        return (1, 0, 0, 1)
    else:
        return (0, 1, 1, 0)
