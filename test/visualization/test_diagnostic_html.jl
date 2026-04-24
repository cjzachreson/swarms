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

@testset "Diagnostic HTML writer" begin
     test_diagnostic_writer_rejects_mismatched_frame_counts()
     test_diagnostic_writer_creates_file()
end
