using Random: AbstractRNG

function initialize_swarm(particle_count::Integer, params::SwarmParameters, rng::AbstractRNG)
     particle_count > 0 || throw(ArgumentError("particle_count must be positive"))

     positions = Matrix{Float64}(undef, 2, particle_count)
     headings = Vector{Float64}(undef, particle_count)

     for particle_index in 1:particle_count
          positions[1, particle_index] = params.domain_width * rand(rng)
          positions[2, particle_index] = params.domain_height * rand(rng)
          headings[particle_index] = 2pi * rand(rng)
     end

     return SwarmState(positions, headings)
end
