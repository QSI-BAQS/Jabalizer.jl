include("jabalizer.jl")

using PyCall
cirq = pyimport("cirq")

source = @__FILE__
circ_dir =  "cirq_circuits"

py"""
import os, sys
dirname = os.path.dirname($source)
sys.path.insert(0, dirname)
sys.path.insert(0, os.path.join(dirname, $circ_dir))
"""

# cirq_circuit  = pyimport("gui_output")
cirq_circuit  = pyimport("cirq_circuit_adder_qct_8")

circuit = cirq_circuit.build_circuit()

println()
println("Initial Circuit")
println()
print(circuit.__str__())

(g,A,seq) = Jabalizer.ToGraph(circuit)

using GraphPlot
gplot(g)
