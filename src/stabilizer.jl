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
        qubits = size(tab, 2)>>1
        new(qubits, view(tab, row, 1:qubits), view(tab, row, qubits+1:2*qubits), tab[row, end])
    end
    function Stabilizer(vec::AbstractVector{<:Integer})
        qubits = length(vec)>>1
        new(qubits, view(vec, 1:qubits), view(vec, qubits+1:2*qubits), vec[end])
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
    prod.phase = (left.phase + right.phase) % 4
    for n = 1:qubits
        (prod.X[n], prod.Z[n], phase) =
            _prodtab[((left.X[n]<<3)|(left.Z[n]<<2)|(right.X[n]<<1)|right.Z[n])+1]
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
