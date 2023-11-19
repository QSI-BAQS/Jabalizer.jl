#!/usr/bin/env python

from qiskit import QuantumCircuit, ClassicalRegister, QuantumRegister
import qiskit
from qiskit_aer.aerprovider import AerSimulator
import json
import numpy as np
import copy


def main():
    # name = "toffoli_ppo"
    # gate_inverse = toffoli
    name = "fourier_4_oooo"
    # name = "fourier_4_pppp"
    gate_inverse = qft_inverse

    # name = name + "_analyzed.json"
    name = "output/" + name + "_analyzed.json"

    # which path (0: times optimal, -1: space optimal
    path_idx = -1

    # load all the information; below are some commented print commands to view it
    with open(name) as f:
        data = json.load(f)
    frames = data["frames"]["storage"]
    frames_map = data["frames_map"]
    output_map = data["output_map"]
    total_num_bits = len(frames_map) + len(output_map)
    graph = data["graph"]
    local_ops = data["local_ops"]
    local_ops.reverse()
    all_paths = data["paths"]
    path = data["paths"][path_idx]
    initializer = data["initializer"]
    measurements = [None] * total_num_bits
    for m, b, a in data["measurements"]:
        measurements[b] = (m, a)

    # with do_init one can set arbitrary inputs which will be interesting when testing
    # graphs that work for arbitrary input
    do_init = None
    # do_init = [
    #     [0, 1, 2],
    #     [
    #         ["h", [], [0]],
    #         ["crz", [2.0], [0, 1]],
    #         ["crx", [2.95], [1, 2]],
    #         ["u", [1.2, 2.3, 3.4], [0]],
    #         ["ccx", [], [0, 2, 1]],
    #     ],
    # ]

    # run the circuit according to the instructions induced by the information we have
    # and get the resulting probability distribution
    pdf = simulate(
        gate_inverse,
        frames_map,
        output_map,
        measurements,
        path,
        frames,
        copy.deepcopy(graph),
        local_ops,
        initializer,
        total_num_bits,
        do_init,
        show_circuit=True,
    )

    # print(f"path: {path}")
    # print(f"graph: {graph}")
    # print(f"frames: {frames}")
    # print(f"frames_map: {frames_map}")
    # print(f"measurements: {measurements}")
    # print(f"output_map: {output_map}")
    # print(f"local_ops: {local_ops}")
    # print(f"initializer: {initializer}")
    # print(f"all_paths: {all_paths}")

    print(f"pdf: {pdf}")  # should be [1, 0, 0, 0, ....]


def simulate(
    gate_inverse,
    frames_map,
    output_map,
    measurements,
    path,
    frames,
    graph,
    local_ops,
    initializer,
    total_num_bits,
    do_init=None,
    show_circuit=False,
):
    creg = ClassicalRegister(total_num_bits)
    reg = QuantumRegister(total_num_bits)
    c = QuantumCircuit(reg, creg)

    initialized = [False] * total_num_bits

    if do_init:
        for bit in do_init[0]:
            initialized[bit] = True
        for gate, parameter, bits in do_init[1]:
            if len(parameter) > 0:
                getattr(c, gate)(*parameter, *bits)
            else:
                getattr(c, gate)(*bits)
        c.h(2)

    for measure_set in path[1][1]:
        # perform the initialization and measurement for the measure_set (that's the
        # "group" I meant in the README.md
        step(
            c,
            measure_set,
            frames,
            graph,
            local_ops,
            measurements,
            frames_map,
            initialized,
        )

    # do the correction on the output qubits and invert the gate and the initialization
    for node in output_map:
        correct(c, node, frames[str(node)], frames_map)
    c.barrier()
    gate_inverse(c, output_map)
    c.barrier()
    if do_init:
        for gate, parameter, bits in reversed(do_init[1]):
            gate_circ = QuantumCircuit(len(bits))
            tmp_bits = [i for i in range(len(bits))]
            if len(parameter) > 0:
                getattr(gate_circ, gate)(*parameter, *tmp_bits)
            else:
                getattr(gate_circ, gate)(*tmp_bits)
            inverse = gate_circ.inverse().to_instruction()
            bits = [output_map[bit] for bit in bits]
            c.append(inverse, bits)
    else:
        for gate, bit in initializer:
            init(c, gate, output_map[bit])
    c.barrier()

    for bit in output_map:
        c.measure(bit, bit)

    if show_circuit:
        print(c)

    cc = qiskit.transpile(c, backend=AerSimulator(), optimization_level=3)
    # print(cc)
    result = AerSimulator().run(cc, shots=1024).result().get_counts()
    return counts_to_pdf(output_map, result)


def step(
    c: QuantumCircuit,
    measure_set,
    frames,
    graph,
    local_ops,
    measurements,
    frames_map,
    initialized,
):
    for node in measure_set:
        # initialize the node and its neighbors and create the edges
        if not initialized[node]:
            initialized[node] = True
            c.h(node)
        for neighbor in graph[node]:
            neighbors_neighbors = graph[neighbor]
            neighbors_neighbors.remove(node)
            if not initialized[neighbor]:
                initialized[neighbor] = True
                c.h(neighbor)
            c.cz(node, neighbor)
        # local corrections from the Gauß-like elimination
        for op in [m[0] for m in local_ops if m[1] == node]:
            if op == "H":
                c.h(node)
            elif op == "Z":
                c.z(node)
            elif op == "Pdag":
                c.s(node)
            else:
                raise Exception(f"other local correction: {op}")
        measurement = measurements[node]
        # don't measure if it is actually an output qubit
        if measurement == None:
            pass
        else:
            # pauli correction and measurements
            correct(c, node, frames[str(node)], frames_map)
            measurement, add = measurement
            if measurement == "T":
                c.t(node)
            elif measurement == "TD":
                c.tdg(node)
            elif measurement == "RZ":
                # decoding of the integer for the qft rotations
                if add < 0:
                    c.rz(-np.pi / float(2 ** (-add)), node)
                else:
                    c.rz(np.pi / float(2**add), node)
            else:
                raise Exception(f"other measurement type: {measurement}")
            c.h(node)
            c.measure(node, node)
    c.barrier()


# the pauli corrections (in reality one would of course first calculate the bitsum and
# then do only one conditional Pauli)
def correct(c: QuantumCircuit, node, stack, frames_map):
    for (left, right), bit in zip(zip(stack["left"], stack["right"]), frames_map):
        if left:
            c.x(node).c_if(bit, 1)
        if right:
            c.z(node).c_if(bit, 1)


# transformed the counts from the qiskit simulation into a real pdf; some really ugly
# bit shifting (and similar) is necessary here
def counts_to_pdf(bits, counts):
    num_bits = len(bits)
    pdf = np.zeros(2**num_bits, dtype=np.int_)
    masks = []
    for i, _ in enumerate(pdf):
        bit = 0
        for j, b in enumerate(bits):
            bit += (i & 2**j) << (b - j)
        masks.append(bit)
    masks.reverse()
    for e in counts:
        found = False
        for i, mask in enumerate(masks):
            # if (int(e, 2) ^ mask) == 0:
            if (int(e, 2) & mask) == mask:
                # print(e, f"{mask:b}")
                pdf[2**num_bits - 1 - i] += counts[e]
                found = True
                break
        if not found:
            raise Exception(f"no mask found for {e}")
    # print([f"{m:b}" for m in masks])
    pdf = pdf / float(np.sum(pdf))
    return pdf


def init(c: QuantumCircuit, gate, bits):
    if gate == "H":
        c.h(bits)
    elif gate == "X":
        c.x(bits)
    elif gate == None:
        pass
    else:
        raise Exception(f"other initializer: {gate}")


def toffoli(c: QuantumCircuit, bits):
    c.ccx(*bits)


def ccz(c: QuantumCircuit, bits):
    c.ccz(*bits)


def qft_inverse(c: QuantumCircuit, bits):
    for i in range(0, len(bits)):
        for j in range(0, i):
            c.crz(-np.pi / float(2 ** (i - j)), bits[j], bits[i])
        c.h(bits[i])


if __name__ == "__main__":
    main()
