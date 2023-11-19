# Some scripts for small scale testing

*So currently the repo is private and you all should have push access, but I if you want
to push something, I would prefer it if is done with a separate branch first and then
make something like a pull request*

Before I describe how to use it:

**Important**: These are just some dirty script that I patched together to make things
work for the simple use cases I had. There are a few things that should be improved to
make things more convenient and usable:
- the naming convention for the output files is a house of cards: specify the file name,
  without "output/" prefix and ".json" suffix in jabalize.jl, e.g., "bar" -> jabalize
produces "output/bar\_some\_suffix.json" files -> pass "bar" as command line option to
the analyze script -> analyze reads "output/bar\_some\_suffix.json" files and produces
"output/bar\_analyzed.json" -> specify "bar" in check.py -> check.py reads
"output/bar\_analyzed.json"
- the way the RZ measurement is implement works only for the qft examples (specific
rotation angle encoding)
- more idiomatic code (especially the julia code ... I never really coded in julia)
- make things more functional
- instead of hardcoding the circuits in jabalize.jl, it would be nice to parse qasm
files or similar; to make this work properly one might first need to refactor how gates
are represented in Jabalizer (currently just strings; some proper structures with
parameters would make things easier, I guess; for example it's really ugly how I encoded
the rotation parameters for the qft ...); okay, if you always decompose into Clifford +
T it's actually fine the way it is because we don't need parameters

Also, there's currently a lot of commented "print" commands in the script which might
have some useful debugging output

The scripts are only for small scale. For example, dumping huge matrices into json files
might become a problem for large circuits; a binary serialization might be better then.

I've been using Python 3.11.5., Julia 1.9.3 and the latest Rust toolchain (but stable
1.65 should be sufficient, I think)

In the Rust and Python script, indexing starts from 0, so qubits labels are shifted by
one compared to the Julia stuff

## How to use it

### Installing the Jabalizer library

- First follow the instructions in jabalizer's README.md (on the this branch)
- Now in the julia repl, go into the package management modus (`julia` and then `]`;
backspace to get out of it) and set up the dependencies:
  - `activate .`
  - `add JSON`
    `add Pkg`
  - `dev <path/to/jabalizer>` (`add ...` does not work for me)
  - backspace to get out
I'm not tracking the Project.toml and Manifest.toml files, because we have a path
dependency. There should be a cleaner way to set all this up, e.g., with something
like a build script, but I don't really know anything about this stuff for julia.

### The jabalize.jl script

Run it interactively (for caching because precompiling jabalizer takes forever) in the
julia repl after activating the local project (`active .`), with `include(jabalize.jl`).

The script has some hardcoded circuits (toffoli and qft) which are put into jabalizer's
compile function from the icm module. This compile function decomposes the circuit into
Clifford + teleported rotation, in a very limited way (rotation parameter encoded ...),
and while doing that runs the pauli\_tracker for the circuit. The decomposed circuit is
then fed into jabalizers main function to generate the spacial graph state. Then
everything is just dump into multiple json files which are used in the next step

### The analyze script

Build it with `cargo build --release` and run the binary in the target/release directory
(there's also `analyze` link to it when on linux) or direcly use `cargo run --release`.

This script takes all the output from before and defines the "paths" through the graph
which are allowed by the measurement flow captured by the pauli tracking. With path I
mean a sequence of grouped initialization and measurement steps for the qubits. The
number of possible paths is generally higher than exponential. We only want the "best"
paths. "best" means that we want small memory requirements, i.e., we don't want to keep
many qubits in memory at the same time, and/or a small number of these "groups" of
initialization and measurement steps (if the number of these groups is low, one can in
theory (completely ignoring the hardware) perform more stuff in parallel. The output
will be something like (the following are just arbitrary numbers)
```
|groups|   |memory|      measurement sequence
2          5            [[0, 1, 2], [3, 4]]
3          3            [[0], [1, 2] [3, 4]]
```
The best paths are not necessarily unique. Finding these best paths is a hard task and
currently done by brute forcing, with some shortcuts (the documentation of the
pauli\_tracker crate has some information about how it is done in the schedule module).
For small numbers of nodes the runtime is okay but it completely explodes for higher
numbers. It also depends highly on the spacial graph and the measurement flow from the
pauli tracking. The script can also be run multi-threaded (currently, this prints some
information about which tasks have been started and finished with some additional
information; just comment the according lines in src/run.rs::threaded\_search if you
don't want that). Alternatively (this is actually the default) one can also skip the
search for the best paths and choose the trivial path which can be directly read off
from the pauli tracking results (this is actually the time optimal path). See `analyze
--help`. The results of this script are dump into single json file, together with the
data in the other related json files (so that we only have to load one json file from
now on.

### The check.py script

To run this script, create a python environment, e.g., `python -m venv .venv` (`.venv`
will not be tracked), activate it, e.g., `. .venv/bin/activate`, and install the
requirement, `pip install -r requirements.txt`.

This scripts loads the json file from the previous step. We have all information to
construct the circuit. The circuit is constructed according to these information, and
then it is appended with the inverse action of what it should be doing. The circuit is
then simulated and the resulting probability distribution should hopefully be (1, 0, 0,
0, 0, ....), corresponding to ket{0}.
