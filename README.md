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

While simulating arbitrary quantum circuits is classically inefficient with exponential resource overhead, via the [Gottesman-Knill theorem](https://arxiv.org/abs/quant-ph/9807006) it is known that circuits comprising only Clifford operations (ones that commute with the Pauli group) can be efficiently simulated using the stabilizer formalism. The efficiency of classically simulating stabilizer circuits was subsequently improved upon by [Aaronson & Gottesman](https://arxiv.org/abs/quant-ph/0406196) using the CHP approach which tracks both stabilizers and anti-stabilizers, improving the performance of measurements within this model. Jabalizer employs the highly-optimised [STIM simulator](https://github.com/quantumlib/Stim) as the CHP backend.

# Graph states

All stabilizer states can be converted to graph states via local operations, achieved via a tailored Gaussian elimination procedure on the stabilizer tableau. Jabalizer allows an arbitrary stabilizer state to be converted to a locally equivalent graph state and provide the associated adjacency matrix for the respective graph.

# Acknowledgements

We especially thank Craig Gidney and co-developers for developing the STIM package which provides the CHP backend upon which Jabalizer is based. The technical whitepaper for STIM is available [here](https://arxiv.org/abs/2103.02202).
