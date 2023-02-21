module Gates

const gate_alias =
    [("H_XZ", :H),
     ("P", :S),
     ("PHASE", :S),
     ("SQRT_Z", :S),
     ("SQRT_Z_DAG", :S_DAG),
     ("S^-1", :S_DAG),
     ("S_Dagger", :S_DAG),
     ("CX", :CNOT),
     ("ZCX", :CNOT),
     ("ZCY", :CY),
     ("ZCZ", :CZ),
     ]

const gate1_list =
    [("I",     :Id),
     ("X",     :X),	# HSSH
     ("Y",     :Y),	# SSHSSH
     ("Z",     :Z),	# SS
     ("C_XYZ", :C_XYZ),	# SSSH
     ("C_ZYX", :C_ZYX),	# HS
     ("H",     :H),
     ("H_XY",  :H_XY),	# HSSHS
     ("H_YZ",  :H_YZ),	# HSHSS
     ("S",     :S),
     ("S_DAG", :S_DAG),
     ("SQRT_X",     :SQRT_X),     # HSH
     ("SQRT_X_DAG", :SQRT_X_DAG), # SHS
     ("SQRT_Y",     :SQRT_Y),	  # SSH
     ("SQRT_Y_DAG", :SQRT_Y_DAG), # HSS
     ]

const gate2_list =
    [("CNOT",   :CNOT),
     ("CY",     :CY),     # S1 S1 S1 CNOT01 S1
     ("CZ",     :CZ),     # H1 CNOT01 H1
     ("XCX",    :XCX),    # H0 CNOT01 H0
     ("XCY",    :XCY),    # H0 S1 S1 S1 CNOT01 H0 S1
     ("XCZ",    :XCZ),    # CNOT10
     ("YCX",    :YCX),    # S0 S0 S0 H1 CNOT10 S0 H1
     ("YCY",    :YCY),    # S0 S0 S0 S1 S1 S1 H0 CNOT01 H0 S0 S1
     ("YCZ",    :YCZ),
     ("SWAP",   :SWAP),   # CNOT01 CNOT10 CNOT01
     ("CXSWAP", :CXSWAP), # CNOT10 CNOT01
     ("SWAPCX", :SWAPCX), # CNOT01 CNOT10
     ("ISWAP",  :ISWAP),  # H0 S0 S0 S0 CNOT01 S0 CNOT10 H1 S1 S0
     ("ISWAP_DAG", :ISWAP_DAG),
         # S0 S0 S0 S1 S1 S1 H1 CNOT10 S0 S0 S0 CNOT01 S0 H0
     ("SQRT_XX", :SQRT_XX),
         # H0 CNOT01 H1 S0 S1 H0 H1
     ("SQRT_XX_DAG", :SQRT_XX_DAG),
         # H0 CNOT01 H1 S0 S0 S0 S1 S1 S1 H0 H1
     ("SQRT_YY", :SQRT_YY),
         # S0 S0 S0 S1 S1 S1 H0 CNOT01 H1 S0 S1 H0 H1 S0 S1
     ("SQRT_YY_DAG", :SQRT_YY_DAG),
         # S0 S0 S0 S1 H0 CNOT01 H1 S0 S1 H0 H1 S0 S1 S1 S1
     ("SQRT_ZZ", :SQRT_ZZ),
         # H1 CNOT01 H1 S0 S1
     ("SQRT_ZZ_DAG", :SQRT_ZZ_DAG),
         # H1 CNOT01 H1 S0 S0 S0 S1 S1 S1
     ]
                   
abstract type Gate end
abstract type Gate1 <: Gate end
abstract type Gate2 <: Gate end

export Gate, Gate1, Gate2

#=
"Pauli-I"
"Pauli-X"
"Pauli-Y"
"Pauli-Z"
"S (Phase)"
"Hadamard"
"Controlled NOT"
"CZ"
"SWAP"
=#

for (name, sym) in gate1_list
    @eval begin
        export $sym ; struct $sym <: Gate1 ; qubit::Int ; end
    end
end
for (name, sym) in gate2_list
    @eval begin
        export $sym ; struct $sym <: Gate2 ; qubit1::Int ; qubit2::Int ; end
    end
end

# Aliases
const P = S ; export P
const PHASE = S ; export PHASE

const gate_map = Dict{String,Type{<:Gate}}()
export gate_map

# This is called by the Jabalizer package's __init__ function
function _init_gate_map()
    for (name, sym) in vcat(gate1_list, gate2_list, gate_alias)
        gate_map[name] = eval(sym)
    end
end

end # module Gates
