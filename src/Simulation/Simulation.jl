module Simulation

include("State.jl")
include("Parameters.jl")
include("Initialization.jl")
include("Vicsek.jl")

export SwarmParameters, SwarmState, initialize_swarm, step!

end
