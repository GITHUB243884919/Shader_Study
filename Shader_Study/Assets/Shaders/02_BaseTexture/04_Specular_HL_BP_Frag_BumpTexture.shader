﻿//Blinn-Phong模型
//漫反射用半兰伯特
//逐像素
Shader "Custom/Base_Texture/Specular_HL_BP_Frag_BumpTexture"
{
	Properties
	{
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}
		_BumpTex("Bump Texture", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1.0

		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(1.0, 256)) = 20
	}
	SubShader
	{
		//Tags { "RenderType"="Opaque" }
		Tags { "LightMode"="ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				fixed4 uv     : TEXCOORD0;
				
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed4 uv  : TEXCOORD0;
				fixed3 lightDir : TEXCOORD1;
				fixed3 viewDir : TEXCOORD2;
			};

			sampler2D _MainTex;
			fixed4    _MainTex_ST;
			sampler2D _BumpTex;
			fixed4    _BumpTex_ST;
			fixed4    _Color;
			fixed4    _BumpScale;
			fixed4    _Diffuse;
			fixed4    _Specular;
			float     _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos   = mul(UNITY_MATRIX_MVP, v.vertex);
				//uv
				//o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//o.uv.zw = TRANSFORM_TEX(v.uv, _BumpTex);
				o.uv.zw = v.uv.xy * _BumpTex_ST.xy + _BumpTex_ST.zw;
				//tangent
				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(_World2Object, _WorldSpaceLightPos0).xyz;
				o.lightDir = mul(rotation, o.lightDir).xyz;
				o.viewDir  = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				
				// Get the texel in the normal map
				fixed4 packedNormal = tex2D(_BumpTex, i.uv.zw);
				fixed3 tangentNormal;
				// If the texture is not marked as "Normal map"
//				tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
//				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				// Or mark the texture as "Normal map", and use the built-in funciton
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}
	}
	FallBack "Specular"
}