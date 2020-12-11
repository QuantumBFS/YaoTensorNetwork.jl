export GraphBuilder, nlines, maxorder
export assign_label!, add!, tn_attach!, finish!
export generate_eingraph

mutable struct GraphBuilder{T}
    lines::Vector{Int}
    tensors::Vector{AbstractArray{T,N} where N}
    labels::Vector{Tuple}
    label_counter::Int
end

function swaplines!(gb::GraphBuilder, i::Int, j::Int)
    li = gb.lines[i]
    gb.lines[i] = gb.lines[j]
    gb.lines[j] = li
    return gb
end

function GraphBuilder(::Type{T}, config::Union{Vector{Int}, BitStr}) where T
    n = length(config)
    tensors = (AbstractArray{T,N} where N)[c == 0 ? T[1, 0.0] : T[0.0, 1] for c in config]
    GraphBuilder(collect(1:n), tensors, Vector{Tuple}([(i,) for i=1:n]), n)
end
GraphBuilder(config::Union{Vector{Int}, BitStr}) = GraphBuilder(ComplexF64, config)
GraphBuilder(n::Int) = GraphBuilder(zeros(Int,n))

nlines(gb::GraphBuilder) = length(gb.lines)
ntensors(gb::GraphBuilder) = length(gb.tensors)
maxorder(gb::GraphBuilder) = maximum(ndims, gb.tensors)
function assign_label!(gb::GraphBuilder, lineno::Int)
    olabel = gb.lines[lineno]
    nlabel = gb.label_counter+=1
    gb.lines[lineno] = nlabel
    olabel, nlabel
end

assign_label!(gb::GraphBuilder) = gb.label_counter+=1

function add!(gb::GraphBuilder, tensor::AbstractArray{T,N}, label::NTuple{N,Int}) where {T,N}
    push!(gb.tensors, tensor)
    push!(gb.labels, label)
end

function tn_attach!(gb::GraphBuilder, gate::Pair{Int,<:AbstractArray{T2,2}}) where {T2}
    a, b = assign_label!(gb, gate.first)
    add!(gb, gate.second, (a,b))
    gb
end

function tn_attach!(gb::GraphBuilder, gate::Pair{NTuple{M,Int},<:AbstractArray}; pre::Int=-1, hasnext::Bool=false) where {M}
    @assert M == log2dim1(gate.second)
    as, bs = zip([assign_label!(gb, loc) for loc in gate.first]...)
    prenex = Int[]
    pre > 0 && push!(prenex, pre)
    hasnext && push!(prenex, assign_label!(gb))
    tensor = reshape(gate.second, fill(2,2*M+length(prenex))...)
    add!(gb, tensor, (as..., bs..., prenex...))
    gb
end

function tn_attach!(gb::GraphBuilder, gates::Pair...)
    ng = length(gates)
    ng == 0 && return gb

    local b
    for i=1:ng
        gate = gates[i]
        tn_attach!(gb, gate; pre=i==1 ? -1 : gb.label_counter, hasnext=i!=ng)
    end
    gb
end

function finish!(gb::GraphBuilder, config::Union{Vector{Int}, BitStr})
    @assert length(config) == nlines(gb)
    for i=1:nlines(gb)
        add!(gb, config[i]==1 ? [0.0im, 1] : [1, 0.0im], (gb.lines[i],))
    end
    gb.lines .= -1
    gb
end

function tn_pop!(gb::GraphBuilder)
    t = pop!(gb.tensors)
    l = pop!(gb.labels)
    # tensors labels must be arrange as `left` first, then `right` and finally `up` and `down`.
    nconnect = findfirst(x->x in gb.lines, l) - 1
    if !(nconnect isa Nothing)
        for i=1:nconnect
            # find and restore the line
            for j=1:nlines(gb)
                if gb.lines[j] == l[nconnect+i]
                    gb.lines[j] = l[i]
                end
            end
        end
    end
    return (t, l)
end

function reset_final!(gb::GraphBuilder, config::Union{Vector{Int},BitStr})
    n = nlines(gb)
    nt = ntensors(gb)
    gb.lines = [(@assert length(gb.labels[nt-n+i]) == 1; gb.labels[nt-n+i][1]) for i=1:n]
    gb.tensors = gb.tensors[1:end-n]
    gb.labels = gb.labels[1:end-n]
    finish!(gb, config)
end

function generate_eingraph(gb::GraphBuilder)
    EinGraph([gb.tensors...], gb.labels)
end
maxorder(gb::EinGraph) = maximum(ndims, gb.tensors)
