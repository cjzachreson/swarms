using Random: AbstractRNG

function step!(state::SwarmState, params::SwarmParameters, dt::Real, rng::AbstractRNG)
     dt >= 0 || throw(ArgumentError("dt must be non-negative"))

     particle_count = length(state.headings)
     old_positions = copy(state.positions)
     old_headings = copy(state.headings)

     for particle_index in 1:particle_count
          mean_heading = neighbor_mean_heading(
               old_positions,
               old_headings,
               particle_index,
               params.alignment_radius,
               params.domain_width,
               params.domain_height,
          )
          noise = params.noise_strength * (rand(rng) - 0.5)
          state.headings[particle_index] = mean_heading + noise
     end

     distance = params.speed * Float64(dt)
     for particle_index in 1:particle_count
          state.positions[1, particle_index] = wrap_periodic(
               old_positions[1, particle_index] + distance * cos(state.headings[particle_index]),
               params.domain_width,
          )
          state.positions[2, particle_index] = wrap_periodic(
               old_positions[2, particle_index] + distance * sin(state.headings[particle_index]),
               params.domain_height,
          )
     end

     return state
end

function neighbor_mean_heading(
     positions::Matrix{Float64},
     headings::Vector{Float64},
     particle_index::Int,
     alignment_radius::Float64,
     domain_width::Float64,
     domain_height::Float64,
)
     radius_squared = alignment_radius^2
     sin_sum = 0.0
     cos_sum = 0.0

     for neighbor_index in eachindex(headings)
          dx = periodic_delta(positions[1, neighbor_index] - positions[1, particle_index], domain_width)
          dy = periodic_delta(positions[2, neighbor_index] - positions[2, particle_index], domain_height)

          if dx^2 + dy^2 <= radius_squared
               sin_sum += sin(headings[neighbor_index])
               cos_sum += cos(headings[neighbor_index])
          end
     end

     return atan(sin_sum, cos_sum)
end

periodic_delta(delta::Float64, width::Float64) = delta - width * round(delta / width)

wrap_periodic(value::Float64, width::Float64) = mod(value, width)
