"""
    stim_tableau(stim_sim::PyObject)::Array{Int64}

Return a Jabilizer tableau from a stim TableauSimulator instance

# Arguments
- `stim_sim::PyObject`: stim.TableauSimulator from which to compute the Jabalizer tableau
"""
function stim_tableau(stim_sim::PyObject)::Array{Int64}

    inverse_tableau = stim_sim.current_inverse_tableau()
    forward_tableau = inverse_tableau^-1

    tab_arr = [forward_tableau.z_output(i - 1) for i in 1:length(forward_tableau)]

    qubits = length(tab_arr)
    tableau = zeros(Int64, qubits, 2 * qubits + 1)

    for i in 1:qubits
        # update sign
        if tab_arr[i].sign == -1
            tableau[i, end] = 2
        end

        # Stabalizer replacement
        for j in 1:qubits
            # X replacement
            if get(tab_arr[i], j - 1, "index not found") == 1
                tableau[i, j] = 1
            end
            # Z replacement
            if get(tab_arr[i], j - 1, "index not found") == 3
                tableau[i, j + qubits] = 1
            end

            # Y replacement
            if get(tab_arr[i], j - 1, "index not found") == 2
                tableau[i, j] = 1
                tableau[i , j + qubits] = 1
            end
        end
    end
    return(tableau)
end

"""
    update_tableau(state::StabilizerState)

Update the state tableau with the current state of the stim simulator
"""
function update_tableau(state::StabilizerState)

    # Extract the tableau in Jabalizer format
    tableau = stim_tableau(state.simulator)

    # create a new state temporarily
    inbetween_state = TableauToState(tableau)

    # update the initial state
    state.qubits = inbetween_state.qubits
    state.stabilizers = deepcopy(inbetween_state.stabilizers)


end

"""
    ToGraph(state)

Convert a state to its graph state equivalent under local operations.
"""
# function ToGraph(state::StabilizerState)
#     newState = deepcopy(state)
#     qubits = state.qubits
#     stabs = length(state.stabilizers)
#     LOseq = [] # Sequence of local operations performed

#     # Make X-block full rank
#     tab = sortslices(ToTableau(newState), dims = 1, rev = true)
#     for n = 1:stabs
#         if (sum(tab[n:stabs, n]) == 0)
#             H(newState, n)
#             push!(LOseq, ("H", n))
#         end
#         tab = sortslices(ToTableau(newState), dims = 1, rev = true)
#     end

#     # Make upper-triangular X-block
#     for n = 1:qubits
#         for m = (n+1):stabs
#             if tab[m, n] == 1
#                 tab = RowAdd(tab, n, m)
#             end
#         end
#         tab = sortslices(tab, dims = 1, rev = true)
#     end

#     # Make diagonal X-block
#     for n = (stabs-1):-1:1
#         for m = (n+1):stabs
#             if tab[n, m] == 1
#                 tab = RowAdd(tab, m, n)
#             end
#         end
#     end

#     newState = StabilizerState(tab)

#     # Reduce all stabilizer phases to +1

#     # Adjacency matrix
#     A = tab[:, (qubits+1):(2*qubits)]
#     phases = sum(tab[:, 2*qubits+1])

#     if A != A'
#         println("Error: invalid graph conversion (non-symmetric).")
#     end

#     if tr(A) != 0
#         println("Error: invalid graph conversion (non-zero trace).")
#     end

#     if phases != 0
#         println("Error: invalid graph conversion (non-zero phase).")
#         println("phases=",phases)
#     end

#     return (newState, A, LOseq)
# end

function ToGraph(state::StabilizerState)

    # update the state tableau from the stim simulator
    # update_tableau(state)
    newState = deepcopy(state)
    qubits = state.qubits
    stabs = length(state.stabilizers)
    LOseq = [] # Sequence of local operations performed

    # print("ORIGINAL")
    # display(ToTableau(newState))

    tab = sortslices(ToTableau(newState), dims = 1, rev = true)

    # Make X-block upper triangular
    for n in 1:stabs
        # println("loop:",n)
        tab = sortslices(tab, dims = 1, rev = true)

        lead_sum = sum(tab[n:stabs, n])
        # println("lead:",lead_sum)

        if lead_sum == 0
            H(newState, n)
            swapcols!(tab, n, n + qubits)
            push!(LOseq, ("H", n))
            tab = sortslices(tab, dims = 1, rev = true)
            lead_sum = sum(tab[n:stabs, n])
        end

        if lead_sum > 1
            for m in (n+1):(n+lead_sum-1)
                tab = RowAdd(tab, n, m)
                # println("add:",n," -> ",m)
            end
        end

        # display(tab)
    end

    # print("---UPPER---")
    # display(tab)

    # Make upper-triangular X-block
    # for n = 1:qubits
    #     for m = (n+1):stabs
    #         if tab[m, n] == 1
    #             tab = RowAdd(tab, n, m)
    #         end
    #     end
    #     tab = sortslices(tab, dims = 1, rev = true)
    # end

    # Make diagonal X-block
    for n = (stabs-1):-1:1
        for m = (n+1):stabs
            if tab[n, m] == 1
                tab = RowAdd(tab, m, n)
            end
        end
    end

    # Phase correction
    for n=1:qubits
        if tab[n,2*qubits+1] != 0
            tab[n,2*qubits+1] = 0
            push!(LOseq, ("Z", n))
        end
    end

    # Y correct
    for n = 1:qubits
    # Check if there is a Y on the diagonal
    if tab[n,n] == 1 && tab[n, qubits + n] == 1
        # Change Y to X
        tab[n, qubits + n] = 0
        push!(LOseq, ("P",n))
    end
end

    newState = TableauToState(tab)

    # println("---OUT---")
    # display(tab)

    # Reduce all stabilizer phases to +1

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
        println("phases=",phases)
    end

    return (newState, A, LOseq)
end

function swapcols!(X::AbstractMatrix, i::Integer, j::Integer)
    @inbounds for k = 1:size(X,1)
        X[k,i], X[k,j] = X[k,j], X[k,i]
    end
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


function isequal(state_1::StabilizerState, state_2::StabilizerState)
    check = []
    for (stab1, stab2) in zip(state_1.stabilizers, state_2.stabilizers)
        push!(check, stab1.X == stab2.X)
        push!(check, stab1.Z == stab2.Z)
        push!(check, stab1.phase == stab2.phase)
    end

    return all(check)
end
