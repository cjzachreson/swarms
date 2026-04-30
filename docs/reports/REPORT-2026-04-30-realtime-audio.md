# Realtime Audio Progress Report 2026-04-30

## Overview

This stage added real microphone input and the first browser-based real-time swarm visualization path.

The working live path is:

```text
webcam microphone
-> PortAudio blocking reads
-> DSP feature extraction
-> envelope/onset control frame
-> Vicsek parameter mapping
-> WebSocket JSON stream
-> browser canvas visualization
```

The main result is that finger snaps into the webcam microphone produce visible changes in the swarm. In the current mapping, the RMS envelope controls speed and onset strength controls angular noise.

## Dependency Changes

Added:

- `PortAudio.jl` for microphone input.
- `HTTP.jl` for the local browser server and WebSocket stream.

Adjusted:

- `DSP.jl` was downgraded to `0.7.10` because `PortAudio.jl` depends on `SampledSignals.jl`, and the compatible package set requires the older DSP version.

The existing DSP analysis tests passed after the downgrade.

## Microphone Diagnostic Save/Replay

The finite microphone diagnostic script is:

```text
scripts/examples/diagnostic_microphone_recording_html.jl
```

Default behavior records 5 seconds from the webcam microphone:

```bash
julia -q --project=. scripts/examples/diagnostic_microphone_recording_html.jl
```

It saves captured `AudioSampleFrame`s to:

```text
outputs/recordings/microphone_recording.jls
```

It writes the diagnostic HTML to:

```text
outputs/diagnostic_microphone_recording.html
```

Replay mode avoids recording again and reuses the saved sample frames:

```bash
SOUNDSWARMS_MIC_MODE=replay julia -q --project=. scripts/examples/diagnostic_microphone_recording_html.jl
```

The recording format currently uses Julia `Serialization`. This is fine for local repeatable debugging, but should be revisited before sharing recordings across machines or Julia versions.

## Current Offline Mapping

The microphone diagnostic now uses:

```text
RMS envelope     -> speed
onset_strength   -> noise_strength
```

Current swarm settings:

```text
alignment_radius = 2.0
max_speed        = 2.0
max_noise        = 3.0
dt               = 1.0
```

This preserves the invariant:

```text
speed * dt <= alignment_radius
```

The speed cap and sensing radius were lowered together to produce more local, interesting, and cheaper dynamics.

## Realtime Browser Prototype

The live browser prototype is:

```text
scripts/examples/realtime_microphone_browser.jl
```

Run it with:

```bash
julia -q --project=. scripts/examples/realtime_microphone_browser.jl
```

Then open:

```text
http://127.0.0.1:8080
```

The script starts an HTTP server and serves an embedded browser canvas frontend. The browser connects back to Julia over WebSocket. Julia reads microphone windows, analyzes them, steps the swarm, and sends live JSON frames to the browser.

Current realtime configuration:

```text
device fragment   = C270 HD WEBCAM
sample_rate       = 48000
window_size       = 1024
host              = 127.0.0.1
port              = 8080
particle_count    = 220
alignment_radius  = 2.0
speed range       = 0.02 to 2.0
noise range       = 0.0 to 3.0
```

The browser shows:

- swarm particles with trails;
- live RMS/envelope signal;
- onset signal;
- mapped speed;
- mapped noise.

## Known Issues

- There is minor latency in the live browser prototype.
- A startup warning was observed:

```text
libportaudio: Input overflowed
```

This did not break the stream. It likely comes from startup/precompile/browser connection work delaying initial audio reads.

Likely mitigations:

- discard a few warmup audio buffers before streaming;
- test smaller/larger `window_size` values;
- reduce particle count or JSON payload if rendering/network cost becomes visible;
- avoid expensive one-time work inside the WebSocket loop.

## Useful Commands

Full test suite:

```bash
julia -q --project=. -e 'using Test; include(joinpath("test", "runtests.jl")); println("test complete")'
```

Record finite microphone diagnostic:

```bash
julia -q --project=. scripts/examples/diagnostic_microphone_recording_html.jl
```

Replay finite microphone diagnostic:

```bash
SOUNDSWARMS_MIC_MODE=replay julia -q --project=. scripts/examples/diagnostic_microphone_recording_html.jl
```

Run realtime browser prototype:

```bash
julia -q --project=. scripts/examples/realtime_microphone_browser.jl
```

Open:

```text
http://127.0.0.1:8080
```

## Recommended Next Work

1. Add warmup buffer reads to the realtime loop.
2. Make realtime config easier to tune, mirroring the offline mic diagnostic.
3. Try `window_size = 512`, `1024`, and `2048` to compare latency/stability.
4. Reduce JSON payload or particle count if needed.
5. Decide when to extract shared microphone/audio utilities from the example scripts into `src/Audio` or `src/Runtime`.
6. Continue treating the browser/WebSocket path as the main portable live visualization candidate before evaluating GLMakie.
