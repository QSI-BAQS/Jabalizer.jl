"""
Add a qubit to a stabilizer with given Pauli operator and phase.
"""
function AddQubit(stabilizer::Stabilizer, pauli::Char, phase::Int64)
    if pauli == 'I'
        x = 0
        z = 0
    elseif pauli == 'X'
        x = 1
        z = 0
    elseif pauli == 'Z'
        x = 0
        z = 1
    elseif pauli == 'Y'
        x = 1
        z = 1
    end

    push!(stabilizer.X, x)
    push!(stabilizer.Z, z)
    stabilizer.phase += phase
    stabilizer.qubits += 1
end

"""
Add a qubit to a stabilizer with identity operator.
"""
function AddQubit(stabilizer::Stabilizer)
    AddQubit(stabilizer, 'I', 0)
end

"""
Add multiple qubits to a Stabilizer.
"""
function AddQubits(stabilizer::Stabilizer, length::Int64)
    for i = 1:length
        AddQubit(stabilizer, 'I', 0)
    end
end

function AddQubit(state::StabilizerState, pauli::Char, phase::Int64, label::String)
    for s in state.stabilizers
        AddQubit(s)
    end

    newStabilizer = Stabilizer(state.qubits)
    AddQubit(newStabilizer, pauli, phase)
    push!(state.stabilizers, newStabilizer)
    push!(state.labels, label)
    push!(state.lost, 0)
    state.qubits += 1
end

function AddQubit(state::StabilizerState, pauli::Char, phase::Int64)
    AddQubit(state, pauli, phase, string(state.qubits + 1))
end

function AddQubit(state::StabilizerState, qubit::Char, label::String)
    pauli = 'I'
    phase::Int64 = 0

    if qubit == '0'
        pauli = 'Z'
        phase = 0
    elseif qubit == '1'
        pauli = 'Z'
        phase = 2
    elseif qubit == '+'
        pauli = 'X'
        phase = 0
    elseif qubit == '-'
        pauli = 'X'
        phase = 2
    elseif qubit == 'L'
        pauli = 'Y'
        phase = 0
    elseif qubit == 'R'
        pauli = 'Y'
        phase = 2
    end

    AddQubit(state, pauli, phase, label)
end

function AddQubit(state::StabilizerState, qubit::Char)
    AddQubit(state, qubit, string(state.qubits + 1))
end

"""
    AddBell(state, labelA, labelB)

Add Bell state ``(|00\\rangle+|11\\rangle)/\\sqrt{2}`` to a State.
"""
function AddBell(state::StabilizerState, label1::String, label2::String)
    AddGHZ(state, 2, [label1, label2])
end

"""
    AddBell(state)

Add Bell state ``(|00\\rangle+|11\\rangle)/\\sqrt{2}`` to a State.
"""
function AddBell(state::StabilizerState)
    AddGHZ(state, 2)
end

"""
    AddGHZ(state, size, labels)

Add a GHZ state to a State.
"""
function AddGHZ(state::StabilizerState, size::Int64, labels::Array{String})
    AddQubit(state, '+', labels[1])
    start = state.qubits

    for i = 1:(size-1)
        AddQubit(state, '0', labels[i+1])
        CNOT(state, start, start + i)
    end
end

"""
    AddGHZ(state, size)

Add a GHZ state to a State.
"""
function AddGHZ(state::StabilizerState, size::Int64)
    labels::Array{String} = []

    for i = 1:size
        push!(labels, string(state.qubits + i))
    end

    AddGHZ(state, size, labels)
end

"""
    AddGHZ(state)

Add a 3-qubit GHZ state to a State.
"""
function AddGHZ(state::StabilizerState)
    AddGHZ(state, 3)
end

"""
    AddGraph(state, graph, labels)

Add a graph state to a State.
"""
function AddGraph(state::StabilizerState, graph::Array{Int64,2}, labels::Array{String})
    qubits = state.qubits
    graphSize = size(graph, 1)

    for n = 1:graphSize
        AddQubit(state, '+', labels[n])
    end

    for i = 1:(graphSize-1)
        for j = (i+1):graphSize
            if graph[i, j] == 1
                CZ(state, qubits + i, qubits + j)
            end
        end
    end
end

"""
    AddGraph(state, graph)

Add a graph state to a State.
"""
function AddGraph(state::StabilizerState, graph::Array{Int64,2})
    qubits = size(graph, 1)
    labels::Array{String} = []

    for n = 1:qubits
        push!(labels, string(state.qubits + n))
    end

    AddGraph(state, graph, labels)
end
