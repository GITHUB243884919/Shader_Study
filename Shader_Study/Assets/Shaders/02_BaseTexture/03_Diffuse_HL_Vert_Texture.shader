//漫反射用半兰伯特
//逐像素
Shader "Custom/Base_Texture/Diffuse_HL_Vert_Texture"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1, 1, 1, 1)
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
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
				fixed2 uv     : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed2 uv  : TEXCOORD0;
				//fixed3 worldNormal : TEXCOORD1;
				//fixed3 worldViewDir : TEXCOORD2;
				fixed3 color :COLOR;
			};

			sampler2D _MainTex;
			fixed4    _MainTex_ST;
			fixed4     _Color;
			fixed4 _Diffuse;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv  = TRANSFORM_TEX(v.uv, _MainTex);
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				//diffuse
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)_World2Object));
				fixed  halfLamb = dot(worldNormal, worldLight) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLamb;

				o.color = ambient + diffuse;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 albedo = tex2D(_MainTex, i.uv) * _Color.rgb; 
				


				//specular
				//fixed3 viewDir = normalize(i.worldViewDir);
				//fixed3 halfDir = normalize(worldLight + viewDir);
				//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);
				
				fixed3 color = i.color * albedo;
				return fixed4(color, 1);
			}
			ENDCG
		}
	}
}
