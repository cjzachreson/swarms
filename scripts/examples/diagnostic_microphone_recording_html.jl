using PortAudio
using Random
using Serialization
using SoundSwarms

struct MicrophoneDiagnosticConfig
     mode::Symbol
     device_name_fragment::String
     sample_rate::Int
     window_size::Int
     duration_seconds::Float64
     recording_path::String
     output_path::String
     max_frequency::Float64
     spectrum_bin_count::Int
     onset_scale::Float64
     smoothing_alpha::Float64
     envelope_attack_alpha::Float64
     envelope_decay_alpha::Float64
     particle_count::Int
     domain_width::Float64
     domain_height::Float64
     fps::Float64
     trail_alpha::Float64
     mapping::FeatureParameterMapping
     base_params::SwarmParameters
end

function microphone_mode()
     mode_name = lowercase(get(ENV, "SOUNDSWARMS_MIC_MODE", "record"))
     mode_name == "record" && return :record
     mode_name == "replay" && return :replay

     throw(ArgumentError("SOUNDSWARMS_MIC_MODE must be record or replay"))
end

const MICROPHONE_DIAGNOSTIC_CONFIG = MicrophoneDiagnosticConfig(
     microphone_mode(),
     "C270 HD WEBCAM",
     48000,
     1024,
     5.0,
     joinpath("outputs", "recordings", "microphone_recording.jls"),
     joinpath("outputs", "diagnostic_microphone_recording.html"),
     5000.0,
     72,
     4.0,
     0.25,
     0.8,
     0.08,
     220,
     100.0,
     100.0,
     45.0,
     0.08,
     FeatureParameterMapping(0.02, 2.0, 0.0, 3.0; speed_feature = :rms, noise_feature = :onset_strength),
     SwarmParameters(0.6, 2.0, 0.12, 100.0, 100.0),
)

function run_example()
     rng = MersenneTwister(126)
     config = MICROPHONE_DIAGNOSTIC_CONFIG
     frame_count = ceil(Int, config.duration_seconds * config.sample_rate / config.window_size)

     sample_frames = microphone_sample_frames(config, frame_count)
     analysis = analyze_sample_frames_dsp(sample_frames; max_frequency = config.max_frequency, spectrum_bin_count = config.spectrum_bin_count, spectrum_normalization = :global)
     onset_frames = with_onset_strength(analysis.features, OnsetStrengthConfig(config.onset_scale))
     smoothed_frames = smooth_feature_frames(onset_frames, ExponentialSmoothingConfig(config.smoothing_alpha))
     envelope = envelope_feature_values(onset_frames, PeakDecayEnvelopeConfig(config.envelope_attack_alpha, config.envelope_decay_alpha); feature = :rms)
     control_frames = envelope_speed_control_frames(smoothed_frames, envelope)
     state = initialize_swarm(config.particle_count, config.base_params, rng)
     run_frames = run_controlled_simulation(state, config.base_params, control_frames, config.mapping, 1.0, rng)
     swarm_frames = [frame.swarm for frame in run_frames]
     parameter_frames = [frame.params for frame in run_frames]

     write_diagnostic_html_animation(
          config.output_path,
          swarm_frames,
          control_frames,
          config.domain_width,
          config.domain_height;
          fps = config.fps,
          trail_alpha = config.trail_alpha,
          feature_trace_keys = (:rms, :onset_strength),
          parameter_frames = parameter_frames,
          spectrum_frames = analysis.spectra,
     )
     println("Wrote $(config.output_path)")
end

function microphone_sample_frames(config::MicrophoneDiagnosticConfig, frame_count::Integer)
     if config.mode === :record
          input_device = preferred_input_device(config.device_name_fragment)
          cue_recording(input_device, config)
          sample_frames = record_microphone_sample_frames(input_device, frame_count; sample_rate = config.sample_rate, window_size = config.window_size)
          save_sample_frames(config.recording_path, sample_frames)
          return sample_frames
     elseif config.mode === :replay
          println("Replaying microphone recording from: $(config.recording_path)")
          return load_sample_frames(config.recording_path)
     end

     throw(ArgumentError("mode must be :record or :replay"))
end

function record_microphone_sample_frames(input_device, frame_count::Integer; sample_rate::Integer, window_size::Integer)
     frame_count > 0 || throw(ArgumentError("frame_count must be positive"))
     window_size > 0 || throw(ArgumentError("window_size must be positive"))

     stream = PortAudioStream(input_device, 1, 0; samplerate = sample_rate, frames_per_buffer = window_size)
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

function envelope_speed_control_frames(frames::AbstractVector{AudioFeatureFrame}, envelope::AbstractVector{<:Real})
     length(frames) == length(envelope) || throw(ArgumentError("frames and envelope must have the same length"))

     return [
          AudioFeatureFrame(
               frames[index].time,
               envelope[index],
               frames[index].low_band,
               frames[index].mid_band,
               frames[index].high_band,
               frames[index].spectral_centroid,
               frames[index].onset_strength,
          )
          for index in eachindex(frames)
     ]
end

function save_sample_frames(path::AbstractString, frames::AbstractVector{AudioSampleFrame})
     !isempty(frames) || throw(ArgumentError("frames must not be empty"))

     mkpath(dirname(path))
     open(path, "w") do io
          serialize(io, collect(frames))
     end
     println("Saved recording to $(path)")

     return path
end

function load_sample_frames(path::AbstractString)
     isfile(path) || throw(ArgumentError("recording file does not exist: $(path)"))

     frames = open(deserialize, path)
     frames isa Vector{AudioSampleFrame} || throw(ArgumentError("recording file does not contain AudioSampleFrame data: $(path)"))
     !isempty(frames) || throw(ArgumentError("recording file contains no frames: $(path)"))

     return frames
end

function preferred_input_device(name_fragment::AbstractString)
     input_devices = [device for device in devices() if device.input_bounds.max_channels > 0]

     for device in input_devices
          if occursin(name_fragment, device.name)
               return device
          end
     end

     available = join(["- $(device.name)" for device in input_devices], "\n")
     throw(ArgumentError("preferred input device containing \"$(name_fragment)\" was not found. Available input devices:\n$(available)"))
end

function cue_recording(input_device, config::MicrophoneDiagnosticConfig)
     println("Recording $(config.duration_seconds) seconds from: $(input_device.name)")
     println("Sample rate: $(config.sample_rate) Hz")
     println("Window size: $(config.window_size) samples")
     println("Recording save path: $(config.recording_path)")
     println("Output: $(config.output_path)")
     for count in 3:-1:1
          println("Starting in $(count)...")
          sleep(1)
     end
     println("Recording now.")
end

function mono_samples(buffer)
     return [Float64(buffer[index, 1]) for index in axes(buffer, 1)]
end

run_example()
