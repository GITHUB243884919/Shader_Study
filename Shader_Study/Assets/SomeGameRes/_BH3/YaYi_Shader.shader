// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/YaYi"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_LightMapTex("LightMapTex",2D)  = "black" {}
		_Color("MainColor",color) = (1,1,1,1)
		_LightArea("LightArea",float) = 0
		_SecondShadow("SecondShadow",float) = 0
		_FirstShadowMultColor("FirstShadowMultColor",color) = (1,1,1,1)
		_SecondShadowMultColor("SecondShadowMultColor",color) = (1,1,1,1)
		_Shininess("Shininess",float) =  0
		_SpecMulti("SpecMulti",Range(0,1)) = 0
		_LightSpecColor("LightSpecColor",color) = (1,1,1,1)
		_BloomFactor("BloomFactor",float) = 0
		_LightPos("LightPos",vector) = (1,0,0,0)
		  
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" }
		LOD 100

		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			lighting on
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"  
            #include "AutoLight.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;  // MVP position
				float2 uv : TEXCOORD0; //s_TEXCOORD0
				fixed4 color0 : TEXCOORD2;  // VERTEX COLOR  vs_COLOR0
				float color1 : TEXCOORD3;  // vs_COLOR1 
				float3 worldNor : TEXCOORD4; //s_TEXCOORD1
				float3 worldPos : TEXCOORD5;  //s_TEXCOORD2
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _LightMapTex;
			fixed4 _Color;
			float _LightArea;
			float _SecondShadow;
			fixed4 _FirstShadowMultColor;
			fixed4 _SecondShadowMultColor;
			float _Shininess;
			float _SpecMulti;
			fixed4 _LightSpecColor;
			float _BloomFactor;
			float4 _LightPos;
		//	float4 _WorldSpaceLightPos0;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);//UnityObjectToClipPos(v.vertex);
				o.color0 = v.color;  //VERTEX COLOR 
				o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.worldNor = normalize(mul(float4(v.normal,0), unity_WorldToObject).xyz);

				o.color1 = dot(o.worldNor,normalize(_WorldSpaceLightPos0.xyz))*0.5+0.5;  //normalize(float3(_WorldSpaceLightPos0))
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed3 specCol = tex2D(_LightMapTex, i.uv).rgb;
				float spec1 = max(floor(-i.color0.x*specCol.y+1.5),0.0);
				int spec1_int = int(spec1);
				fixed3 tempCol_1 = specCol.y * i.color0.x;
				float3 temp_1 = 0;
				temp_1.xy = tempCol_1.xx * float2(1.2,1.25) + float2(0.1,-0.125);
				if(spec1_int!=0)
					tempCol_1.x = temp_1.y;
				else 
					tempCol_1.x = temp_1.x;
				tempCol_1.x += i.color1;
				tempCol_1.x = tempCol_1.x*0.5 +(-_LightArea) + 1;
				tempCol_1.x = max(floor(tempCol_1.x),0);
				spec1_int = int(tempCol_1.x);
				temp_1.xyz = tex2D(_MainTex,i.uv).rgb;
				tempCol_1 = temp_1.xyz * _FirstShadowMultColor.rgb;
				fixed3 tempCol_3 = 0;
				if(spec1_int!=0)
					tempCol_3 = temp_1.xyz;
				else
					tempCol_3 = tempCol_1;
				fixed3  tempCol_4 = temp_1.xyz * _SecondShadowMultColor.rgb;
				float tempCol_19 = i.color0.x * specCol.y + i.color1;
				tempCol_19 = tempCol_19*0.5 + (-_SecondShadow);
				tempCol_19 += 1;
				tempCol_19 = max(floor(tempCol_19),0);
				spec1_int = int(tempCol_19);
				if(spec1_int !=0)
					tempCol_1.xyz = tempCol_1.xyz ;
				else
					tempCol_1.xyz = tempCol_4.xyz;
				 float tempCol2 = i.color0.x * specCol.y + 0.909999967;
				 tempCol2 = max(floor(tempCol2),0);
				 int spec2_int = int(tempCol2);
				 if(spec2_int != 0)
				 	tempCol_1 = tempCol_3;
				 else
				 	tempCol_1 = tempCol_1;
				 temp_1 = (-i.worldPos) + _WorldSpaceCameraPos.xyz;
				 tempCol2 = normalize(temp_1);
				 temp_1 = temp_1*tempCol2.xxx + normalize(_WorldSpaceLightPos0.xyz);
				 tempCol2 = normalize(temp_1);
				 temp_1 = tempCol2.xxx* temp_1;
				 tempCol2 = normalize(temp_1);
				 fixed3 tempCol3 = tempCol2.xxx * i.worldNor.xyz ;
				 tempCol_19 = dot(tempCol3,temp_1);
				 tempCol_19 = max(tempCol_19,0);
				 tempCol_19 = log2(tempCol_19);
				 tempCol_19 = tempCol_19 * _Shininess;
				 tempCol_19 = exp2(tempCol_19);
				 //float tempCol_6 = -specCol.z + 1;
				 float tempCol_6 = -specCol.z + 1;
				 tempCol_6 = -tempCol_19 + tempCol_6;
				 tempCol2 = tempCol_6 + 1;
				 tempCol2 = max(floor(tempCol2),0);
				// tempCol_6 = max(floor(tempCol_6),0);
				 spec2_int = int(tempCol2);
				 tempCol_3 = fixed3(_SpecMulti * _LightSpecColor.xxyz.y,_SpecMulti * _LightSpecColor.xxyz.z,_SpecMulti*float(_LightSpecColor.z));
				 tempCol_3.xyz = specCol.xxx * tempCol_3.xyz;
				 if(spec2_int!=0)
				 	tempCol_3.xyz = 0;
				 else
				  tempCol_3.xyz = tempCol_3.xyz;
				 tempCol_1.xyz += tempCol_3.xyz;
				  tempCol_1.xyz *= _Color.rgb;

				return fixed4(tempCol_1.xyz,_BloomFactor);
			}
			ENDCG
		}
	}
}