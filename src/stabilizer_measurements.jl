
"""
    FusionI(state, first, second)

Apply type-I fusion gate to a state.
"""
function FusionI(state::StabilizerState, qubit1::Int64, qubit2::Int64)::Int64
    CNOT(state, qubit1, qubit2)
    phase = MeasureX(state, qubit1)
    return phase
end

"""
    FusionII(state, first, second)

Apply type-II fusion gate to a state.
"""
function FusionII(state::StabilizerState, qubit1::Int64, qubit2::Int64)
     H(state, qubit1)
     H(state, qubit2)
     CNOT(state, qubit1, qubit2)
     parity = MeasureZ(state, qubit2)
     if parity == 1
         H(state, qubit1)
     end
     phase = MeasureX(state, qubit1)
     return (parity, phase)
end

"""
    MeasureZ(state, qubit_any)

Apply non-demolishing Z measurement on qubit_any in given state.
Written using measurement algo in 'Improved Simulation of stabilizer circuits' by Aaranson and Gottesman
"""
function MeasureZ(state::StabilizerState, qubit::Int64)::Int64
    # implement the row reduction procedure as per Gottesman
    # randomly choose outcome
    # update the state
    # return outcome

    measure_outcome = 0
    qbit = GetQubitLabel(state, qubit)
    in_counter = 0
    out_counter = 0

    # Check if measurement outcome at qbit is random or determinate
    for s in state.stabilizers
        out_counter += 1

        if s.X[qbit] == 1
            in_counter += 1
            break
        end
    end

    ## Case 1: One of the stabilisers has X (or Y) at qbit i.e. Z measurement outcome at qbit is random ##
    if in_counter > 0
        print("Random Outcome")
        println()
        p = state.stabilizers[out_counter]

        # 1st step
        counter = 0
        for s in state.stabilizers
            counter += 1
            if counter != out_counter && s.X[qbit] == 1
                RowSum(s, p)
            end
        end

        # 2nd step only for destabilisers i.e. not needed here

        # 3rd step
        for j = 1:p.qubits
            state.stabilizers[out_counter].X[j] = 0
            state.stabilizers[out_counter].Z[j] = 0

            phases = [1,2]
            weights = StatsBase.uweights(Float64, 2)
            state.stabilizers[out_counter].phase += 2*StatsBase.sample(phases, StatsBase.Weights(weights))
            measure_outcome = (0 + 1im)^state.stabilizers[out_counter].phase
        end
        state.stabilizers[out_counter].Z[qbit] = 1

    ## Case 2: None of the stabilisers has X (or Y) at qbit i.e. Z measurement outcome at qbit is determinate ##
    elseif in_counter == 0
        print("Determinate outcome")
        println()
        scratch_row = deepcopy(last(state.stabilizers))
        push!(state.stabilizers, scratch_row)

        # 1st step
        for j = 1:state.stabilizers[1].qubits
            last(state.stabilizers).X[j] = 0
            last(state.stabilizers).Z[j] = 0
        end
        last(state.stabilizers).phase += 4

        # 2nd step
        out_counter = 0
        for s in state.stabilizers
            out_counter += 1

            # Workaround to algo where it needs to find destabilisers with X at qbit.
            # We substitute the need for destabilisers by finding stabilisers with Z at qbit instead.
            if s.Z[qbit] == 1 && out_counter <= state.stabilizers[1].qubits
                RowSum(last(state.stabilizers), s)
            end
        end

        measure_outcome = (0 + 1im)^last(state.stabilizers).phase
        #=
        print("complete stab is:")
        println()
        print(state)
        println()
        =#
        pop!(state.stabilizers)
    end

    return measure_outcome
end

"""
    MeasureX(state, qubit_any)

Apply non-demolishing X measurement on qubit_any in given state.
"""
function MeasureX(state::StabilizerState, qubit::Int64)::Int64
    measure_outcome = 0
    qbit = GetQubitLabel(state, qubit)

    H(state, qubit)
    measure_outcome = MeasureZ(state, qubit)
    H(state, qubit)

    measure_outcome = (0 + 1im)^state.stabilizers[qbit].phase
    return(measure_outcome)
end

"""
    MeasureY(state, qubit_any)

Apply non-demolishing Y measurement on qubit_any in given state.
"""
function MeasureY(state::StabilizerState, qubit::Int64)::Int64
    measure_outcome = 0
    qbit = GetQubitLabel(state, qubit)

    P(state, qubit)
    measure_outcome = MeasureX(state, qubit)
    P(state, qubit)

    measure_outcome = (0 + 1im)^state.stabilizers[qbit].phase
    return(measure_outcome)
end

"""
    RowSum(Stabilizer_h, Stabilizer_i)

Performs the rowsum(h,i) operation in a given tableau; used in MeasureZ (and X, y) functions.
Written using rowsum algo in 'Improved Simulation of stabilizer circuits' by Aaranson and Gottesman
"""
function RowSum(stabilizer_h::Stabilizer, stabilizer_i::Stabilizer)
    g_sum = 0
    for j=1:stabilizer_h.qubits
        x_h = stabilizer_h.X[j]
        z_h = stabilizer_h.Z[j]
        x_i = stabilizer_i.X[j]
        z_i = stabilizer_i.Z[j]

        g_sum += G(x_h, z_h, x_i, z_i)
    end

    h_phase = (0 + 1im)^stabilizer_h.phase
    i_phase = (0 + 1im)^stabilizer_i.phase

    r_h = abs(-0.5*(h_phase - 1))
    r_i = abs(-0.5*(i_phase - 1))

    dummy = 2*(r_h) + 2*(r_i) + g_sum
    if mod(dummy,4) == 0
        stabilizer_h.phase = 4
    elseif mod(dummy,4) == 2
        stabilizer_h.phase = 2
    end

    for j = 1:stabilizer_h.qubits
        stabilizer_h.X[j] = stabilizer_h.X[j] ⊻ stabilizer_i.X[j]
        stabilizer_h.Z[j] = stabilizer_h.Z[j] ⊻ stabilizer_i.Z[j]
    end
end

"""
    G(x1, z1, x2, z2)

Performs bit operations on given 4 bit input; used in rowsum function of a tableau.
Written using rowsum algo in 'Improved Simulation of stabilizer circuits' by Aaranson and Gottesman
"""
function G(x1::Int64, z1::Int64, x2::Int64, z2::Int64)::Int64
    if x1 == 0 && z1 == 0
        g = 0
    elseif x1 == 1 && z1 == 1
        g = z2 - x2
    elseif x1 == 1 && z1 == 0
        g = z2*(2*x2 - 1)
    elseif x1 == 0 && z1 == 1
        g = x2*(1 - 2*z2)
    end

    return g
end
