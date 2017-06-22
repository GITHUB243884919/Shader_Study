
Shader "Custom/Study/Diffuse/TextureMap_1"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
				fixed3 worldLight : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Diffuse;
			fixed4 _Specular;
			float  _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = normalize(mul(v.normal, (float3x3)_World2Object));
				o.worldLight = normalize(_WorldSpaceLightPos0.xyz);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed  halfLamb = dot(i.worldNormal, i.worldLight) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLamb;

				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.pos).xyz;
				fixed3 halfDir = normalize(i.worldLight + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(i.worldNormal, halfDir)), _Gloss);
				

				fixed4 col = fixed4(ambient + diffuse + specular, 1);
				return col;
			}
			ENDCG
		}
	}
}
