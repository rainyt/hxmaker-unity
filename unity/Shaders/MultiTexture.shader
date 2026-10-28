Shader "Hxmaker/MultiTexture"
{
    Properties
    {
        _HxTex0("纹理 0", 2D) = "white" {}
        _HxTex1("纹理 1", 2D) = "white" {}
        _HxTex2("纹理 2", 2D) = "white" {}
        _HxTex3("纹理 3", 2D) = "white" {}
        _HxTex4("纹理 4", 2D) = "white" {}
        _HxTex5("纹理 5", 2D) = "white" {}
        _HxTex6("纹理 6", 2D) = "white" {}
        _HxTex7("纹理 7", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue"="Overlay" "RenderType"="Transparent" }
        Pass
        {
            ZTest Always
            ZWrite Off
            Cull Off
            Blend One OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vertex
            #pragma fragment Fragment
            // 所有槽位变体均随构建保留，不能被材质静态扫描裁剪。
            #pragma multi_compile_local _ HX_TEXTURES_4 HX_TEXTURES_8
            #include "UnityCG.cginc"
            Texture2D _HxTex0;
            #if defined(HX_TEXTURES_4) || defined(HX_TEXTURES_8)
            Texture2D _HxTex1, _HxTex2, _HxTex3;
            #endif
            #if defined(HX_TEXTURES_8)
            Texture2D _HxTex4, _HxTex5, _HxTex6, _HxTex7;
            #endif
            // 显式采样器避免为平滑与像素风批次修改共享纹理的全局过滤模式。
            SamplerState hx_linear_clamp_sampler;
            SamplerState hx_point_clamp_sampler;
            float _HxSmooth;
            float4 _HxResolution;
            float4 _HxClip;
            struct Input
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float4 offset : TEXCOORD1;
                float4 properties : TEXCOORD2;
            };
            struct Varying
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float4 offset : TEXCOORD1;
                float4 properties : TEXCOORD2;
                float2 logical : TEXCOORD3;
            };
            Varying Vertex(Input input)
            {
                Varying output;
                output.position = float4(input.position.x / _HxResolution.x * 2 - 1, 1 - input.position.y / _HxResolution.y * 2, 0, 1);
                output.logical = input.position.xy;
                output.uv = float2(input.uv.x, 1 - input.uv.y);
                output.color = input.color; output.offset = input.offset; output.properties = input.properties;
                return output;
            }
            #define HX_SAMPLE(texture) (_HxSmooth > 0.5 ? texture.Sample(hx_linear_clamp_sampler, input.uv) : texture.Sample(hx_point_clamp_sampler, input.uv))
            float4 Fragment(Varying input) : SV_Target
            {
                clip(input.logical - _HxClip.xy);
                clip(_HxClip.zw - input.logical);
                float id = input.properties.y;
                float4 color;
                #if defined(HX_TEXTURES_8)
                if (id > 6.5) color = HX_SAMPLE(_HxTex7);
                else if (id > 5.5) color = HX_SAMPLE(_HxTex6);
                else if (id > 4.5) color = HX_SAMPLE(_HxTex5);
                else if (id > 3.5) color = HX_SAMPLE(_HxTex4);
                else
                #endif
                #if defined(HX_TEXTURES_4) || defined(HX_TEXTURES_8)
                if (id > 2.5) color = HX_SAMPLE(_HxTex3);
                else if (id > 1.5) color = HX_SAMPLE(_HxTex2);
                else if (id > 0.5) color = HX_SAMPLE(_HxTex1);
                else
                #endif
                color = HX_SAMPLE(_HxTex0);
                color = saturate(color * input.color + input.offset);
                color.a *= saturate(input.properties.x) * saturate(input.properties.w);
                color.rgb *= color.a;
                // ADD 顶点把混合 alpha 归零，仍保留已乘透明度的 RGB。
                color.a *= 1 - step(0.5, input.properties.z);
                return color;
            }
            ENDHLSL
        }
    }
}
