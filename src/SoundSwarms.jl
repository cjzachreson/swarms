module SoundSwarms

include("Simulation/Simulation.jl")
include("Audio/Audio.jl")
include("Control/Control.jl")
include("Visualization/Visualization.jl")
include("Runtime/Runtime.jl")

using .Simulation
using .Audio
using .Control
using .Visualization
using .Runtime

export SwarmParameters, SwarmState, initialize_swarm, step!
export AudioFeatureBuffer, AudioFeatureFrame, buffer_capacity, latest_feature, push_feature!
export synthetic_feature_frame, synthetic_feature_frames
export FeatureParameterMapping, map_features_to_parameters
export SwarmFrame, write_diagnostic_html_animation, write_html_animation
export ControlledRunFrame, run_controlled_simulation

end
