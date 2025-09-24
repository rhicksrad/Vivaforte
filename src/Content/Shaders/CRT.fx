sampler TextureSampler : register(s0);

float CRTIntensity = 0.0f;
float2 TextureSize = float2(1600.0f, 900.0f);

float4 MainPS(float4 position : SV_POSITION, float4 color : COLOR0, float2 texCoord : TEXCOORD0) : SV_TARGET
{
    float4 sample = tex2D(TextureSampler, texCoord) * color;
    float3 rgb = sample.rgb;
    float alpha = sample.a;

    float intensity = saturate(CRTIntensity);
    float extra = max(CRTIntensity - 1.0f, 0.0f);

    float2 centered = texCoord * 2.0f - 1.0f;
    float dist = dot(centered, centered);
    float vignette = saturate(1.0f - 0.35f * dist);

    float scan = 1.0f;
    if (TextureSize.y > 0.0f)
    {
        float wave = sin(texCoord.y * TextureSize.y * 3.14159265f);
        scan = saturate(1.0f - 0.18f * wave * wave);
    }

    float attenuation = vignette * scan;
    float3 modulated = lerp(rgb, rgb * attenuation, intensity);
    float glowStrength = 0.08f * intensity + 0.12f * extra;
    float3 glow = rgb * glowStrength;

    float3 finalColor = saturate(modulated + glow);
    return float4(finalColor, alpha);
}

technique Technique1
{
    pass P0
    {
        PixelShader = compile ps_3_0 MainPS();
    }
}
