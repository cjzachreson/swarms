using Test

@testset "SoundSwarms.jl" begin
     include("audio/test_feature_buffer.jl")
     include("audio/test_synthetic.jl")
     include("audio/test_analysis.jl")
     include("control/test_mappings.jl")
     include("runtime/test_controlled_run.jl")
     include("simulation/test_initialization.jl")
     include("simulation/test_vicsek.jl")
     include("visualization/test_diagnostic_html.jl")
end
