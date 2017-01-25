package khage.g4;

typedef Stencil = {
    mode : kha.graphics4.CompareMode,
    bothPass : kha.graphics4.StencilAction,
    depthFail : kha.graphics4.StencilAction,
    fail : kha.graphics4.StencilAction,
    referenceValue : Int,
    readMask : Int,
    writeMask : Int
}

typedef Depth = {
    write:Bool,
    mode:kha.graphics4.CompareMode
}

typedef Blend = {
    source : kha.graphics4.BlendingFactor,
    destination : kha.graphics4.BlendingFactor
}

typedef Cull = {
    mode:kha.graphics4.CullMode
}

typedef PipelineConf = {
    ?stencil : Stencil,
    ?depth : Depth,
    ?cull : Cull,
    ?blend : Blend,
    ?inputLayout : Array<kha.graphics4.VertexStructure>
}