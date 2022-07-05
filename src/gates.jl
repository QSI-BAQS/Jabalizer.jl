module Gates

abstract type Gate end
abstract type Gate1 <: Gate end
abstract type Gate2 <: Gate end

export Gate, Gate1, Gate2
export Id, P, X, Y, Z, H, CNOT, CZ, SWAP

"""P gate"""
struct P <: Gate1 ; qubit::Int ; end
"""Pauli-I gate"""
struct Id <: Gate1 ; qubit::Int ; end
"""Pauli-X gate"""
struct X <: Gate1 ; qubit::Int ; end
"""Pauli-Y gate"""
struct Y <: Gate1 ; qubit::Int ; end
"""Pauli-Z gate"""
struct Z <: Gate1 ; qubit::Int ; end
"""Hadamard gate"""
struct H <: Gate1 ; qubit::Int ; end

"""Controlled NOT gate"""
struct CNOT <: Gate2 ; qubit1::Int ; qubit2::Int ; end
"""CZ gate"""
struct CZ <: Gate2 ;   qubit1::Int ; qubit2::Int ; end
"""SWAP gate"""
struct SWAP <: Gate2 ; qubit1::Int ; qubit2::Int ; end

end # module Gates
