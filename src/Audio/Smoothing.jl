abstract type FeatureSmoothingConfig end

struct ExponentialSmoothingConfig <: FeatureSmoothingConfig
     alpha::Float64

     function ExponentialSmoothingConfig(alpha::Real)
          isfinite(alpha) || throw(ArgumentError("alpha must be finite"))
          0 <= alpha <= 1 || throw(ArgumentError("alpha must be between 0 and 1"))

          return new(Float64(alpha))
     end
end

struct OnsetStrengthConfig
     scale::Float64

     function OnsetStrengthConfig(scale::Real = 1.0)
          isfinite(scale) || throw(ArgumentError("scale must be finite"))
          scale >= 0 || throw(ArgumentError("scale must be non-negative"))

          return new(Float64(scale))
     end
end

struct PeakDecayEnvelopeConfig
     attack_alpha::Float64
     decay_alpha::Float64

     function PeakDecayEnvelopeConfig(attack_alpha::Real, decay_alpha::Real)
          validate_alpha("attack_alpha", attack_alpha)
          validate_alpha("decay_alpha", decay_alpha)

          return new(Float64(attack_alpha), Float64(decay_alpha))
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

function with_onset_strength(frames::AbstractVector{AudioFeatureFrame}, config::OnsetStrengthConfig = OnsetStrengthConfig())
     !isempty(frames) || throw(ArgumentError("frames must not be empty"))

     onset_frames = AudioFeatureFrame[replace_onset_strength(first(frames), 0.0)]

     for index in 2:length(frames)
          previous = frames[index - 1]
          current = frames[index]
          onset_strength = clamp01(max(0.0, current.rms - previous.rms) * config.scale)
          push!(onset_frames, replace_onset_strength(current, onset_strength))
     end

     return onset_frames
end

function envelope_feature_values(
     frames::AbstractVector{AudioFeatureFrame},
     config::PeakDecayEnvelopeConfig;
     feature::Symbol = :rms,
)
     !isempty(frames) || throw(ArgumentError("frames must not be empty"))
     is_audio_feature_name(feature) || throw(ArgumentError("unsupported envelope feature: $(feature)"))

     envelope = Float64[audio_feature_value(frames[1], feature)]

     for index in 2:length(frames)
          current_value = audio_feature_value(frames[index], feature)
          previous_envelope = envelope[end]
          alpha = current_value >= previous_envelope ? config.attack_alpha : config.decay_alpha
          push!(envelope, smooth_value(previous_envelope, current_value, alpha))
     end

     return envelope
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

function replace_onset_strength(frame::AudioFeatureFrame, onset_strength::Float64)
     return AudioFeatureFrame(
          frame.time,
          frame.rms,
          frame.low_band,
          frame.mid_band,
          frame.high_band,
          frame.spectral_centroid,
          onset_strength,
     )
end

function audio_feature_value(frame::AudioFeatureFrame, feature::Symbol)
     feature === :rms && return frame.rms
     feature === :low_band && return frame.low_band
     feature === :mid_band && return frame.mid_band
     feature === :high_band && return frame.high_band
     feature === :spectral_centroid && return frame.spectral_centroid
     feature === :onset_strength && return frame.onset_strength

     throw(ArgumentError("unsupported audio feature: $(feature)"))
end

function is_audio_feature_name(feature::Symbol)
     return feature in (
          :rms,
          :low_band,
          :mid_band,
          :high_band,
          :spectral_centroid,
          :onset_strength,
     )
end

function validate_alpha(name::AbstractString, alpha::Real)
     isfinite(alpha) || throw(ArgumentError("$(name) must be finite"))
     0 <= alpha <= 1 || throw(ArgumentError("$(name) must be between 0 and 1"))

     return nothing
end

smooth_value(previous::Float64, current::Float64, alpha::Float64) = alpha * current + (1 - alpha) * previous
