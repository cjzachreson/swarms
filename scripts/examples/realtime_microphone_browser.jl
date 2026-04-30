using HTTP
using PortAudio
using Random
using SoundSwarms

struct RealtimeBrowserConfig
     device_name_fragment::String
     sample_rate::Int
     window_size::Int
     host::String
     port::Int
     particle_count::Int
     domain_width::Float64
     domain_height::Float64
     max_frequency::Float64
     spectrum_bin_count::Int
     onset_scale::Float64
     envelope_attack_alpha::Float64
     envelope_decay_alpha::Float64
     mapping::FeatureParameterMapping
     base_params::SwarmParameters
end

const REALTIME_BROWSER_CONFIG = RealtimeBrowserConfig(
     "C270 HD WEBCAM",
     48000,
     1024,
     "127.0.0.1",
     8080,
     220,
     100.0,
     100.0,
     5000.0,
     72,
     4.0,
     0.8,
     0.08,
     FeatureParameterMapping(0.02, 2.0, 0.0, 3.0; speed_feature = :rms, noise_feature = :onset_strength),
     SwarmParameters(0.6, 2.0, 0.12, 100.0, 100.0),
)

mutable struct RealtimeControlState
     previous_rms::Float64
     envelope::Float64
end

function run_example()
     config = REALTIME_BROWSER_CONFIG
     url = "http://$(config.host):$(config.port)"

     println("Serving real-time browser demo at $(url)")
     println("Open $(url) in a browser, then keep this Julia process running.")
     HTTP.serve(stream -> route_stream(stream, config), config.host, config.port; stream = true)
end

function route_stream(stream, config::RealtimeBrowserConfig)
     request = stream.message

     if HTTP.WebSockets.isupgrade(request)
          return HTTP.WebSockets.upgrade(stream) do websocket
               run_realtime_loop(websocket, config)
          end
     end

     request.body = read(stream)
     closeread(stream)
     request.response = HTTP.Response(200, ["Content-Type" => "text/html; charset=utf-8"], browser_html(config))
     request.response.request = request
     startwrite(stream)
     write(stream, request.response.body)

     return nothing
end

function run_realtime_loop(websocket, config::RealtimeBrowserConfig)
     rng = MersenneTwister(512)
     input_device = preferred_input_device(config.device_name_fragment)
     stream = PortAudioStream(input_device, 1, 0; samplerate = config.sample_rate, frames_per_buffer = config.window_size)
     state = initialize_swarm(config.particle_count, config.base_params, rng)
     control_state = RealtimeControlState(0.0, 0.0)
     frame_index = 0

     println("Streaming from: $(input_device.name)")

     try
          while !HTTP.WebSockets.isclosed(websocket)
               buffer = read(stream, config.window_size)
               samples = mono_samples(buffer)
               sample_frame = AudioSampleFrame(frame_index * config.window_size / config.sample_rate, config.sample_rate, samples)
               analysis = analyze_sample_frame_dsp(sample_frame; max_frequency = config.max_frequency, spectrum_bin_count = config.spectrum_bin_count)
               control_frame = realtime_control_frame(analysis.feature, control_state, config)
               params = map_features_to_parameters(config.base_params, control_frame, config.mapping, 1.0)
               HTTP.WebSockets.send(websocket, realtime_frame_json(state, control_frame, params, config))
               step!(state, params, 1.0, rng)
               frame_index += 1
          end
     finally
          close(stream)
          println("Stopped real-time stream.")
     end
end

function realtime_control_frame(feature::AudioFeatureFrame, state::RealtimeControlState, config::RealtimeBrowserConfig)
     onset_strength = clamp01(max(0.0, feature.rms - state.previous_rms) * config.onset_scale)
     alpha = feature.rms >= state.envelope ? config.envelope_attack_alpha : config.envelope_decay_alpha
     state.envelope = clamp01(alpha * feature.rms + (1 - alpha) * state.envelope)
     state.previous_rms = feature.rms

     return AudioFeatureFrame(
          feature.time,
          state.envelope,
          feature.low_band,
          feature.mid_band,
          feature.high_band,
          feature.spectral_centroid,
          onset_strength,
     )
end

function preferred_input_device(name_fragment::AbstractString)
     input_devices = [device for device in devices() if device.input_bounds.max_channels > 0]

     for device in input_devices
          if occursin(name_fragment, device.name)
               return device
          end
     end

     available = join(["- $(device.name)" for device in input_devices], "\n")
     throw(ArgumentError("preferred input device containing \"$(name_fragment)\" was not found. Available input devices:\n$(available)"))
end

function mono_samples(buffer)
     return [Float64(buffer[index, 1]) for index in axes(buffer, 1)]
end

function realtime_frame_json(state::SwarmState, feature::AudioFeatureFrame, params::SwarmParameters, config::RealtimeBrowserConfig)
     positions = String[]
     for particle_index in axes(state.positions, 2)
          x = state.positions[1, particle_index]
          y = state.positions[2, particle_index]
          push!(positions, "[$(x),$(y)]")
     end

     return "{" *
            "\"domain_width\":$(config.domain_width)," *
            "\"domain_height\":$(config.domain_height)," *
            "\"positions\":[" * join(positions, ",") * "]," *
            "\"features\":{\"rms\":$(feature.rms),\"onset_strength\":$(feature.onset_strength)}," *
            "\"params\":{\"speed\":$(params.speed),\"noise_strength\":$(params.noise_strength)}" *
            "}"
end

clamp01(value::Real) = clamp(Float64(value), 0.0, 1.0)

function browser_html(config::RealtimeBrowserConfig)
     return """
     <!doctype html>
     <html lang="en">
     <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>SoundSwarms Live Microphone</title>
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
                    width: min(96vw, 1000px);
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
               <canvas id="swarm" width="1000" height="620"></canvas>
               <canvas id="traces" width="1000" height="260"></canvas>
          </main>
          <script>
               const swarmCanvas = document.getElementById("swarm");
               const traceCanvas = document.getElementById("traces");
               const swarmCtx = swarmCanvas.getContext("2d");
               const traceCtx = traceCanvas.getContext("2d");
               const historyLength = 240;
               const history = [];
               let latestFrame = null;

               const socket = new WebSocket(`ws://\${location.host}`);
               socket.onmessage = (event) => {
                    latestFrame = JSON.parse(event.data);
                    history.push(latestFrame);
                    if (history.length > historyLength) {
                         history.shift();
                    }
                    draw(latestFrame);
               };

               function draw(frame) {
                    drawSwarm(frame);
                    drawTraces(frame);
               }

               function drawSwarm(frame) {
                    swarmCtx.fillStyle = "rgba(5, 6, 7, 0.08)";
                    swarmCtx.fillRect(0, 0, swarmCanvas.width, swarmCanvas.height);
                    swarmCtx.fillStyle = "#78dce8";
                    for (const particle of frame.positions) {
                         const x = particle[0] / frame.domain_width * swarmCanvas.width;
                         const y = particle[1] / frame.domain_height * swarmCanvas.height;
                         swarmCtx.beginPath();
                         swarmCtx.arc(x, y, 2.0, 0, Math.PI * 2);
                         swarmCtx.fill();
                    }
               }

               function drawTraces(frame) {
                    traceCtx.fillStyle = "#050607";
                    traceCtx.fillRect(0, 0, traceCanvas.width, traceCanvas.height);

                    const leftPad = 74;
                    const rightPad = 14;
                    const topPad = 18;
                    const bottomPad = 28;
                    const plotWidth = traceCanvas.width - leftPad - rightPad;
                    const plotHeight = traceCanvas.height - topPad - bottomPad;
                    const traces = [
                         { name: "rms", color: "#78dce8", values: history.map((item) => item.features.rms) },
                         { name: "onset", color: "#ab9df2", values: history.map((item) => item.features.onset_strength) },
                         { name: "speed", color: "#a9dc76", values: history.map((item) => item.params.speed / 2.0) },
                         { name: "noise", color: "#ff6188", values: history.map((item) => item.params.noise_strength / 3.0) }
                    ];

                    traceCtx.strokeStyle = "#2f363d";
                    traceCtx.lineWidth = 1;
                    traceCtx.strokeRect(leftPad, topPad, plotWidth, plotHeight);
                    traceCtx.fillStyle = "#b8c0c7";
                    traceCtx.font = "12px system-ui";
                    traceCtx.fillText("live controls", leftPad, 13);
                    traceCtx.fillText("0", 52, topPad + plotHeight);
                    traceCtx.fillText("1", 52, topPad + 5);

                    for (const trace of traces) {
                         traceCtx.strokeStyle = trace.color;
                         traceCtx.lineWidth = 2;
                         traceCtx.beginPath();
                         for (let i = 0; i < trace.values.length; i++) {
                              const x = leftPad + (i / Math.max(1, historyLength - 1)) * plotWidth;
                              const y = topPad + (1 - Math.max(0, Math.min(1, trace.values[i]))) * plotHeight;
                              if (i === 0) {
                                   traceCtx.moveTo(x, y);
                              } else {
                                   traceCtx.lineTo(x, y);
                              }
                         }
                         traceCtx.stroke();
                    }

                    let legendX = leftPad;
                    for (const trace of traces) {
                         traceCtx.fillStyle = trace.color;
                         traceCtx.fillRect(legendX, traceCanvas.height - 16, 10, 10);
                         traceCtx.fillStyle = "#d7dde2";
                         traceCtx.fillText(trace.name, legendX + 14, traceCanvas.height - 7);
                         legendX += 110;
                    }
               }

               swarmCtx.fillStyle = "#050607";
               swarmCtx.fillRect(0, 0, swarmCanvas.width, swarmCanvas.height);
               traceCtx.fillStyle = "#050607";
               traceCtx.fillRect(0, 0, traceCanvas.width, traceCanvas.height);
          </script>
     </body>
     </html>
     """
end

run_example()
