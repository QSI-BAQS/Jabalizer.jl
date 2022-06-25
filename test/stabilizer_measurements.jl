const measurement_test_cases = (
    ("0", Jabalizer.MeasureZ, 0, [0 1 0]),
    ("1", Jabalizer.MeasureZ, 1, [0 1 2]),
    ("+", Jabalizer.MeasureX, 0, [1 0 0]),
    ("-", Jabalizer.MeasureX, 1, [1 0 2]),
    ("+y", Jabalizer.MeasureY, 0, [1 1 0]),
    ("-y", Jabalizer.MeasureY, 1, [1 1 2]),
)

const init_operations = Dict("0" => [],
    "1" => [Jabalizer.X],
    "+" => [Jabalizer.H],
    "-" => [Jabalizer.X, Jabalizer.H],
    "+y" => [Jabalizer.H, Jabalizer.P],
    "-y" => [Jabalizer.X, Jabalizer.H, Jabalizer.P])

@testset "Measurements" begin

    for (init_state_str, measurement_op, target_output, target_tableau) in measurement_test_cases
        @testset "Measurement $measurement_op on state $init_state_str" begin
            state = Jabalizer.ZeroState(1)
            for init_op in init_operations[init_state_str]
                init_op(state, 1)
            end
            measurement = measurement_op(state, 1)
            @test measurement == target_output
            @test Jabalizer.ToTableau(state) == target_tableau
        end

    end

end
