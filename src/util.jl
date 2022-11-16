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
        ps = tab_arr[i] # Get stim PauliString representation
        # update sign
        pyconvert(Number, ps.sign) == -1 && (tableau[i, end] = 2)

        # Stabilizer replacement
        for j in 1:qubits
            v = pyconvert(Int, get(ps, j - 1, -1))
            # Note: 0123 represent IXYZ (different from the xz representation used here)
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
    inbetween_state = tableau_to_state(tableau)

    # update the initial state
    state.qubits = inbetween_state.qubits
    state.stabilizers = deepcopy(inbetween_state.stabilizers)

    # mark it as updated
    state.is_updated = true
end

function Base.rand(::Type{StabilizerState}, qubits::Int)
    forward_tableau = stim.Tableau.random(qubits).inverse()
    state = StabilizerState(qubits)
    state.simulator.set_inverse_tableau(forward_tableau)
    svec = state.stabilizers

    for i in 1:qubits
        stab = Stabilizer(qubits)
        push!(svec, stab)
        ps = forward_tableau.z_output(i - 1)
        # update sign
        stab.phase = pyconvert(Number, ps.sign) == -1 ? 2 : 0

        # Stabilizer replacement
        for j in 1:qubits
            v = pyconvert(Int, get(ps, j - 1, -1))
            # Note: 0123 represent IXYZ (different from the xz representation used here)
            if v == 1           # X replacement
                stab.X[j] = 1
            elseif v == 3       # Z replacement
                stab.Z[j] = 1
            elseif v == 2       # Y replacement
                stab.X[j] = 1
                stab.Z[j] = 1
            end
        end
    end

    # mark it as updated
    state.is_updated = true
    return state
end

"""
    to_graph(state)

Convert a state to its adjacency graph state equivalent under local operations.
"""
function to_graph(state::StabilizerState)

    #TODO: Add a check if state is not empty. If it is, throw an exception.
    # update the state tableau from the stim simulator
    update_tableau(state)
    qubits = state.qubits
    svec = deepcopy(state.stabilizers)
    # Sequence of local operations performed
    op_seq = Tuple{String, Int}[]

    # Make X-block upper triangular
    for n in 1:qubits
        sort!(svec, rev=true)
        lead_sum = calc_sum(svec, qubits, n)

        if lead_sum == 0
            # Perform Hadamard operation
            for stab in svec
                x, z = stab.X[n], stab.Z[n]
                x == 1 && z == 1 && (stab.phase ⊻= 2) # toggle bit 2 of phase if Y
                # Swap bits
                stab.X[n], stab.Z[n] = z, x
            end
            push!(op_seq, ("H", n))
            sort!(svec, rev=true)
            lead_sum = calc_sum(svec, qubits, n)
        end

        if lead_sum > 1
            for m in (n+1):(n+lead_sum-1)
                _add_row!(svec, n, m)
            end
        end
    end

    # Make diagonal X-block
    for n = (qubits-1):-1:1, m = (n+1):qubits
        svec[n].X[m] == 1 && _add_row!(svec, m, n)
    end

    # Adjacency matrix
    A = Array{Int}(undef, qubits, qubits)

    for n = 1:qubits
        stab = svec[n]

        # Phase correction
        if stab.phase != 0
            stab.phase = 0
            push!(op_seq, ("Z", n))
        end

        # Y correct
        if stab.X[n] == 1 && stab.Z[n] == 1
            # Change Y to X
            stab.Z[n] = 0
            push!(op_seq, ("P", n))
        end

        # Copy Z to adjacency matrix
        A[n, :] .= stab.Z

        # Check diagonal for any non-zero values
        A[n, n] == 0 ||
            println("Error: invalid graph conversion (non-zero trace).")
    end

    issymmetric(A) || println("Error: invalid graph conversion (non-symmetric).")

    return (graph_to_state(A), A, op_seq)
end

function calc_sum(svec, qubits, bit)
    tot = 0
    for i = bit:qubits
        tot += svec[i].X[bit]
    end
    tot
end

"""
    _add_row!(tableau, source, dest)

Row addition operation
"""
function _add_row!(svec::Vector{Stabilizer}, source::Int, dest::Int)
    left = svec[source]
    right = svec[dest]
    # Calculate product of source & dest rows
    right.phase = (left.phase + right.phase) & 3
    for n = 1:length(svec)
        (right.X[n], right.Z[n], phase) =
            _prodtab[((left.X[n]<<3)|(left.Z[n]<<2)|(right.X[n]<<1)|right.Z[n])+1]
        right.phase = (right.phase + phase) & 3
    end
    return
end

"""
Returns number of qubits in the icm-compatible circuit.
"""
function count_qubits(circuit::Vector{ICMGate})
    qubit_ids = Set()
    for gate in circuit
        union!(qubit_ids, Set(gate[2]))
    end
    return length(qubit_ids)
end
