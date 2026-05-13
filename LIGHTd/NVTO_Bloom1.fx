//=================================================================================================
//
//  NVTO_Bloom1.fx
//  by NIVIENTO 2026
//  Steam: https://steamcommunity.com/id/Niviento/
//
//  All code licensed under the MIT license
//
//=================================================================================================

#include "ReShade.fxh"

uniform int ANB_DebugView <
	ui_type = "combo";
	ui_items = "Final\0Bright Pass\0Blur X 1\0Blur X 2\0Bloom Only\0";
	ui_label = "Debug View";
	ui_category = "00 Debug";
> = 0;

uniform float ANB_DebugBoost <
	ui_type = "slider";
	ui_min = 0.1;
	ui_max = 20.0;
	ui_step = 0.01;
	ui_label = "Debug Boost";
	ui_category = "00 Debug";
> = 3.01;

uniform float ANB_Intensity <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 5.0;
	ui_step = 0.001;
	ui_label = "Intensity";
	ui_category = "01 Main";
> = 1.398;

uniform float ANB_Threshold <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 0.001;
	ui_label = "Threshold";
	ui_category = "01 Main";
> = 1.264;

uniform float ANB_Knee <
	ui_type = "slider";
	ui_min = 0.001;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "Soft Knee";
	ui_category = "01 Main";
> = 1.000;

uniform float ANB_HorizontalLength <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 260.0;
	ui_step = 0.1;
	ui_label = "Horizontal Length Pixels";
	ui_category = "02 Shape";
> = 77.9;

uniform float ANB_HorizontalSpread <
	ui_type = "slider";
	ui_min = 0.25;
	ui_max = 3.0;
	ui_step = 0.001;
	ui_label = "Horizontal Spread";
	ui_category = "02 Shape";
> = 3.000;

uniform float ANB_VerticalLength <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 80.0;
	ui_step = 0.1;
	ui_label = "Vertical Length Pixels";
	ui_category = "02 Shape";
> = 80.0;

uniform float ANB_VerticalSpread <
	ui_type = "slider";
	ui_min = 0.25;
	ui_max = 3.0;
	ui_step = 0.001;
	ui_label = "Vertical Spread";
	ui_category = "02 Shape";
> = 1.709;

uniform float ANB_Core <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "Core Amount";
	ui_category = "02 Shape";
> = 0.000;

uniform float3 ANB_Tint <
	ui_type = "color";
	ui_label = "Tint";
	ui_category = "03 Color";
> = float3(1.0, 1.0, 1.0);

uniform float ANB_Saturation <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 0.001;
	ui_label = "Bloom Saturation";
	ui_category = "03 Color";
> = 0.701;

uniform int ANB_BlendMode <
	ui_type = "combo";
	ui_items = "Screen\0Additive\0Bloom Only\0";
	ui_label = "Blend Mode";
	ui_category = "04 Output";
> = 0;

uniform float ANB_OutputExposure <
	ui_type = "slider";
	ui_min = 0.25;
	ui_max = 2.0;
	ui_step = 0.001;
	ui_label = "Output Exposure";
	ui_category = "04 Output";
> = 1.000;

texture2D ANB_BrightTex
{
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	Format = RGBA16F;
};

texture2D ANB_BlurX1Tex
{
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	Format = RGBA16F;
};

texture2D ANB_BlurX2Tex
{
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	Format = RGBA16F;
};

texture2D ANB_BloomTex
{
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	Format = RGBA16F;
};

sampler2D sANB_Bright
{
	Texture = ANB_BrightTex;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

sampler2D sANB_BlurX1
{
	Texture = ANB_BlurX1Tex;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

sampler2D sANB_BlurX2
{
	Texture = ANB_BlurX2Tex;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

sampler2D sANB_Bloom
{
	Texture = ANB_BloomTex;
	AddressU = Clamp;
	AddressV = Clamp;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
};

float3 ANB_ReadScene(float2 uv)
{
	return tex2D(ReShade::BackBuffer, saturate(uv)).rgb;
}

float ANB_Luma(float3 c)
{
	return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float3 ANB_SaturationAdjust(float3 c, float amount)
{
	float l = ANB_Luma(c);
	return lerp(float3(l, l, l), c, amount);
}

float ANB_Gaussian(float x, float sigma)
{
	return exp(-0.5 * (x * x) / max(sigma * sigma, 0.00001));
}

float3 ANB_BrightExtract(float3 c)
{
	float l = ANB_Luma(c);

	float low = ANB_Threshold - ANB_Knee;
	float high = ANB_Threshold + ANB_Knee;

	float m = smoothstep(low, high, l);

	float punch = max(l - ANB_Threshold, 0.0);
	float gain = 1.0 + punch * 1.25;

	return c * m * gain;
}

float4 PS_ANB_Bright(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
	float2 p = ReShade::PixelSize;

	float3 c = ANB_ReadScene(uv) * 0.28;

	c += ANB_ReadScene(uv + float2( p.x, 0.0)) * 0.12;
	c += ANB_ReadScene(uv + float2(-p.x, 0.0)) * 0.12;
	c += ANB_ReadScene(uv + float2(0.0,  p.y)) * 0.12;
	c += ANB_ReadScene(uv + float2(0.0, -p.y)) * 0.12;

	c += ANB_ReadScene(uv + float2( p.x,  p.y)) * 0.06;
	c += ANB_ReadScene(uv + float2(-p.x,  p.y)) * 0.06;
	c += ANB_ReadScene(uv + float2( p.x, -p.y)) * 0.06;
	c += ANB_ReadScene(uv + float2(-p.x, -p.y)) * 0.06;

	c = ANB_BrightExtract(c);

	return float4(c, 1.0);
}

float3 ANB_BlurX_FromBright(float2 uv, float radiusScale)
{
	float spread01 = saturate((ANB_HorizontalSpread - 0.25) / 2.75);
	float sigma = lerp(0.22, 0.72, spread01);

	float radius = ANB_HorizontalLength * radiusScale;
	float3 sum = 0.0;
	float weightSum = 0.0;

	[unroll]
	for (int i = -18; i <= 18; i++)
	{
		float fi = (float)i;
		float t = fi / 18.0;
		float w = ANB_Gaussian(t, sigma);

		float2 o = float2(t * radius * ReShade::PixelSize.x, 0.0);

		sum += tex2D(sANB_Bright, uv + o).rgb * w;
		weightSum += w;
	}

	return sum / max(weightSum, 0.00001);
}

float3 ANB_BlurX_FromX1(float2 uv, float radiusScale)
{
	float spread01 = saturate((ANB_HorizontalSpread - 0.25) / 2.75);
	float sigma = lerp(0.24, 0.78, spread01);

	float radius = ANB_HorizontalLength * radiusScale;
	float3 sum = 0.0;
	float weightSum = 0.0;

	[unroll]
	for (int i = -18; i <= 18; i++)
	{
		float fi = (float)i;
		float t = fi / 18.0;
		float w = ANB_Gaussian(t, sigma);

		float2 o = float2(t * radius * ReShade::PixelSize.x, 0.0);

		sum += tex2D(sANB_BlurX1, uv + o).rgb * w;
		weightSum += w;
	}

	return sum / max(weightSum, 0.00001);
}

float3 ANB_BlurY_FromX2(float2 uv)
{
	float spread01 = saturate((ANB_VerticalSpread - 0.25) / 2.75);
	float sigma = lerp(0.22, 0.85, spread01);

	float radius = ANB_VerticalLength;
	float3 sum = 0.0;
	float weightSum = 0.0;

	[unroll]
	for (int i = -14; i <= 14; i++)
	{
		float fi = (float)i;
		float t = fi / 14.0;
		float w = ANB_Gaussian(t, sigma);

		float2 o = float2(0.0, t * radius * ReShade::PixelSize.y);

		sum += tex2D(sANB_BlurX2, uv + o).rgb * w;
		weightSum += w;
	}

	float3 blurred = sum / max(weightSum, 0.00001);
	float3 core = tex2D(sANB_Bright, uv).rgb * ANB_Core;

	return blurred + core;
}

float4 PS_ANB_BlurX1(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
	float3 c = ANB_BlurX_FromBright(uv, 0.55);
	return float4(c, 1.0);
}

float4 PS_ANB_BlurX2(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
	float3 c = ANB_BlurX_FromX1(uv, 0.85);
	return float4(c, 1.0);
}

float4 PS_ANB_BlurY(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
	float3 c = ANB_BlurY_FromX2(uv);

	c = ANB_SaturationAdjust(c, ANB_Saturation);
	c *= ANB_Tint;

	return float4(c, 1.0);
}

float4 PS_ANB_Final(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
	float3 scene = ANB_ReadScene(uv);

	float3 bright = tex2D(sANB_Bright, uv).rgb;
	float3 x1 = tex2D(sANB_BlurX1, uv).rgb;
	float3 x2 = tex2D(sANB_BlurX2, uv).rgb;
	float3 bloom = tex2D(sANB_Bloom, uv).rgb * ANB_Intensity;

	if (ANB_DebugView == 1)
	{
		return float4(saturate(bright * ANB_DebugBoost), 1.0);
	}

	if (ANB_DebugView == 2)
	{
		return float4(saturate(x1 * ANB_DebugBoost), 1.0);
	}

	if (ANB_DebugView == 3)
	{
		return float4(saturate(x2 * ANB_DebugBoost), 1.0);
	}

	if (ANB_DebugView == 4)
	{
		return float4(saturate(bloom * ANB_DebugBoost), 1.0);
	}

	float3 outCol = scene;

	if (ANB_BlendMode == 0)
	{
		outCol = 1.0 - (1.0 - scene) * (1.0 - saturate(bloom));
	}
	else if (ANB_BlendMode == 1)
	{
		outCol = scene + bloom;
	}
	else
	{
		outCol = bloom;
	}

	outCol *= ANB_OutputExposure;

	return float4(saturate(outCol), 1.0);
}

technique NVTO_Bloom1
{
	pass Bright
	{
		RenderTarget = ANB_BrightTex;
		VertexShader = PostProcessVS;
		PixelShader = PS_ANB_Bright;
	}

	pass BlurX1
	{
		RenderTarget = ANB_BlurX1Tex;
		VertexShader = PostProcessVS;
		PixelShader = PS_ANB_BlurX1;
	}

	pass BlurX2
	{
		RenderTarget = ANB_BlurX2Tex;
		VertexShader = PostProcessVS;
		PixelShader = PS_ANB_BlurX2;
	}

	pass BlurY
	{
		RenderTarget = ANB_BloomTex;
		VertexShader = PostProcessVS;
		PixelShader = PS_ANB_BlurY;
	}

	pass Final
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_ANB_Final;
	}
}