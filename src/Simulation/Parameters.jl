struct SwarmParameters
     speed::Float64
     alignment_radius::Float64
     noise_strength::Float64
     domain_width::Float64
     domain_height::Float64

     function SwarmParameters(
          speed::Real,
          alignment_radius::Real,
          noise_strength::Real,
          domain_width::Real,
          domain_height::Real,
     )
          speed >= 0 || throw(ArgumentError("speed must be non-negative"))
          alignment_radius >= 0 || throw(ArgumentError("alignment_radius must be non-negative"))
          noise_strength >= 0 || throw(ArgumentError("noise_strength must be non-negative"))
          domain_width > 0 || throw(ArgumentError("domain_width must be positive"))
          domain_height > 0 || throw(ArgumentError("domain_height must be positive"))

          return new(
               Float64(speed),
               Float64(alignment_radius),
               Float64(noise_strength),
               Float64(domain_width),
               Float64(domain_height),
          )
     end
end
