using SoundSwarms

function test_synthetic_feature_frame_is_normalized()
     frame = synthetic_feature_frame(1.25)

     @test frame.time == 1.25
     @test 0 <= frame.rms <= 1
     @test 0 <= frame.low_band <= 1
     @test 0 <= frame.mid_band <= 1
     @test 0 <= frame.high_band <= 1
     @test 0 <= frame.spectral_centroid <= 1
     @test 0 <= frame.onset_strength <= 1
end

function test_synthetic_feature_frames_are_deterministic()
     frames_a = synthetic_feature_frames(5; dt = 0.1)
     frames_b = synthetic_feature_frames(5; dt = 0.1)

     @test frames_a == frames_b
     @test [frame.time for frame in frames_a] ≈ [0.0, 0.1, 0.2, 0.3, 0.4]
end

function test_synthetic_feature_frames_validate_inputs()
     @test_throws ArgumentError synthetic_feature_frame(-0.1)
     @test_throws ArgumentError synthetic_feature_frames(0; dt = 0.1)
     @test_throws ArgumentError synthetic_feature_frames(5; dt = 0.0)
end

@testset "Synthetic audio features" begin
     test_synthetic_feature_frame_is_normalized()
     test_synthetic_feature_frames_are_deterministic()
     test_synthetic_feature_frames_validate_inputs()
end
