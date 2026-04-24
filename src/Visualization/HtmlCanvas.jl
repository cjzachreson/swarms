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
