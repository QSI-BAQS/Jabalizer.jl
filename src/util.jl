"""
    ToGraph(State)

Convert a State to its graph state equivalent under local operations.
"""
function ToGraph(state::State)
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

    newState = State(tab)

    # Reduce all stabilizer phases to +1

    # Adjacency matrix
    adjM = tab[:, (qubits+1):(2*qubits)]

    if (adjM != adjM') || (tr(adjM) != 0)
        println("Error: invalid graph conversion.")
    end

    return (newState, adjM, Tuple(LOseq))
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
