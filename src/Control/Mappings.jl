struct FeatureParameterMapping
     min_speed::Float64
     max_speed::Float64
     min_noise_strength::Float64
     max_noise_strength::Float64
     speed_feature::Symbol
     noise_feature::Symbol

     function FeatureParameterMapping(
          min_speed::Real,
          max_speed::Real,
          min_noise_strength::Real,
          max_noise_strength::Real;
          speed_feature::Symbol = :rms,
          noise_feature::Symbol = :high_band,
     )
          min_speed >= 0 || throw(ArgumentError("min_speed must be non-negative"))
          max_speed >= min_speed || throw(ArgumentError("max_speed must be at least min_speed"))
          min_noise_strength >= 0 || throw(ArgumentError("min_noise_strength must be non-negative"))
          max_noise_strength >= min_noise_strength || throw(ArgumentError("max_noise_strength must be at least min_noise_strength"))
          is_audio_feature(speed_feature) || throw(ArgumentError("speed_feature must name an audio feature"))
          is_audio_feature(noise_feature) || throw(ArgumentError("noise_feature must name an audio feature"))

          return new(
               Float64(min_speed),
               Float64(max_speed),
               Float64(min_noise_strength),
               Float64(max_noise_strength),
               speed_feature,
               noise_feature,
          )
     end
end

function map_features_to_parameters(
     base_params::SwarmParameters,
     frame::AudioFeatureFrame,
     mapping::FeatureParameterMapping,
     dt::Real,
)
     dt > 0 || throw(ArgumentError("dt must be positive"))

     max_allowed_speed = base_params.alignment_radius / Float64(dt)
     effective_max_speed = min(mapping.max_speed, max_allowed_speed)
     effective_min_speed = min(mapping.min_speed, effective_max_speed)
     speed_feature_value = audio_feature_value(frame, mapping.speed_feature)
     noise_feature_value = audio_feature_value(frame, mapping.noise_feature)

     return SwarmParameters(
          lerp(effective_min_speed, effective_max_speed, speed_feature_value),
          base_params.alignment_radius,
          lerp(mapping.min_noise_strength, mapping.max_noise_strength, noise_feature_value),
          base_params.domain_width,
          base_params.domain_height,
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

is_audio_feature(feature::Symbol) = feature in (
     :rms,
     :low_band,
     :mid_band,
     :high_band,
     :spectral_centroid,
     :onset_strength,
)

lerp(low::Float64, high::Float64, amount::Float64) = low + amount * (high - low)
