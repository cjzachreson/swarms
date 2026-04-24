using Random
using SoundSwarms

function controlled_run_fixture()
     rng = MersenneTwister(1)
     base_params = SwarmParameters(1.0, 2.0, 0.1, 10.0, 10.0)
     initial_state = initialize_swarm(8, base_params, rng)
     audio_frames = synthetic_feature_frames(5; dt = 0.1)
     mapping = FeatureParameterMapping(0.2, 8.0, 0.1, 0.8)

     return initial_state, base_params, audio_frames, mapping
end

function test_run_controlled_simulation_length_and_pairing()
     initial_state, base_params, audio_frames, mapping = controlled_run_fixture()
     run_frames = run_controlled_simulation(initial_state, base_params, audio_frames, mapping, 1.0, MersenneTwister(2))

     @test length(run_frames) == length(audio_frames)
     @test [frame.audio for frame in run_frames] == audio_frames
end

function test_run_controlled_simulation_speed_bounds()
     initial_state, base_params, audio_frames, mapping = controlled_run_fixture()
     dt = 0.5
     run_frames = run_controlled_simulation(initial_state, base_params, audio_frames, mapping, dt, MersenneTwister(2))

     @test all(frame.params.speed * dt <= base_params.alignment_radius for frame in run_frames)
end

function test_run_controlled_simulation_does_not_mutate_initial_state()
     initial_state, base_params, audio_frames, mapping = controlled_run_fixture()
     original_positions = copy(initial_state.positions)
     original_headings = copy(initial_state.headings)

     run_controlled_simulation(initial_state, base_params, audio_frames, mapping, 1.0, MersenneTwister(2))

     @test initial_state.positions == original_positions
     @test initial_state.headings == original_headings
end

function test_run_controlled_simulation_validates_dt()
     initial_state, base_params, audio_frames, mapping = controlled_run_fixture()

     @test_throws ArgumentError run_controlled_simulation(initial_state, base_params, audio_frames, mapping, 0.0, MersenneTwister(2))
end

@testset "Controlled simulation runner" begin
     test_run_controlled_simulation_length_and_pairing()
     test_run_controlled_simulation_speed_bounds()
     test_run_controlled_simulation_does_not_mutate_initial_state()
     test_run_controlled_simulation_validates_dt()
end
