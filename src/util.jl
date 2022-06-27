# TODO: It's better to avoid having general use `util` files
# We should move these functions to appropriate modules

# TODO: shouldn't Jabalizer Tableau be its own type?
"""
    stim_tableau(stim_sim::Py)::Matrix{Int}

Return a Jabalizer tableau from a stim TableauSimulator instance

# Arguments
- `stim_sim::Py`: stim.TableauSimulator from which to compute the Jabalizer tableau
"""
function stim_tableau(stim_sim::Py)::Matrix{Int}

    forward_tableau = stim_sim.current_inverse_tableau().inverse()
    qubits = length(forward_tableau)
    tab_arr = [forward_tableau.z_output(i - 1) for i in 1:qubits]
    tableau = zeros(Int, qubits, 2 * qubits + 1)

    for i in 1:qubits
        # update sign
        pyconvert(Number, tab_arr[i].sign) == -1 && (tableau[i, end] = 2)

        # Stabilizer replacement
        for j in 1:qubits
            v = pyconvert(Int, get(tab_arr[i], j - 1, -1))
            if v == 1           # X replacement
                tableau[i, j] = 1
            elseif v == 3       # Z replacement
                tableau[i, j+qubits] = 1
            elseif v == 2       # Y replacement
                tableau[i, j] = 1
                tableau[i, j+qubits] = 1
            end
        end
    end

    return tableau
end

"""
    update_tableau(state::StabilizerState)

Update the state tableau with the current state of the stim simulator
"""
function update_tableau(state::StabilizerState)
    state.is_updated && return

    # Extract the tableau in Jabalizer format
    tableau = stim_tableau(state.simulator)

    # create a new state temporarily
    inbetween_state = TableauToState(tableau)

    # update the initial state
    state.qubits = inbetween_state.qubits
    state.stabilizers = deepcopy(inbetween_state.stabilizers)

    # mark it as updated
    state.is_updated = true
end

"""
    ToGraph(state)

Convert a state to its graph state equivalent under local operations.
"""
function ToGraph(state::StabilizerState)

    # update the state tableau from the stim simulator
    update_tableau(state)
    newState = deepcopy(state)
    qubits = state.qubits
    stabs = length(state.stabilizers)
    LOseq = [] # Sequence of local operations performed

    tab = sortslices(ToTableau(newState), dims=1, rev=true)

    # Make X-block upper triangular
    for n in 1:stabs
        tab = sortslices(tab, dims=1, rev=true)
        lead_sum = sum(tab[n:stabs, n])

        if lead_sum == 0
            H(tab, n)
            push!(LOseq, ("H", n))
            tab = sortslices(tab, dims=1, rev=true)
            lead_sum = sum(tab[n:stabs, n])
        end

        if lead_sum > 1
            for m in (n+1):(n+lead_sum-1)
                tab = RowAdd(tab, n, m)
            end
        end
    end

    # Make diagonal X-block
    for n = (stabs-1):-1:1
        for m = (n+1):stabs
            if tab[n, m] == 1
                tab = RowAdd(tab, m, n)
            end
        end
    end

    # Phase correction
    for n = 1:qubits
        if tab[n, 2*qubits+1] != 0
            tab[n, 2*qubits+1] = 0
            push!(LOseq, ("Z", n))
        end
    end

    # Y correct
    for n = 1:qubits
        # Check if there is a Y on the diagonal
        if tab[n, n] == 1 && tab[n, qubits+n] == 1
            # Change Y to X
            tab[n, qubits+n] = 0
            push!(LOseq, ("P", n))
        end
    end

    newState = GraphToState(tab[:, qubits+1:2*qubits])

    # Adjacency matrix
    A = tab[:, (qubits+1):(2*qubits)]
    phases = sum(tab[:, 2*qubits+1])

    if A != A'
        println("Error: invalid graph conversion (non-symmetric).")
    end

    if tr(A) != 0
        println("Error: invalid graph conversion (non-zero trace).")
    end

    if phases != 0
        println("Error: invalid graph conversion (non-zero phase).")
        println("phases=", phases)
    end

    return (newState, A, LOseq)
end

# TODO: Why this is the only operation we have for tabs?
# TODO: Madhav – could you provide some extra context in the docstring.
"""
    H(tab::Matrix{Int}, qubit)

Performs the Hadamard operation on the given tableau
"""
function H(tab::Matrix{Int}, qubit) # TODO: I'd say `tab` should be renamed to `tableau` (in other places as well)
    qubit_no = length(tab[:, 1])
    for i in 1:qubit_no
        x = tab[i, qubit]
        z = tab[i, qubit+qubit_no]

        # Apply phase correction if needed
        if (x == 1) && (z == 1)
            tab[i, 2*qubit_no+1] = (tab[i, 2*qubit_no+1] + 2) % 4
        end

        #Swap x and z
        tab[i, qubit] = z
        tab[i, qubit+qubit_no] = x

    end
end

"""
    RowAdd(tableau, source, dest)

Row addition operation for tableaus.
"""
function RowAdd(tab::Matrix{Int}, source::Int, dest::Int)
    prod = Stabilizer(@view tab[source, :]) * Stabilizer(@view tab[dest, :])
    tab[dest, :] = ToTableau(prod)
    return tab
end

"""
Convert tableau form of single Pauli operator to char.
"""
function TabToPauli(X::Int, Z::Int)::Char
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


# TODO: Performing these on strings look weird to me.
# It seems to me there's some better data structure for this.
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
