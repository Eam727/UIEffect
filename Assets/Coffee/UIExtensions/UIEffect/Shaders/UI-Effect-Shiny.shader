Shader "UI/Hidden/UI-Effect-Shiny"
{
	Properties
	{
		[PerRendererData] _MainTex ("Main Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

		_ParamTex ("Parameter Texture", 2D) = "white" {}
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

		Pass
		{
			Name "Default"

		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			
			#pragma multi_compile __ UNITY_UI_ALPHACLIP

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "UI-Effect.cginc"
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color	: COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID

				float2 uv1 : TEXCOORD1;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color	: COLOR;
				float2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
				
				half4 effectFactor : TEXCOORD2;
				half2 effectFactor2 : TEXCOORD3;

				half param : TEXCOORD4;
			};
			
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			sampler2D _ParamTex;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;

				OUT.vertex = UnityObjectToClipPos(IN.vertex);

				OUT.texcoord = IN.texcoord;
				
				OUT.color = IN.color * _Color;

				OUT.texcoord = UnpackToVec2(IN.texcoord.x);
				OUT.param = IN.texcoord.y;

				OUT.effectFactor = UnpackToVec4(IN.uv1.x);
				OUT.effectFactor2 = UnpackToVec2(IN.uv1.y);

				OUT.effectFactor2.x = OUT.effectFactor2.x * 2 - 0.5;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed nomalizedPos = IN.effectFactor.x;
			
				fixed4 param1 = tex2D(_ParamTex, float2(0.25, IN.param));
				fixed4 param2 = tex2D(_ParamTex, float2(0.75, IN.param));
                fixed location = param1.x;
                fixed width = param1.y/4;
                fixed softness = param1.z;
				fixed brightness = param1.w;
				fixed gloss = param2.x;

				half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd);
				fixed4 originAlpha = color.a;
				color *= IN.color;
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

				#ifdef UNITY_UI_ALPHACLIP
				clip (color.a - 0.001);
				#endif

//				fixed nomalizedPos = IN.effectFactor.x;
//				fixed softness = IN.effectFactor.y;
//				fixed width = IN.effectFactor.z;
//				fixed brightness = IN.effectFactor.w;
//				half location = IN.effectFactor2.x;
//				half gloss = IN.effectFactor2.y;

				half normalized = 1 - saturate(abs((nomalizedPos - location) / width));
				half shinePower = smoothstep(0, softness*2, normalized);
				half3 reflectColor = lerp(1, color.rgb * 10, gloss);

				color.rgb += originAlpha * (shinePower / 2) * brightness * reflectColor;
				return color;
			}
		ENDCG
		}
	}
}
