struct ControlledRunFrame
     swarm::SwarmFrame
     audio::AudioFeatureFrame
     params::SwarmParameters
end

function run_controlled_simulation(
     initial_state::SwarmState,
     base_params::SwarmParameters,
     audio_frames::AbstractVector{AudioFeatureFrame},
     mapping::FeatureParameterMapping,
     dt::Real,
     rng::AbstractRNG,
)
     dt > 0 || throw(ArgumentError("dt must be positive"))

     state = SwarmState(initial_state.positions, initial_state.headings)
     run_frames = ControlledRunFrame[]

     for audio_frame in audio_frames
          params = map_features_to_parameters(base_params, audio_frame, mapping, dt)
          push!(run_frames, ControlledRunFrame(SwarmFrame(state.positions), audio_frame, params))
          step!(state, params, dt, rng)
     end

     return run_frames
end
