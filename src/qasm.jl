using OpenQASM
using OpenQASM.Types
using OpenQASM.Tools
using RBNF: Token

const qasm_map =
    Dict("id" => "I",
         "h" => "H",
         "x" => "X",
         "y" => "Y",
         "z" => "Z",
         "cnot" => "CNOT",
         "swap" => "SWAP",
         "s" => "S",
         "sdg" => "S_DAG",
         "t" => "T",
         "tdg" => "T_DAG",
         "cx" => "CNOT",
         "cz" => "CZ")

const hdr3beg = """OPENQASM 3;\ninclude "stdgates.inc";\nqubit["""
const hdr3end = """] _all_qubits;\nlet q = _all_qubits[0:"""

const hdr2 = """OPENQASM 2.0;\ninclude "qelib1.inc";\nqreg q["""

"""
Convert a very specific input string with a OpenQASM 3.0 header to a
OpenQASM 2.0 header, as a convenience hack until we have a real 3.0 parser
"""
function convert3to2(str::String)
    pos = sizeof(hdr3beg)
    nxt = findnext(']', str, pos)
    startswith(SubString(str, nxt), hdr3end) || error("Header doesn't match template")
    qubits = parse(Int, str[pos+1:nxt-1])
    pos = nxt + sizeof(hdr3end)
    nxt = findnext(']', str, pos)
    maxqb = parse(Int, str[pos:nxt-1])
    maxqb == qubits - 1 || error("Mismatched number of qubits $maxqb != $qubits - 1")
    string(hdr2, qubits, SubString(str, nxt))
end

export load_icm_circuit_from_qasm, icm_circuit_from_qasm

"""
Loads icm compatible circuit from a QASM (2.0) file
"""
load_icm_circuit_from_qasm(filename) = icm_circuit_from_qasm(read(filename, String))

"""
Parses icm compatible circuit from a QASM (2.0) input string
"""
function icm_circuit_from_qasm(str::String)
    # Hack to handle QASM 3 header
    startswith(str, hdr3beg) && (str = convert3to2(str))
    ast = OpenQASM.parse(str)
    # Check header information
    ast.version == v"2.0.0" || error("Unsupported QASM version: $(ast.version)")
    ap = ast.prog
    inc = ap[1]
    (inc isa Include && inc.file isa Token{:str} && inc.file.str == "\"qelib1.inc\"") ||
        error("Standard include missing")
    reg = ap[2]
    (reg isa RegDecl && reg.type isa Token{:reserved} && reg.type.str == "qreg" &&
     reg.size isa Token{:int} && reg.name isa Token{:id}) ||
         error("Missing qubit register declaration")
    # Pick up qubit reg name
    nam = reg.name.str
    siz = parse(Int, reg.size.str)
    circuit = Vector{Tuple{String,Vector{String}}}()
    for i = 3:length(ap)
        gate = ap[i]
        gate isa Instruction || error("Not an instruction: $gate")
        isempty(gate.cargs) || error("Classical bits not supported yet")
        ins = get(qasm_map, gate.name, "")
        ins == "" && error("Instruction $ins not found")
        args = gate.qargs
        vals = String[]
        for qarg in args
            (qarg isa Bit &&
             qarg.name isa Token{:id} && qarg.name.str == nam &&
             qarg.address isa Token{:int}) ||
             error("Invalid instruction argument: $qarg")
            push!(vals, qarg.address.str)
        end
        push!(circuit, (ins, vals))
    end
    siz, circuit
end
