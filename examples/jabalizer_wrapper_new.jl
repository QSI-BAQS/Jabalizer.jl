#!/usr/bin/env julia

# Copyright 2022-2024 Rigetti & Co, LLC
#
# This Computer Software is developed under Agreement HR00112230006 between Rigetti & Co, LLC and
# the Defense Advanced Research Projects Agency (DARPA). Use, duplication, or disclosure is subject
# to the restrictions as stated in Agreement HR00112230006 between the Government and the Performer.
# This Computer Software is provided to the U.S. Government with Unlimited Rights; refer to LICENSE
# file for Data Rights Statements. Any opinions, findings, conclusions or recommendations expressed
# in this material are those of the author(s) and do not necessarily reflect the views of the DARPA.
#
# Use of this work other than as specifically authorized by the U.S. Government is licensed under
# the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.

# A julia wrapper script to manage RRE's default FT-compiler, Jabalizer.
#
# Parts of the following code are inspired and/or customized from the original templates in the 
# open-source references of:
# [1] https://github.com/QSI-BAQS/Jabalizer.jl
# [2] https://github.com/zapatacomputing/benchq

# [1] is distributed under the MIT License and includes the following copyright and permission 
# statements:
# Copyright (c) 2021 Peter Rohde, Madhav Krishnan Vijayan, Simon Devitt, Alexandru Paler.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


if !isinteractive()
    import Pkg
    Pkg.activate("Jabalizer.jl/")
    Pkg.add("JSON")
    Pkg.add("Graphs")
    Pkg.add("GraphPlot")
    Pkg.add("Documenter")
    Pkg.add("PythonCall"); Pkg.build("PythonCall");
end

using Jabalizer
using JSON

# circuit is an orquestra.quantum.circuits.Circuit object
function run_jabalizer(circuit, circuit_fname, suffix, debug_flag=false)
    if debug_flag
        println("\nRRE: Jabalizer FT-compiler starts ...\n")
    end

    mkpath("output/$(circuit_fname)/")

    # circuit is an orquestra.quantum.circuits.Circuit object representing 
    # a quantum circuit acting on [0,1,...,n_qubits-1] qubits

    # Reading the orquestra circuit and convert to one-based indexing
    onebased_circuit = Gate[]
    for op in circuit.operations
        name = Jabalizer.pyconvert(String, op.gate.name)
        cargs = nothing # Nariman: read in rotation gate angles, for example if RX(0.5) then cargs = [0.5] a list of one Float64
        qargs = [Jabalizer.pyconvert(Int, qubit) + 1 for qubit in op.qubit_indices] # one-based indexing
        push!(onebased_circuit, Jabalizer.Gate(name, cargs, qargs))
    end
    n_qubits = Jabalizer.pyconvert(Int, circuit.n_qubits)

    # Warning: from now on assume input_circuit is a list of Jabalizer.Gate
    # acting on [1,2,...,n_qubits]. Please ensure this when splitting qasm files.
    
    if debug_flag
        println("RRE: Running `Jabalizer.gcompile` function ...\n")
    end

    # ASSUME qubits are indexed from 1 to n_qubits
    graphstate, correction, inputnodes, outputnodes, frames_map, measurements = Jabalizer.gcompile(
        Jabalizer.QuantumCircuit([1:n_qubits], onebased_circuit);
        universal=true,
        ptracking=true,
    )

    # Move to Jabalizer
    # Converting to sparse graph representation (adjacency list)
    sparsegraph::Vector{Vector{Int}} = []
    for i in range(1, n_total)
        node = []
        for (j, e) in enumerate(graphState.A[i, :])
            if e == 1 && j != i
                push!(node, j - 1)
            end
        end
        push!(graph, node)
    end

    jabalizer_out = Dict(
        :graphstate     => graphstate, # the "spacial" graph as adjacency list
        :correction     => correction, # local corrections on the spacial graph from the Gauß-like elimination
        :inputnodes     => inputnodes, # which qubits are the input qubits
        :outputnodes    => outputnodes, # which qubits are the output qubits
        :frames_map     => frames_map, # which Pauli frames belong to which measurements
        :initializer    => [], # currently not used, i.e. initial state is 00...0
        :measurements   => measurements, # sequence of single qubit measurements (gate_name, qubit, additional information encoded in one integer (cf. qft rotations))
    )

    if debug_flag
        println("RRE: Writing Jabalizer outputs to JSON...\n")
    end

    filepath = "output/$(circuit_fname)/$(circuit_fname)$(suffix)_all0init_jabalizer.out.json"

    open(filepath, "w") do file
        write(file, JSON.json(jabalize_output))
    end

    # # Replace unwanted chars in jabalize JSON (since Julia lacks some JSON tools)
    # jabalize_string = read(jabalizeframes_json, String)
    # jabalize_string = replace(jabalize_string, "}{" => ",", count=1)
    # open(jabalizeframes_json, "w") do file
    #     write(file, jabalize_string)
    # end
end

