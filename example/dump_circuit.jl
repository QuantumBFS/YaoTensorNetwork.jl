using Yao
using YaoExtensions, YaoTensorNetwork, BitBasis
using YaoBlocks.Optimise
using Fire

# the switch for seperating control gates
sepctrl = false
seperatecontrol(sepctrl)
rk = 4-sepctrl

@main function qft(nbit::Int)
    config = bit_literal(ones(Int,nbit)...)   # final output config
    c = qft_circuit(nbit)
    gb = circuit2tn(c, final_config=config)
    dump_graph(joinpath(@__DIR__, "graphs", "qft$nbit-rank$rk"), gb)
end

@main function variational(nbit::Int, depth::Int)
    c = variational_circuit(nbit, depth, pair_square(isqrt(nbit), isqrt(nbit); periodic=false))
    gb = circuit2tn(c)  # collapse to 00000 state
    dump_graph(joinpath(@__DIR__, "graphs", "variational$nbit-d$depth-rank$rk"), gb)
end

@main function variational2d(nx::Int, ny::Int, depth::Int)
    nbit = nx*ny
    c = variational_circuit(nbit, depth, pair_square(nx, ny; periodic=false))
    gb = circuit2tn(c)  # collapse to 00000 state
    dump_graph(joinpath(@__DIR__, "graphs", "variational2d$nbit-d$depth-rank$rk"), gb)
end

# dump supremacy circuit
@main function supremacy2d(nx::Int, ny::Int, depth::Int, seed::Int=1)
    nbit = nx*ny
    c = rand_supremacy2d(nx, ny, depth; seed=seed)
    gb = circuit2tn(simplify_blocktypes(c))  # collapse to 00000 state
    dump_graph(joinpath(@__DIR__, "graphs", "supremacy2d$nbit-d$depth-rank$rk"), gb)
end

# dump supremacy circuit
@main function google53(depth::Int, nbits::Int=53, seed::Int=1)
    c = rand_google53(depth; seed=seed, nbits=nbits)
    fs = FSimGate(0.5π, π/6)
    if sepctrl
        c = replace_block(fs => openbox(fs), c)
    end
    gb = circuit2tn(simplify_blocktypes(c))  # collapse to 00000 state
    dump_graph(joinpath(@__DIR__, "graphs", "google53$nbits-d$depth-rank$rk"), gb)
end
