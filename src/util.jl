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

function clear!(stab::Stabilizer)
    fill!(stab.X.chunks, 0)
    fill!(stab.Z.chunks, 0)
    stab
end

function copyrow!(stab::Stabilizer, ps, row, qubits)
    # update sign
    stab.phase = pyconvert(Number, ps.sign) == -1 ? 2 : 0
    xs = stab.X
    zs = stab.Z

    # Stabilizer replacement
    for j in 1:qubits
        v = pyconvert(Int, get(ps, j - 1, -1))
        # Note: 0123 represent IXYZ (different from the xz representation used here)
        if v == 1           # X replacement
            xs[j] = 1
        elseif v == 3       # Z replacement
            zs[j] = 1
        elseif v == 2       # Y replacement
            xs[j] = 1
            zs[j] = 1
        end
    end
end

out_time(n,a,b) =
    println("$n:\t$(round(a/1000000000,digits=3))s, $(round(b/1000000000,digits=3))s")

"""
    update_tableau(state::StabilizerState)

Update the state tableau with the current state of the stim simulator
"""
function update_tableau(state::StabilizerState)
    state.is_updated && return

    # Extract the tableau in Jabalizer format
    stim_sim = state.simulator
    print("current_inverse_tableau: "); @time tableau = stim_sim.current_inverse_tableau()
    #print("inverse: "); @time tableau = invtab.inverse()
    oldlen = state.qubits
    state.qubits = qubits = length(tableau)
    svec = state.stabilizers
    cnt = t_zout = t_copy = 0
    print("update stabilizers: "); @time begin
    println()
    if isempty(svec)
        for i in 1:qubits
            stab = Stabilizer(qubits)
            push!(svec, stab)
            t1 = time_ns()
            ps = tableau.inverse_z_output(i - 1)
            t2 = time_ns()
            t_zout += (t2 - t1)
            copyrow!(stab, ps, i, qubits)
            t3 = time_ns()
            t_copy += (t3 - t2)
            if (cnt += 1) > 999
                out_time(i, t_zout, t_copy)
                cnt = t_zout = t_copy = 0
            end
        end
    else
        qubits == oldlen || error("Mismatch qubits $qubits != $oldlen, $(length(svec))")
        for i in 1:qubits
            t1 = time_ns()
            ps = tableau.inverse_z_output(i - 1)
            t2 = time_ns()
            t_zout += (t2 - t1)
            copyrow!(clear!(svec[i]), ps, i, qubits)
            t3 = time_ns()
            t_copy += (t3 - t2)
            if (cnt += 1) > 999
                out_time(i, t_zout, t_copy)
                cnt = t_zout = t_copy = 0
            end
        end
    end
    end
    out_time(cnt, t_zout, t_copy)

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

    for i in 1:qubits
        stab = Stabilizer(qubits)
        push!(svec, stab)
        copyrow!(stab, tableau.z_output(i - 1), i, qubits)
    end

    # mark it as updated
    state.is_updated = true
    return state
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

    # Make diagonal X-block
    print("\tMake diagonal: ")
    @time begin
    for n = (qubits-1):-1:1, m = (n+1):qubits
        svec[n].X[m] == 1 && _add_row!(svec, m, n)
    end
    end

    # Adjacency matrix
    A = Array{Int}(undef, qubits, qubits)

    #@timeit to "phase correction and checks" begin
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
    end

    if !issymmetric(A)
        println("Error: invalid graph conversion (non-symmetric).")
        show(A)
        println()
        show(to_tableau(state))
        println()
        show(state)
        println()
    end
    return (svec, A, op_seq)
end

"""
    to_graph(state)

Convert a state to its adjacency graph state equivalent under local operations.
"""
function to_graph(state::StabilizerState)
    @time (svec, A, op_seq) = _to_graph(state)
    print("\tgraph_to_state: ") ; @time g = graph_to_state(A)
    g, A, op_seq
end

export adjacency_matrix
"""
    adjacency_matrix(state)

Convert a state to its adjacency graph state equivalent under local operations.
"""
adjacency_matrix(state::StabilizerState) = _to_graph(state)[2]

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
function writecsv(nam, mat::Matrix)
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
function writemat(nam, mat::Matrix)
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
