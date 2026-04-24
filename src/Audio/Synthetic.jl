function synthetic_feature_frame(time::Real)
     time >= 0 || throw(ArgumentError("time must be non-negative"))

     t = Float64(time)
     rms = normalized_wave(t, 0.12)
     low_band = normalized_wave(t, 0.045)
     mid_band = normalized_wave(t + 0.6, 0.075)
     high_band = normalized_wave(t + 1.2, 0.18)
     spectral_centroid = clamp(0.25 + 0.55 * high_band + 0.20 * mid_band, 0.0, 1.0)
     onset_strength = pulse_train(t, 0.35, 0.10)

     return AudioFeatureFrame(t, rms, low_band, mid_band, high_band, spectral_centroid, onset_strength)
end

function synthetic_feature_frames(count::Integer; dt::Real)
     count > 0 || throw(ArgumentError("count must be positive"))
     dt > 0 || throw(ArgumentError("dt must be positive"))

     return [synthetic_feature_frame((index - 1) * Float64(dt)) for index in 1:count]
end

normalized_wave(time::Float64, frequency::Float64) = 0.5 + 0.5 * sin(2pi * frequency * time)

function pulse_train(time::Float64, frequency::Float64, width::Float64)
     phase = mod(time * frequency, 1.0)
     distance_to_pulse = min(phase, 1.0 - phase)

     return exp(-(distance_to_pulse / width)^2)
end
