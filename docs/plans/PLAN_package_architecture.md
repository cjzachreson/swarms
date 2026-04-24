# Package Architecture Plan

## Goal

Define the first architecture for `SoundSwarms.jl`, a Julia package that simulates 2D swarms whose dynamics can respond to real-time or recorded audio input. The intended final use case is live deployment in party or music environments, while early development can use synthetic input data for deterministic progress.

## Core Invariant

Audio does not drive the solver directly.

The runtime path is:

```text
audio source -> audio features -> control frame -> model parameters -> simulation step -> visualization
```

This keeps the simulation engine testable and lets audio, mapping, and visualization evolve independently.

## Proposed Package Layout

```text
Project.toml
src/
     SoundSwarms.jl
     Simulation/
          Simulation.jl
          State.jl
          Parameters.jl
          Vicsek.jl
          Integrators.jl
     Audio/
          Audio.jl
          Sources.jl
          Features.jl
          Smoothing.jl
     Control/
          Control.jl
          Frames.jl
          Mappings.jl
     Visualization/
          Visualization.jl
          Realtime.jl
          RenderState.jl
     Config/
          Config.jl
          Defaults.jl
          Validation.jl
test/
     runtests.jl
     _setup/
     simulation/
     audio/
     control/
     config/
docs/
     plans/
     reports/
     worklogs/
```

The package name is `SoundSwarms.jl`.

## Simulation Engine

The simulation engine owns swarm state, model parameters, and time stepping. It should not depend on audio input, feature extraction, configuration files, or visualization.

Initial responsibilities:

- Initialize particle positions and headings from a config and explicit RNG.
- Advance the state with a fixed `dt`.
- Implement a standard Vicsek-style update.
- Support deterministic stochasticity through explicit RNG arguments.
- Expose lightweight observation data for visualization and tests.

Candidate types:

```julia
SwarmState
SwarmParameters
SimulationConfig
SimulationClock
```

Candidate functions:

```julia
initialize_swarm(config, rng)
step!(state, params, dt, rng)
observe(state)
```

Initial model features:

- 2D positions.
- Headings or velocities.
- Alignment radius.
- Base speed.
- Angular noise.
- Periodic domain boundaries.

Later model extensions can include adhesion, repulsion, trail-following, vortexing, and other visually interesting dynamics.

## Audio Processing

The audio layer converts microphone or recorded audio into normalized feature frames. Real-time microphone support is the priority, but recorded audio should produce the same feature-frame interface.

Initial responsibilities:

- Provide audio source abstractions for microphone and recorded input.
- Buffer short audio windows.
- Extract normalized features from each window.
- Smooth noisy feature streams before they reach the control layer.
- Store feature frames in a finite-length history buffer.

Candidate types:

```julia
AudioSource
MicrophoneSource
RecordedAudioSource
AudioBuffer
AudioFeatureFrame
AudioFeatureBuffer
AudioFeatureConfig
```

Initial feature candidates:

- `rms`
- `peak`
- `low_band`
- `mid_band`
- `high_band`
- `spectral_centroid`
- `onset_strength`

Real-time audio should update a latest-frame buffer or equivalent state. The simulation loop should read the latest smoothed frame when it advances.

The feature history buffer should support smooth behavior transitions and longer-timescale responses. For example, control mappings may use recent feature values for immediate reactions, while rhythm, phrase, or energy-trend logic can use summaries over longer windows.

Microphone input can be deferred until the simulation, control, and visualization foundations are in place. Early work should use synthetic feature streams and recorded/simulated feature frames. When real audio input is added, cross-platform support should be evaluated because the development environment will include both Windows and Linux. Candidate ecosystems to investigate include `AudioIO.jl`, which appears no longer maintained, and the broader JuliaAudio projects on GitHub.

## Control Mapping

The control layer maps audio features onto model parameters. This is where creative interpretation belongs.

Initial responsibilities:

- Convert `AudioFeatureFrame` values into normalized `ControlFrame` values.
- Summarize `AudioFeatureBuffer` history for longer-timescale control.
- Apply a `ControlFrame` to base simulation parameters.
- Keep mappings configurable and independently testable.

Candidate types:

```julia
ControlFrame
ParameterMapping
MappingConfig
```

Example mappings:

```text
rms            -> speed multiplier
onset_strength -> repulsion pulse
low_band       -> alignment strength
high_band      -> angular noise
centroid       -> visual color or vortex bias
```

The control layer should support synthetic test inputs without requiring audio devices.

## Visualization

The visualization layer renders current simulation state and optional visual effects. It should consume simulation observations rather than owning model logic.

Initial responsibilities:

- Display particles in real time.
- Render positions, headings, trails, or simple visual encodings.
- Optionally display audio-derived visual state.
- Avoid mutating simulation state directly.

Candidate types:

```julia
RenderState
VisualizationConfig
RealtimeView
```

Candidate Julia tools to evaluate:

- `GLMakie.jl` for real-time 2D visualization.
- `Observables.jl` if using Makie reactive state.

The final visualization stack should be chosen after discussion and after checking package compatibility and performance on the target development environments. Initial visualization priority is particles plus trails, so the design should include data structures suitable for maintaining a trail or pixel field.

## Configuration

Configuration should be structured and explicit. Plain Julia structs are enough for the first version; file loading can be added once fields stabilize.

Candidate config types:

```julia
SimulationConfig
AudioConfig
FeatureConfig
MappingConfig
VisualizationConfig
SwarmRunConfig
```

Example composition:

```julia
struct SwarmRunConfig
     simulation::SimulationConfig
     audio::AudioConfig
     features::FeatureConfig
     mapping::MappingConfig
     visualization::VisualizationConfig
end
```

Configuration should support deterministic tests through explicit seeds. It should not rely on global random state.

## Runtime Loop

The first real-time loop should use fixed simulation `dt` and asynchronous audio feature updates.

```text
start audio source
initialize swarm
initialize visualization

while running
     feature_frame = latest_smoothed_audio_features()
     control_frame = map_features(feature_frame, mapping_config)
     params = apply_control(base_params, control_frame)
     step!(state, params, dt, rng)
     render!(state)
end
```

The simulation step rate and audio callback rate should remain independent. A later solver layer can add variable or adaptive `dt` without changing the audio interface.

## Testing Strategy

The first tests should focus on deterministic pure logic.

Priority tests:

- Swarm initialization with seeded RNG.
- One-step Vicsek update on a small known system.
- Feature extraction from synthetic audio buffers.
- Smoothing behavior on simple numeric sequences.
- Mapping known feature frames to expected parameter changes.
- Config defaults and validation.

Real microphone input should not be required by the normal test suite. Microphone support can have optional smoke tests or manual examples.

## Initial Milestones

1. Scaffold the Julia package structure.
2. Add core simulation state, parameters, and fixed-step Vicsek update.
3. Add deterministic simulation tests.
4. Add audio feature-frame, feature-buffer, and control-frame types without device IO.
5. Add simple feature/history-to-parameter mappings and tests.
6. Add synthetic audio feature examples.
7. Add particles-plus-trails visualization using synthetic control input.
8. Discuss and choose the initial visualization stack.
9. Evaluate real-time audio input packages on Windows and Linux.
10. Connect microphone features to visualization through the control layer.

## Open Questions

- Visualization stack: should the first target be `GLMakie.jl`, another Julia graphics stack, or a separate rendering process?
- Audio input package: which Julia package is reliable enough across Windows and Linux?
- Feature history: what buffer length and summary statistics are useful for rhythm-scale behavior?
- Trail representation: should trails be particle histories, a decaying pixel field, or both?
