
Shader "Custom/Study/Diffuse/TextureMap_1"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1, 1, 1, 1)
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
				fixed2 uv     : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed2 uv  : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldPos : TEXCOORD2;
				
			};

			sampler2D _MainTex;
			fixed4    _MainTex_ST;
			fixed4     _Color;
			fixed4 _Diffuse;
			fixed4 _Specular;
			float  _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = mul(v.normal, (float3x3)_World2Object);
				o.worldPos = mul(_Object2World, v.vertex).xyz;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed  halfLamb = dot(normalize(i.worldNormal), normalize(_WorldSpaceLightPos0)) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * halfLamb;
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos).xyz;
				fixed3 halfDir = normalize(normalize(_WorldSpaceLightPos0) + normalize(viewDir));
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(i.worldNormal, halfDir)), _Gloss);
				

				fixed3 color = ambient + diffuse + specular;
				return fixed4(color, 1);
			}
			ENDCG
		}
	}
}
