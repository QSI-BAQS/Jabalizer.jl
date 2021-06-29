# Jabalizer

<script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML" type="text/javascript"></script>

# Contents

* Table of contents
{:toc}

# Developers

+ Madhav Krishnan Vijayan ([mkv.215@gmail.com](mailto:mkv.215@gmail.com))
+ Hudson Leone ([leoneht0@gmail.com](mailto:leoneht0@gmail.com))
+ Peter Rohde ([dr.rohde@gmail.com](mailto:dr.rohde@gmail.com), [www.peterrohde.org](https://www.peterrohde.org))

# About

Jabalizer is a simulator for quantum Clifford circuits and graph states written in Julia, both of which can be efficiently simulated using the stabilizer formalism. Jabalizer provides generic functions able to operate within both pictures and dynamically convert between them, allowing arbitrary Clifford circuits to be simulated and converted into graph state language, and vice-versa.

# Stabilizer circuits

While simulating arbitrary quantum circuits is classically inefficient with exponential resource overhead, via the [Gottesman-Knill theorem](https://arxiv.org/abs/quant-ph/9807006) it is known that circuits comprising only Clifford operations (ones that commute with the Pauli group) can be efficiently simulated using the stabilizer formalism. In the stabilizer formalism an _n_-qubit state is defined as the simultaneous positive eigenstate of _n_ 'stabilizers', each of which is an _n_-fold tensor product of Pauli operators and a sign (+/-). That is, for each stabilizer $$ S_i $$ (for $$ i=1\dots n $$) the state $$ |\psi\rangle $$ satisfies,
$$ S_i|\psi\rangle = |\psi\rangle $$.

As an example, the Bell state $$ \frac{1}{\sqrt{2}}(|0,0\rangle + |1,1\rangle) $$ can equivalently be represented by the two stabilizers,
$$ S_1 = XX $$,
$$ S_2 = ZZ $$.

Similarly, the three-qubit GHZ state can be represented by the three stabilizers,
$$ S_1 = XXX $$,
$$ S_2 = ZZI $$,
$$ S_3 = IZZ $$.

Evolving stabilizer states can be performed in the Heisenberg picture by conjugating the stabilizers with the unitary operations acting upon the state since for the evolution,
$$ |\psi'\rangle = U |\psi\rangle $$,
we can equivalently write,
$$ |\psi'\rangle = US_i |\psi\rangle  = U S_i U^\dag U |\psi\rangle = U S_i U^\dag |\psi'\rangle  = S_i' |\psi'\rangle $$,
where $$ S_i' = U S_i U^\dag $$, stabilizes the evolved states $$ |\psi'\rangle = U |\psi\rangle $$.

The efficiency of classically simulating stabilizer circuits was subsequently improved upon by [Aaronson & Gottesman](https://arxiv.org/abs/quant-ph/0406196) using the so-called CHP approach which tracks both stabilizers and anti-stabilizers, improving the performance of measurements within this model. Jabalizer employs the highly-optimised [STIM simulator](https://github.com/quantumlib/Stim) as its CHP backend.

# Graph states

$$ S_i = X_i \prod_{j\in n_i} Z_j $$

All stabilizer states can be converted to graph states via local operations, achieved via a tailored Gaussian elimination procedure on the stabilizer tableau. Jabalizer allows an arbitrary stabilizer state to be converted to a locally equivalent graph state and provide the associated adjacency matrix for the respective graph.

# Acknowledgements

We especially thank Craig Gidney and co-developers for developing the STIM package which provides the CHP backend upon which Jabalizer is based. The technical whitepaper for STIM is available [here](https://arxiv.org/abs/2103.02202).
