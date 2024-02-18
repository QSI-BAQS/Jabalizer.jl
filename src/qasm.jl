using OpenQASM
using OpenQASM.Types
using OpenQASM.Tools
using RBNF: Token
using MLStyle

function parse_file(filename::String)
    return OpenQASM.parse(read(filename, String))
end

# Take output of parse_file and return same data as icm_circuit_from_qasm
function transform(qasm)
    return @match qasm begin
        Token{:reserved}(str=str) => @match str begin
            :pi => Base.pi
            _ => String(str)
        end
        Token{:id}(str=str) => String(str)
        Token{:float64}(str=str) => parse(Float64, str) 
        Token{:int}(str=str) => parse(Int64, str)
        Token{:str}(str=str) => str
        Include(file) => transform(file)
        RegDecl(type, name, size) => (transform(type), transform(name), transform(size))
        Bit(name=id, address=int) => transform(int) + 1 # assume only one name "q"
        Instruction(name, cargs, qargs) => @match name begin
            "id"    => ("I", transform(qargs[1]))
            "h"     => ("H", transform(qargs[1]))
            "x"     => ("X", transform(qargs[1]))
            "y"     => ("Y", transform(qargs[1]))
            "z"     => ("Z", transform(qargs[1]))
            "cnot"  => ("CNOT", transform(qargs[1]))
            "swap"  => ("SWAP", transform(qargs[1]))
            "s"     => ("S", transform(qargs[1]))
            "sdg"   => ("S_DAG", transform(qargs[1]))
            "t"     => ("T", transform(qargs[1]))
            "tdg"   => ("T_Dagger", transform(qargs[1]))
            "cx"    => ("CNOT", map(transform, qargs))
            "cz"    => ("CZ", transform(qargs[1]))
            "rz"    => ("RZ", map(transform, cargs), map(transform, qargs)) #TODO: fix rz(pi/2) q[1];
            _       => (name, cargs, qargs)
        end
        MainProgram(prog=statements) => let result = map(transform, statements)
            # (number of qubits, circuit as Vector{ICMGate})
            (result[2][3], result[3:end])
        end
    end
end

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
         "tdg" => "T_Dagger", # Temp hack removed; "T", # "T_Dagger", # Temporary Hack!
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

Note : qasm is 0 indexed while Jabalizer is 1 indexed so qubits labels will
be transalated from i -> i+1.
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
    circuit = Vector{Tuple{String, Vector{Int}}}()
    for i = 3:length(ap)
        gate = ap[i]
        gate isa Instruction || error("Not an instruction: $gate")
        isempty(gate.cargs) || error("Classical bits not supported yet")
        ins = get(qasm_map, gate.name, "")
        ins == "" && error("Instruction $ins not found")
        args = gate.qargs
        vals = Int[]
        for qarg in args
            (qarg isa Bit &&
             qarg.name isa Token{:id} && qarg.name.str == nam &&
             qarg.address isa Token{:int}) ||
             error("Invalid instruction argument: $qarg")
            # convert to 1 index from qasm 0 index
            push!(vals, parse(Int, qarg.address.str) + 1) 
        end
        push!(circuit, (ins, vals))
    end
    siz, circuit
end
