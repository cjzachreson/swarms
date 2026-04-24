using Test

@testset "SoundSwarms.jl" begin
     include("simulation/test_initialization.jl")
     include("simulation/test_vicsek.jl")
end
