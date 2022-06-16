using Jabalizer
using PyCall

cirq = pyimport("cirq");


# Adds script location to python search path
# This is required to import the icm module and to import saved circuit files
source = @__FILE__
circ_dir = "cirq_circuits"

py"""
import os, sys
dirname = os.path.dirname($source)
sys.path.insert(0, dirname)
sys.path.insert(0, os.path.join(dirname, $circ_dir))
"""
icm = pyimport("icm");

cd(circ_dir)
cirq_circuit = pyimport("control_v");
cd("..")

circuit = cirq_circuit.build_circuit()

gates_to_decomp = [cirq.T, cirq.T^-1];

iicm_circuit = icm.iicm_circuit(circuit, gates_to_decomp)


iicm_length = length(iicm_circuit.all_qubits())
state = Jabalizer.ZeroState(iicm_length);


Jabalizer.execute_cirq_circuit(state, iicm_circuit)


(g, A, seq) = Jabalizer.ToGraph(state)
# Jabalizer.gplot(g)