using YaoTensorNetwork, Yao

nx = 4
ny = 4
depth = 8
c = rand_supremacy2d(nx, ny, depth);
reg = rand_state(nx*ny)
pl = reg |> c |> probs

using Plots
N = 2^(nx*ny)
y = exp.(-N.*pl)
x = N.*pl
order = sortperm(x)
x = x[order]
y = y[order]
plot(x, y, yscale=:log10)
