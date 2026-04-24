using Random
using SoundSwarms

function run_example()
     rng = MersenneTwister(42)
     particle_count = 220
     domain_width = 100.0
     domain_height = 100.0
     params = SwarmParameters(0.8, 7.0, 0.35, domain_width, domain_height)
     state = initialize_swarm(particle_count, params, rng)
     frames = SwarmFrame[]

     for _ in 1:900
          push!(frames, SwarmFrame(state.positions))
          step!(state, params, 1.0, rng)
     end

     output_path = joinpath("outputs", "basic_vicsek.html")
     write_html_animation(output_path, frames, domain_width, domain_height; fps = 45, trail_alpha = 0.08)
     println("Wrote $(output_path)")
end

run_example()
