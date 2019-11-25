import YaoBlocks.Optimise.to_basictypes
export simplify_blocktypes

function to_basictypes_ex(pb::PutBlock{N,C,<:ChainBlock}) where {N,C}
    chain(N, [put(N, pb.locs=>b) for b in subblocks(content(pb))])
end

function to_basictypes_ex(pb::PutBlock{N,C,<:ControlBlock}) where {N,C}
    c = content(pb)
    ControlBlock{N}(map(loc->pb.locs[loc], c.ctrl_locs), c.ctrl_config,
            content(c), map(loc->pb.locs[loc], c.locs))
end

function to_basictypes_ex(pb::PutBlock{N,C,<:PutBlock}) where {N,C}
    c = content(pb)
    PutBlock{N}(content(c), map(loc->pb.locs[loc], c.locs))
end
to_basictypes_ex(pb::AbstractBlock) = pb

simplify_blocktypes(c) = simplify(c, rules=[to_basictypes, to_basictypes_ex])
