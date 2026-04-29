using DSP

function analyze_sample_frame(
     frame::AudioSampleFrame;
     max_frequency::Real = min(4000.0, frame.sample_rate / 2),
     spectrum_bin_count::Integer = 48,
)
     max_frequency > 0 || throw(ArgumentError("max_frequency must be positive"))
     max_frequency <= frame.sample_rate / 2 || throw(ArgumentError("max_frequency must not exceed Nyquist frequency"))
     spectrum_bin_count > 0 || throw(ArgumentError("spectrum_bin_count must be positive"))

     frequencies = collect(range(20.0, Float64(max_frequency); length = spectrum_bin_count))
     amplitudes = [dft_amplitude(frame.samples, frame.sample_rate, frequency) for frequency in frequencies]
     normalized_amplitudes = clamp01.(amplitudes)
     rms = clamp01(sqrt(sum(abs2, frame.samples) / length(frame.samples)))
     centroid = spectral_centroid(frequencies, normalized_amplitudes, Float64(max_frequency))
     low_band = band_level(frequencies, normalized_amplitudes, 20.0, 400.0)
     mid_band = band_level(frequencies, normalized_amplitudes, 400.0, 1500.0)
     high_band = band_level(frequencies, normalized_amplitudes, 1500.0, Float64(max_frequency))
     feature = AudioFeatureFrame(frame.time, rms, low_band, mid_band, high_band, centroid, 0.0)
     spectrum = AudioSpectrumFrame(frame.time, frequencies, normalized_amplitudes)

     return (feature = feature, spectrum = spectrum)
end

function analyze_sample_frames(frames::AbstractVector{AudioSampleFrame}; kwargs...)
     analyses = [analyze_sample_frame(frame; kwargs...) for frame in frames]

     return (
          features = [analysis.feature for analysis in analyses],
          spectra = [analysis.spectrum for analysis in analyses],
     )
end

function analyze_sample_frame_dsp(
     frame::AudioSampleFrame;
     max_frequency::Real = min(4000.0, frame.sample_rate / 2),
     spectrum_bin_count::Integer = 48,
)
     max_frequency > 0 || throw(ArgumentError("max_frequency must be positive"))
     max_frequency <= frame.sample_rate / 2 || throw(ArgumentError("max_frequency must not exceed Nyquist frequency"))
     spectrum_bin_count > 0 || throw(ArgumentError("spectrum_bin_count must be positive"))

     periodogram_frame = periodogram(frame.samples; fs = frame.sample_rate, window = hanning(length(frame.samples)))
     raw_frequencies = collect(freq(periodogram_frame))
     raw_amplitudes = sqrt.(max.(collect(power(periodogram_frame)), 0.0))
     frequencies = collect(range(20.0, Float64(max_frequency); length = spectrum_bin_count))
     amplitudes = [interpolated_amplitude(raw_frequencies, raw_amplitudes, frequency) for frequency in frequencies]
     normalized_amplitudes = normalize_amplitudes(amplitudes)
     rms = clamp01(sqrt(sum(abs2, frame.samples) / length(frame.samples)))
     centroid = spectral_centroid(frequencies, normalized_amplitudes, Float64(max_frequency))
     low_band = band_level(frequencies, normalized_amplitudes, 20.0, 400.0)
     mid_band = band_level(frequencies, normalized_amplitudes, 400.0, 1500.0)
     high_band = band_level(frequencies, normalized_amplitudes, 1500.0, Float64(max_frequency))
     feature = AudioFeatureFrame(frame.time, rms, low_band, mid_band, high_band, centroid, 0.0)
     spectrum = AudioSpectrumFrame(frame.time, frequencies, normalized_amplitudes)

     return (feature = feature, spectrum = spectrum)
end

function analyze_sample_frames_dsp(frames::AbstractVector{AudioSampleFrame}; kwargs...)
     analyses = [analyze_sample_frame_dsp(frame; kwargs...) for frame in frames]

     return (
          features = [analysis.feature for analysis in analyses],
          spectra = [analysis.spectrum for analysis in analyses],
     )
end

function dft_amplitude(samples::Vector{Float64}, sample_rate::Float64, frequency::Float64)
     real_sum = 0.0
     imag_sum = 0.0

     for sample_index in eachindex(samples)
          phase = 2pi * frequency * (sample_index - 1) / sample_rate
          real_sum += samples[sample_index] * cos(phase)
          imag_sum -= samples[sample_index] * sin(phase)
     end

     return 2 * sqrt(real_sum^2 + imag_sum^2) / length(samples)
end

function band_level(frequencies::Vector{Float64}, amplitudes::Vector{Float64}, low::Float64, high::Float64)
     selected = [amplitudes[index] for index in eachindex(frequencies) if low <= frequencies[index] < high]
     isempty(selected) && return 0.0

     return clamp01(maximum(selected))
end

function spectral_centroid(frequencies::Vector{Float64}, amplitudes::Vector{Float64}, max_frequency::Float64)
     amplitude_sum = sum(amplitudes)
     amplitude_sum > 0 || return 0.0

     return clamp01(sum(frequencies .* amplitudes) / amplitude_sum / max_frequency)
end

function interpolated_amplitude(frequencies::Vector{Float64}, amplitudes::Vector{Float64}, target_frequency::Float64)
     target_frequency <= first(frequencies) && return first(amplitudes)

     for index in 2:length(frequencies)
          if target_frequency <= frequencies[index]
               low_frequency = frequencies[index - 1]
               high_frequency = frequencies[index]
               high_frequency > low_frequency || return amplitudes[index]

               amount = (target_frequency - low_frequency) / (high_frequency - low_frequency)
               return amplitudes[index - 1] + amount * (amplitudes[index] - amplitudes[index - 1])
          end
     end

     return last(amplitudes)
end

function normalize_amplitudes(amplitudes::Vector{Float64})
     maximum_amplitude = maximum(amplitudes)
     maximum_amplitude > 0 || return zeros(Float64, length(amplitudes))

     return clamp01.(amplitudes ./ maximum_amplitude)
end

clamp01(value::Real) = clamp(Float64(value), 0.0, 1.0)
