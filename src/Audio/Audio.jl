module Audio

include("Features.jl")
include("Samples.jl")
include("FeatureBuffer.jl")
include("Synthetic.jl")
include("Analysis.jl")

export AudioFeatureBuffer, AudioFeatureFrame, buffer_capacity, latest_feature, push_feature!
export AudioSampleFrame, AudioSpectrumFrame
export analyze_sample_frame, analyze_sample_frames
export synthetic_feature_frame, synthetic_feature_frames, synthetic_sweep_sample_frames

end
