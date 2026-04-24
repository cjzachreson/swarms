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
     fps::Real = 30,
     trail_alpha::Real = 0.12,
     feature_trace_keys = (:rms, :low_band, :mid_band, :high_band, :onset_strength),
)
     !isempty(swarm_frames) || throw(ArgumentError("swarm_frames must not be empty"))
     length(swarm_frames) == length(audio_frames) || throw(ArgumentError("swarm_frames and audio_frames must have the same length"))
     domain_width > 0 || throw(ArgumentError("domain_width must be positive"))
     domain_height > 0 || throw(ArgumentError("domain_height must be positive"))
     canvas_width > 0 || throw(ArgumentError("canvas_width must be positive"))
     swarm_canvas_height > 0 || throw(ArgumentError("swarm_canvas_height must be positive"))
     trace_canvas_height > 0 || throw(ArgumentError("trace_canvas_height must be positive"))
     fps > 0 || throw(ArgumentError("fps must be positive"))
     0 <= trail_alpha <= 1 || throw(ArgumentError("trail_alpha must be between 0 and 1"))
     trace_keys = collect_feature_trace_keys(feature_trace_keys)

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
                    Float64(fps),
                    Float64(trail_alpha),
                    trace_keys,
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
     fps,
     trail_alpha,
     trace_keys,
)
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
          </main>
          <script>
               const swarmFrames = $(frames_json(swarm_frames));
               const audioFrames = $(audio_frames_json(audio_frames));
               const traceKeys = $(trace_keys_json(trace_keys));
               const traceColors = {
                    rms: "#78dce8",
                    low_band: "#a9dc76",
                    mid_band: "#ffd866",
                    high_band: "#ff6188",
                    onset_strength: "#ab9df2"
               };
               const domainWidth = $(domain_width);
               const domainHeight = $(domain_height);
               const swarmCanvas = document.getElementById("swarm");
               const traceCanvas = document.getElementById("traces");
               const swarmCtx = swarmCanvas.getContext("2d");
               const traceCtx = traceCanvas.getContext("2d");
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

                    for (const key of traceKeys) {
                         traceCtx.strokeStyle = traceColors[key];
                         traceCtx.lineWidth = 2;
                         traceCtx.beginPath();

                         for (let i = 0; i < audioFrames.length; i++) {
                              const x = leftPad + (i / Math.max(1, audioFrames.length - 1)) * plotWidth;
                              const y = topPad + (1 - audioFrames[i][key]) * plotHeight;
                              if (i === 0) {
                                   traceCtx.moveTo(x, y);
                              } else {
                                   traceCtx.lineTo(x, y);
                              }
                         }

                         traceCtx.stroke();
                    }

                    const cursorX = leftPad + (currentIndex / Math.max(1, audioFrames.length - 1)) * plotWidth;
                    traceCtx.strokeStyle = "#f2f5f7";
                    traceCtx.lineWidth = 1;
                    traceCtx.beginPath();
                    traceCtx.moveTo(cursorX, topPad);
                    traceCtx.lineTo(cursorX, topPad + plotHeight);
                    traceCtx.stroke();

                    let legendX = leftPad;
                    for (const key of traceKeys) {
                         traceCtx.fillStyle = traceColors[key];
                         traceCtx.fillRect(legendX, traceCanvas.height - 16, 10, 10);
                         traceCtx.fillStyle = "#d7dde2";
                         traceCtx.fillText(key, legendX + 14, traceCanvas.height - 7);
                         legendX += 130;
                    }
               }

               function animate(timestamp) {
                    if (timestamp - previousTime >= frameInterval) {
                         drawSwarm(swarmFrames[frameIndex]);
                         drawTraces(frameIndex);
                         frameIndex = (frameIndex + 1) % swarmFrames.length;
                         previousTime = timestamp;
                    }

                    requestAnimationFrame(animate);
               }

               swarmCtx.fillStyle = "#050607";
               swarmCtx.fillRect(0, 0, swarmCanvas.width, swarmCanvas.height);
               drawTraces(0);
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

is_diagnostic_audio_feature(feature::Symbol) = feature in (
     :rms,
     :low_band,
     :mid_band,
     :high_band,
     :spectral_centroid,
     :onset_strength,
)
