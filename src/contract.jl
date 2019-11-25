using OMEinsum

function contract(gb::EinGraph)
    EinCode((gb.labels...,), ())(gb.tensors...)[]
end
