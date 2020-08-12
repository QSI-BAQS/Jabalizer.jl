# Jabalizer
# Quantum stabilizer circuit simulator
# by Peter P. Rohde

#module Jabalizer

export State, Stabilizer, GetQubitLabel, ToString, Print, AddQubit, I, P, X, Y, Z, H, CNOT, CZ

"""
Stabilizer datatype for a single Pauli group stabilizer.
qubits: number of qubits.
X,Z: binary bitstrings where;
    (X=1,Z=0) denotes Pauli X,
    (X=0,Z=1) denotes Pauli Z,
    (X=1,Z=1) denotes Pauli Y.
phase: (1,-1,i,-i) denotes the phase of the stabilizer.
"""
mutable struct Stabilizer
    qubits::Int64
    X::Array{Int8}
    Z::Array{Int8}
    phase::Complex

    """
    Generator for an empty stabilizer.
    """
    Stabilizer() = new(0, [], [], 1+0im)

    """
    Generator for an n-qubit identity stabilizer.
    """
    Stabilizer(n) = new(n, zeros(n), zeros(n), 1+0im)
end

"""
State datatype for a stabilizer state.
qubits: number of qubits.
stabilizers: set of state stabilizers.
labels: qubit labels.
"""
mutable struct State
    qubits::Int64
    stabilizers::Array{Stabilizer}
    labels::Array{String}

    State() = new(0,[],[])
    State(n) = new(n,[],[])
end

function GetQubitLabel(state::State, qubit::Int64)
        return qubit
end

function GetQubitLabel(state::State, qubit::String)
        return findfirst(x->x==qubit, state.labels)
end

"""
Convert a stabilizer to a string.
"""
function ToString(stabilizer::Stabilizer)
    str = ""

    for i in 1:stabilizer.qubits
        if stabilizer.X[i] == 0 && stabilizer.Z[i] == 0
            thisPauli = 'I'
        elseif stabilizer.X[i] == 1 && stabilizer.Z[i] == 0
            thisPauli = 'X'
        elseif stabilizer.X[i] == 0 && stabilizer.Z[i] == 1
            thisPauli = 'Z'
        elseif stabilizer.X[i] == 1 && stabilizer.Z[i] == 1
            thisPauli = 'Y'
        end

        str = string(str, thisPauli)
    end

    return string(str, " (", stabilizer.phase, ")")
end

"""
Print a stabilizer to the terminal.
"""
function Print(stabilizer::Stabilizer)
    println("Stabilizer for ", stabilizer.qubits, " qubits:")
    println(ToString(stabilizer))
    println()
end

"""
Convert a state to a string.
"""
function ToString(state::State)
    str = ""

    for s in state.stabilizers
        str = string(str, ToString(s), '\n')
    end

    return str
end

"""
Print a state string to the terminal.
"""
function Print(state::State)
    println("Stabilizers for ", state.qubits, " qubit state:")
    println(ToString(state))

    println("Qubit labels:")
    println(state.labels)
end

function AddQubit(stabilizer::Stabilizer, pauli::Char, phase::Complex)
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
    stabilizer.phase *= phase
    stabilizer.qubits += 1
end

function AddQubit(stabilizer::Stabilizer)
    AddQubit(stabilizer,'I',1+0im)
end

function AddQubits(stabilizer::Stabilizer, length::Int64)
    for i in 1:length
        AddQubit(stabilizer,'I',1+0im)
    end
end

function AddQubit(state::State, pauli::Char, phase::Complex, label::String)
    for s in state.stabilizers
        AddQubit(s)
    end

    newStabilizer = Stabilizer(state.qubits)
    AddQubit(newStabilizer, pauli, phase)
    push!(state.stabilizers, newStabilizer)
    push!(state.labels, label)
    state.qubits += 1
end

function AddQubit(state::State, pauli::Char, phase::Complex)
    AddQubit(state, pauli, phase, string(state.qubits+1))
end

function AddQubit(state::State, qubit::Char, label::String)
    pauli = 'I'
    phase::Complex = 1

    if qubit == '0'
        pauli = 'Z'
        phase = 1
    elseif qubit == '1'
        pauli = 'Z'
        phase = -1
    elseif qubit == '+'
        pauli = 'X'
        phase = 1
    elseif qubit == '-'
        pauli = 'X'
        phase = -1
    elseif qubit == 'L'
        pauli = 'Y'
        phase = 1
    elseif qubit == 'R'
        pauli = 'Y'
        phase = -1
    end

    AddQubit(state, pauli, phase, label)
end

function AddQubit(state::State, qubit::Char)
    AddQubit(state, qubit, string(state.qubits+1))
end

function AddBell(state::State, label1::String, label2::String) # |00>+|11>
    AddGHZ(state, 2, [label1, label2])
end

function AddBell(state::State)
    AddGHZ(state, 2)
end

function AddGHZ(state::State, size::Int64, labels::Array{String})
    for s in state.stabilizers
        AddQubits(s,size)
    end

    AddQubit(state,'+',labels[1])
    start = state.qubits

    for i in 1:(size-1)
        AddQubit(state,'0',labels[i+1])
        CNOT(state, start, start+i)
    end
end

function AddGHZ(state::State, size::Int64)
    labels::Array{String} = []

    for i in 1:size
        push!(labels, string(state.qubits+i))
    end

    AddGHZ(state, size, labels)
end

function AddGHZ(state::State)
    AddGHZ(state, 3)
end

function AddGraph(state::State, graph::Array{Int64,2}, labels::Array{String})
    qubits = state.qubits
    graphSize = size(graph,1)

    for n in 1:graphSize
        AddQubit(state,'+',labels[n])
    end

    for i in 1:(graphSize-1)
        for j in (i+1):graphSize
            if graph[i,j] == 1
                CZ(state, qubits+i, qubits+j)
            end
        end
    end
end

function AddGraph(state::State, graph::Array{Int64,2})
    qubits = size(graph,1)
    labels::Array{String} = []

    for n in 1:qubits
        push!(labels, string(state.qubits+n))
    end

    AddGraph(state, graph, labels)
end

function I(stabilizer::Stabilizer, qubit::Int64)
    # IUI = U
end

function P(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 0 && z == 1 # PZP' = Z
        stabilizer.phase *= -1
    elseif x == 1 && z == 0 # PXP' = ?
        stabilizer.phase *= -1
    elseif x == 1 && z == 1 # PYP' = ?
    end
end

function X(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 0 && z == 1 # XZX = -Z
        stabilizer.phase *= -1
    elseif x == 1 && z == 1 # XYX = -Y
        stabilizer.phase *= -1
    end
end

function Y(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 0 && z == 1 # YZY =
        stabilizer.phase *= -1
    elseif x == 1 && z == 1 # YXY = -X
        stabilizer.phase *= -1
    end
end

function Z(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 1 && z == 0 # ZXZ = -X
        stabilizer.phase *= -1
    elseif x == 1 && z == 1 # ZYZ = -Y
        stabilizer.phase *= -1
    end
end

function H(stabilizer::Stabilizer, qubit::Int64)
    x = stabilizer.X[qubit]
    z = stabilizer.Z[qubit]

    if x == 1 && z == 0
        stabilizer.X[qubit] = 0
        stabilizer.Z[qubit] = 1
    elseif x == 0 && z == 1
        stabilizer.X[qubit] = 1
        stabilizer.Z[qubit] = 0
    elseif x == 1 && z == 1
        stabilizer.phase *= -1
    end
end

function CZ(stabilizer::Stabilizer, control::Int64, target::Int64)
    xc = stabilizer.X[control]
    zc = stabilizer.Z[control]
    xt = stabilizer.X[target]
    zt = stabilizer.Z[target]

    if xc == 1
        stabilizer.Z[target] = 1 - stabilizer.Z[target]
    end

    if xt == 1
        stabilizer.Z[control] = 1 - stabilizer.Z[control]
    end
end

function SWAP(stabilizer::Stabilizer, qubit1::Int64, qubit2::Int64)
    tempZ = stabilizer.Z[qubit1]
    tempX = stabilizer.X[qubit1]

    stabilizer.Z[qubit1] = stabilizer.Z[qubit2]
    stabilizer.X[qubit1] = stabilizer.X[qubit2]

    stabilizer.Z[qubit2] = tempZ
    stabilizer.X[qubit2] = tempX
end

function I(state::State, qubit)
end

function P(state::State, qubit)
    for s in state.stabilizers
        P(s, GetQubitLabel(qubit))
    end
end

function X(state::State, qubit)
    for s in state.stabilizers
        X(s, GetQubitLabel(qubit))
    end
end

function Y(state::State, qubit)
    for s in state.stabilizers
        Y(s, GetQubitLabel(state,qubit))
    end
end

function Z(state::State, qubit)
    for s in state.stabilizers
        Z(s, GetQubitLabel(state,qubit))
    end
end

function H(state::State, qubit)
    for s in state.stabilizers
        H(s, GetQubitLabel(state,qubit))
    end
end

function CNOT(state::State, control, target)
    H(state,target)
    CZ(state,control,target)
    H(state,target)
end

function CZ(state::State, control, target)
    for s in state.stabilizers
        CZ(s, GetQubitLabel(state,control), GetQubitLabel(state,target))
    end
end

function SWAP(state::State, qubit1, qubit2)
    for s in state.stabilizers
        SWAP(s, GetQubitLabel(state,qubit1), GetQubitLabel(state,qubit2))
    end
end

function ChannelZ(state::State, qubit, prob::Float64)
    if rand(Float64) < prob
        Z(state,qubit)
    end
end

function ChannelZ(state::State, prob::Float64)
    for qubit in 1:state.qubits
        ChannelZ(state,qubit,prob)
    end
end

function ChannelX(state::State, qubit, prob::Float64)
    if rand(Float64) < prob
        X(state,qubit)
    end
end

function ChannelX(state::State, prob::Float64)
    for qubit in 1:state.qubits
        ChannelX(state,qubit,prob)
    end
end

function ChannelY(state::State, qubit, prob::Float64)
    if rand(Float64) < prob
        Y(state,qubit)
    end
end

function ChannelY(state::State, prob::Float64)
    for qubit in 1:state.qubits
        ChannelY(state,qubit,prob)
    end
end

function ChannelDepol(state::State, qubit, prob::Float64)
    if rand(Float64) < ((1-prob)/3)
        X(state,qubit)
        Y(state,qubit)
        Z(state,qubit)
    end
end

function ChannelDepol(state::State, prob::Float64)
    for qubit in 1:state.qubits
        ChannelDepol(state, qubit, prob)
    end
end

function ChannelPauli(state::State, qubit, pXYZ::Array{Float64})
    r = rand(Float64)

    if r <= pXYZ[1]
        ChannelX(state,qubit,pXYZ[1])
    elseif r > pXYZ[1] && r <= pXYZ[2]
        ChannelY(state,qubit,pXYZ[2])
    elseif r > (pXYZ[1]+pXYZ[2]) && r <= (pXYZ[1]+pXYZ[2]+pXYZ[3])
        ChannelZ(state,qubit,pXYZ[3])
    end
end

function ChannelPauli(state::State, pXYZ::Array{Float64})
    for qubit in 1:state.qubits
        ChannelPauli(state,qubit,pXYZ)
    end
end

#end

println("---\n")
state = State()
graph = [0 1 0;1 0 1; 0 1 0]
#AddGHZ(state,5)
AddGraph(state,graph)
Print(state)
ChannelDepol(state,0.5)
Print(state)

