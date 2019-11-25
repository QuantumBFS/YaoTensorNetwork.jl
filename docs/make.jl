using Documenter, YaoTensorNetwork

makedocs(;
    modules=[YaoTensorNetwork],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/GiggleLiu/YaoTensorNetwork.jl/blob/{commit}{path}#L{line}",
    sitename="YaoTensorNetwork.jl",
    authors="JinGuo Liu, Pan Zhang, Lei Wang",
    assets=String[],
)

deploydocs(;
    repo="github.com/GiggleLiu/YaoTensorNetwork.jl",
)
