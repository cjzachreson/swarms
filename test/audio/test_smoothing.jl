using SoundSwarms

smoothing_frame(time; rms, low = rms, mid = rms, high = rms, centroid = rms, onset = rms) = AudioFeatureFrame(time, rms, low, mid, high, centroid, onset)

function test_exponential_smoothing_config_validation()
     config = ExponentialSmoothingConfig(0.25)

     @test config.alpha == 0.25
     @test_throws ArgumentError ExponentialSmoothingConfig(-0.1)
     @test_throws ArgumentError ExponentialSmoothingConfig(1.1)
     @test_throws ArgumentError ExponentialSmoothingConfig(Inf)
end

function test_smooth_feature_frames_exponential_recurrence()
     frames = [
          smoothing_frame(0.0; rms = 0.0),
          smoothing_frame(0.1; rms = 1.0),
          smoothing_frame(0.2; rms = 1.0),
     ]

     smoothed = smooth_feature_frames(frames, ExponentialSmoothingConfig(0.25))

     @test length(smoothed) == 3
     @test smoothed[1] === frames[1]
     @test smoothed[2].rms ≈ 0.25
     @test smoothed[3].rms ≈ 0.4375
     @test [frame.time for frame in smoothed] == [0.0, 0.1, 0.2]
end

function test_smooth_feature_frames_smooths_all_feature_fields()
     frames = [
          smoothing_frame(0.0; rms = 0.0, low = 0.1, mid = 0.2, high = 0.3, centroid = 0.4, onset = 0.5),
          smoothing_frame(0.1; rms = 1.0, low = 0.9, mid = 0.8, high = 0.7, centroid = 0.6, onset = 0.5),
     ]

     smoothed = smooth_feature_frames(frames, ExponentialSmoothingConfig(0.5))

     @test smoothed[2].rms ≈ 0.5
     @test smoothed[2].low_band ≈ 0.5
     @test smoothed[2].mid_band ≈ 0.5
     @test smoothed[2].high_band ≈ 0.5
     @test smoothed[2].spectral_centroid ≈ 0.5
     @test smoothed[2].onset_strength ≈ 0.5
end

function test_smooth_feature_frames_preserves_bounds_and_input()
     frames = [
          smoothing_frame(0.0; rms = 0.0),
          smoothing_frame(0.1; rms = 1.0),
     ]
     original_second = frames[2]

     smoothed = smooth_feature_frames(frames, ExponentialSmoothingConfig(0.4))

     @test frames[2] === original_second
     @test all(0 <= frame.rms <= 1 for frame in smoothed)
     @test smoothed[2] !== frames[2]
end

function test_smooth_feature_frames_validates_inputs()
     @test_throws ArgumentError smooth_feature_frames(AudioFeatureFrame[], ExponentialSmoothingConfig(0.5))
end

function test_onset_strength_config_validation()
     config = OnsetStrengthConfig(2.0)

     @test config.scale == 2.0
     @test OnsetStrengthConfig().scale == 1.0
     @test_throws ArgumentError OnsetStrengthConfig(-0.1)
     @test_throws ArgumentError OnsetStrengthConfig(Inf)
end

function test_with_onset_strength_uses_positive_rms_delta()
     frames = [
          smoothing_frame(0.0; rms = 0.2, onset = 0.7),
          smoothing_frame(0.1; rms = 0.5, onset = 0.7),
          smoothing_frame(0.2; rms = 0.4, onset = 0.7),
          smoothing_frame(0.3; rms = 0.9, onset = 0.7),
     ]

     onset_frames = with_onset_strength(frames, OnsetStrengthConfig(2.0))

     @test [frame.onset_strength for frame in onset_frames] ≈ [0.0, 0.6, 0.0, 1.0]
     @test [frame.time for frame in onset_frames] == [frame.time for frame in frames]
     @test onset_frames[2].rms == frames[2].rms
     @test onset_frames[2].spectral_centroid == frames[2].spectral_centroid
     @test onset_frames[2] !== frames[2]
end

function test_with_onset_strength_validates_inputs()
     @test_throws ArgumentError with_onset_strength(AudioFeatureFrame[])
end

function test_peak_decay_envelope_config_validation()
     config = PeakDecayEnvelopeConfig(0.8, 0.2)

     @test config.attack_alpha == 0.8
     @test config.decay_alpha == 0.2
     @test_throws ArgumentError PeakDecayEnvelopeConfig(-0.1, 0.2)
     @test_throws ArgumentError PeakDecayEnvelopeConfig(0.8, 1.1)
     @test_throws ArgumentError PeakDecayEnvelopeConfig(Inf, 0.2)
end

function test_envelope_feature_values_rises_and_decays_predictably()
     frames = [
          smoothing_frame(0.0; rms = 0.2),
          smoothing_frame(0.1; rms = 1.0),
          smoothing_frame(0.2; rms = 0.0),
          smoothing_frame(0.3; rms = 0.0),
     ]

     envelope = envelope_feature_values(frames, PeakDecayEnvelopeConfig(0.5, 0.25))

     @test envelope ≈ [0.2, 0.6, 0.45, 0.3375]
end

function test_envelope_feature_values_supports_feature_selection()
     frames = [
          smoothing_frame(0.0; rms = 0.0, high = 0.2),
          smoothing_frame(0.1; rms = 0.0, high = 1.0),
     ]

     envelope = envelope_feature_values(frames, PeakDecayEnvelopeConfig(0.5, 0.25); feature = :high_band)

     @test envelope ≈ [0.2, 0.6]
     @test_throws ArgumentError envelope_feature_values(frames, PeakDecayEnvelopeConfig(0.5, 0.25); feature = :not_a_feature)
     @test_throws ArgumentError envelope_feature_values(AudioFeatureFrame[], PeakDecayEnvelopeConfig(0.5, 0.25))
end

@testset "Audio feature smoothing" begin
     test_exponential_smoothing_config_validation()
     test_smooth_feature_frames_exponential_recurrence()
     test_smooth_feature_frames_smooths_all_feature_fields()
     test_smooth_feature_frames_preserves_bounds_and_input()
     test_smooth_feature_frames_validates_inputs()
     test_onset_strength_config_validation()
     test_with_onset_strength_uses_positive_rms_delta()
     test_with_onset_strength_validates_inputs()
     test_peak_decay_envelope_config_validation()
     test_envelope_feature_values_rises_and_decays_predictably()
     test_envelope_feature_values_supports_feature_selection()
end
