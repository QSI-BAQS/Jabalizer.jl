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
end

using Jabalizer

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
        cargs = nothing # Thinh: read in rotation gate angles, for example if RX(0.5) then cargs = [0.5] a list of one Float64
        qargs = [Jabalizer.pyconvert(Int, qubit) + 1 for qubit in op.qubit_indices] # one-based indexing
        push!(onebased_circuit, Jabalizer.Gate(name, cargs, qargs))
    end
    n_qubits = Jabalizer.pyconvert(Int, circuit.n_qubits)

    # Warning: from now on assume input_circuit is a list of Jabalizer.Gate
    # acting on [1,2,...,n_qubits]. Please ensure this when splitting qasm files.
    
    filepath = "output/$(circuit_fname)/$(circuit_fname)$(suffix)_all0init_jabalizer.out.json"

    if debug_flag
        @info "RRE: Running `Jabalizer.mbqccompile` ...\n"
    end

    # ASSUME qubits are indexed from 1 to n_qubits
    js = Jabalizer.mbqccompile(
        Jabalizer.QuantumCircuit([1:n_qubits], onebased_circuit);
        universal=true,
        ptracking=true,
        filepath=filepath,
    )

    return js # return the Jabalizer output in JSON format
    # js = JSON.json(Dict(
    #     :time => time, # length(steps) how many time steps
    #     :space => space, # maximum number of qubits required
    #     :steps => steps, # actual MBQC instructions: for each step in steps init nodes and CZ based on spacialgraph
    #     :spacialgraph => [zerobasing(nb) for nb in Graphs.SimpleGraphs.adj(fullgraph)], # description of CZ gates to be applied (edge = apply CZ gate)
    #     :correction => [(g, zerobasing(q)) for (g, q) in correction], # potential local Clifford correction on each nodes right after CZ above
    #     :measurements => map(unpackGate, measurements), # list of measurements
    #     :statenodes => zerobasing(labels[:state]), # nodes where the input state is currently in
    #     :outputnodes => zerobasing(labels[:output]), # get the output state returned by the circuit from these nodes
    #     :frameflags => ptracker[:frameflags], # already zero-based # used to be frame_maps
    #     :initializer => initializer, # what was passed in from caller
    # ))
end

