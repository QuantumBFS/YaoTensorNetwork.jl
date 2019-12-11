export attach_gate!, contract, circuit2tn

_tmat(blk) = transpose(Matrix(mat(ComplexF64, blk)))

function attach_gate!(gb::GraphBuilder, tree::ChainBlock{N}) where N
    for b in subblocks(tree)
        attach_gate!(gb, b)
    end
end

function attach_gate!(gb::GraphBuilder, tree::PutBlock{N}) where N
    tn_attach!(gb, tree.locs=>_tmat(content(tree)))
end

function attach_gate!(gb::GraphBuilder, tree::PutBlock{N,2,<:SWAPGate}) where N
    swaplines!(gb, tree.locs...)
end

function attach_gate!(gb::GraphBuilder, tree::PutBlock{N,C,<:RotationGate{C,T,<:KronBlock{C,C2,<:NTuple{C2,AbstractBlock{1}}}}}) where {N,C,C2,T}
    tensors = Any[]
    if seperatecontrol()
        rt = content(tree)
        kr = rt.block
        for (i,loc_) in enumerate(kr.locs)
            loc = tree.locs[loc_]
            mi = IMatrix{2}()
            mk = _tmat(kr[loc_])
            if i==1
                mi = cos(rt.theta/2)*mi
                mk = -im*sin(rt.theta/2)*mk
            end
            if i==1 || i==length(kr.locs)
                tensor = zeros(ComplexF64,2,2,2)
                tensor[:,:,1] = mi
                tensor[:,:,2] = mk
            else
                tensor = zeros(ComplexF64,2,2,2,2)
                tensor[:,:,1,1] = mi
                tensor[:,:,2,2] = mk
            end
            push!(tensors, (loc...,)=>tensor)
        end
        tn_attach!(gb, tensors...)
    else
        tn_attach!(gb, tree.locs=>_tmat(content(tree)))
    end
end

function attach_gate!(gb::GraphBuilder, tree::ControlBlock{N,GT,C,M}) where {N,GT,C,M}
    if seperatecontrol()
        tensors = Any[]
        for i in 1:C
            cbit = tree.ctrl_locs[i]
            cval = tree.ctrl_config[i]
            tensor = i == 1 ? control3(ComplexF64;inverse=cval==0) : control4(ComplexF64;inverse=cval==0)
            push!(tensors, (cbit,)=>tensor)
        end
        tensor = zeros(ComplexF64, 2^M, 2^M, 2)
        tensor[1:2^(2*M)] .= vec(IMatrix{1<<M}())
        tensor[end-2^(2*M)+1:end] .= vec(_tmat(content(tree)))
        tn_attach!(gb, tensors..., tree.locs=>tensor)
    else
        locs = (tree.ctrl_locs..., tree.locs...)
        address = zeros(Int, N)
        address[[locs...]] .= 1:C+M
        c = map_address(tree, AddressInfo(C+M, address))
        tn_attach!(gb, locs=>Matrix(c))
    end
end

function circuit2tn(c::AbstractBlock; initial_config=zeros(Int,nqubits(c)), final_config=zeros(Int, nqubits(c)))
    gb = GraphBuilder(initial_config)
    attach_gate!(gb, c)
    finish!(gb, final_config)
    return generate_eingraph(gb)
end
