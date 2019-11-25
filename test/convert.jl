using Yao, YaoBlocks.Optimise
using YaoTensorNetwork
using Test
using YaoExtensions
using BitBasis

@testset "generate" begin
    @test seperatecontrol() == false
    for sep in [true, false]
        seperatecontrol(sep)
        gb = GraphBuilder(4)
        attach_gate!(gb, put(4,3=>X))
        @test gb.lines == [1,2,5,4]
        attach_gate!(gb, control(4,2,3=>X))
        @test gb.lines == [1,6,7+sep,4]
        finish!(gb, [0,0,1,0])
        @test gb.lines == [-1,-1,-1,-1]
        @test ntensors(gb) == 10 + sep
        @test contract(generate_eingraph(gb)) ≈ 1
    end
end

@testset "circuit contract" begin
    nbit = 2
    # single qubit gates
    c = chain(put(2, 1=>Rx(0.5)), put(2,2=>Rx(1.5)))
    gb = circuit2tn(c)
    @test contract(gb) ≈ select(zero_state(nbit) |> c, bit"00").state[]

    # add cz
    c = chain(put(2, 1=>Rx(0.5)), put(2,2=>Rx(1.5)), control(2, 2, 1=>Z))
    for config in basis(BitStr64{2})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(nbit) |> c, config).state[]
    end

    # add cnot
    c = chain(put(2, 1=>Rx(0.5)), put(2,2=>Rx(1.5)), control(2, 2, 1=>X))
    for config in basis(BitStr64{2})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(nbit) |> c, config).state[]
    end

    # add swap
    c = chain(put(3, 1=>Rx(0.5)), put(3,2=>Rx(1.5)), put(3,3=>Rx(2.5)), put(3, (1,3)=>SWAP))
    for config in basis(BitStr64{3})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end

    # put rot kron
    c = chain(put(3, (2,3)=>rot(kron(X,Y), 0.5)), put(3,2=>Rx(1.5)))
    seperatecontrol(true)
    for config in basis(BitStr64{3})
        gb = circuit2tn(c; final_config=config)
        @test maximum(ndims, gb.tensors) == 3
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end

    # add control swap
    c = chain(put(3, 1=>Rx(0.5)), put(3,2=>Rx(1.5)), put(3,3=>Rx(2.5)), control(3, 2, (1,3)=>SWAP))
    for config in basis(BitStr64{3})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end

    # add i-cnot
    c = chain(put(3, 1=>Rx(0.5)), put(3,2=>Rx(1.5)), put(3,3=>Rx(2.5)), control(3, -2, (1,3)=>SWAP))
    for config in basis(BitStr64{3})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end

    # add multi-control
    c = chain(put(3, 1=>Rx(0.5)), put(3,2=>Rx(1.5)), put(3,3=>Rx(2.5)), control(3, (1,2), 3=>X))
    for config in basis(BitStr64{3})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end

    # add multi-control with inverse
    c = chain(put(3, 1=>Rx(0.5)), put(3,2=>Rx(1.5)), put(3,3=>Rx(2.5)), control(3, (1,-2), 3=>X))
    for config in basis(BitStr64{3})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end

    # add two qubit matblock
    u1 = rand_unitary(4)
    u2 = rand_unitary(4)
    c = chain(3,put((1,2)=>matblock(u1)), put((2,3)=>matblock(u2)))
    for config in basis(BitStr64{3})
        gb = circuit2tn(c; final_config=config)
        @test contract(gb) ≈ select(zero_state(3) |> c, config).state[]
    end

    # random circuit
    nbit = 2
    c = dispatch!(variational_circuit(nbit, 1, [1=>2]), :random)
    for config in basis(BitStr64{nbit})
        gb = circuit2tn(c, final_config=config)
        @test contract(gb) ≈ select(zero_state(nbit) |> c, config).state[]
    end

    # qft circuit
    nbit = 4
    c = QFTCircuit(4)
    for sep in [true, false]
        seperatecontrol(sep)
        for config in basis(BitStr64{nbit})
            gb = circuit2tn(c, final_config=config)
            @test contract(gb) ≈ select(zero_state(nbit) |> c, config).state[]
        end
    end

    # supremacy 2d circuit
    nx, ny = 2, 2
    c = rand_supremacy2d(nx, ny, 6)
    c = simplify_blocktypes(c)
    deleteat!(c[2].blocks, 1)
    for sep in [true, false]
        seperatecontrol(sep)
        for config in basis(BitStr64{nbit})
            gb = circuit2tn(c, final_config=config)
            l = contract(gb)
            r = select(zero_state(nbit) |> c, config).state[]
            @test isapprox(l, r; atol=1e-8)
        end
    end

    nx, ny = 2, 2
    nbit = nx*ny
    c = variational_circuit(nbit, 1, pair_square(nx, ny; periodic=false))
    dispatch!(c, :random)
    for sep in [true, false]
        seperatecontrol(sep)
        for config in basis(BitStr64{nbit})
            gb = circuit2tn(c, final_config=config)
            #@show contract(gb)
            @test contract(gb) ≈ select(zero_state(nbit) |> c, config).state[]
        end
    end
end

@testset "saveload" begin
    nbit = 2
    c = dispatch!(variational_circuit(nbit, 1, [1=>2]), :random)
    gb = circuit2tn(c, final_config=bit"01")
    dump_graph("_test", gb)
    gb2 = load_graph(eltype(gb),"_test")
    @test gb ≈ gb2
end
