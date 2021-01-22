**Testing how gate decomposition that introduce ancillas would look like in Cirq**

For this the ICM form of circuits is being implemented.
*Fault-Tolerant High Level Quantum Circuits: Form, Compilation and Description*
https://arxiv.org/abs/1509.02004

The insertion of ancilla performs many updates on the subsequent gates 
from the circuit. Therefore, this code uses a `SplitQubit` as introduced in:
*Faster manipulation of large quantum circuits using wire label reference
diagrams* https://arxiv.org/abs/1811.06011

**NOTE**: Very experimental, alpha code for the moment.