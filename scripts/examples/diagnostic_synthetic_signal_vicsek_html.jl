using Random
using SoundSwarms

function run_example()
     rng = MersenneTwister(42)
     particle_count = 220
     domain_width = 100.0
     domain_height = 100.0
     base_params = SwarmParameters(0.8, 7.0, 0.35, domain_width, domain_height)
     mapping = FeatureParameterMapping(0.05, 2.2, 0.02, 1.1; speed_feature = :rms, noise_feature = :spectral_centroid)
     state = initialize_swarm(particle_count, base_params, rng)
     sample_frames = synthetic_sweep_sample_frames(520; sample_rate = 8000.0, window_size = 256, hop_size = 128)
     analysis = analyze_sample_frames(sample_frames; max_frequency = 3000.0, spectrum_bin_count = 56)
     run_frames = run_controlled_simulation(state, base_params, analysis.features, mapping, 1.0, rng)
     swarm_frames = [frame.swarm for frame in run_frames]

     output_path = joinpath("outputs", "diagnostic_synthetic_signal_vicsek.html")
     write_diagnostic_html_animation(
          output_path,
          swarm_frames,
          analysis.features,
          domain_width,
          domain_height;
          fps = 45,
          trail_alpha = 0.08,
          feature_trace_keys = (:rms, :spectral_centroid),
          spectrum_frames = analysis.spectra,
     )
     println("Wrote $(output_path)")
end

run_example()
