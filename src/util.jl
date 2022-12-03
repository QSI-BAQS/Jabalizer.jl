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

function out_time(n, a, tottim, totcnt=0)
    print("\t$n:\t$(round(a/1000000000,digits=3))s, ")
    tim = tottim/1000000000/60
    print("elapsed time: ", round(tim, digits=2), " min")
    totcnt == 0 || print(", remaining time: ", round(tim/n*(totcnt-n), digits=2), " min")
    println()
end

"""
    update_tableau(state::StabilizerState)

Update the state tableau with the current state of the stim simulator
"""
function update_tableau(state::StabilizerState)
    state.is_updated && return

    # Extract the tableau in Jabalizer format
    stim_sim = state.simulator
    print("\tcurrent_inverse_tableau: "); @time invtab = stim_sim.current_inverse_tableau()
    print("\tinverse: "); @time tableau = invtab.inverse()
    print("\tto_numpy: "); @time (x2x, x2z, z2x, z2z, x_signs, z_signs) = tableau.to_numpy()
    print("\tconvert x: "); @time xmat = pyconvert(BitMatrix, z2x)
    print("\tconvert z: "); @time zmat = pyconvert(BitMatrix, z2z)
    print("\tconvert signs: "); @time signs = pyconvert(BitVector, z_signs)
    oldlen = state.qubits
    state.qubits = qubits = length(tableau)
    svec = state.stabilizers
    pt = t0 = time_ns()
    cnt = 0
    print("\tupdate stabilizers: "); @time begin
    println()
    if isempty(svec)
        for i in 1:qubits
            stab = Stabilizer(qubits)
            push!(svec, stab)
            stab.phase = signs[i]<<1
            stab.X .= xmat[i,:]
            stab.Z .= zmat[i,:]
            if (cnt += 1) > 9999
                tn = time_ns() ; out_time(i, tn-pt, tn-t0, qubits) ; pt = tn
                cnt = 0
            end
        end
    else
        qubits == oldlen || error("Mismatch qubits $qubits != $oldlen, $(length(svec))")
        for i in 1:qubits
            stab = svec[i]
            stab.phase = signs[i]<<1
            stab.X .= xmat[i,:]
            stab.Z .= zmat[i,:]
            if (cnt += 1) > 9999
                tn = time_ns() ; out_time(i, tn-pt, tn-t0, qubits) ; pt = tn
                cnt = 0
            end
        end
    end
    tn = time_ns() ; out_time(cnt, tn-pt, tn-t0)
    end

    # mark it as updated
    state.is_updated = true
end

"""
    rand(StabilizerState, qubits::Int)

    Return a random (valid) stabilizer state with the given number of qubits
"""
function Base.rand(::Type{StabilizerState}, qubits::Int)
    tableau = stim.Tableau.random(qubits).inverse()
    state = StabilizerState(qubits)
    state.simulator.set_inverse_tableau(tableau)
    svec = state.stabilizers

    x2x, x2z, z2x, z2z, x_signs, z_signs = tableau.to_numpy()
    xmat = pyconvert(BitMatrix, z2x)
    zmat = pyconvert(BitMatrix, z2z)
    signs = pyconvert(BitVector, z_signs)
    for i in 1:qubits
        stab = Stabilizer(qubits)
        push!(svec, stab)
        stab.phase = signs[i]<<1
        stab.X .= xmat[i,:]
        stab.Z .= zmat[i,:]
    end

    # mark it as updated
    state.is_updated = true
    return state
end

function _is_symmetric(svec::Vector{Stabilizer})
    qubits = length(svec)
    for i = 1:qubits-1
        sz = svec[i].Z
        for j = i+1:qubits
            sz[j] == svec[j].Z[i] || return false
        end
    end
    return true
end

function _to_graph(state::StabilizerState)

    #TODO: Add a check if state is not empty. If it is, throw an exception.
    # update the state tableau from the stim simulator
    print("update_tableau: "); @time update_tableau(state)
    qubits = state.qubits
    svec = deepcopy(state.stabilizers)
    # Sequence of local operations performed
    op_seq = Tuple{String, Int}[]
    print("\tsort!: "); @time sort!(svec, rev=true)

    print("\tMake X-block upper triangular: ")
    @time begin
    # Make X-block upper triangular
    for n in 1:qubits
        # Find first X (or Y) below diagonal.
        first_x = find_first_x(svec, qubits, n, n)

        # if diagonal is zero,
        #    1) perform Hadamard operation if no other X found
        #    2) swap rows with first X found
        if svec[n].X[n] == 0
            if first_x == 0
                # Perform Hadamard operation
                for stab in svec
                    x, z = stab.X[n], stab.Z[n]
                    if xor(x, z) == 1
                        # Swap bits
                        stab.X[n], stab.Z[n] = z, x
                    elseif x == 1 && z == 1
                        stab.phase ⊻= 2 # toggle bit 2 of phase if Y
                    end
                end
                push!(op_seq, ("H", n))
                # Recalculate first_x (should always be non-zero,
                # since Z column should have at least 1 bit set
                first_x = find_first_x(svec, qubits, n, n)
            end
            # If we are not already at end (i.e. n == qubits), and diagonal is still 0, swap rows
            if first_x != 0 && svec[n].X[n] == 0
                # Swap rows to bring X to diagonal
                svec[n], svec[first_x] = svec[first_x], svec[n]
                # Recalculate first_x after swap, starting after first_x row (which now has 0 X)
                first_x = find_first_x(svec, qubits, first_x, n)
            end
        end

        # If there are any rows with X set in this column below the diagonal,
        # perform rowadd operations
        if first_x != 0
            for m in first_x:qubits
                svec[m].X[n] == 0 || _add_row!(svec, n, m)
            end
        end
    end
    end

    # Make diagonal X-block
    print("\tMake diagonal: ")
    @time begin
    for n = (qubits-1):-1:1, m = (n+1):qubits
        svec[n].X[m] == 1 && _add_row!(svec, m, n)
    end
    end

    print("\tPhase correction and checks: ")
    @time begin
    for n = 1:qubits
        stab = svec[n]

        # Phase correction
        if stab.phase != 0
            stab.phase = 0
            push!(op_seq, ("Z", n))
        end

        # Y correct
        if stab.Z[n] == 1
            if stab.X[n] == 1
                # Change Y to X
                stab.Z[n] = 0
                push!(op_seq, ("P", n))
            else
                # Check diagonal for any non-zero values
                println("Error: invalid graph conversion (non-zero trace).")
            end
        end
    end
    end

    print("\tCheck symmetry: ")
    @time begin
    if !_is_symmetric(svec)
        println("Error: invalid graph conversion (non-symmetric).")
        show(to_tableau(state))
        println()
        show(state)
        println()
    end
    end

    return (svec, op_seq)
end

function _create_matrix(svec::Vector{Stabilizer})
    qubits = length(svec)

    print("\tCreate Adjacency Matrix: ")
    @time begin
    # Adjacency matrix
    A = BitMatrix(undef, qubits, qubits)

    for n = 1:qubits
        stab = svec[n]
        # Copy Z to adjacency matrix
        A[n, :] .= stab.Z
    end
    end
#=
    print("\tCheck symmetry: ")
    @time begin
    if !issymmetric(A)
        println("Error: invalid graph conversion (non-symmetric).")
        show(A)
        println()
        show(to_tableau(state))
        println()
        show(state)
        println()
    end
    end
=#
    A
end

"""
    to_graph(state)

Convert a state to its adjacency graph state equivalent under local operations.
"""
function to_graph(state::StabilizerState)
    @time begin
        svec, op_seq = _to_graph(state)
        A = _create_matrix(svec)
        print("\tgraph_to_state: ") ; @time g = graph_to_state(A)
    end
    g, A, op_seq
end

export adjacency_matrix
"""
    adjacency_matrix(state)

Convert a state to its adjacency graph state equivalent under local operations.
"""
adjacency_matrix(state::StabilizerState) = _create_matrix(_to_graph(state)[1])

"""Find first X set below the diagonal in column col"""
function find_first_x(svec, qubits, row, col)
    while (row += 1) <= qubits
        svec[row].X[col] == 0 || return row
    end
    return 0
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

export writecsv
"""
Output adjacency matrix in CSV format
"""
function writecsv(nam, mat::AbstractMatrix)
    len = size(mat, 1)
    vec = Vector{UInt8}(undef, len*2)
    for i = 2:2:len*2-2
        vec[i] = UInt8(',')
    end
    vec[end] = UInt8('\n')
    open(nam, "w") do io
        for i = 1:len
            for j = 1:len
                vec[j*2-1] = UInt8('0') + mat[i,j]
            end
            write(io, vec)
        end
    end
end

export writemat
"""
Output adjacency matrix in internal format
"""
function writemat(nam, mat::AbstractMatrix)
    len = size(mat, 1)
    vec = Vector{UInt8}(undef, len+1)
    vec[end] = UInt8('\n')
    open(nam, "w") do io
        println(io, len)
        for i = 1:len
            for j = 1:len
                vec[j] = UInt8('0') + mat[i,j]
            end
            write(io, vec)
        end
    end
end
