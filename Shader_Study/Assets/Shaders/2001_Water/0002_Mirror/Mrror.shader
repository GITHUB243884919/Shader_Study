Shader "Custom/Mirror" {
    Properties 
    {
        _ReflectionTex ("Internal Reflection", 2D) = "" {}
    }


// -----------------------------------------------------------
// Fragment program cards


    Subshader 
    {
        Tags {"RenderType"="Opaque" }
	    Pass 
        {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata {
	            float4 vertex : POSITION;
	            float3 normal : NORMAL;
            };

            struct v2f {
	            float4 pos : SV_POSITION;
		        float4 ref : TEXCOORD0;
	            UNITY_FOG_COORDS(2)
            };

            v2f vert(appdata v)
            {
	            v2f o;
	            o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	
	            o.ref = ComputeScreenPos(o.pos);

	            UNITY_TRANSFER_FOG(o,o.pos);
	            return o;
            }

            sampler2D _ReflectionTex;

            half4 frag( v2f i ) : SV_Target
            {
	            half4 refl = tex2Dproj( _ReflectionTex, UNITY_PROJ_COORD(i.ref));
	            half4 color = refl;

	            UNITY_APPLY_FOG(i.fogCoord, color);
	            return color;
            }
        ENDCG
	    }
    }

}
