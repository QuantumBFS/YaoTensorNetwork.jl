export read_line_by_line, xor_tensor

"""read a file to data type T line by line, and convert to a vector."""
function read_line_by_line(::Type{T}, filename::String) where T
    map.(s -> parse(T, s), split.(eachline(filename), '\t'))
end

function control3(::Type{T}; inverse::Bool=false) where {T}
    tensor = zeros(T, 2,2,2)
    a, b = [1,0], [0,1]
    tensor[1,1,:] .= inverse ? b : a
    tensor[2,2,:] .= inverse ? a : b
    return tensor
end

function control4(::Type{T}; inverse::Bool=false) where {T}
    tensor = zeros(T, 2,2,2,2)
    a, b = [1,0], [0,1]
    tensor[1,1,1,:] .= a
    tensor[2,2,1,:] .= a
    tensor[1,1,2,:] .= inverse ? b : a
    tensor[2,2,2,:] .= inverse ? a : b
    return tensor
end

function xor_tensor(::Type{T}) where {T}
    tensor = zeros(T, 2,2,2)
    tensor[:,:,1] .= [1 0; 0 1]
    tensor[:,:,2] .= [0 1; 1 0]
    return tensor
end
