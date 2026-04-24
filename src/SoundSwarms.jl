module SoundSwarms

include("Simulation/Simulation.jl")
include("Visualization/Visualization.jl")

using .Simulation
using .Visualization

export SwarmParameters, SwarmState, step!
export SwarmFrame, write_html_animation

end
