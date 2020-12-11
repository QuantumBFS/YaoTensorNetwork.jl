export attach_gate!, contract, circuit2tn

_tmat(::Type{T}, blk) where T = transpose(Matrix(mat(T, blk)))

function attach_gate!(gb::GraphBuilder, tree::ChainBlock{N}) where N
    for b in subblocks(tree)
        attach_gate!(gb, b)
    end
end

function attach_gate!(gb::GraphBuilder{T}, tree::PutBlock{N}) where {T,N}
    tn_attach!(gb, tree.locs=>_tmat(T, content(tree)))
end

function attach_gate!(gb::GraphBuilder, tree::PutBlock{N,2,<:SWAPGate}) where N
    swaplines!(gb, tree.locs...)
end

function attach_gate!(gb::GraphBuilder{T}, tree::PutBlock{N,C,<:RotationGate{C,TR,<:KronBlock{C,C2,<:NTuple{C2,AbstractBlock{1}}}}}) where {N,C,C2,TR,T}
    tensors = Any[]
    if seperatecontrol()
        rt = content(tree)
        kr = rt.block
        for (i,loc_) in enumerate(kr.locs)
            loc = tree.locs[loc_]
            mi = IMatrix{2}()
            mk = _tmat(T, kr[loc_])
            if i==1
                mi = cos(rt.theta/2)*mi
                mk = -im*sin(rt.theta/2)*mk
            end
            if i==1 || i==length(kr.locs)
                tensor = zeros(T,2,2,2)
                tensor[:,:,1] = mi
                tensor[:,:,2] = mk
            else
                tensor = zeros(T,2,2,2,2)
                tensor[:,:,1,1] = mi
                tensor[:,:,2,2] = mk
            end
            push!(tensors, (loc...,)=>tensor)
        end
        tn_attach!(gb, tensors...)
    else
        tn_attach!(gb, tree.locs=>_tmat(T, content(tree)))
    end
end

function attach_gate!(gb::GraphBuilder{T}, tree::ControlBlock{N,GT,C,M}) where {N,GT,C,M,T}
    if seperatecontrol()
        tensors = Any[]
        for i in 1:C
            cbit = tree.ctrl_locs[i]
            cval = tree.ctrl_config[i]
            tensor = i == 1 ? control3(T;inverse=cval==0) : control4(T;inverse=cval==0)
            push!(tensors, (cbit,)=>tensor)
        end
        tensor = zeros(T, 2^M, 2^M, 2)
        tensor[1:2^(2*M)] .= vec(IMatrix{1<<M}())
        tensor[end-2^(2*M)+1:end] .= vec(_tmat(T, content(tree)))
        tn_attach!(gb, tensors..., tree.locs=>tensor)
    else
        locs = (tree.ctrl_locs..., tree.locs...)
        address = zeros(Int, N)
        address[[locs...]] .= 1:C+M
        c = map_address(tree, AddressInfo(C+M, address))
        tn_attach!(gb, locs=>Matrix(c))
    end
end

function circuit2tn(::Type{T}, c::AbstractBlock; initial_config=zeros(Int,nqubits(c)), final_config=zeros(Int, nqubits(c))) where T
    gb = GraphBuilder(T, initial_config)
    attach_gate!(gb, c)
    finish!(gb, final_config)
    return generate_eingraph(gb)
end

circuit2tn(c::AbstractBlock; initial_config=zeros(Int,nqubits(c)), final_config=zeros(Int, nqubits(c))) = circuit2tn(ComplexF64, c; initial_config=initial_config, final_config=final_config)

function opennetwork(c::AbstractBlock{N}) where N
    gb = GraphBuilder(zeros(Int, N))
    gb.tensors = gb.tensors[N+1:end]
    gb.labels = gb.tensors[N+1:end]
    attach_gate!(gb, c)
    return generate_eingraph(gb)
end
