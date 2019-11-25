# Dump Circuits

## Setup
Please install Fire by typing `] add Fire` in a Julia REPL.

## Examples
```bash
julia dump_circuit.jl supremacy2d 6 8 10  # nx, ny, depth
julia dump_circuit.jl variational2d 6 8 10  # nx, ny, depth
julia dump_circuit.jl variational 6 10  # n, depth
julia dump_circuit.jl qft 6  # n
julia dump_circuit.jl google53 10  # depth
```
