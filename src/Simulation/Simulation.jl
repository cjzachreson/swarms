module Simulation

include("State.jl")
include("Parameters.jl")
include("Vicsek.jl")

export SwarmParameters, SwarmState, step!

end
