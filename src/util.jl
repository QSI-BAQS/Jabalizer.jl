using TimerOutputs

const to = TimerOutput()

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

function copystate!(stab::Stabilizer, tableau, row, qubits)
    ps = tableau.z_output(row - 1)
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

"""
    update_tableau(state::StabilizerState)

Update the state tableau with the current state of the stim simulator
"""
function n_update_tableau(state::StabilizerState)
    state.is_updated && return

    # Extract the tableau in Jabalizer format
    stim_sim = state.simulator
    forward_tableau = stim_sim.current_inverse_tableau().inverse()
    qubits = state.qubits
    #len = length(forward_tableau)
    #qubits == len || error("Mismatch qubits $qubits != $len")
    svec = state.stabilizers
    if isempty(svec)
        for i in 1:qubits
            stab = Stabilizer(qubits)
            push!(svec, stab)
            copystate!(stab, forward_tableau, i, qubits)
        end
    else
        for i in 1:qubits
            copystate!(clear!(svec[i]), forward_tableau, i, qubits)
        end
    end

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
        copystate!(stab, forward_tableau, i, qubits)
    end

    # mark it as updated
    state.is_updated = true
    return state
end

debug_graph = true
function set_debug(val) ; global debug_graph = val != 0 ; end
export set_debug

function find_eq(v1, v2, i, qubits)
    while i <= qubits
        v1[i] == v2[i] && return i
        i += 1
    end
    i
end
function find_ne(v1, v2, i, qubits)
    while i <= qubits
        v1[i] != v2[i] && return i
        i += 1
    end
    i
end

function disp_diff(msg, sv1, sv2, n, qubits)
    println("\n", msg, ": n = ", n)
    print("    ")
    count = 0
    i = 1
    while i <= qubits
        # Skip to first value not equal
        i = find_ne(sv1, sv2, i, qubits)
        i > qubits && break
        eq = find_eq(sv1, sv2, i, qubits)
        count += (eq - i + 1)
        print(" ", i)
        i == eq || (print(":", eq - 1); i = eq)
    end
    println("  Count = ", count)
end

#=
function _disp(svec::Vector{Stabilizer})
    qubits = length(svec)
    qubits > 9 && return
    for i = 1:qubits ; println(svec[i]); end
end
=#
_disp(svec::Vector{Stabilizer}) = nothing

"""
    to_graph(state)

Convert a state to its adjacency graph state equivalent under local operations.
"""
function _to_graph(state::StabilizerState)

    #TODO: Add a check if state is not empty. If it is, throw an exception.
    # update the state tableau from the stim simulator
    print("update_tableau: "); @time update_tableau(state)
    qubits = state.qubits
    svec = deepcopy(state.stabilizers)
    # Sequence of local operations performed
    op_seq = Tuple{String, Int}[]
    print("sort!: "); @time sort!(svec, rev=true)
    _disp(svec)

    # Make X-block upper triangular
    for n in 1:qubits
        # Find first X (or Y) below diagonal.
        first_x = find_first_x(svec, qubits, n, n)
        println("first_x = $first_x")

        # if diagonal is zero,
        #    1) perform Hadamard operation if no other X found
        #    2) swap rows with first X found
        if svec[n].X[n] == 0
            if first_x == 0
                # Perform Hadamard operation
                @time begin
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
                    println("Hadamard: $n -> $first_x")
                end
                _disp(svec)
            end
            # If we are not already at end (i.e. n == qubits), and diagonal is still 0, swap rows
            if first_x != 0 && svec[n].X[n] == 0
                # Swap rows to bring X to diagonal
                svec[n], svec[first_x] = svec[first_x], svec[n]
                print("Swap: $n, $first_x -> ")
                # Recalculate first_x after swap, starting after first_x row (which now has 0 X)
                first_x = find_first_x(svec, qubits, first_x, n)
                println(first_x)
                _disp(svec)
            end
        end

        # If there are any rows with X set in this column below the diagonal,
        # perform rowadd operations
        if first_x != 0
            print("add rows: $n, $first_x\t")
            @time begin
                for m in first_x:qubits
                    svec[m].X[n] == 0 || _add_row!(svec, n, m)
                end
            end
            println()
        end
        _disp(svec)
    end

    # Make diagonal X-block
    print("Make diagonal: ")
    @time begin
    for n = (qubits-1):-1:1, m = (n+1):qubits
        svec[n].X[m] == 1 && _add_row!(svec, m, n)
    end
    end
    _disp(svec)

    # Adjacency matrix
    A = Array{Int}(undef, qubits, qubits)

    #@timeit to "phase correction and checks" begin
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
        if qubits < 10
            show(A)
            println()
            show(to_tableau(state))
            println()
            show(state)
            println()
        end
    end
    show(to)
    println()
#   return (graph_to_state(A), A, op_seq)
    return (svec, graph_to_state(A), A, op_seq)
end

to_graph(state::StabilizerState) = _to_graph(state)[2:4]

function to_graph_1(state::StabilizerState)

    #TODO: Add a check if state is not empty. If it is, throw an exception.
    # update the state tableau from the stim simulator
    update_tableau(state)
    qubits = state.qubits
    svec = deepcopy(state.stabilizers)
    # Sequence of local operations performed
    op_seq = Tuple{String, Int}[]
    @timeit to "sort" sort!(svec, rev=true)
    #=
    debug_graph && (savesvec = deepcopy(svec))
    # check if any rows changed
    debug_graph && svec != savesvec && disp_diff("sort", svec, savesvec, 1, qubits)
    =#

    # Make X-block upper triangular
    for n in 1:qubits
        @timeit to "calc_sum 1" (lead_sum = calc_sum(svec, qubits, n))

        if lead_sum == 0
            # Perform Hadamard operation
            @timeit to "hadamard" begin
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
            end
            debug_graph && (savesvec = deepcopy(svec))
            @timeit to "sort H" sort!(svec, rev=true)
            if debug_graph
                if svec == savesvec
                    println("sort H - no change")
                else
                    disp_diff("sort H", svec, savesvec, n, qubits)
                end
            end
            @timeit to "calc_sum 2" lead_sum = calc_sum(svec, qubits, n)
            _disp(svec)
        end

        if lead_sum > 1
            debug_graph && println("add rows(", lead_sum, "): ", n+1, ":", n+lead_sum-1)
            @timeit to "add row loop" begin
            for m in (n+1):(n+lead_sum-1)
                _add_row!(svec, n, m)
            end
            end
            debug_graph && (savesvec = deepcopy(svec))
            @timeit to "sort 2" sort!(svec, rev=true)
            # check if any rows changed
            debug_graph && svec != savesvec && disp_diff("sort", svec, savesvec, n, qubits)
            _disp(svec)
        end
    end

    # Make diagonal X-block
    @timeit to "make diagonal" begin
    for n = (qubits-1):-1:1, m = (n+1):qubits
        svec[n].X[m] == 1 && _add_row!(svec, m, n)
    end
    end
    _disp(svec)

    # Adjacency matrix
    A = Array{Int}(undef, qubits, qubits)

    @timeit to "phase correction and checks" begin
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
    show(to)
    println()
    #    return (graph_to_state(A), A, op_seq)
    return (svec, graph_to_state(A), A, op_seq)
end

"""Calculate number of X bits set in column bit"""
function calc_sum(svec, qubits, bit)
    tot = 0
    for i = bit:qubits
        tot += svec[i].X[bit]
    end
    tot
end

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

function old_graph(state::StabilizerState)
    #TODO: Add a check if state is not empty. If it is, throw an exception.
    # update the state tableau from the stim simulator
    update_tableau(state)
    newState = deepcopy(state)
    qubits = state.qubits
    stabs = length(state.stabilizers)
    LOseq = Any[] # Sequence of local operations performed

    tab = sortslices(to_tableau(newState), dims=1, rev=true)

    # Make X-block upper triangular
    for n in 1:stabs
        tab = sortslices(tab, dims=1, rev=true)
        lead_sum = sum(tab[n:stabs, n])

        if lead_sum == 0
            println("H $n")
            hadamard!(tab, n)
            push!(LOseq, ("H", n))
            tab = sortslices(tab, dims=1, rev=true)
            lead_sum = sum(tab[n:stabs, n])
            show(tab)
            println()
        end

        if lead_sum > 1
            print("Add row:")
            for m in (n+1):(n+lead_sum-1)
                print(" $n:$m")
                _add_row!(tab, n, m)
            end
            println()
            show(tab)
            println()
        end
    end

    # Make diagonal X-block
    print("Diagonal X-block:")
    for n = (stabs-1):-1:1, m = (n+1):stabs
        if tab[n, m] == 1
            print(" $m:$n")
            _add_row!(tab, m, n)
        end
    end
    println()
    show(tab)
    println()

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

    newState = graph_to_state(tab[:, qubits+1:2*qubits])

    # Adjacency matrix
    A = tab[:, (qubits+1):(2*qubits)]
    phases = sum(tab[:, 2*qubits+1])

    A == A' || println("Error: invalid graph conversion (non-symmetric).")
    tr(A) == 0 || println("Error: invalid graph conversion (non-zero trace).")
    phases == 0 || println("Error: invalid graph conversion (non-zero phase).\nphases=$phases")

    #    return (newState, A, LOseq)
    return (tab, newState, A, LOseq)
end

# TODO: Why this is the only operation we have for tabs?
# TODO: Madhav – could you provide some extra context in the docstring.
"""
    hadamard!(tab::Matrix{Int}, qubit)

Performs the Hadamard operation on the given tableau
"""
function hadamard!(tab::AbstractArray{<:Integer}, qubit)
    # TODO: I'd say `tab` should be renamed to `tableau` (in other places as well)
    qubit_no = size(tab, 2) >> 1
    for i in 1:qubit_no
        x, z = tab[i, qubit], tab[i, qubit+qubit_no]
        x == 1 && z == 1 && (tab[i, end] ⊻= 2) # toggle bit 2 of phase if Y
        # Swap bits
        tab[i, qubit], tab[i, qubit+qubit_no] = z, x
    end
end

"""
    _add_row(tableau, source, dest)

Row addition operation for tableaus.
"""
function _add_row!(tab::Matrix{Int}, source::Int, dest::Int)
    prod = Stabilizer(view(tab, source, :)) * Stabilizer(view(tab, dest, :))
    tab[dest, :] = to_tableau_row(prod)
end
