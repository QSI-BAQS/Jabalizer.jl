# Jabalizer

[![Build Status](https://github.com/madhavkrishnan/Jabalizer.jl/workflows/CI/badge.svg)](https://github.com/madhavkrishnan/Jabalizer.jl/actions)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/madhavkrishnan/Jabalizer.jl?svg=true)](https://ci.appveyor.com/project/madhavkrishnan/Jabalizer-jl)
[![Coverage](https://codecov.io/gh/madhavkrishnan/Jabalizer.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/madhavkrishnan/Jabalizer.jl)
[![Coverage](https://coveralls.io/repos/github/madhavkrishnan/Jabalizer.jl/badge.svg?branch=master)](https://coveralls.io/github/madhavkrishnan/Jabalizer.jl?branch=master)



<script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

# Contents

* Table of contents
{:toc}

# Developers

+ Madhav Krishnan Vijayan ([mkv.215@gmail.com](mailto:mkv.215@gmail.com))
+ Hudson Leone
+ Darcy Morgan
+ Simon Devitt
+ Peter Rohde ([dr.rohde@gmail.com](mailto:dr.rohde@gmail.com), [www.peterrohde.org](https://www.peterrohde.org))
+ Michał Stęchły([michal.stechly@zapatacomputing.com](mailto:michal.stechly@zapatacomputing.com))
+ Scott Jones
+ Athena Caesura

# About

Jabalizer is a simulator for quantum Clifford circuits and graph states written in Julia, both of which can be efficiently simulated using the stabilizer formalism. Jabalizer provides generic functions able to operate within both pictures and dynamically convert between them, allowing arbitrary Clifford circuits to be simulated and converted into graph state language, and vice-versa.

Julia modules can be called from Python or run in Jupyter notebooks too. You can learn more about the Julia language at [www.julialang.org](https://www.julialang.org).

# Installation

Jabalizer can be installed like any Julia package. Clone this repo to your local system using

```
git clone https://github.com/QSI-BAQS/Jabalizer.git
```
Checkout the required branch_name with (skip if installing the master branch)
```
git checkout branch_name
```
type `]` in the Julia REPL (make sure you are in the directory where you cloned Jabalizer not inside the Jabalizer repo) to enter the pkg mode and enter
```
pkg> add Jabalizer#branch_name
```
The module can be tested using,
```
pkg> test Jabalizer
```
# Technical Manuscript
TODO

# Stabilizer circuits

While simulating arbitrary quantum circuits is classically inefficient with exponential resource overhead, via the [Gottesman-Knill theorem](https://arxiv.org/abs/quant-ph/9807006) it is known that circuits comprising only Clifford operations (ones that commute with the Pauli group) can be efficiently simulated using the stabilizer formalism. In the stabilizer formalism an _n_-qubit state is defined as the simultaneous positive eigenstate of _n_ 'stabilizers', each of which is an _n_-fold tensor product of Pauli operators (_I_,_X_,_Y_,_Z_) and a sign (+/-). That is, for each stabilizer $$ S_i $$ (for $$ i\in 1\dots n $$) the state,

$$ |\psi\rangle $$

satisfies

$$ S_i|\psi\rangle = |\psi\rangle. $$

As an example, the Bell state

$$ \frac{1}{\sqrt{2}}(|00\rangle + |11\rangle) $$

can equivalently be represented by the two stabilizers

$$ S_1 = XX, $$

$$ S_2 = ZZ. $$

The orthogonal Bell state

$$ \frac{1}{\sqrt{2}}(|01\rangle + |10\rangle) $$

differs only slightly with stabilizers,

$$ S_1 = XX, $$

$$ S_2 = -ZZ. $$

Similarly, the three-qubit GHZ state

$$ \frac{1}{\sqrt{2}}(|000\rangle + |111\rangle) $$

can be represented by the three stabilizers,

$$ S_1 = XXX, $$

$$ S_2 = ZZI, $$

$$ S_3 = IZZ. $$

Evolving stabilizer states can be performed in the Heisenberg picture by conjugating the stabilizers with the unitary operations acting upon the state since for the evolution,

$$ |\psi'\rangle = U |\psi\rangle, $$

we can equivalently write,

$$ |\psi'\rangle = U S_i |\psi\rangle = U S_i U^\dagger U |\psi\rangle = U S_i U^\dagger |\psi'\rangle = S_i' |\psi'\rangle, $$

where,

$$ S_i' = U S_i U^\dagger, $$

stabilizes the evolved state

$$|\psi'\rangle = U |\psi\rangle. $$

Thus the rule for evolving states in the stabilizer formalism is to simply update each of the _n_ stabilizers via

$$ S_i' = U S_i U^\dagger. $$

The efficiency of classically simulating stabilizer circuits was subsequently improved upon by [Aaronson & Gottesman](https://arxiv.org/abs/quant-ph/0406196) using the so-called CHP approach which tracks both stabilizers and anti-stabilizers, improving the performance of measurements within this model. Jabalizer employs the highly-optimised [STIM simulator](https://github.com/quantumlib/Stim) as its CHP backend.

# Graph states

A graph state is defined as a set of _n_ qubits represented as vertices in a graph, where qubits are initialised into the

$$ |+\rangle = \frac{1}{\sqrt{2}}(|0\rangle + |1\rangle) $$

state and edges between them represent the application of controlled-phase (CZ) gates. This leads to the general stabilizer representation for graph states,

$$ S_i = X_i \prod_{j\in n_i} Z_j, $$

for each qubit _i_, where $$ n_i $$ denotes the graph neighbourhood of vertex _i_.

For example, the set of stabilizers associated with the graph,

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/123741542-96930b80-d8ed-11eb-9b9a-1caf37f5fcf0.jpeg" width="50%"></p>
<!--- ![image](https://user-images.githubusercontent.com/4382522/123741542-96930b80-d8ed-11eb-9b9a-1caf37f5fcf0.jpeg) --->

is given by,

$$ S_1 = XZII, $$

$$ S_2 = ZXZZ, $$

$$ S_3 = IZXZ, $$

$$ S_4 = IZZX. $$

Viewing this as a matrix note that the _X_ operators appear along the main diagonal, which the locations of the _Z_ operators define the adjacency matrix for the graph.

All stabilizer states can be converted to graph states via local operations, achieved via a tailored Gaussian elimination procedure on the stabilizer tableau. Jabalizer allows an arbitrary stabilizer state to be converted to a locally equivalent graph state and provide the associated adjacency matrix for the respective graph.

# Example code

Here's some simple Jabalizer code that executes the gate sequence used to generate a GHZ state, display the associated set of stabilizers, and then convert it to its locally equivalent graph state, which is then manipulated via several Pauli measurements and finally converted back to stabilizer form.

```julia
using Jabalizer

# Prepare a 6-qubit GHZ state
n = 6
state = zero_state(n)
Jabalizer.H(1)(state)
Jabalizer.CNOT(1,2)(state)
Jabalizer.CNOT(1,3)(state)
Jabalizer.CNOT(1,4)(state)
Jabalizer.CNOT(1,5)(state)
Jabalizer.CNOT(1,6)(state)

# Display the stabilizer tableau
Jabalizer.update_tableau(state)
tab = Jabalizer.to_tableau(state)
display(tab)

# Convert to graph state
graphState = GraphState(state)

# Display graph adjacency matrix
display(graphState.A)

# Plot graph
Jabalizer.gplot(Jabalizer.Graph(graphState.A))

# Convert back to stabilizer state
stabState = StabilizerState(graphState)
```

Produces the output:

```julia

6×13 Matrix{Int64}:
 1  1  1  1  1  1  0  0  0  0  0  0  0
 0  0  0  0  0  0  1  1  0  0  0  0  0
 0  0  0  0  0  0  1  0  1  0  0  0  0
 0  0  0  0  0  0  1  0  0  1  0  0  0
 0  0  0  0  0  0  1  0  0  0  1  0  0
 0  0  0  0  0  0  1  0  0  0  0  1  0

6×6 Matrix{Int64}:
 0  1  1  1  1  1
 1  0  0  0  0  0
 1  0  0  0  0  0
 1  0  0  0  0  0
 1  0  0  0  0  0
```

<p align="center"><img src="https://user-images.githubusercontent.com/4382522/123879677-b45f7f80-d984-11eb-8590-67a3714eec71.png" width="50%"></p>

# Acknowledgements

We especially thank [Craig Gidney](https://algassert.com) and co-developers for developing the [STIM package](https://github.com/quantumlib/Stim) which provides the CHP backend upon which Jabalizer is based, and especially for implementing some modifications that provided the functionality necessary for this integration. The technical whitepaper for STIM is available [here](https://arxiv.org/abs/2103.02202).
