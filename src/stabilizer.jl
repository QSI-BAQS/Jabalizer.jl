"""
    Stabilizer type

Type for a single stabilizer in the n-qubit Pauli group.
"""
mutable struct Stabilizer
    qubits::Int
    X::Vector{Int}
    Z::Vector{Int}
    phase::Int

    """
        Stabilizer()

    Constructor for an empty stabilizer.
    """
    Stabilizer() = new(0, Int[], Int[], 0)

    """
        Stabilizer(n)

    Constructor for an n-qubit identity stabilizer.
    """
    Stabilizer(n::Int) = new(n, zeros(Int, n), zeros(Int, n), 0)

    """
        Stabilizer(tableau)

    Constructor for a stabilizer from tableau form.
    """
    function Stabilizer(tab::AbstractVector{Int})
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
        leftPauli = TabToPauli(left.X[n], left.Z[n])
        rightPauli = TabToPauli(right.X[n], right.Z[n])

        thisPauli = PauliProd(leftPauli, rightPauli)
        thisTab = PauliToTab(thisPauli[1])

        (prod.X[n], prod.Z[n]) = (thisTab[1], thisTab[2])
        prod.phase += thisPauli[2]
        prod.phase %= 4
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
