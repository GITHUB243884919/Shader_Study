//http://www.gad.qq.com/article/detail/19040
Shader "Custom/Water/GerstnerWave/Study/2"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

        _Q("Q", Vector)  = (0, 0, 0, 0)
        _A("A", Vector)  = (0, 0, 0, 0)
        _S("S", Vector) = (0, 0, 0, 0)
        _Dx("DX", Vector) = (0, 0, 0, 0)
        _Dz("DZ", Vector) = (0, 0, 0, 0)
        _L("L", Vector) = (0, 0, 0, 0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

            float4 _Q;
			float4 _A;
            float4 _S;
            float4 _Dx;
            float4 _Dz;
            float4 _L;                                      
            float3 CalculateWavesDisplacement(float3 vert)
            {
                float PI = 3.141592f;
                float3 pos = float3(0,0,0);
                float4 w = 2*PI/_L;
                float4 psi = _S*2*PI/_L;
                float4 phase = w*_Dx*vert.x+w*_Dz*vert.z+psi*_Time.x;
                float4 sinp=float4(0,0,0,0), cosp=float4(0,0,0,0);
                sincos(phase, sinp, cosp);
                //sinp = sin(phase)
                pos.x = dot(_Q*_A*_Dx, cosp);
                pos.z = dot(_Q*_A*_Dz, cosp);
                pos.y = dot(_A, sinp);
                return pos;
            } 
            v2f vert (appdata v)
            {
                v2f o;

                float3 worldPos = mul(_Object2World, v.vertex);
                float3 disPos = CalculateWavesDisplacement(worldPos);
                v.vertex.xyz = mul(_World2Object, float4(worldPos+disPos, 1));
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
