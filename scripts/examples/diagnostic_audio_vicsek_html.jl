using Random
using SoundSwarms

function run_example()
     rng = MersenneTwister(42)
     particle_count = 220
     domain_width = 100.0
     domain_height = 100.0
     params = SwarmParameters(0.8, 7.0, 0.35, domain_width, domain_height)
     state = initialize_swarm(particle_count, params, rng)
     step_count = 900
     dt = 1.0
     feature_dt = 1 / 30
     swarm_frames = SwarmFrame[]
     audio_frames = synthetic_feature_frames(step_count; dt = feature_dt)

     for _ in 1:step_count
          push!(swarm_frames, SwarmFrame(state.positions))
          step!(state, params, dt, rng)
     end

     output_path = joinpath("outputs", "diagnostic_audio_vicsek.html")
     write_diagnostic_html_animation(output_path, swarm_frames, audio_frames, domain_width, domain_height; fps = 45, trail_alpha = 0.08)
     println("Wrote $(output_path)")
end

run_example()
