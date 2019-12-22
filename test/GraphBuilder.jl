using YaoTensorNetwork, Yao
using Test, BitBasis
using YaoExtensions
using OMEinsum
using YaoBlocks.Optimise

@testset "GraphBuilder" begin
    gb = GraphBuilder(4)
    @test nlines(gb) == 4
    label = assign_label!(gb)
    @test label == 5
    tn_attach!(gb, 2=>Matrix(mat(X)))
    @test length(gb.tensors) == 5
    @test gb.label_counter == 6
    @test gb.lines == [1,6,3,4]
    tn_attach!(gb, (1,2)=>Matrix(mat(SWAP)))
    @test gb.label_counter == 8
    @test gb.lines == [7,8,3,4]
    tn_attach!(gb, (1,2)=>randn(ComplexF64, 4,4,2), (4,)=>randn(ComplexF64, 2,2,2))
    @test gb.label_counter == 12
    @test length(gb.labels) == ntensors(gb) == 8
    @test gb.lines == [9,10,3,12]
end

@testset "dump graph" begin
    nbit = 6
    config = bit_literal(ones(Int,nbit)...)   # final output config

    c = qft_circuit(nbit)
    gb = circuit2tn(c, final_config=config)
    @test contract(gb) ≈ select(zero_state(nbit) |> c, config).state[]

    dump_graph("_qft", gb)
    gb2 = load_graph(eltype(gb),"_qft")
    @test gb ≈ gb2
    @test contract(gb2) ≈ select(zero_state(nbit) |> c, config).state[]
end

@testset "circuit build" begin
    c = rand_google53(4)
    @test length(collect_blocks(FSimGate, c)) == 86
    @test nparameters(c) == 86*2
    @test length(collect_blocks(PrimitiveBlock{1}, c)) == 53*4
end

@testset "gates" begin
    @test isunitary(FSimGate(0.5, 0.6))
    fs = FSimGate(π/2, π/6)
    cphase(nbits, i::Int, j::Int, θ::T) where T = control(nbits, i, j=>shift(θ))
    ic = ISWAP*cphase(2, 2, 1, π/6)
    @test mat(fs) ≈ mat(ic)'
    ISWAP_ = SWAP*rot(kron(Z,Z), π/2)
    @test Matrix(ISWAP) ≈ Matrix(ISWAP_)*exp(im*π/4)
    fs_ = openbox(fs)
    @test mat(fs) ≈ Matrix(fs_)

    c  = chain(put(3,(3,1)=>fs), chain(put(3,(1,2)=>fs), put(3, (1,3)=>fs), put(3, (3,2)=>fs)))
    c_ = simplify_blocktypes(replace_block(fs=>fs_, c))
    c  = chain(put(3,(3,1)=>fs_), chain(put(3,(1,2)=>fs_), put(3, (1,3)=>fs_), put(3, (3,2)=>fs_)))

    @test Matrix(c) ≈ Matrix(simplify_blocktypes(c_))

    # add swap
    for config in basis(BitStr64{3})
        seperatecontrol(true)
        gb = circuit2tn(c_; final_config=config)
        @test maxorder(gb) == 3
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]

        seperatecontrol(false)
        gb = circuit2tn(c_; final_config=config)
        @test maxorder(gb) == 4
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end
end
