

@testset "stim tableau to tableau" begin
    # TODO: Add the following tests:
    # 1. Check if the conversion works well.
    # TODO: What should the test cases be?
end


@testset "Update tableau" begin
    # TODO: Add the following tests:
    # 1. Check if update works correctly
    # TODO: What should the test cases be?
end


@testset "Stabilizer State to Graph" begin
    # TODO: Add the following tests:
    # 1. Check if the conversion works back and forth
    # TODO: What should the test cases be?
end

@testset "Test Tab operations" begin
    # TODO: Add the following tests:
    # 1. Check if H works properly
    # 2. Check if RowAdd works properly
    # TODO: What should the test cases be?
end

@testset "Test Pauli - Tableau conversion" begin
    # TODO: Add the following tests:
    # 1. Check if the conversion works back and forth
    # TODO: What should the test cases be?
end

@testset "Test Pauli operations" begin
    # TODO: Add the following tests:
    # 1. Check if PauliProd works well
    # TODO: What should the test cases be?
end

"""
    PauliProd(left, right)

Product of two Pauli operators.
"""
function PauliProd(left::Char, right::Char)
    if left == 'X' && right == 'Z'
        return ('Y', 3)
    elseif left == 'X' && right == 'Y'
        return ('Z', 1)
    elseif left == 'Z' && right == 'X'
        return ('Y', 1)
    elseif left == 'Z' && right == 'Y'
        return ('X', 3)
    elseif left == 'Y' && right == 'Z'
        return ('X', 1)
    elseif left == 'Y' && right == 'X'
        return ('Z', 3)
    elseif left == 'I'
        return (right, 0)
    elseif right == 'I'
        return (left, 0)
    else
        return ('I', 0)
    end
end