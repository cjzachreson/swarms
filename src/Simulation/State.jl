struct SwarmState
     positions::Matrix{Float64}
     headings::Vector{Float64}

     function SwarmState(positions::AbstractMatrix{<:Real}, headings::AbstractVector{<:Real})
          size(positions, 1) == 2 || throw(ArgumentError("positions must have shape 2 x n"))
          size(positions, 2) == length(headings) || throw(ArgumentError("positions and headings must describe the same number of particles"))

          return new(Matrix{Float64}(positions), Vector{Float64}(headings))
     end
end
