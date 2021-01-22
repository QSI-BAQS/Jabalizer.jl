"""
    FLAG MANIPULATIONS
"""
def is_op_with_decomposed_flag(op, gate_type):
    if op.gate == gate_type:
        return hasattr(op, "decomposed")
    return False

def reset_decomposition_flags(circuit, gate_type):
    for op in circuit.all_operations():
        if is_op_with_decomposed_flag(op, gate_type):
            op.decomposed = False

def add_decomposition_flags(circuit, gate_type):
    for op in circuit.all_operations():
        if not is_op_with_decomposed_flag(op, gate_type):
            setattr(op, "decomposed", True)

def remove_decomposition_flags(circuit, gate_type):
    for op in circuit.all_operations():
        if is_op_with_decomposed_flag(op, gate_type):
            delattr(op, "decomposed")

"""
opid
"""

from icm.icm_operation_id import OperationId

def is_op_with_op_id(op, gate_types):
    if op.gate in gate_types:
        return hasattr(op, "icm_op_id")
    return False

def reset_op_ids(circuit, gate_types):
    remove_decomposition_flags(circuit, gate_types)
    add_decomposition_flags(circuit, gate_types)

def add_op_ids(circuit, gate_types):
    nr_op = 0
    for op in circuit.all_operations():
        if not is_op_with_op_id(op, gate_types):
            setattr(op, "icm_op_id", OperationId(nr_op))
            # increase the id
            nr_op += 1

def remove_op_ids(circuit, gate_types):
    for op in circuit.all_operations():
        if is_op_with_op_id(op, gate_types):
            delattr(op, "icm_op_id")