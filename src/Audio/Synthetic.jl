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

function synthetic_sweep_sample_frames(
     frame_count::Integer;
     sample_rate::Real = 8000.0,
     window_size::Integer = 256,
     hop_size::Integer = 128,
)
     frame_count > 0 || throw(ArgumentError("frame_count must be positive"))
     sample_rate > 0 || throw(ArgumentError("sample_rate must be positive"))
     window_size > 0 || throw(ArgumentError("window_size must be positive"))
     hop_size > 0 || throw(ArgumentError("hop_size must be positive"))

     total_samples = (frame_count - 1) * hop_size + window_size
     duration = total_samples / Float64(sample_rate)
     signal = Vector{Float64}(undef, total_samples)
     phase = 0.0

     for sample_index in 1:total_samples
          time = (sample_index - 1) / Float64(sample_rate)
          progress = duration == 0 ? 0.0 : time / duration
          frequency = sweep_frequency(progress)
          amplitude = sweep_amplitude(progress)
          phase += 2pi * frequency / Float64(sample_rate)
          signal[sample_index] = amplitude * sin(phase)
     end

     frames = AudioSampleFrame[]
     for frame_index in 1:frame_count
          start_index = (frame_index - 1) * hop_size + 1
          stop_index = start_index + window_size - 1
          time = (start_index - 1) / Float64(sample_rate)
          push!(frames, AudioSampleFrame(time, sample_rate, signal[start_index:stop_index]))
     end

     return frames
end

normalized_wave(time::Float64, frequency::Float64) = 0.5 + 0.5 * sin(2pi * frequency * time)

function pulse_train(time::Float64, frequency::Float64, width::Float64)
     phase = mod(time * frequency, 1.0)
     distance_to_pulse = min(phase, 1.0 - phase)

     return exp(-(distance_to_pulse / width)^2)
end

function sweep_frequency(progress::Float64)
     clipped_progress = clamp(progress, 0.0, 1.0)

     if clipped_progress <= 0.5
          return lerp_scalar(120.0, 1800.0, clipped_progress / 0.5)
     end

     return lerp_scalar(1800.0, 180.0, (clipped_progress - 0.5) / 0.5)
end

function sweep_amplitude(progress::Float64)
     clipped_progress = clamp(progress, 0.0, 1.0)

     if clipped_progress <= 0.5
          return lerp_scalar(0.75, 0.35, clipped_progress / 0.5)
     end

     return lerp_scalar(0.35, 0.0, (clipped_progress - 0.5) / 0.5)
end

lerp_scalar(low::Float64, high::Float64, amount::Float64) = low + amount * (high - low)
