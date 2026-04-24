module Audio

include("Features.jl")
include("FeatureBuffer.jl")
include("Synthetic.jl")

export AudioFeatureBuffer, AudioFeatureFrame, buffer_capacity, latest_feature, push_feature!
export synthetic_feature_frame, synthetic_feature_frames

end
