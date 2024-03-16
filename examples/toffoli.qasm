// Generated from Cirq v1.1.0

OPENQASM 2.0;
include "qelib1.inc";


// Qubits: [q(0), q(1), q(2)]
qreg q[3];


t q[0];
t q[1];
h q[2];
cx q[0],q[1];
t q[2];
cx q[1],q[2];
tdg q[1];
t q[2];
cx q[0],q[1];
cx q[1],q[2];
cx q[0],q[1];
tdg q[2];
cx q[1],q[2];
cx q[0],q[1];
tdg q[2];
cx q[1],q[2];
h q[2];
