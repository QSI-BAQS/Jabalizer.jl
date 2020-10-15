"""
    ToGraph(state)

Convert a state to its graph state equivalent under local operations.
"""
function ToGraph(state::StabilizerState)
    newState = deepcopy(state)
    qubits = state.qubits
    stabs = length(state.stabilizers)
    LOseq = [] # Sequence of local operations performed

    # Make X-block full rank
    tab = sortslices(ToTableau(newState), dims = 1, rev = true)
    for n = 1:stabs
        if (sum(tab[n:stabs, n]) == 0)
            H(newState, n)
            push!(LOseq, ("H", n))
        end
        tab = sortslices(ToTableau(newState), dims = 1, rev = true)
    end

    # Make upper-triangular X-block
    for n = 1:qubits
        for m = (n+1):stabs
            if tab[m, n] == 1
                tab = RowAdd(tab, n, m)
            end
        end
        tab = sortslices(tab, dims = 1, rev = true)
    end

    # Make diagonal X-block
    for n = (stabs-1):-1:1
        for m = (n+1):stabs
            if tab[n, m] == 1
                tab = RowAdd(tab, m, n)
            end
        end
    end

    newState = StabilizerState(tab)

    # Reduce all stabilizer phases to +1

    # Adjacency matrix
    A = tab[:, (qubits+1):(2*qubits)]

    if (A != A') || (tr(A) != 0)
        println("Error: invalid graph conversion.")
    end

    return (newState, A, Tuple(LOseq))
end

"""
    RowAdd(tableau, source, dest)

Row addition operation for tableaus.
"""
function RowAdd(tab::Array{Int64}, source::Int64, dest::Int64)
    prod = Stabilizer(tab[source, :]) * Stabilizer(tab[dest, :])
    tab[dest, :] = ToTableau(prod)
    return tab
end

"""
Convert tableau form of single Pauli operator to char.
"""
function TabToPauli(X::Int64, Z::Int64)::Char
    if X == 0 && Z == 0
        return 'I'
    elseif X == 1 && Z == 0
        return 'X'
    elseif X == 0 && Z == 1
        return 'Z'
    elseif X == 1 && Z == 1
        return 'Y'
    else
        return 'I'
    end
end

"""
Convert Pauli operator from char to tableau form.
"""
function PauliToTab(pauli::Char)
    if pauli == 'I'
        return (0, 0)
    elseif pauli == 'X'
        return (1, 0)
    elseif pauli == 'Z'
        return (0, 1)
    elseif pauli == 'Y'
        return (1, 1)
    else
        return (0, 0)
    end
end

"""
    PauliProd(left, right)

Product of two Pauli operators.
"""
function PauliProd(left::Char, right::Char)
    if left == 'X' && right == 'Z'
        return ('Y', 3)
    elseif left == 'X' && right == 'Y'
        return ('Z', 1)
    elseif left == 'Z' && right == 'X'
        return ('Y', 1)
    elseif left == 'Z' && right == 'Y'
        return ('X', 3)
    elseif left == 'Y' && right == 'Z'
        return ('X', 1)
    elseif left == 'Y' && right == 'X'
        return ('Z', 3)
    elseif left == 'I'
        return (right, 0)
    elseif right == 'I'
        return (left, 0)
    else
        return ('I', 0)
    end
end

"""
    ExecuteCircuit(state, gates)

Execute a gate sequence.
"""
function ExecuteCircuit(state::StabilizerState, gates::Array{})
    for gate in gates
        if gate[1] == "I"
            Id(state, gate[2])
        elseif gate[1] == "X"
            X(state, gate[2])
        elseif gate[1] == "Y"
            Y(state, gate[2])
        elseif gate[1] == "Z"
            Z(state, gate[2])
        elseif gate[1] == "H"
            H(state, gate[2])
        elseif gate[1] == "P"
            P(state, gate[2])
        elseif gate[1] == "CNOT"
            CNOT(state, gate[2], gate[3])
        elseif gate[1] == "CZ"
            CZ(state, gate[2], gate[3])
        elseif gate[1] == "SWAP"
            SWAP(state, gate[2], gate[3])
        else
            println("Warning: unknown gate.")
        end
    end
end
