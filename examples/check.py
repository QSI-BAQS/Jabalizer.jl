# instructions of how to do it:
# - it's basically just putting the check.py script from the track_paulis_bit_frames and
# the compile_flow.py script from the mbqc_scheduling repo
# (pauli_tracking/python_lib/examples/compile_flow.py) together
# - the stitching is done by doing a cz between the incoming qubit (which is in jabalizer
# identied with iiq in the icm compile function) and the input qubit (iq) of the widget
# and then doing a x measurement on the incoming qubit
#
# I'll probably write some notes about what is done in jabalizer into the paper draft
# which should help understanding what is happening
