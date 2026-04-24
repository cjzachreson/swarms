struct AudioSampleFrame
     time::Float64
     sample_rate::Float64
     samples::Vector{Float64}

     function AudioSampleFrame(time::Real, sample_rate::Real, samples::AbstractVector{<:Real})
          time >= 0 || throw(ArgumentError("time must be non-negative"))
          sample_rate > 0 || throw(ArgumentError("sample_rate must be positive"))
          !isempty(samples) || throw(ArgumentError("samples must not be empty"))
          all(isfinite, samples) || throw(ArgumentError("samples must be finite"))

          return new(Float64(time), Float64(sample_rate), Vector{Float64}(samples))
     end
end

struct AudioSpectrumFrame
     time::Float64
     frequencies::Vector{Float64}
     amplitudes::Vector{Float64}

     function AudioSpectrumFrame(time::Real, frequencies::AbstractVector{<:Real}, amplitudes::AbstractVector{<:Real})
          time >= 0 || throw(ArgumentError("time must be non-negative"))
          length(frequencies) == length(amplitudes) || throw(ArgumentError("frequencies and amplitudes must have the same length"))
          !isempty(frequencies) || throw(ArgumentError("frequencies must not be empty"))
          all(isfinite, frequencies) || throw(ArgumentError("frequencies must be finite"))
          all(isfinite, amplitudes) || throw(ArgumentError("amplitudes must be finite"))
          all(frequency -> frequency >= 0, frequencies) || throw(ArgumentError("frequencies must be non-negative"))
          all(amplitude -> 0 <= amplitude <= 1, amplitudes) || throw(ArgumentError("amplitudes must be between 0 and 1"))

          return new(Float64(time), Vector{Float64}(frequencies), Vector{Float64}(amplitudes))
     end
end
