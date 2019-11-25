# TensorQC

Converting Quantum Circuit to tensor networks

To start, open a Julia REPL and type `]` to enter pkg mode, install dependancies by
```julia
pkg> add Yao LuxurySparse BitBasis DelimitedFiles OMEinsum
pkg> dev YaoExtensions
pkg> dev git@gitlab.theory.iphy.ac.cn:codes/tensorqc.git
```

If the second line does not work, please try clone and `pkg> dev .` at top level folder.

## Learn by Example
```julia
julia> using Yao, YaoExtensions, YaoTensorNetwork

julia> c = dispatch!(variational_circuit(2, 1, [1=>2]), :random);

julia> eg = circuit2tn(c; initial_config=bit"00", final_config=bit"11")
EinGraph{Complex{Float64},Array{Complex{Float64},N} where N}
 T[1](2)
 T[2](2)
 T[1,3](2, 2)
 T[3,4](2, 2)
 T[2,5](2, 2)
 T[5,6](2, 2)
 T[4,7,8](2, 2, 2)
 T[6,9,8](2, 2, 2)
 T[7,10](2, 2)
 T[10,11](2, 2)
 T[9,12](2, 2)
 T[12,13](2, 2)
 T[11](2)
 T[13](2)


julia> res = contract(eg)
-0.005533928306495697 - 0.21124814706199962im

julia> dump_graph("_test", eg);

julia> eg2 = load_graph(eltype(eg), "_test");
```
