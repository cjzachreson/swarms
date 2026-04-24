module Audio

include("Features.jl")
include("FeatureBuffer.jl")

export AudioFeatureBuffer, AudioFeatureFrame, buffer_capacity, latest_feature, push_feature!

end
