include("jabalizer.jl")
include("execute_cirq.jl")

source = @__FILE__
circ_dir =  "cirq_circuits"

py"""
import os, sys
dirname = os.path.dirname($source)
sys.path.insert(0, dirname)
sys.path.insert(0, os.path.join(dirname, $circ_dir))
"""

cirq_circuit  = pyimport("gui_output")

my_circuit = cirq_circuit.build_circuit()
println()
println(my_circuit.__str__())

qubits = length(my_circuit.all_qubits())
state = Jabalizer.ZeroState(qubits)
println("Initial State")
print(state)
println("\nApplying the circuit:\n")
print(my_circuit.__str__())
println()
execute_cirq_circuit(state, my_circuit)
println("\nFinal State\n")
print(state)

(g,A,seq) = Jabalizer.ToGraph(state)

using GraphPlot
gplot(g)

println()
println("Graph Adjacency matrix:")
display(A)
