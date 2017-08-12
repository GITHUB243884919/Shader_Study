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
                float  PI  = 3.141592f;
                float3 pos = float3(0, 0, 0);
                
                // _L波长，w影响波长 
                float4 w   = 2 * PI / _L;

                // _S速度，速度与常数的关系（_S * 2 * PI / _L）= _S * w，乘以时间，决定了位移
                //float4 psi = _S*2*PI/_L;
                float4 psi = _Time.x * _S * w;
                
                // _Dx和_Dz分别表示在x和z方向上的运动方向
                //float4 phase = w *_Dx * vert.x + w *_Dz *vert.z + psi *_Time.x;
                float4 phase = w * (_Dx * vert.x + _Dz * vert.z) + psi;
                
                // 分别计算一个sin波和cos波
                float4 sinp = float4(0, 0, 0, 0);
                float4 cosp = float4(0, 0, 0, 0);
                sincos(phase, sinp, cosp);
                
                // 下面是进行4个波的叠加，四个波的叠加操作是通过点乘函数完成的
                // _A 表示振幅，_A.xyzw表示4个波的振幅
                // _Dx以及_Dz分别存放了方向参数D的x值和z值，即波a的参数D为(_Dx.x, _Dz.x)。
                // Q可以用来控制波的陡度，其值越大，则波越陡，当然这里要注意，如果Q值太大了，就会造成环
                //     Q / psi = 1，则会形成最尖锐的波
                //     Q / psi > 1  超过1则会造成环
                //     Q / psi = 0  则是最平缓的波
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
