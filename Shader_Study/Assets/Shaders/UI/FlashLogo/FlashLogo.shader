Shader "Custom/UI/FlashLogo" 
{
    Properties 
    {
        _MainTex ("Texture", 2D) = "white" { }
    }
    SubShader
    {
    Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
    Blend SrcAlpha OneMinusSrcAlpha 
        AlphaTest Greater 0.1
        pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
       
            sampler2D _MainTex;
            float4 _MainTex_ST;
           
            struct v2f {
                float4  pos : SV_POSITION;
                float2  uv : TEXCOORD0;
            };
           
            //���㺯��ûʲô�ر�ģ��ͳ���һ��
            v2f vert (appdata_base v)
            {
                v2f o;
                   o.pos = mul(UNITY_MATRIX_MVP,v.vertex);
                o.uv =    TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }
           
            //�������ʹ����� frag����֮ǰ�������޷�ʶ��
            //���ģ����㺯�����Ƕȣ�uv,�����x���ȣ��������ʼʱ�䣬ƫ�ƣ�����ѭ��ʱ��
            float inFlash(float angle,float2 uv,float xLength,int interval,int beginTime, float offX, float loopTime )
            {
                //����ֵ
                float brightness =0;
               
                //��б��
                float angleInRad = 0.0174444 * angle;
               
                //��ǰʱ��
                float currentTime = _Time.y;
           
                //��ȡ���ι��յ���ʼʱ��
                int currentTimeInt = _Time.y/interval;
                currentTimeInt *=interval;
               
                //��ȡ���ι��յ�����ʱ�� = ��ǰʱ�� - ��ʼʱ��
                float currentTimePassed = currentTime -currentTimeInt;
                if(currentTimePassed >beginTime)
                {
                    //�ײ���߽���ұ߽�
                    float xBottomLeftBound;
                    float xBottomRightBound;

                    //�˵�߽�
                    float xPointLeftBound;
                    float xPointRightBound;
                   
                    float x0 = currentTimePassed-beginTime;
                    x0 /= loopTime;
           
                    //�����ұ߽�
                    xBottomRightBound = x0;
                   
                    //������߽�
                    xBottomLeftBound = x0 - xLength;
                   
                    //ͶӰ��x�ĳ��� = y/ tan(angle)
                    float xProjL;
                    xProjL= (uv.y)/tan(angleInRad);

                    //�˵����߽� = �ײ���߽� - ͶӰ��x�ĳ���
                    xPointLeftBound = xBottomLeftBound - xProjL;
                    //�˵���ұ߽� = �ײ��ұ߽� - ͶӰ��x�ĳ���
                    xPointRightBound = xBottomRightBound - xProjL;
                   
                    //�߽����һ��ƫ��
                    xPointLeftBound += offX;
                    xPointRightBound += offX;
                   
                    //����õ���������
                    if(uv.x > xPointLeftBound && uv.x < xPointRightBound)
                    {
                        //�õ�������������ĵ�
                        float midness = (xPointLeftBound + xPointRightBound)/2;
                       
                        //�������ĵ�ĳ̶ȣ�0��ʾλ�ڱ�Ե��1��ʾλ�����ĵ�
                        float rate= (xLength -2*abs(uv.x - midness))/ (xLength);
                        brightness = rate;
                    }
                }
                brightness= max(brightness,0);
               
                //������ɫ = ����ɫ * ����
                //float4 col = float4(1,1,1,1) *brightness;
				//return brightness;
				float4 col = float4(0.5,1,1,1) *brightness;
                return col;
            }
           
            float4 frag (v2f i) : COLOR
            {
                 float4 outp;
                
                 //����uvȡ��������ɫ���ͳ���һ��
                float4 texCol = tex2D(_MainTex,i.uv);
       
                //����i.uv�Ȳ������õ�����ֵ
                float tmpBrightness;
				//float angle,float2 uv,float xLength,int interval,int beginTime, float offX, float loopTime
                
				//tmpBrightness =inFlash(-45,i.uv,0.25,5,2,0.15,0.7);
				tmpBrightness =inFlash(-45,i.uv,0.75,2,0.5,0.15,0.7);
           
                //ͼ�������ж�����Ϊ ��ɫ��A > 0.5,���Ϊ������ɫ+����ֵ
                if(texCol.w >0.5)
                        outp  =texCol+float4(1,1,1,1)*tmpBrightness;
                //�հ������ж�����Ϊ ��ɫ��A <=0.5,����հ�
                else
                    outp =float4(0,0,0,0);

                return outp;
            }
            ENDCG
        }
    }
}