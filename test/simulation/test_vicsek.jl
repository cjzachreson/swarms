using Random
using SoundSwarms

function test_zero_noise_alignment_step()
     state = SwarmState([0.0 1.0; 0.0 0.0], [0.0, pi / 2])
     params = SwarmParameters(1.0, 2.0, 0.0, 10.0, 10.0)

     step!(state, params, 1.0, MersenneTwister(1))

     @test state.headings ≈ [pi / 4, pi / 4]
     @test state.positions ≈ [
          cos(pi / 4) 1.0 + cos(pi / 4)
          sin(pi / 4) sin(pi / 4)
     ]
end

function test_periodic_wrapping()
     state = SwarmState(reshape([9.75, 5.0], 2, 1), [0.0])
     params = SwarmParameters(1.0, 1.0, 0.0, 10.0, 10.0)

     step!(state, params, 0.5, MersenneTwister(1))

     @test state.positions[:, 1] ≈ [0.25, 5.0]
end

function test_periodic_neighbor_distance()
     state = SwarmState([0.2 9.8; 0.0 0.0], [0.0, pi / 2])
     params = SwarmParameters(0.0, 1.0, 0.0, 10.0, 10.0)

     step!(state, params, 1.0, MersenneTwister(1))

     @test state.headings ≈ [pi / 4, pi / 4]
end

@testset "Vicsek update" begin
     test_zero_noise_alignment_step()
     test_periodic_wrapping()
     test_periodic_neighbor_distance()
end
