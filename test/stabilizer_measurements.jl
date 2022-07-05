const measurement_test_cases =
    (("0", measure_z, 0, [0 1 0]),
     ("1", measure_z, 1, [0 1 2]),
     ("+", measure_x, 0, [1 0 0]),
     ("-", measure_x, 1, [1 0 2]),
     ("+y", measure_y, 0, [1 1 0]),
     ("-y", measure_y, 1, [1 1 2]))

const init_operations =
    Dict("0" => (),
         "1" => (X,),
         "+" => (H,),
         "-" => (X, H),
         "+y" => (H, P),
         "-y" => (X, H, P))

@testset "Measurements" begin

    for (init_state_str, measurement_op, target_output, target_tableau) in measurement_test_cases
        @testset "Measurement $measurement_op on state $init_state_str" begin
            state = zero_state(1)
            for init_op in init_operations[init_state_str]
                init_op(1)(state)
            end
            measurement = measurement_op(state, 1)
            @test measurement == target_output
            @test to_tableau(state) == target_tableau
        end

    end

end
