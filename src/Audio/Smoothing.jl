abstract type FeatureSmoothingConfig end

struct ExponentialSmoothingConfig <: FeatureSmoothingConfig
     alpha::Float64

     function ExponentialSmoothingConfig(alpha::Real)
          isfinite(alpha) || throw(ArgumentError("alpha must be finite"))
          0 <= alpha <= 1 || throw(ArgumentError("alpha must be between 0 and 1"))

          return new(Float64(alpha))
     end
end

function smooth_feature_frames(frames::AbstractVector{AudioFeatureFrame}, config::ExponentialSmoothingConfig)
     !isempty(frames) || throw(ArgumentError("frames must not be empty"))

     smoothed_frames = AudioFeatureFrame[first(frames)]

     for index in 2:length(frames)
          previous = smoothed_frames[end]
          current = frames[index]
          push!(smoothed_frames, smooth_feature_frame(previous, current, config.alpha))
     end

     return smoothed_frames
end

function smooth_feature_frame(previous::AudioFeatureFrame, current::AudioFeatureFrame, alpha::Float64)
     return AudioFeatureFrame(
          current.time,
          smooth_value(previous.rms, current.rms, alpha),
          smooth_value(previous.low_band, current.low_band, alpha),
          smooth_value(previous.mid_band, current.mid_band, alpha),
          smooth_value(previous.high_band, current.high_band, alpha),
          smooth_value(previous.spectral_centroid, current.spectral_centroid, alpha),
          smooth_value(previous.onset_strength, current.onset_strength, alpha),
     )
end

smooth_value(previous::Float64, current::Float64, alpha::Float64) = alpha * current + (1 - alpha) * previous
