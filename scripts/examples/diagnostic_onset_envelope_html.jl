using SoundSwarms

function run_example()
     frame_count = 180
     audio_frames = synthetic_pulse_feature_frames(frame_count; dt = 1 / 30)
     onset_frames = with_onset_strength(audio_frames, OnsetStrengthConfig(2.5))
     envelope = envelope_feature_values(onset_frames, PeakDecayEnvelopeConfig(0.8, 0.08); feature = :rms)
     swarm_frames = static_swarm_frames(frame_count)

     output_path = joinpath("outputs", "diagnostic_onset_envelope.html")
     write_diagnostic_html_animation(
          output_path,
          swarm_frames,
          onset_frames,
          10.0,
          10.0;
          swarm_canvas_height = 120,
          trace_canvas_height = 320,
          fps = 30,
          trail_alpha = 1.0,
          feature_trace_keys = (:rms, :onset_strength),
          extra_trace_series = (; rms_envelope = envelope),
     )
     println("Wrote $(output_path)")
end

function synthetic_pulse_feature_frames(count::Integer; dt::Real)
     return [
          AudioFeatureFrame(
               (index - 1) * Float64(dt),
               pulse_rms(index),
               0.0,
               0.0,
               0.0,
               0.0,
               0.0,
          )
          for index in 1:count
     ]
end

function pulse_rms(index::Integer)
     value = 0.08

     for center in (25, 58, 92, 128, 154)
          distance = abs(index - center)
          if distance <= 8
               value = max(value, 1.0 - distance / 8)
          end
     end

     return value
end

function static_swarm_frames(count::Integer)
     positions = [
          2.0 4.0 6.0 8.0;
          5.0 5.0 5.0 5.0
     ]

     return [SwarmFrame(positions) for _ in 1:count]
end

run_example()
