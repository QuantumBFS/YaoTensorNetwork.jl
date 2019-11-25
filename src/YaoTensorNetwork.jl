module YaoTensorNetwork

using BitBasis
using Yao, LuxurySparse
using DelimitedFiles
using Random
using Requires
using YaoBlocks.Optimise

const control_seperated = Ref(false)

export seperatecontrol
"""
    seperatecontrol([val::Bool])

Global switch, seperate control into rank tree tensors if true.
set value if `val` provided.
"""
function seperatecontrol(val::Bool)
    control_seperated[] = val
end

seperatecontrol() = control_seperated[]

include("utils.jl")
include("EinGraph.jl")
include("GraphBuilder.jl")
include("convert.jl")
include("tobasic_ext.jl")

@init @require OMEinsum = "ebe7aa44-baf0-506c-a96f-8464559b3922" include("contract.jl")

end # module
