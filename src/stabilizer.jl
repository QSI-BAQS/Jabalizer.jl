"""
    Stabilizer type

Type for a single stabilizer in the n-qubit Pauli group.
"""
mutable struct Stabilizer
    qubits::Int
    X::BitVector
    Z::BitVector
    phase::Int

    """
        Stabilizer()

    Constructor for an empty stabilizer.
    """
    Stabilizer() = new(0, falses(0), falses(0), 0)

    """
        Stabilizer(n)

    Constructor for an n-qubit identity stabilizer.
    """
    Stabilizer(n::Int) = new(n, falses(n), falses(n), 0)

    """
        Stabilizer(tableau)

    Constructor for a stabilizer from tableau form.
    """
    function Stabilizer(tab::AbstractArray)
        len = length(tab) - 1
        qubits = div(len, 2)
        new(qubits, tab[1:qubits], tab[qubits+1:end-1], tab[end])
    end
end

"""
Convert stabilizer to tableau form.
"""
ToTableau(stabilizer::Stabilizer) = vcat(stabilizer.X, stabilizer.Z, stabilizer.phase)

"""
    adjoint(stabilizer)

Conjugate of a stabilizer.
"""
function Base.adjoint(stabilizer::Stabilizer)::Stabilizer
    conj = deepcopy(stabilizer)
    conj.phase = (-conj.phase) % 4
    return conj
end

const OpI = 0
const OpX = 1
const OpZ = 2
const OpY = 3

_pauli(x::Bool, z::Bool) = (z<<1)|x

function _prod(left::Int, right::Int)
    if left == OpX
        right == OpZ && return (1, 1, 3) # (OpY, 3)
        right == OpY && return (0, 1, 1) # (OpZ, 1)
        right == OpI && return (1, 0, 0) # (OpX, 0)
    elseif left == OpZ
        right == OpX && return (1, 1, 1) # (OpY, 1)
        right == OpY && return (1, 0, 3) # (OpX, 3)
        right == OpI && return (0, 1, 0) # (OpZ, 0)
    elseif left == OpY
        right == OpZ && return (1, 0, 1) # (OpX, 1)
        right == OpX && return (0, 1, 3) # (OpZ, 3)
        right == OpI && return (1, 1, 0) # (OpY, 0)
    else # left == OpI
        return (right&1, right>>1, 0)
    end
    return (0, 0, 0) # (OpI, 0)
end

"""
    *(left,right)

Multiplication operator for stabilizers.
"""
function Base.:*(left::Stabilizer, right::Stabilizer)::Stabilizer
    left.qubits == right.qubits || return left
    qubits = left.qubits
    prod = Stabilizer(qubits)
    prod.phase = (left.phase + right.phase) % 4
    for n = 1:qubits
        (prod.X[n], prod.Z[n], phase) =
            _prod(_pauli(left.X[n], left.Z[n]), _pauli(right.X[n], right.Z[n]))
        prod.phase = (prod.phase + phase) % 4
    end
    return prod
end

function Base.print(io::IO, stabilizer::Stabilizer)
    print(io, stabilizer.phase == 0 ? '+' : '-')
    for (x, z) in zip(stabilizer.X, stabilizer.Z)
        print(io, "IXZY"[((z<<1)|x)+1])
    end
end

Base.display(stabilizer::Stabilizer) =
    println("Stabilizer for ", stabilizer.qubits, " qubits:\n", stabilizer)
