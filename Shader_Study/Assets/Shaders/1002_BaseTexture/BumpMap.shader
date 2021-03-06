﻿//Blinn-Phong模型
//漫反射用半兰伯特
//逐像素
//Shader "Custom/Base_Texture/Specular_HL_BP_Frag_BumpTexture"
Shader "Custom/Base_Texture/BumpMap" {
    Properties {
                _MainText("MainText",2D)="white"{}                
                _BumpMap("BumpMap",2D)="white"{}
        }
        SubShader {
                pass{
                Tags{"LightMode"="ForwardBase"}
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
 
                float4 _LightColor0;
                sampler2D _BumpMap;
                fixed4    _BumpMap_ST;
                sampler2D _MainText;
                fixed4    _MainText_ST;

                struct v2f {
                        float4 pos:SV_POSITION;
                        float4 uv:TEXCOORD0;
                        float3 lightDir:TEXCOORD1;
                };
 
                v2f vert (appdata_full v) {
                        v2f o;
                        o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
                        
                        o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainText);
                        o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
                        TANGENT_SPACE_ROTATION;
                        o.lightDir= mul(_World2Object, _WorldSpaceLightPos0).xyz;//Direction Light
                        o.lightDir=mul(rotation,o.lightDir);
                        return o;
                }
                float4 frag(v2f i):COLOR
                {
                        float4 c=1;
                        float3 N=UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                        float diff=max(0,dot(N,i.lightDir));
                        c=_LightColor0*diff;
                        c*=tex2D(_MainText,i.uv.xy);
                        return c;
                }
                ENDCG
                }
        } 
}