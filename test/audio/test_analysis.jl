using SoundSwarms

function test_audio_sample_frame_validation()
     frame = AudioSampleFrame(0.0, 8000.0, [0.0, 0.1, -0.1])

     @test frame.time == 0.0
     @test frame.sample_rate == 8000.0
     @test frame.samples == [0.0, 0.1, -0.1]
     @test_throws ArgumentError AudioSampleFrame(-0.1, 8000.0, [0.0])
     @test_throws ArgumentError AudioSampleFrame(0.0, 0.0, [0.0])
     @test_throws ArgumentError AudioSampleFrame(0.0, 8000.0, Float64[])
end

function test_synthetic_sweep_sample_frames()
     frames = synthetic_sweep_sample_frames(4; sample_rate = 8000.0, window_size = 32, hop_size = 16)

     @test length(frames) == 4
     @test all(length(frame.samples) == 32 for frame in frames)
     @test [frame.time for frame in frames] ≈ [0.0, 0.002, 0.004, 0.006]
end

function test_analyze_sample_frame_outputs_normalized_features_and_spectrum()
     samples = [0.5 * sin(2pi * 200.0 * (index - 1) / 8000.0) for index in 1:128]
     frame = AudioSampleFrame(0.0, 8000.0, samples)
     analysis = analyze_sample_frame(frame; max_frequency = 2000.0, spectrum_bin_count = 24)

     @test analysis.feature isa AudioFeatureFrame
     @test analysis.spectrum isa AudioSpectrumFrame
     @test length(analysis.spectrum.frequencies) == 24
     @test length(analysis.spectrum.amplitudes) == 24
     @test 0 <= analysis.feature.rms <= 1
     @test 0 <= analysis.feature.low_band <= 1
     @test 0 <= analysis.feature.spectral_centroid <= 1
     @test all(0 .<= analysis.spectrum.amplitudes .<= 1)
end

function test_analyze_sample_frames_pairing()
     frames = synthetic_sweep_sample_frames(3; sample_rate = 8000.0, window_size = 32, hop_size = 16)
     analysis = analyze_sample_frames(frames; max_frequency = 2000.0, spectrum_bin_count = 8)

     @test length(analysis.features) == 3
     @test length(analysis.spectra) == 3
     @test [frame.time for frame in analysis.features] == [frame.time for frame in frames]
     @test [frame.time for frame in analysis.spectra] == [frame.time for frame in frames]
end

@testset "Audio sample analysis" begin
     test_audio_sample_frame_validation()
     test_synthetic_sweep_sample_frames()
     test_analyze_sample_frame_outputs_normalized_features_and_spectrum()
     test_analyze_sample_frames_pairing()
end
