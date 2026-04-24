module Runtime

using Random: AbstractRNG

using ..Audio: AudioFeatureFrame
using ..Control: FeatureParameterMapping, map_features_to_parameters
using ..Simulation: SwarmParameters, SwarmState, step!
using ..Visualization: SwarmFrame

include("ControlledRun.jl")

export ControlledRunFrame, run_controlled_simulation

end
