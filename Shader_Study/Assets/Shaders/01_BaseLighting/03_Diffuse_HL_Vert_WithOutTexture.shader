//半Lambert模型
//逐顶点
Shader "Custom/Base_Lighting/Diffuse/Diffuse_HL_Vert_WithOutTexture"
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
				fixed3 color : COLOR;
			};

			sampler2D _MainTex;
			fixed4 _Diffuse;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)_World2Object));
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//漫反射 = 光的颜色 * 漫反射颜色 * (dot(世界的法线, 世界的光的方向) * 0.5 + 0.5)
				fixed  halfLamb = dot(worldNormal, worldLight) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLamb;
				
				o.color = ambient + diffuse;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 col = fixed4(i.color, 1);
				return col;
			}
			ENDCG
		}
	}
}
