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

@testset "Audio feature smoothing" begin
     test_exponential_smoothing_config_validation()
     test_smooth_feature_frames_exponential_recurrence()
     test_smooth_feature_frames_smooths_all_feature_fields()
     test_smooth_feature_frames_preserves_bounds_and_input()
     test_smooth_feature_frames_validates_inputs()
end
