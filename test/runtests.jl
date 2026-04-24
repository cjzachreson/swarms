using Test

@testset "SoundSwarms.jl" begin
     include("audio/test_feature_buffer.jl")
     include("simulation/test_initialization.jl")
     include("simulation/test_vicsek.jl")
end
