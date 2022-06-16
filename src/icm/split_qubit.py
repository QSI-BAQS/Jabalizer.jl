import cirq
import icm.icm_operation_id as opid


class SplitQubit(cirq.NamedQubit):

    # Static nr_ancilla
    nr_ancilla = -1

    def __init__(self, name):
        super().__init__(name)

        # A qubit/wire is split in two and these are the resulting wires
        self.children = (None, None)

        # The decision on which wire to use is based on the id of the operation
        # that generated the split
        self.threshold = opid.OperationId()

    def get_latest_ref(self, operation_id):

        # this wire has not been split
        if self.children == (None, None):
            return self

        n_ref = self
        stuck = 0
        while n_ref.children != (None, None):
            stuck += 1
            if stuck == 1000:
                print(
                    f"Error: I got stuck updating reference for qubit {self.name} with operation with id : {operation_id.numbers}, exiting loop"
                )
                break
            # Decide based on the threshold
            if n_ref.threshold >= operation_id:
                n_ref = n_ref.children[0]
            else:
                n_ref = n_ref.children[1]

        return n_ref

    def split_this_wire(self, operation_id):
        # It can happen that the reference is too old
        current_wire = self.get_latest_ref(operation_id)

        # The wire receives a threshold for latter updates
        current_wire.threshold = operation_id

        # It is a new wire, but keep the old name
        n_child_0 = SplitQubit(current_wire.name)

        # It is a new wire, that is introduced and gets a new name
        SplitQubit.nr_ancilla += 1
        n_child_1 = SplitQubit("anc_{0}".format(SplitQubit.nr_ancilla))

        # Update the children tuple of this wire
        current_wire.children = (n_child_0, n_child_1)

        # Return the children as a tuple
        return current_wire.children
