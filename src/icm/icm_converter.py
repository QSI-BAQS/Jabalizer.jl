"""
NOTE: Experimental code for testing how gate decomposition that introduces
introduces ancillas would look like in Cirq

For this the ICM form of circuits is being implemented. As described in

"Faster manipulation of large quantum circuits using wire label reference
diagrams" https://arxiv.org/abs/1811.06011
"""

import cirq
from . import icm_flag_manipulations

def decomp_to_icm(cirq_operation):
    """

    :param cirq_operation:
    :return:
    """

    new_op_id = cirq_operation.icm_op_id.add_decomp_level()

    # Assume for the moment that these are only single qubit operations
    new_wires = cirq_operation.qubits[0].split_this_wire(new_op_id)

    """
        In this version the type of the gate, and the initialisation 
        of the qubits is not considered.
    """

    # Create the cnot
    cnot = cirq.CNOT(new_wires[0], new_wires[1])
    # Assign a decomposition id, like [old].1
    cnot.icm_op_id = new_op_id.advance_decomp()

    # Create the measurement
    meas = cirq.measure(new_wires[0])
    # Because this operation follows the CNOT, has ID from the previous
    # results into something like  [oldid].2
    meas.icm_op_id = cnot.icm_op_id.advance_decomp()

    return [cnot, meas]


def keep_icm(cirq_operation):
    """

    :param cirq_operation:
    :return:
    """
    """
        Decompose if the operation is from the set of the ones to keep
    """
    if isinstance(cirq_operation.gate, (cirq.CNotPowGate, cirq.MeasurementGate)):
        return True

    """
        Keep the operation if:
        * this is an operation that should be decomposed
        AND
        * is not marked for decomposition
    """
    if not icm_flag_manipulations.is_op_with_op_id(cirq_operation, [cirq_operation.gate]):
        return True

    return False

# import icm.icm_flag_manipulations as flags
# a = SplitQubit("a")
# b = SplitQubit("b")
#
# mycircuit = cirq.Circuit(cirq.T.on(a), cirq.T.on(b), cirq.CNOT.on(a,b), cirq.S.on(a))
# flags.add_op_ids(mycircuit, [cirq.T, cirq.S])
#
# print(mycircuit)
#
# icm_circuit = cirq.Circuit(cirq.decompose(mycircuit,
#                                           intercepting_decomposer=decomp_to_icm,
#                                           keep = keep_icm))
# print(icm_circuit)