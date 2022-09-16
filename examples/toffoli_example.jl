using Jabalizer
using PythonCall, Compose


cirq = pyimport("cirq");

circuit_file_name = "circuits/toffoli_circuit_3.json"
circuit_string = cirq.read_json(circuit_file_name)
cirq_circuit = cirq.read_json(json_text=circuit_string)

println("\n-------------")
println("Input circuit")
println("-------------\n")
println(cirq_circuit)

gates_to_decomp = ["T", "T^-1"];
icm_input = Jabalizer.load_circuit_from_cirq_json("circuits/toffoli_circuit_3.json")
icm_circuit = Jabalizer.compile(icm_input, gates_to_decomp)


Jabalizer.save_circuit_to_cirq_json(icm_circuit, "icm_output.json");
cirq_circuit = cirq.read_json("icm_output.json")
rm("icm_output.json")

println("\n-----------------")
println("ICM decomposition")
println("-----------------\n")


println(cirq_circuit)

n_qubits = Jabalizer.count_qubits(icm_circuit)
state = Jabalizer.zero_state(n_qubits);

print("\n Initial Stabilizer State\n")
println(state)

Jabalizer.execute_circuit(state, icm_circuit)
print("\n Final Stabilizer State\n")
print(state)


(g,A,seq) = Jabalizer.to_graph(state)



# Save generated graph as image file
draw(SVG("toffoli_graph.svg", 16cm, 16cm), Jabalizer.gplot(g))


println("\nGraph State")
println(g)

println("Adjacency matrix")
display(A)

println("\n\nLocal corrections")
println(seq)
