### THIS PART NEEDS TO BE REWORKED ONCE WE FIX INSTALLATION ISSUES ### 
### START OF SETUP PART ###
cd("../src")

cirq = PyCall.pyimport("cirq")

# Adds script location to python search path
# This is required to import the icm module and to import saved circuit files
source = @__FILE__
circ_dir = "cirq_circuits"

PyCall.py"""
import os, sys
dirname = os.path.dirname($source)
sys.path.insert(0, dirname)
sys.path.insert(0, os.path.join(dirname, $circ_dir))
"""

icm = PyCall.pyimport("icm")

cd(circ_dir)
cirq_circuit = PyCall.pyimport("control_v")
cd("..")
### END OF SETUP PART ###