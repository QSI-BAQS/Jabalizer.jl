OPENQASM 2.0;
include "qelib1.inc";
qreg q[2];
tdg q[0];
h q[1];
cnot q[1], q[0];
tdg q[1];
t q[0];
cnot q[1], q[0];
h q[1];