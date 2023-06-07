"""
    Stabilizer type

Type for a single stabilizer in the n-qubit Pauli group.
"""
mutable struct Stabilizer
    qubits::Int
    X::BitVector
    Z::BitVector
    phase::Int8

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
        Stabilizer(tableau[, row])

    Constructor for a stabilizer from tableau form.
    """
    function Stabilizer(tab::AbstractMatrix{<:Integer}, row=1)
        qubits = size(tab, 2) >> 1
        new(qubits, view(tab, row, 1:qubits), view(tab, row, qubits+1:2*qubits), tab[row, end])
    end
    function Stabilizer(vec::AbstractVector{<:Integer})
        qubits = length(vec) >> 1
        new(qubits, view(vec, 1:qubits), view(vec, qubits+1:2*qubits), vec[end])
    end

    """
        Stabilizer(X::BitVector, Z::BitVector, phase)

    Constructor for a stabilizer from tableau form.
    """
    function Stabilizer(X, Z, phase)
        lx, lz = length(X), length(Z)
        lx == lz || error("X & Z vectors have different lengths ($lx != $lz)")
        new(lx, X, Z, phase)
    end
end

"""
Convert stabilizer to vector form (one row of a tableau)
"""
to_tableau_row(stabilizer::Stabilizer) = vcat(stabilizer.X, stabilizer.Z, stabilizer.phase)

"""
    adjoint(stabilizer)

Conjugate of a stabilizer.
"""
function Base.adjoint(stabilizer::Stabilizer)::Stabilizer
    conj = deepcopy(stabilizer)
    conj.phase = mod(-conj.phase, 4)
    return conj
end

# This table is used to calculate the product by indexing a vector of tuples of the
# results (X, Z, phase), by the values of the left X, left Z, right X, right Z used
# as a 4 bit index (left X is most signficant bit, right Z is least significant bit)
# (+ 1 for Julia 1-based indexing)
const _prodtab = [(0, 0, 0), (0, 1, 0), (1, 0, 0), (1, 1, 0),
    (0, 1, 0), (0, 0, 0), (1, 1, 1), (1, 0, 3),
    (1, 0, 0), (1, 1, 3), (0, 0, 0), (0, 1, 1),
    (1, 1, 0), (1, 0, 1), (0, 1, 3), (0, 0, 0)]

"""
    *(left,right)

Multiplication operator for stabilizers.
"""
function Base.:*(left::Stabilizer, right::Stabilizer)::Stabilizer
    left.qubits == right.qubits || return left
    qubits = left.qubits
    prod = Stabilizer(qubits)
    prod.phase = (left.phase + right.phase) & 3
    for n = 1:qubits
        (prod.X[n], prod.Z[n], phase) =
            _prodtab[((left.X[n]<<3)|(left.Z[n]<<2)|(right.X[n]<<1)|right.Z[n])+1]
        prod.phase = (prod.phase + phase) & 3
    end
    return prod
end

Base.:(==)(s1::Stabilizer, s2::Stabilizer) =
    s1.qubits == s2.qubits && s1.X == s2.X && s1.Z == s2.Z && s1.phase == s2.phase

function Base.isless(s1::Stabilizer, s2::Stabilizer)
    s1.X < s2.X && return true
    s1.X > s2.X && return false
    s1.Z < s2.Z && return true
    s1.Z > s2.Z && return false
    s1.phase < s2.phase
end

function Base.print(io::IO, stabilizer::Stabilizer)
    print(io, stabilizer.phase == 0 ? '+' : '-')
    for (x, z) in zip(stabilizer.X, stabilizer.Z)
        print(io, "IXZY"[((z<<1)|x)+1])
    end
end

Base.display(stabilizer::Stabilizer) =
    println("Stabilizer for ", stabilizer.qubits, " qubits:\n", stabilizer)
