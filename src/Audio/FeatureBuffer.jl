mutable struct AudioFeatureBuffer
     frames::Vector{AudioFeatureFrame}
     capacity::Int
     next_index::Int
     count::Int

     function AudioFeatureBuffer(capacity::Integer)
          capacity > 0 || throw(ArgumentError("capacity must be positive"))

          return new(AudioFeatureFrame[], Int(capacity), 1, 0)
     end
end

buffer_capacity(buffer::AudioFeatureBuffer) = buffer.capacity

Base.length(buffer::AudioFeatureBuffer) = buffer.count

Base.isempty(buffer::AudioFeatureBuffer) = buffer.count == 0

function push_feature!(buffer::AudioFeatureBuffer, frame::AudioFeatureFrame)
     if length(buffer.frames) < buffer.capacity
          push!(buffer.frames, frame)
     else
          buffer.frames[buffer.next_index] = frame
     end

     buffer.next_index = buffer.next_index == buffer.capacity ? 1 : buffer.next_index + 1
     buffer.count = min(buffer.count + 1, buffer.capacity)

     return buffer
end

function latest_feature(buffer::AudioFeatureBuffer)
     !isempty(buffer) || throw(ArgumentError("buffer is empty"))

     latest_index = buffer.next_index == 1 ? buffer.capacity : buffer.next_index - 1

     return buffer.frames[latest_index]
end

function Base.collect(buffer::AudioFeatureBuffer)
     ordered_frames = AudioFeatureFrame[]

     for offset in 0:(buffer.count - 1)
          index = oldest_index(buffer) + offset
          wrapped_index = mod1(index, buffer.capacity)
          push!(ordered_frames, buffer.frames[wrapped_index])
     end

     return ordered_frames
end

function oldest_index(buffer::AudioFeatureBuffer)
     if buffer.count < buffer.capacity
          return 1
     end

     return buffer.next_index
end
