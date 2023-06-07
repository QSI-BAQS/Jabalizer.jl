const qasm2hdr = """
OPENQASM 2.0;
include "qelib1.inc";
qreg q[8];
"""

const qasm3hdr = """
OPENQASM 3;
include "stdgates.inc";
qubit[8] _all_qubits;
let q = _all_qubits[0:7];
"""

const qasmbody = """
h q[0];
x q[1];
y q[2];
z q[3];
cnot q[4],q[5];
swap q[6],q[7];
s q[0];
sdg q[1];
t q[2];
tdg q[3];
cz q[4],q[5];
"""

const icminput =
    (8,
     [("H", ["0"]),
      ("X", ["1"]),
      ("Y", ["2"]),
      ("Z", ["3"]),
      ("CNOT", ["4", "5"]),
      ("SWAP", ["6", "7"]),
      ("S", ["0"]),
      ("S_DAG", ["1"]),
      ("T", ["2"]),
      ("T", ["3"]),   # Will need to change to T_DAG when that is handled directly
      ("CZ", ["4", "5"])]
     )

@testset "QASM file input" begin
    circ2 = icm_circuit_from_qasm(qasm2hdr * qasmbody)
    circ3 = icm_circuit_from_qasm(qasm3hdr * qasmbody)
    @test circ2 == icminput
    @test circ3 == icminput
end
