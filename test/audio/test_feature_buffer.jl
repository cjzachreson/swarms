using SoundSwarms

feature_frame(time; rms = 0.1) = AudioFeatureFrame(time, rms, 0.2, 0.3, 0.4, 0.5, 0.6)

function test_audio_feature_frame_validation()
     frame = feature_frame(0.0)

     @test frame.time == 0.0
     @test frame.rms == 0.1
     @test_throws ArgumentError AudioFeatureFrame(-0.1, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6)
     @test_throws ArgumentError AudioFeatureFrame(0.0, 1.1, 0.2, 0.3, 0.4, 0.5, 0.6)
end

function test_audio_feature_buffer_push_and_latest()
     buffer = AudioFeatureBuffer(3)
     first_frame = feature_frame(0.0; rms = 0.1)
     second_frame = feature_frame(0.1; rms = 0.2)

     push_feature!(buffer, first_frame)
     push_feature!(buffer, second_frame)

     @test buffer_capacity(buffer) == 3
     @test length(buffer) == 2
     @test latest_feature(buffer) === second_frame
end

function test_audio_feature_buffer_rollover_order()
     buffer = AudioFeatureBuffer(3)

     for index in 1:5
          push_feature!(buffer, feature_frame(index / 10; rms = index / 10))
     end

     frames = collect(buffer)

     @test length(buffer) == 3
     @test [frame.time for frame in frames] == [0.3, 0.4, 0.5]
     @test latest_feature(buffer).time == 0.5
end

function test_audio_feature_buffer_rejects_invalid_capacity()
     @test_throws ArgumentError AudioFeatureBuffer(0)
end

@testset "Audio feature buffer" begin
     test_audio_feature_frame_validation()
     test_audio_feature_buffer_push_and_latest()
     test_audio_feature_buffer_rollover_order()
     test_audio_feature_buffer_rejects_invalid_capacity()
end
