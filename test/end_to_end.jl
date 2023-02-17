using Jabalizer

@testset "E2E Jabalizer test" begin

    circuit = Vector{Tuple{String,Vector{String}}}(
        [("CNOT", Vector(["0", "anc_0"])),
        ("H", ["1"]),
        ("CNOT", ["1", "anc_0"]),
        ("CNOT", ["anc_0", "anc_1"]),
        ("CNOT", ["1", "anc_2"]),
        ("CNOT", ["anc_2", "anc_0"]),
        ("H", ["anc_2"])
    ]
    )

    gates_to_decomp = ["T", "T^-1"]

    (icm_circuit, data_qubits_map) = compile(circuit, gates_to_decomp)

    n_qubits = count_qubits(icm_circuit)
    state = zero_state(n_qubits)

    execute_circuit(state, icm_circuit)

    (g, A, seq) = to_graph(state)
    Jabalizer.gplot(g)

    # TODO: check if the result is correct
    @test true
end
