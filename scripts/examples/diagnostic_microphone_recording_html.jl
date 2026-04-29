using PortAudio
using Random
using SoundSwarms

function run_example()
     rng = MersenneTwister(126)
     sample_rate = 44100
     window_size = 1024
     duration_seconds = 5.0
     frame_count = ceil(Int, duration_seconds * sample_rate / window_size)
     domain_width = 100.0
     domain_height = 100.0
     base_params = SwarmParameters(0.6, 7.0, 0.12, domain_width, domain_height)
     mapping = FeatureParameterMapping(0.05, 1.6, 0.01, 1.4; speed_feature = :rms, noise_feature = :onset_strength)

     println("Recording $(duration_seconds) seconds from default input at $(sample_rate) Hz...")
     sample_frames = record_microphone_sample_frames(frame_count; sample_rate = sample_rate, window_size = window_size)
     analysis = analyze_sample_frames_dsp(sample_frames; max_frequency = 5000.0, spectrum_bin_count = 72, spectrum_normalization = :global)
     onset_frames = with_onset_strength(analysis.features, OnsetStrengthConfig(4.0))
     smoothed_frames = smooth_feature_frames(onset_frames, ExponentialSmoothingConfig(0.25))
     envelope = envelope_feature_values(onset_frames, PeakDecayEnvelopeConfig(0.8, 0.08); feature = :rms)
     state = initialize_swarm(220, base_params, rng)
     run_frames = run_controlled_simulation(state, base_params, smoothed_frames, mapping, 1.0, rng)
     swarm_frames = [frame.swarm for frame in run_frames]
     parameter_frames = [frame.params for frame in run_frames]

     output_path = joinpath("outputs", "diagnostic_microphone_recording.html")
     write_diagnostic_html_animation(
          output_path,
          swarm_frames,
          smoothed_frames,
          domain_width,
          domain_height;
          fps = 45,
          trail_alpha = 0.08,
          feature_trace_keys = (:rms, :onset_strength),
          extra_trace_series = (; rms_envelope = envelope),
          parameter_frames = parameter_frames,
          spectrum_frames = analysis.spectra,
     )
     println("Wrote $(output_path)")
end

function record_microphone_sample_frames(frame_count::Integer; sample_rate::Integer, window_size::Integer)
     frame_count > 0 || throw(ArgumentError("frame_count must be positive"))
     window_size > 0 || throw(ArgumentError("window_size must be positive"))

     stream = PortAudioStream(1, 0; samplerate = sample_rate, frames_per_buffer = window_size)
     frames = AudioSampleFrame[]

     try
          for frame_index in 1:frame_count
               buffer = read(stream, window_size)
               samples = mono_samples(buffer)
               time = (frame_index - 1) * window_size / Float64(sample_rate)
               push!(frames, AudioSampleFrame(time, sample_rate, samples))
          end
     finally
          close(stream)
     end

     return frames
end

function mono_samples(buffer)
     return [Float64(buffer[index, 1]) for index in axes(buffer, 1)]
end

run_example()
