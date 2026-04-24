struct AudioFeatureFrame
     time::Float64
     rms::Float64
     low_band::Float64
     mid_band::Float64
     high_band::Float64
     spectral_centroid::Float64
     onset_strength::Float64

     function AudioFeatureFrame(
          time::Real,
          rms::Real,
          low_band::Real,
          mid_band::Real,
          high_band::Real,
          spectral_centroid::Real,
          onset_strength::Real,
     )
          time >= 0 || throw(ArgumentError("time must be non-negative"))
          validate_unit_feature("rms", rms)
          validate_unit_feature("low_band", low_band)
          validate_unit_feature("mid_band", mid_band)
          validate_unit_feature("high_band", high_band)
          validate_unit_feature("spectral_centroid", spectral_centroid)
          validate_unit_feature("onset_strength", onset_strength)

          return new(
               Float64(time),
               Float64(rms),
               Float64(low_band),
               Float64(mid_band),
               Float64(high_band),
               Float64(spectral_centroid),
               Float64(onset_strength),
          )
     end
end

function validate_unit_feature(name::AbstractString, value::Real)
     isfinite(value) || throw(ArgumentError("$(name) must be finite"))
     0 <= value <= 1 || throw(ArgumentError("$(name) must be between 0 and 1"))

     return nothing
end
