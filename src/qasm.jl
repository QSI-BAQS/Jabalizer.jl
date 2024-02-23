using OpenQASM
using MLStyle
import RBNF: Token
export Gate, QuantumCircuit, parse_file

# Wrapper for OpenQASM.Types.Instruction
struct Gate
    name
    cargs
    qargs
end

name(g::Gate) = g.name
cargs(g::Gate) = g.cargs
qargs(g::Gate) = g.qargs
width(g::Gate) = length(qargs(g))

# 
struct QuantumCircuit
    registers::Vector{Int} # allow tensor product of circuits
    circuit::Vector{Gate}
    function QuantumCircuit(registers, circuit)
        @assert all(qargs(g) ⊆ registers for g in circuit)
        return new(registers, circuit)
    end
end

width(qc::QuantumCircuit) = length(qc.registers)
depth(qc::QuantumCircuit) = length(qc.circuit)
registers(qc::QuantumCircuit) = qc.registers
gates(qc::QuantumCircuit) = qc.circuit

Base.show(io::IO, qc::QuantumCircuit) = Base.show(io, gates(qc))

# Parse qasm file and return a QuantumCircuit
function parse_file(filename::String)
    ast = OpenQASM.parse(read(filename, String))
    # Only support the following qasm format
    @assert ast.version == v"2.0.0" "Unsupported QASM version: $(ast.version)"
    @assert length(filter(x->x isa OpenQASM.Types.Include, ast.prog)) == 1 "Incorrect qasm file format: must have one include statement"
    @assert ast.prog[1] isa OpenQASM.Types.Include "Incorrect qasm file format: first statement must be an include statement"
    @assert length(filter(x->x isa OpenQASM.Types.RegDecl, ast.prog)) == 1 "Unsupported multiple qubit register declarations"
    @assert ast.prog[2] isa OpenQASM.Types.RegDecl "Incorrect qasm file format: second statement must be a qubit register declaration"
    return transform(ast)
end

# TODO: expand include statements
function transform(qasm)
    return @match qasm begin
        t::Token{:id} => convert(Symbol, t)
        t::Token{:float64} => convert(Float64, t) 
        t::Token{:int} => convert(Int, t)
        t::Token{:str} => convert(String, t)
        t::Token{:reserved} => convert(Symbol, t)
        OpenQASM.Types.Include(file) => transform(file)
        OpenQASM.Types.RegDecl(type, name, size) => (transform(type), transform(name), transform(size))
        OpenQASM.Types.Bit(name=id, address=int) => transform(int) + 1 # convert to one-based indexing
        OpenQASM.Types.Instruction(name, cargs, qargs) => @match name begin
            "id"    => Gate("I", nothing, map(transform, qargs))
            "h"     => Gate("H", nothing, map(transform, qargs))
            "x"     => Gate("X", nothing, map(transform, qargs))
            "y"     => Gate("Y", nothing, map(transform, qargs))
            "z"     => Gate("Z", nothing, map(transform, qargs))
            "cnot"  => Gate("CNOT", nothing, map(transform, qargs))
            "swap"  => Gate("SWAP", nothing, map(transform, qargs))
            "s"     => Gate("S", nothing, map(transform, qargs))
            "sdg"   => Gate("S_DAG", nothing, map(transform, qargs))
            "t"     => Gate("T", nothing, map(transform, qargs))
            "tdg"   => Gate("T_Dagger", nothing, map(transform, qargs))
            "cx"    => Gate("CNOT", nothing, map(transform, qargs))
            "cz"    => Gate("CZ", nothing, map(transform, qargs))
            "rz"    => Gate("RZ", map(transform, cargs), map(transform, qargs)) #TODO: fix rz(pi/2) q[1];
            _       => error("Instruction not supported by Jabalizer yet")
        end
        OpenQASM.Types.MainProgram(prog=stmts) => let result = map(transform, stmts)
            qubits = 1:result[2][3] # ASSUME continuous register declaration
            circuit = result[3:end]
            QuantumCircuit(qubits, circuit)
        end
    end
end

# BELOW WILL BE DELETED

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
