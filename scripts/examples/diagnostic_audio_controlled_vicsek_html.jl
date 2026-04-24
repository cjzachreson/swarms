using Random
using SoundSwarms

function run_example()
     rng = MersenneTwister(42)
     particle_count = 220
     domain_width = 100.0
     domain_height = 100.0
     base_params = SwarmParameters(0.8, 7.0, 0.35, domain_width, domain_height)
     mapping = FeatureParameterMapping(0.05, 2.2, 0.02, 1.1)
     state = initialize_swarm(particle_count, base_params, rng)
     step_count = 900
     dt = 1.0
     feature_dt = 1 / 30
     swarm_frames = SwarmFrame[]
     audio_frames = synthetic_feature_frames(step_count; dt = feature_dt)

     for frame in audio_frames
          params = map_features_to_parameters(base_params, frame, mapping, dt)
          push!(swarm_frames, SwarmFrame(state.positions))
          step!(state, params, dt, rng)
     end

     output_path = joinpath("outputs", "diagnostic_audio_controlled_vicsek.html")
     write_diagnostic_html_animation(
          output_path,
          swarm_frames,
          audio_frames,
          domain_width,
          domain_height;
          fps = 45,
          trail_alpha = 0.08,
          feature_trace_keys = (:rms, :high_band),
     )
     println("Wrote $(output_path)")
end

run_example()
