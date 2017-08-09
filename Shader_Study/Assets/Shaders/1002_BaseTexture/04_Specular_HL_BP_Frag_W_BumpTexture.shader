//凹凸贴图
//世界空间
//高光用Blinn-Phong模型
//漫反射用半兰伯特
//逐像素
Shader "Custom/Base_Texture/Specular_HL_BP_Frag_W_BumpTexture"
{
	Properties
	{
		_Color("Color", Color) = (1, 1, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}
		_BumpTex("Bump Texture", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0

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
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;  
				float4 TtoW1 : TEXCOORD2;  
				float4 TtoW2 : TEXCOORD3; 
			};

			sampler2D _MainTex;
			fixed4    _MainTex_ST;
			sampler2D _BumpTex;
			fixed4    _BumpTex_ST;
			fixed4    _Color;
			fixed    _BumpScale;
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

				float3 worldPos = mul(_Object2World, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				// Compute the matrix that transform directions from tangent space to world space
				// Put the world position in w component for optimization
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 albedo = tex2D(_MainTex, i.uv) * _Color.rgb; 
				//fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				// Get the position in world space		
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				// Compute the light and view dir in world space
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpTex, i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
				// Transform the narmal from tangent space to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				//diffuse
				fixed  halfLamb = dot(bump, lightDir) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb  * _Diffuse.rgb * halfLamb;
				
				//specular
				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump, halfDir)), _Gloss);
				
				fixed3 color = (ambient + diffuse) * albedo + specular;
				return fixed4(color, 1);
			}
			ENDCG
		}
	}
	//FallBack "Specular"
}
