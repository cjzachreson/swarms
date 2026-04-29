# Audio Integration Plan 29-04-2026

## Goal

Add a practical audio-processing path to `SoundSwarms.jl` while preserving the current architecture:

```text
audio source -> sample windows -> audio features -> control mapping -> simulation -> visualization
```

The immediate aim is not full live performance. The aim is to replace the fixture-scale direct DFT path with a more realistic audio analysis layer, then validate the same feature path with recorded audio and finally microphone input.

## Overall Reasoning

The project already has a useful simulation, control, runtime, and diagnostic visualization foundation. The next risk is audio analysis quality and stability, not rendering. The safest order is therefore:

1. Make feature extraction more realistic using deterministic synthetic inputs.
2. Validate the same extraction path on recorded audio files.
3. Add microphone input only after the analyzer interface is stable.
4. Keep real-time visualization and callback details deferred until the feature stream behaves well.

This order avoids debugging device I/O, audio analysis, control mapping, and rendering at the same time.

## Candidate Package Roles

- `DSP.jl`: primary package for FFT/STFT, periodograms, windows, filters, and later onset or envelope processing.
- `SampledSignals.jl`: interoperability layer for sample-rate-aware buffers and streams.
- `LibSndFile.jl`: likely file-backed audio source for WAV/Ogg/FLAC fixtures and examples.
- `PortAudio.jl`: likely microphone source for manual real-time examples.

The `SoundSwarms` core should continue to expose its own small types, such as `AudioSampleFrame` and `AudioFeatureFrame`, so external package choices do not leak into simulation or control code.

## Step S1: Define Audio Integration Boundaries

Introduce or document two separate concepts:

```julia
AudioSource
FeatureExtractor
```

Reasoning: source acquisition and feature extraction have different failure modes. Recorded files and microphones should be interchangeable once they produce sample windows. Feature extraction should remain testable without audio hardware.

Acceptance:

- Clear internal boundary between sample acquisition and feature extraction.
- Existing synthetic sample-frame path still works.
- No simulation/control API changes.

Out of scope:

- Microphone input.
- New visualization behavior.
- Large source hierarchy unless needed by implementation.

## Step S2: Add a `DSP.jl`-Backed Offline Analyzer

Replace or supplement the current direct DFT analyzer with a `DSP.jl`-based implementation for windowed sample frames.

Initial feature targets:

- `rms`
- `peak`
- `low_band`
- `mid_band`
- `high_band`
- `spectral_centroid`
- optional spectrum data for diagnostics

Reasoning: this is the lowest-risk dependency step. Synthetic inputs are deterministic, the existing diagnostic HTML can show whether feature traces make sense, and tests can compare broad behavior rather than exact visual output.

Acceptance:

- Analyzer accepts existing `AudioSampleFrame`s.
- Output remains `AudioFeatureFrame` plus optional spectrum frames.
- Tests cover normalization, band behavior, centroid direction, and frame counts.
- Existing synthetic diagnostic can switch to the new analyzer.

Out of scope:

- Real microphone input.
- File loading.
- Onset detection beyond simple placeholders.

## Step S3: Add Feature Smoothing and History Summaries

Add small, deterministic smoothing utilities over `AudioFeatureBuffer` or feature sequences.

Initial candidates:

- moving mean
- exponential smoothing
- peak/decay envelope
- frame-to-frame energy delta for simple onset strength

Reasoning: raw audio features can be too jittery for visual control. Smoothing before microphone work makes the later real-time path more controllable and easier to diagnose.

Acceptance:

- Smoothing functions are independent of audio devices.
- Tests use simple numeric sequences with predictable outputs.
- Diagnostic examples can show raw versus smoothed or use smoothed control inputs.

Out of scope:

- Beat tracking.
- Phrase detection.
- Complex rhythm models.

## Step S4: Add Recorded Audio Source Support

Add a recorded-file path using `LibSndFile.jl` and `SampledSignals.jl`, or a narrower file reader if dependency behavior is problematic.

Reasoning: recorded files are the bridge between synthetic fixtures and live microphones. They provide real acoustic complexity while remaining repeatable enough for examples and manual validation.

Acceptance:

- A recorded file can be loaded or streamed into sample windows.
- The same `FeatureExtractor` path handles synthetic and recorded samples.
- A manual example writes a diagnostic HTML output from a recorded clip.
- Tests avoid relying on large binary fixtures unless a tiny fixture is intentionally added.

Out of scope:

- Shipping large audio files.
- Device I/O.
- Real-time synchronization.

## Step S5: Add a Manual Microphone Input Example

Add a `PortAudio.jl`-based example that reads short input blocks from a microphone, converts them into sample windows, extracts feature frames, and stores or displays the latest features.

Reasoning: microphone behavior depends on operating system, device drivers, sample rates, and latency. It should start as a manual example rather than a required test path.

Acceptance:

- The example can list or use default input devices.
- It reads finite-duration microphone input without entering the test suite.
- It produces feature frames through the same extractor as synthetic and recorded sources.
- It handles stream closing cleanly.

Out of scope:

- Custom PortAudio callbacks.
- Hard real-time guarantees.
- Required CI or unit tests using audio hardware.

## Step S6: Connect Live Features to the Runtime Loop

Add a small live-feature buffer or "latest feature" interface that the simulation loop can poll.

Reasoning: the simulation should consume feature frames, not audio samples. Polling the latest smoothed feature frame preserves the existing architecture and keeps audio timing independent from simulation timing.

Acceptance:

- Runtime loop can read the latest available feature frame.
- Simulation advances at its own fixed `dt`.
- Missing or stale audio frames have explicit behavior.
- Manual demo can drive swarm parameters from microphone-derived features.

Out of scope:

- Final rendering backend choice.
- Low-latency callback processing.
- Multi-threaded performance tuning beyond obvious allocation fixes.

## Step S7: Revisit Real-Time Visualization and Callbacks

Evaluate whether blocking `PortAudio.jl` reads and polling are sufficient. If not, investigate callback or task-based alternatives.

Reasoning: callback constraints are only worth solving once the feature extraction and control mapping are known to produce useful behavior. The current docs suggest built-in read/write behavior may be enough for an early live demo.

Acceptance:

- Clear decision on whether polling/block reads are acceptable.
- Documented latency and stability observations on available systems.
- Next visualization plan can be made with real audio behavior in mind.

Out of scope:

- Premature callback architecture.
- Production deployment packaging.

## Immediate Next Step

Start with Step S1 and Step S2 together as one focused implementation plan:

- add `DSP.jl` as the first audio-processing dependency;
- implement a `DSP.jl` analyzer behind the existing sample-frame interface;
- keep the direct DFT analyzer temporarily for comparison or as a fallback;
- update the synthetic-signal diagnostic to use the new analyzer once tests pass.

This keeps the first change narrow: no microphone, no recorded files, and no runtime restructuring unless the analyzer interface forces it.
