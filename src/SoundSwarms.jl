module SoundSwarms

include("Simulation/Simulation.jl")
include("Audio/Audio.jl")
include("Visualization/Visualization.jl")

using .Simulation
using .Audio
using .Visualization

export SwarmParameters, SwarmState, initialize_swarm, step!
export AudioFeatureBuffer, AudioFeatureFrame, buffer_capacity, latest_feature, push_feature!
export SwarmFrame, write_html_animation

end
