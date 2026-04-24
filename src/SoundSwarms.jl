module SoundSwarms

include("Simulation/Simulation.jl")
include("Audio/Audio.jl")
include("Visualization/Visualization.jl")

using .Simulation
using .Audio
using .Visualization

export SwarmParameters, SwarmState, initialize_swarm, step!
export AudioFeatureBuffer, AudioFeatureFrame, buffer_capacity, latest_feature, push_feature!
export synthetic_feature_frame, synthetic_feature_frames
export SwarmFrame, write_diagnostic_html_animation, write_html_animation

end
