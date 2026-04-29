using Random
using SoundSwarms

function run_example()
     rng = MersenneTwister(84)
     frame_count = 220
     particle_count = 220
     domain_width = 100.0
     domain_height = 100.0
     base_params = SwarmParameters(0.6, 7.0, 0.12, domain_width, domain_height)
     mapping = FeatureParameterMapping(0.05, 1.4, 0.01, 1.6; speed_feature = :rms, noise_feature = :onset_strength)
     sample_frames = synthetic_pulse_sample_frames(frame_count; sample_rate = 8000.0, window_size = 256, hop_size = 128)
     analysis = analyze_sample_frames_dsp(sample_frames; max_frequency = 3000.0, spectrum_bin_count = 56, spectrum_normalization = :global)
     onset_frames = with_onset_strength(analysis.features, OnsetStrengthConfig(3.0))
     envelope = envelope_feature_values(onset_frames, PeakDecayEnvelopeConfig(0.8, 0.08); feature = :rms)
     state = initialize_swarm(particle_count, base_params, rng)
     run_frames = run_controlled_simulation(state, base_params, onset_frames, mapping, 1.0, rng)
     swarm_frames = [frame.swarm for frame in run_frames]
     parameter_frames = [frame.params for frame in run_frames]

     output_path = joinpath("outputs", "diagnostic_onset_controlled_vicsek.html")
     write_diagnostic_html_animation(
          output_path,
          swarm_frames,
          onset_frames,
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

function synthetic_pulse_sample_frames(count::Integer; sample_rate::Real, window_size::Integer, hop_size::Integer)
     return [
          AudioSampleFrame(
               (index - 1) * hop_size / Float64(sample_rate),
               sample_rate,
               pulse_samples(index, sample_rate, window_size),
          )
          for index in 1:count
     ]
end

function pulse_samples(frame_index::Integer, sample_rate::Real, window_size::Integer)
     amplitude = pulse_amplitude(frame_index)
     frequency = pulse_frequency(frame_index)

     return [
          amplitude * sin(2pi * frequency * (sample_index - 1) / sample_rate)
          for sample_index in 1:window_size
     ]
end

function pulse_amplitude(index::Integer)
     return 0.08 + 0.92 * pulse_rms(index)
end

function pulse_frequency(index::Integer)
     return index < 110 ? 260.0 : 980.0
end

function pulse_rms(index::Integer)
     value = 0.0

     for center in (30, 64, 104, 142, 178, 202)
          distance = abs(index - center)
          if distance <= 9
               value = max(value, 1.0 - distance / 9)
          end
     end

     return value
end

run_example()
