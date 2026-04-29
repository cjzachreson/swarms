struct SwarmFrame
     positions::Matrix{Float64}

     function SwarmFrame(positions::AbstractMatrix{<:Real})
          size(positions, 1) == 2 || throw(ArgumentError("positions must have shape 2 x n"))

          return new(Matrix{Float64}(positions))
     end
end

function write_html_animation(
     path::AbstractString,
     frames::AbstractVector{SwarmFrame},
     domain_width::Real,
     domain_height::Real;
     canvas_width::Integer = 900,
     canvas_height::Integer = 700,
     fps::Real = 30,
     trail_alpha::Real = 0.12,
)
     !isempty(frames) || throw(ArgumentError("frames must not be empty"))
     domain_width > 0 || throw(ArgumentError("domain_width must be positive"))
     domain_height > 0 || throw(ArgumentError("domain_height must be positive"))
     canvas_width > 0 || throw(ArgumentError("canvas_width must be positive"))
     canvas_height > 0 || throw(ArgumentError("canvas_height must be positive"))
     fps > 0 || throw(ArgumentError("fps must be positive"))
     0 <= trail_alpha <= 1 || throw(ArgumentError("trail_alpha must be between 0 and 1"))

     mkpath(dirname(path))

     open(path, "w") do io
          write(io, html_document(frames, Float64(domain_width), Float64(domain_height), canvas_width, canvas_height, Float64(fps), Float64(trail_alpha)))
     end

     return path
end

function write_diagnostic_html_animation(
     path::AbstractString,
     swarm_frames::AbstractVector{SwarmFrame},
     audio_frames::AbstractVector,
     domain_width::Real,
     domain_height::Real;
     canvas_width::Integer = 1000,
     swarm_canvas_height::Integer = 620,
     trace_canvas_height::Integer = 260,
     parameter_canvas_height::Integer = 220,
     spectrum_canvas_height::Integer = 220,
     fps::Real = 30,
     trail_alpha::Real = 0.12,
     feature_trace_keys = (:rms, :low_band, :mid_band, :high_band, :onset_strength),
     extra_trace_series = (;),
     parameter_frames = nothing,
     spectrum_frames = nothing,
)
     !isempty(swarm_frames) || throw(ArgumentError("swarm_frames must not be empty"))
     length(swarm_frames) == length(audio_frames) || throw(ArgumentError("swarm_frames and audio_frames must have the same length"))
     domain_width > 0 || throw(ArgumentError("domain_width must be positive"))
     domain_height > 0 || throw(ArgumentError("domain_height must be positive"))
     canvas_width > 0 || throw(ArgumentError("canvas_width must be positive"))
     swarm_canvas_height > 0 || throw(ArgumentError("swarm_canvas_height must be positive"))
     trace_canvas_height > 0 || throw(ArgumentError("trace_canvas_height must be positive"))
     parameter_canvas_height > 0 || throw(ArgumentError("parameter_canvas_height must be positive"))
     spectrum_canvas_height > 0 || throw(ArgumentError("spectrum_canvas_height must be positive"))
     fps > 0 || throw(ArgumentError("fps must be positive"))
     0 <= trail_alpha <= 1 || throw(ArgumentError("trail_alpha must be between 0 and 1"))
     trace_keys = collect_feature_trace_keys(feature_trace_keys)
     extra_traces = collect_extra_trace_series(extra_trace_series, length(swarm_frames))
     if parameter_frames !== nothing
          length(swarm_frames) == length(parameter_frames) || throw(ArgumentError("swarm_frames and parameter_frames must have the same length"))
     end
     if spectrum_frames !== nothing
          length(swarm_frames) == length(spectrum_frames) || throw(ArgumentError("swarm_frames and spectrum_frames must have the same length"))
     end

     mkpath(dirname(path))

     open(path, "w") do io
          write(
               io,
               diagnostic_html_document(
                    swarm_frames,
                    audio_frames,
                    Float64(domain_width),
                    Float64(domain_height),
                    canvas_width,
                    swarm_canvas_height,
                    trace_canvas_height,
                    parameter_canvas_height,
                    spectrum_canvas_height,
                    Float64(fps),
                    Float64(trail_alpha),
                    trace_keys,
                    extra_traces,
                    parameter_frames,
                    spectrum_frames,
               ),
          )
     end

     return path
end

function html_document(frames, domain_width, domain_height, canvas_width, canvas_height, fps, trail_alpha)
     return """
     <!doctype html>
     <html lang="en">
     <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>SoundSwarms Vicsek Preview</title>
          <style>
               html, body {
                    margin: 0;
                    width: 100%;
                    height: 100%;
                    background: #101214;
                    color: #f2f5f7;
                    font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
               }

               body {
                    display: grid;
                    place-items: center;
               }

               canvas {
                    width: min(96vw, $(canvas_width)px);
                    height: auto;
                    aspect-ratio: $(canvas_width) / $(canvas_height);
                    background: #050607;
                    border: 1px solid #2f363d;
               }
          </style>
     </head>
     <body>
          <canvas id="swarm" width="$(canvas_width)" height="$(canvas_height)"></canvas>
          <script>
               const frames = $(frames_json(frames));
               const domainWidth = $(domain_width);
               const domainHeight = $(domain_height);
               const canvas = document.getElementById("swarm");
               const ctx = canvas.getContext("2d");
               const frameInterval = 1000 / $(fps);
               let frameIndex = 0;
               let previousTime = 0;

               function drawParticles(frame) {
                    ctx.fillStyle = "rgba(5, 6, 7, $(trail_alpha))";
                    ctx.fillRect(0, 0, canvas.width, canvas.height);

                    ctx.fillStyle = "#78dce8";
                    for (const particle of frame) {
                         const x = particle[0] / domainWidth * canvas.width;
                         const y = particle[1] / domainHeight * canvas.height;
                         ctx.beginPath();
                         ctx.arc(x, y, 2.0, 0, Math.PI * 2);
                         ctx.fill();
                    }
               }

               function animate(timestamp) {
                    if (timestamp - previousTime >= frameInterval) {
                         drawParticles(frames[frameIndex]);
                         frameIndex = (frameIndex + 1) % frames.length;
                         previousTime = timestamp;
                    }

                    requestAnimationFrame(animate);
               }

               ctx.fillStyle = "#050607";
               ctx.fillRect(0, 0, canvas.width, canvas.height);
               requestAnimationFrame(animate);
          </script>
     </body>
     </html>
     """
end

function frames_json(frames::AbstractVector{SwarmFrame})
     frame_strings = [frame_json(frame) for frame in frames]

     return "[" * join(frame_strings, ",") * "]"
end

function frame_json(frame::SwarmFrame)
     particle_strings = String[]

     for particle_index in axes(frame.positions, 2)
          x = frame.positions[1, particle_index]
          y = frame.positions[2, particle_index]
          push!(particle_strings, "[$(x),$(y)]")
     end

     return "[" * join(particle_strings, ",") * "]"
end

function diagnostic_html_document(
     swarm_frames,
     audio_frames,
     domain_width,
     domain_height,
     canvas_width,
     swarm_canvas_height,
     trace_canvas_height,
     parameter_canvas_height,
     spectrum_canvas_height,
     fps,
     trail_alpha,
     trace_keys,
     extra_traces,
     parameter_frames,
     spectrum_frames,
)
     parameter_canvas = parameter_frames === nothing ? "" : """<canvas id="parameters" width="$(canvas_width)" height="$(parameter_canvas_height)"></canvas>"""
     parameter_json = parameter_frames === nothing ? "[]" : parameter_frames_json(parameter_frames)
     has_parameter_frames = parameter_frames === nothing ? "false" : "true"
     extra_traces_json = extra_trace_series_json(extra_traces)
     spectrum_canvas = spectrum_frames === nothing ? "" : """<canvas id="spectrum" width="$(canvas_width)" height="$(spectrum_canvas_height)"></canvas>"""
     spectrum_json = spectrum_frames === nothing ? "[]" : spectrum_frames_json(spectrum_frames)
     has_spectrum = spectrum_frames === nothing ? "false" : "true"

     return """
     <!doctype html>
     <html lang="en">
     <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>SoundSwarms Diagnostic Preview</title>
          <style>
               html, body {
                    margin: 0;
                    width: 100%;
                    min-height: 100%;
                    background: #101214;
                    color: #f2f5f7;
                    font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
               }

               body {
                    display: grid;
                    place-items: center;
                    padding: 18px;
                    box-sizing: border-box;
               }

               main {
                    width: min(96vw, $(canvas_width)px);
                    display: grid;
                    gap: 10px;
               }

               canvas {
                    width: 100%;
                    height: auto;
                    background: #050607;
                    border: 1px solid #2f363d;
               }
          </style>
     </head>
     <body>
          <main>
               <canvas id="swarm" width="$(canvas_width)" height="$(swarm_canvas_height)"></canvas>
               <canvas id="traces" width="$(canvas_width)" height="$(trace_canvas_height)"></canvas>
               $(parameter_canvas)
               $(spectrum_canvas)
          </main>
          <script>
               const swarmFrames = $(frames_json(swarm_frames));
               const audioFrames = $(audio_frames_json(audio_frames));
               const parameterFrames = $(parameter_json);
               const extraTraceSeries = $(extra_traces_json);
               const spectrumFrames = $(spectrum_json);
               const hasParameterFrames = $(has_parameter_frames);
               const hasSpectrum = $(has_spectrum);
               const traceKeys = $(trace_keys_json(trace_keys));
               const traceColors = {
                    rms: "#78dce8",
                    low_band: "#a9dc76",
                    mid_band: "#ffd866",
                    high_band: "#ff6188",
                    spectral_centroid: "#fc9867",
                    onset_strength: "#ab9df2"
               };
               const extraTraceColors = ["#78dce8", "#a9dc76", "#ffd866", "#ff6188", "#fc9867", "#ab9df2", "#c6c8d1"];
               const domainWidth = $(domain_width);
               const domainHeight = $(domain_height);
               const swarmCanvas = document.getElementById("swarm");
               const traceCanvas = document.getElementById("traces");
               const parameterCanvas = document.getElementById("parameters");
               const spectrumCanvas = document.getElementById("spectrum");
               const swarmCtx = swarmCanvas.getContext("2d");
               const traceCtx = traceCanvas.getContext("2d");
               const parameterCtx = hasParameterFrames ? parameterCanvas.getContext("2d") : null;
               const spectrumCtx = hasSpectrum ? spectrumCanvas.getContext("2d") : null;
               const frameInterval = 1000 / $(fps);
               let frameIndex = 0;
               let previousTime = 0;

               function drawSwarm(frame) {
                    swarmCtx.fillStyle = "rgba(5, 6, 7, $(trail_alpha))";
                    swarmCtx.fillRect(0, 0, swarmCanvas.width, swarmCanvas.height);

                    swarmCtx.fillStyle = "#78dce8";
                    for (const particle of frame) {
                         const x = particle[0] / domainWidth * swarmCanvas.width;
                         const y = particle[1] / domainHeight * swarmCanvas.height;
                         swarmCtx.beginPath();
                         swarmCtx.arc(x, y, 2.0, 0, Math.PI * 2);
                         swarmCtx.fill();
                    }
               }

               function drawTraces(currentIndex) {
                    traceCtx.fillStyle = "#050607";
                    traceCtx.fillRect(0, 0, traceCanvas.width, traceCanvas.height);

                    const leftPad = 64;
                    const rightPad = 14;
                    const topPad = 18;
                    const bottomPad = 28;
                    const plotWidth = traceCanvas.width - leftPad - rightPad;
                    const plotHeight = traceCanvas.height - topPad - bottomPad;

                    traceCtx.strokeStyle = "#2f363d";
                    traceCtx.lineWidth = 1;
                    traceCtx.strokeRect(leftPad, topPad, plotWidth, plotHeight);

                    traceCtx.fillStyle = "#b8c0c7";
                    traceCtx.font = "12px system-ui";
                    traceCtx.fillText("features", leftPad, 13);
                    traceCtx.fillText("0", 42, topPad + plotHeight);
                    traceCtx.fillText("1", 42, topPad + 5);

                    const traces = traceKeys.map((key) => ({
                         name: key,
                         color: traceColors[key],
                         values: audioFrames.map((frame) => frame[key])
                    })).concat(extraTraceSeries.map((series, index) => ({
                         name: series.name,
                         color: extraTraceColors[index % extraTraceColors.length],
                         values: series.values
                    })));

                    for (const trace of traces) {
                         traceCtx.strokeStyle = trace.color;
                         traceCtx.lineWidth = 2;
                         traceCtx.beginPath();

                         for (let i = 0; i < trace.values.length; i++) {
                              const x = leftPad + (i / Math.max(1, trace.values.length - 1)) * plotWidth;
                              const y = topPad + (1 - trace.values[i]) * plotHeight;
                              if (i === 0) {
                                   traceCtx.moveTo(x, y);
                              } else {
                                   traceCtx.lineTo(x, y);
                              }
                         }

                         traceCtx.stroke();
                    }

                    const cursorX = leftPad + (currentIndex / Math.max(1, swarmFrames.length - 1)) * plotWidth;
                    traceCtx.strokeStyle = "#f2f5f7";
                    traceCtx.lineWidth = 1;
                    traceCtx.beginPath();
                    traceCtx.moveTo(cursorX, topPad);
                    traceCtx.lineTo(cursorX, topPad + plotHeight);
                    traceCtx.stroke();

                    let legendX = leftPad;
                    for (const trace of traces) {
                         traceCtx.fillStyle = trace.color;
                         traceCtx.fillRect(legendX, traceCanvas.height - 16, 10, 10);
                         traceCtx.fillStyle = "#d7dde2";
                         traceCtx.fillText(trace.name, legendX + 14, traceCanvas.height - 7);
                         legendX += 130;
                    }
               }

               function drawParameterTraces(currentIndex) {
                    if (!hasParameterFrames) {
                         return;
                    }

                    parameterCtx.fillStyle = "#050607";
                    parameterCtx.fillRect(0, 0, parameterCanvas.width, parameterCanvas.height);

                    const keys = [
                         { name: "speed", color: "#78dce8" },
                         { name: "noise_strength", color: "#ff6188" }
                    ];
                    const leftPad = 80;
                    const rightPad = 14;
                    const topPad = 18;
                    const bottomPad = 24;
                    const gap = 18;
                    const plotWidth = parameterCanvas.width - leftPad - rightPad;
                    const plotHeight = (parameterCanvas.height - topPad - bottomPad - gap) / keys.length;

                    parameterCtx.fillStyle = "#b8c0c7";
                    parameterCtx.font = "12px system-ui";
                    parameterCtx.fillText("parameters", leftPad, 13);

                    for (let plotIndex = 0; plotIndex < keys.length; plotIndex++) {
                         const key = keys[plotIndex];
                         const yTop = topPad + plotIndex * (plotHeight + gap);
                         const values = parameterFrames.map((frame) => frame[key.name]);
                         let minValue = Math.min(...values);
                         let maxValue = Math.max(...values);
                         if (maxValue === minValue) {
                              maxValue = minValue + 1;
                         }

                         parameterCtx.strokeStyle = "#2f363d";
                         parameterCtx.lineWidth = 1;
                         parameterCtx.strokeRect(leftPad, yTop, plotWidth, plotHeight);

                         parameterCtx.fillStyle = "#b8c0c7";
                         parameterCtx.fillText(key.name, 8, yTop + 13);
                         parameterCtx.fillText(maxValue.toFixed(2), 42, yTop + 12);
                         parameterCtx.fillText(minValue.toFixed(2), 42, yTop + plotHeight);

                         parameterCtx.strokeStyle = key.color;
                         parameterCtx.lineWidth = 2;
                         parameterCtx.beginPath();

                         for (let i = 0; i < parameterFrames.length; i++) {
                              const x = leftPad + (i / Math.max(1, parameterFrames.length - 1)) * plotWidth;
                              const amount = (parameterFrames[i][key.name] - minValue) / (maxValue - minValue);
                              const y = yTop + (1 - amount) * plotHeight;
                              if (i === 0) {
                                   parameterCtx.moveTo(x, y);
                              } else {
                                   parameterCtx.lineTo(x, y);
                              }
                         }

                         parameterCtx.stroke();
                    }

                    const cursorX = leftPad + (currentIndex / Math.max(1, parameterFrames.length - 1)) * plotWidth;
                    parameterCtx.strokeStyle = "#f2f5f7";
                    parameterCtx.lineWidth = 1;
                    parameterCtx.beginPath();
                    parameterCtx.moveTo(cursorX, topPad);
                    parameterCtx.lineTo(cursorX, parameterCanvas.height - bottomPad);
                    parameterCtx.stroke();
               }

               function heatColor(value) {
                    const v = Math.max(0, Math.min(1, value));
                    const r = Math.floor(255 * Math.max(0, Math.min(1, 1.8 * v - 0.35)));
                    const g = Math.floor(255 * Math.max(0, Math.min(1, 1.8 * v)));
                    const b = Math.floor(255 * Math.max(0, Math.min(1, 0.9 - 1.2 * v)));
                    return "rgb(" + r + ", " + g + ", " + b + ")";
               }

               function drawSpectrum(currentIndex) {
                    if (!hasSpectrum) {
                         return;
                    }

                    spectrumCtx.fillStyle = "#050607";
                    spectrumCtx.fillRect(0, 0, spectrumCanvas.width, spectrumCanvas.height);

                    const leftPad = 64;
                    const rightPad = 14;
                    const topPad = 18;
                    const bottomPad = 28;
                    const plotWidth = spectrumCanvas.width - leftPad - rightPad;
                    const plotHeight = spectrumCanvas.height - topPad - bottomPad;
                    const frameWidth = plotWidth / Math.max(1, spectrumFrames.length);
                    const binCount = spectrumFrames[0].amplitudes.length;
                    const binHeight = plotHeight / Math.max(1, binCount);

                    for (let i = 0; i < spectrumFrames.length; i++) {
                         const amplitudes = spectrumFrames[i].amplitudes;
                         for (let bin = 0; bin < amplitudes.length; bin++) {
                              spectrumCtx.fillStyle = heatColor(amplitudes[bin]);
                              const x = leftPad + i * frameWidth;
                              const y = topPad + plotHeight - (bin + 1) * binHeight;
                              spectrumCtx.fillRect(x, y, Math.ceil(frameWidth) + 1, Math.ceil(binHeight) + 1);
                         }
                    }

                    spectrumCtx.strokeStyle = "#2f363d";
                    spectrumCtx.lineWidth = 1;
                    spectrumCtx.strokeRect(leftPad, topPad, plotWidth, plotHeight);

                    spectrumCtx.fillStyle = "#b8c0c7";
                    spectrumCtx.font = "12px system-ui";
                    spectrumCtx.fillText("spectrum", leftPad, 13);
                    spectrumCtx.fillText("low", 36, topPad + plotHeight);
                    spectrumCtx.fillText("high", 32, topPad + 5);

                    const cursorX = leftPad + (currentIndex / Math.max(1, spectrumFrames.length - 1)) * plotWidth;
                    spectrumCtx.strokeStyle = "#f2f5f7";
                    spectrumCtx.lineWidth = 1;
                    spectrumCtx.beginPath();
                    spectrumCtx.moveTo(cursorX, topPad);
                    spectrumCtx.lineTo(cursorX, topPad + plotHeight);
                    spectrumCtx.stroke();
               }

               function animate(timestamp) {
                    if (timestamp - previousTime >= frameInterval) {
                         drawSwarm(swarmFrames[frameIndex]);
                         drawTraces(frameIndex);
                         drawParameterTraces(frameIndex);
                         drawSpectrum(frameIndex);
                         frameIndex = (frameIndex + 1) % swarmFrames.length;
                         previousTime = timestamp;
                    }

                    requestAnimationFrame(animate);
               }

               swarmCtx.fillStyle = "#050607";
               swarmCtx.fillRect(0, 0, swarmCanvas.width, swarmCanvas.height);
               drawTraces(0);
               drawParameterTraces(0);
               drawSpectrum(0);
               requestAnimationFrame(animate);
          </script>
     </body>
     </html>
     """
end

function audio_frames_json(audio_frames)
     frame_strings = [audio_frame_json(frame) for frame in audio_frames]

     return "[" * join(frame_strings, ",") * "]"
end

function audio_frame_json(frame)
     return "{" *
            "\"time\":$(frame.time)," *
            "\"rms\":$(frame.rms)," *
            "\"low_band\":$(frame.low_band)," *
            "\"mid_band\":$(frame.mid_band)," *
            "\"high_band\":$(frame.high_band)," *
            "\"spectral_centroid\":$(frame.spectral_centroid)," *
            "\"onset_strength\":$(frame.onset_strength)" *
            "}"
end

function parameter_frames_json(parameter_frames)
     frame_strings = [parameter_frame_json(frame) for frame in parameter_frames]

     return "[" * join(frame_strings, ",") * "]"
end

function parameter_frame_json(frame)
     return "{" *
            "\"speed\":$(frame.speed)," *
            "\"noise_strength\":$(frame.noise_strength)" *
            "}"
end

function spectrum_frames_json(spectrum_frames)
     frame_strings = [spectrum_frame_json(frame) for frame in spectrum_frames]

     return "[" * join(frame_strings, ",") * "]"
end

function spectrum_frame_json(frame)
     frequencies = "[" * join(string.(frame.frequencies), ",") * "]"
     amplitudes = "[" * join(string.(frame.amplitudes), ",") * "]"

     return "{" *
            "\"time\":$(frame.time)," *
            "\"frequencies\":$(frequencies)," *
            "\"amplitudes\":$(amplitudes)" *
            "}"
end

function collect_feature_trace_keys(feature_trace_keys)
     trace_keys = Symbol.(collect(feature_trace_keys))
     !isempty(trace_keys) || throw(ArgumentError("feature_trace_keys must not be empty"))

     for key in trace_keys
          is_diagnostic_audio_feature(key) || throw(ArgumentError("unsupported feature trace key: $(key)"))
     end

     return trace_keys
end

function trace_keys_json(trace_keys)
     return "[" * join(["\"$(key)\"" for key in trace_keys], ",") * "]"
end

function collect_extra_trace_series(extra_trace_series, expected_length::Integer)
     trace_pairs = collect(pairs(extra_trace_series))
     extra_traces = Pair{Symbol, Vector{Float64}}[]

     for (name, values) in trace_pairs
          trace_name = Symbol(name)
          trace_values = Vector{Float64}(values)
          length(trace_values) == expected_length || throw(ArgumentError("extra trace $(trace_name) must have $(expected_length) values"))
          all(isfinite, trace_values) || throw(ArgumentError("extra trace $(trace_name) values must be finite"))
          all(value -> 0 <= value <= 1, trace_values) || throw(ArgumentError("extra trace $(trace_name) values must be between 0 and 1"))
          push!(extra_traces, trace_name => trace_values)
     end

     return extra_traces
end

function extra_trace_series_json(extra_traces)
     series_strings = [extra_trace_json(name, values) for (name, values) in extra_traces]

     return "[" * join(series_strings, ",") * "]"
end

function extra_trace_json(name::Symbol, values::Vector{Float64})
     values_json = "[" * join(string.(values), ",") * "]"

     return "{" *
            "\"name\":\"$(name)\"," *
            "\"values\":$(values_json)" *
            "}"
end

is_diagnostic_audio_feature(feature::Symbol) = feature in (
     :rms,
     :low_band,
     :mid_band,
     :high_band,
     :spectral_centroid,
     :onset_strength,
)
