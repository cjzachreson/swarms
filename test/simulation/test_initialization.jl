using Random
using SoundSwarms

function test_initialize_swarm_dimensions()
     params = SwarmParameters(1.0, 2.0, 0.1, 10.0, 20.0)
     state = initialize_swarm(5, params, MersenneTwister(1))

     @test size(state.positions) == (2, 5)
     @test length(state.headings) == 5
end

function test_initialize_swarm_domain_bounds()
     params = SwarmParameters(1.0, 2.0, 0.1, 10.0, 20.0)
     state = initialize_swarm(100, params, MersenneTwister(1))

     @test all(0.0 .<= state.positions[1, :] .< params.domain_width)
     @test all(0.0 .<= state.positions[2, :] .< params.domain_height)
     @test all(0.0 .<= state.headings .< 2pi)
end

function test_initialize_swarm_is_deterministic()
     params = SwarmParameters(1.0, 2.0, 0.1, 10.0, 20.0)
     state_a = initialize_swarm(10, params, MersenneTwister(123))
     state_b = initialize_swarm(10, params, MersenneTwister(123))

     @test state_a.positions == state_b.positions
     @test state_a.headings == state_b.headings
end

function test_initialize_swarm_rejects_invalid_particle_count()
     params = SwarmParameters(1.0, 2.0, 0.1, 10.0, 20.0)

     @test_throws ArgumentError initialize_swarm(0, params, MersenneTwister(1))
end

@testset "Swarm initialization" begin
     test_initialize_swarm_dimensions()
     test_initialize_swarm_domain_bounds()
     test_initialize_swarm_is_deterministic()
     test_initialize_swarm_rejects_invalid_particle_count()
end
