//半Lambert模型
//逐像素
Shader "Custom/Base_Lighting/Diffuse/Diffuse_HL_Frag_WithOutTexture"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
			};

			sampler2D _MainTex;
			fixed4 _Diffuse;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				o.worldNormal  = mul(v.normal, (float3x3)_World2Object);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//漫反射 = 光的颜色 * 漫反射颜色 * (dot(世界的法线, 世界的光的方向) * 0.5 + 0.5)
				fixed  halfLamb = dot(worldNormal, worldLight) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLamb;
				fixed3 color = ambient + diffuse;
				return fixed4(color, 1);
			}
			ENDCG
		}
	}
}
