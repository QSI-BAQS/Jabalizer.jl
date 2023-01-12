### Fast to_graph implementation
"""
_swap_row!(svec::Vector{Stabilizer}, r1::Int, r2::Int)

Row swap operation
"""
function _swap_row!(svec::Vector{Stabilizer}, r1::Int, r2::Int)
    temp = svec[r1]
    svec[r1] = svec[r2]
    svec[r2] = temp
end

"""
x_locs(svec::Vector{Stabilizer}, qubits::Int, bit::Int)

Find locations of Xs above or below the diagonal in a tableau column.
By default returns the ones below.
"""
function x_locs(svec::Vector{Stabilizer}, qubits::Int, bit::Int; above::Bool=false)
    incr = above ? -1 : 1
    stop = above ? 1 : qubits

    locs = Int64[]
    for i = bit:incr:stop
        if svec[i].X[bit]
            push!(locs ,i)
        end
    end

    return locs
end

function fast_to_graph(state::StabilizerState)

    #TODO: Add a check if state is not empty. If it is, throw an exception.
    # update the state tableau from the stim simulator
    update_tableau(state)
    qubits = state.qubits
    svec = deepcopy(state.stabilizers)
    # Sequence of local operations performed
    op_seq = Tuple{String, Int}[]

    # Make X-block upper triangular
    for n in 1:qubits
        # sort!(svec, rev=true) # getting rid of this sort, also why rev?
        # lead_sum = calc_sum(svec, qubits, n)

        locs = x_locs(svec, qubits, n)
        x_num = length(locs)


        if x_num == 0
            # Perform Hadamard operation
            for stab in svec
                x, z = stab.X[n], stab.Z[n]
                x == 1 && z == 1 && (stab.phase ⊻= 2) # toggle bit 2 of phase if Y
                # Swap bits
                stab.X[n], stab.Z[n] = z, x
            end
            push!(op_seq, ("H", n))
            # sort!(svec, rev=true)
            locs = x_locs(svec, qubits, n)
            x_num = length(locs)
        end

        # If first X is not on the diagonal
        locs[1] != n && _swap_row!(svec,n, locs[1])

        # Remove Xs below the diagonal
        popfirst!(locs)
        for r_idx in locs
            _add_row!(svec, n, r_idx)
        end
    end

    # Make diagonal X-block
    for n = qubits:-1:2
        # Find x locations above the diagonal
        locs = x_locs(svec, qubits, n; above=true)

        # Remove diagonal index
        test_idx = popfirst!(locs)
        if test_idx != n
            error("No diagonal X in upper-triangular block - algorithm failure!")
        end

        for idx in locs
            _add_row!(svec, n, idx)
        end
    end

    # Adjacency matrix
    A = Array{Int}(undef, qubits, qubits)

    for n = 1:qubits
        stab = svec[n]

        # Y correct
        if stab.X[n] == 1 && stab.Z[n] == 1
            # Change Y to X
            stab.Z[n] = 0
            push!(op_seq, ("Pdag", n))
        end

        # Phase correction
        if stab.phase != 0
            stab.phase = 0
            push!(op_seq, ("Z", n))
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
