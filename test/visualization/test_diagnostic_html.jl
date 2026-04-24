using SoundSwarms

function test_diagnostic_writer_rejects_mismatched_frame_counts()
     swarm_frames = [SwarmFrame([0.0; 0.0;;])]
     audio_frames = synthetic_feature_frames(2; dt = 0.1)

     @test_throws ArgumentError write_diagnostic_html_animation(
          tempname() * ".html",
          swarm_frames,
          audio_frames,
          10.0,
          10.0,
     )
end

function test_diagnostic_writer_creates_file()
     path = tempname() * ".html"
     swarm_frames = [SwarmFrame([0.0; 0.0;;]), SwarmFrame([1.0; 1.0;;])]
     audio_frames = synthetic_feature_frames(2; dt = 0.1)

     write_diagnostic_html_animation(path, swarm_frames, audio_frames, 10.0, 10.0)

     @test isfile(path)
     @test occursin("SoundSwarms Diagnostic Preview", read(path, String))
end

function test_diagnostic_writer_filters_feature_traces()
     path = tempname() * ".html"
     swarm_frames = [SwarmFrame([0.0; 0.0;;]), SwarmFrame([1.0; 1.0;;])]
     audio_frames = synthetic_feature_frames(2; dt = 0.1)

     write_diagnostic_html_animation(
          path,
          swarm_frames,
          audio_frames,
          10.0,
          10.0;
          feature_trace_keys = (:rms, :high_band),
     )

     html = read(path, String)
     @test occursin("const traceKeys = [\"rms\",\"high_band\"]", html)
     @test_throws ArgumentError write_diagnostic_html_animation(
          tempname() * ".html",
          swarm_frames,
          audio_frames,
          10.0,
          10.0;
          feature_trace_keys = (:not_a_feature,),
     )
end

function test_diagnostic_writer_accepts_spectrum_frames()
     path = tempname() * ".html"
     swarm_frames = [SwarmFrame([0.0; 0.0;;]), SwarmFrame([1.0; 1.0;;])]
     audio_frames = synthetic_feature_frames(2; dt = 0.1)
     spectrum_frames = [
          AudioSpectrumFrame(0.0, [100.0, 200.0], [0.2, 0.8]),
          AudioSpectrumFrame(0.1, [100.0, 200.0], [0.7, 0.1]),
     ]

     write_diagnostic_html_animation(
          path,
          swarm_frames,
          audio_frames,
          10.0,
          10.0;
          spectrum_frames = spectrum_frames,
     )

     html = read(path, String)
     @test occursin("const hasSpectrum = true", html)
     @test occursin("spectrumFrames", html)
     @test_throws ArgumentError write_diagnostic_html_animation(
          tempname() * ".html",
          swarm_frames,
          audio_frames,
          10.0,
          10.0;
          spectrum_frames = spectrum_frames[1:1],
     )
end

@testset "Diagnostic HTML writer" begin
     test_diagnostic_writer_rejects_mismatched_frame_counts()
     test_diagnostic_writer_creates_file()
     test_diagnostic_writer_filters_feature_traces()
     test_diagnostic_writer_accepts_spectrum_frames()
end
