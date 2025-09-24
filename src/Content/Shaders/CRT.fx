sampler TextureSampler : register(s0);

float4 MainPS(float4 position : SV_POSITION, float4 color : COLOR0, float2 texCoord : TEXCOORD0) : SV_TARGET
{
    return tex2D(TextureSampler, texCoord) * color;
}

technique Technique1
{
    pass P0
    {
        PixelShader = compile ps_3_0 MainPS();
    }
}
