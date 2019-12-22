export EinGraph, ntensors, dump_graph, load_graph

struct EinGraph{T, AT<:AbstractArray{T}}
    tensors::Vector{AT}
    labels::Vector{NTuple{M,Int} where M}
end

function EinGraph(tensors::Vector{<:AbstractArray}, labels)
    T = promote_type(eltype.(tensors)...)
    EinGraph([eltype(t) == T ? t : T.(t) for t in tensors], (NTuple{M,Int} where M)[labels...])
end

function Base.:(==)(gb1::EinGraph, gb2::EinGraph)
    gb1.tensors == gb2.tensors && gb1.labels == gb2.labels
end
function Base.:(≈)(gb1::EinGraph, gb2::EinGraph)
    gb1.tensors ≈ gb2.tensors && gb1.labels == gb2.labels
end
Base.eltype(eg::EinGraph{T}) where T = T
Base.eltype(::Type{<:EinGraph{T}}) where T = T

function Base.show(io::IO, gb::EinGraph)
    println(io, summary(gb))
    for i=1:ntensors(gb)
        println(io, " T[$(join(gb.labels[i], ","))]($(join(size(gb.tensors[i]), ", ")))")
    end
end

ntensors(gb::EinGraph) = length(gb.tensors)

function dump_graph(prefix::String, eg::EinGraph{T}) where T
    open(prefix*".tensors.dat", "w") do io
        for t in eg.tensors
            writedlm(io, transpose(reinterpret(real(T), vec(t))))
        end
    end
    open(prefix*".sizes.dat", "w") do io
        for t in eg.tensors
            writedlm(io, [size(t)...]')
        end
    end
    open(prefix*".labels.dat", "w") do io
        for l in eg.labels
            writedlm(io, [l...]')
        end
    end
end

function load_graph(::Type{T}, prefix::String) where T
    vecs = []
    datas = read_line_by_line(real(T), prefix*".tensors.dat")
    sizes = read_line_by_line(Int, prefix*".sizes.dat")
    labels = read_line_by_line(Int, prefix*".labels.dat")
    T <: Complex && (datas = copy.(reinterpret.(T, datas)))
    datas = map((x,y)->reshape(x, y...), datas, sizes)
    EinGraph(datas, [(l...,) for l in labels])
end

function graph2strings(eg::YaoTensorNetwork.EinGraph{T}) where T
    res = String[]
    io = IOBuffer()
    for t in eg.tensors
        writedlm(io, transpose(reinterpret(real(T), vec(t))))
    end
    push!(res, String(take!(io)))
    for t in eg.tensors
        writedlm(io, [size(t)...]')
    end
    push!(res, String(take!(io)))
    for l in eg.labels
        writedlm(io, [l...]')
    end
    push!(res, String(take!(io)))
    res
end
