import Base.print

"""
    Stabilizer type

Type for a single stabilizer in the n-qubit Pauli group.
"""
mutable struct Stabilizer
    qubits::Int64
    X::Array{Int64}
    Z::Array{Int64}
    phase::Int64

    """
        Stabilizer()

    Constructor for an empty stabilizer.
    """
    Stabilizer() = new(0, [], [], 0)

    """
        Stabilizer(n)

    Constructor for an n-qubit identity stabilizer.
    """
    Stabilizer(n::Int64) = new(n, zeros(n), zeros(n), 0)

    """
        Stabilizer(tableau)

    Constructor for a stabilizer from tableau form.
    """
    Stabilizer(tab::Array{Int64}) = new(
        Int64((length(tab) - 1) / 2),
        tab[1:Int64((length(tab) - 1) / 2)],
        tab[Int64((length(tab) - 1) / 2 + 1):Int64(length(tab) - 1)],
        last(tab),
    )
end

"""
Convert stabilizer to tableau form.
"""
function ToTableau(stabilizer::Stabilizer)
    return vcat(stabilizer.X, stabilizer.Z, stabilizer.phase)
end

"""
    adjoint(stabilizer)

Conjugate of a stabilizer.
"""
function adjoint(stabilizer::Stabilizer)::Stabilizer
    conj = deepcopy(stabilizer)
    conj.phase = (-conj.phase) % 4
    return conj
end

"""
    *(left,right)

Multiplication operator for stabilizers.
"""
function *(left::Stabilizer, right::Stabilizer)::Stabilizer
    if left.qubits != right.qubits
        return left
    end

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

"""
    string(stabilizer)

Convert stabilizer to string.
"""
function string(stabilizer::Stabilizer)
    str = ""

    for i = 1:stabilizer.qubits
        if stabilizer.X[i] == 0 && stabilizer.Z[i] == 0
            thisPauli = 'I'
        elseif stabilizer.X[i] == 1 && stabilizer.Z[i] == 0
            thisPauli = 'X'
        elseif stabilizer.X[i] == 0 && stabilizer.Z[i] == 1
            thisPauli = 'Z'
        elseif stabilizer.X[i] == 1 && stabilizer.Z[i] == 1
            thisPauli = 'Y'
        end

        str = string(str, thisPauli)
    end

    return string(str, " (", (0 + 1im)^stabilizer.phase, ")")
end

"""
    print(stabilizer)

Print a stabilizer to terminal.
"""
function print(stabilizer::Stabilizer, info::Bool = false, tab::Bool = false)
    if info == true
        println("Stabilizer for ", stabilizer.qubits, " qubits:")
    end

    if tab == false
        str = string(stabilizer)
    else
        str = ToTableau(stabilizer)
    end

    println(str)
end
