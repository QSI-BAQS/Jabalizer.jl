const gate_map = Dict()


# This is called by the Jabalizer package's __init__ function
function _init_gate_map()
    copy!(gate_map,
        Dict("I" => Jabalizer.Id,
             "X" => Jabalizer.X,	# HSSH
             "Y" => Jabalizer.Y,	# SSHSSH
             "Z" => Jabalizer.Z,	# SS
             "C_XYZ" => Jabalizer.C_XYZ,	# SSSH
             "C_ZYX" => Jabalizer.C_ZYX,	# HS
             "H" => Jabalizer.H,	# H_XZ
             "H_XZ" => Jabalizer.H,
             "H_XY" => Jabalizer.H_XY,		# HSSHS
             "H_YZ" => Jabalizer.H_YZ,		# HSHSS
             "S" => Jabalizer.P,		# SQRT_Z
             "SQRT_X" => Jabalizer.SQRT_X,		# HSH
             "SQRT_X_DAG" => Jabalizer.SQRT_X_DAG,	# SHS
             "SQRT_Y" => Jabalizer.SQRT_Y,		# SSH
             "SQRT_Y_DAG" => Jabalizer.SQRT_Y_DAG,	# HSS
             "SQRT_Z" => Jabalizer.P,		# S
             "SQRT_Z_DAG" => Jabalizer.SQRT_Z_DAG,	# SSS
             "S_DAG" =>  => Jabalizer.S_DAG,		# SQRT_Z_DAG
             "SWAP" => Jabalizer.SWAP,
                 # CNOT a b; CNOT b a; CNOT a b
             "CXSWAP" => Jabalizer.CXSWAP,
                 # CNOT b a; CNOT a b
             "PHASE" => Jabalizer.P, # TODO: IS IT?!?!?!
             "CNOT" => Jabalizer.CNOT,	# CX,ZCX
             "CX" => Jabalizer.CNOT,
             "ZCX" => Jabalizer.CNOT,
             "CY" => Jabalizer.CY,  # ZCY
                 # S b; S b; S b; CNOT a b; S b
             "ZCY" => Jabalizer.CY,
             "CZ" => Jabalizer.CZ,	# ZCZ
                 # H b; CNOT a b; H b
             "ZCZ" => Jabalizer.CZ,
             "ISWAP" => Jabalizer.ISWAP,
                 # H a; S a; S a; S a; CNOT a b; S a; CNOT b a; H b; S b; S a
             "ISWAP_DAG" => Jabalizer.ISWAP_DAG,
                 # S a; S a; S a; S b; S b; S b; H b;
		 # CNOT b a; S a; S a; S a;
                 # CNOT a b; S a; H a
	     "SQRT_XX" => Jabalizer.SQRT_XX,
                 # H a; CNOT a b; H b; S a; S b; H a; H b
	     "SQRT_XX_DAG" => Jabalizer.SQRT_XX_DAG,
                 # H a; CNOT a b; H b; S a; S a; S a; S b; S b; S b; H a; H b
	     "SQRT_YY" => Jabalizer.SQRT_YY,
                 # S a; S a; S a; S b; S b; S b; H a;
                 # CNOT a b; H b; S a; S b; H a; H b; S a; S b
	     "SQRT_YY_DAG" => Jabalizer.SQRT_YY_DAG,
                 # S a; S a; S a; S b; H a;
                 # CNOT a b; H b; S a; S b; H a; H b; S a; S b; S b; S b;
	     "SQRT_ZZ" => Jabalizer.SQRT_ZZ,
                 # H b; CNOT a b; H b; S a; S b
	     "SQRT_ZZ_DAG" => Jabalizer.SQRT_ZZ_DAG,
                 # H b; CNOT a b; H b; S a; S a; S a; S b; S b; S b
             "SWAPCX" => Jabalizer.SWAPCX,
                 # CNOT a b; CNOT b a
             "XCX" => Jabalizer.XCX,
                 # H a; CNOT a b; H a
             "XCY" => Jabalizer.XCY,
                 # H a; S b; S b; S b; CNOT a b; H a; S b
             "XCZ" => Jabalizer.XCZ,
                 # CNOT b a
             "YCX" => Jabalizer.YCX,
                 # S a; S a; S a; H b; CNOT b a; S a; H b
             "YCY" => Jabalizer.YCY,
                 # S a; S a; S a; S b; S b; S b; H a; CNOT a b; H a; S a; S b
             "YCZ" => Jabalizer.YCZ,
             # S a; S a; S a; CNOT b a; S a
             ))
end

"""
Executes circuit using stim simulator and applies it to a given state.
"""
function execute_circuit(state::StabilizerState, circuit::Vector{ICMGate})
    n_qubits = 0
    qubit_map = Dict{String,Int}()
    for op in circuit
        qindices = Vector{Int}()
        for qindex in op[2]
            if !haskey(qubit_map, qindex)
                n_qubits += 1
                qubit_map[qindex] = n_qubits
            end
            push!(qindices, qubit_map[qindex])

        end
        gate = gate_map[op[1]](qindices...)
        gate(state)
    end
end
