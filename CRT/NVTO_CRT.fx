//=================================================================================================
//
//  NVTO_CRT.fx
//  by NIVIENTO 2026
//  Steam: https://steamcommunity.com/id/Niviento/
//
//  All code licensed under the MIT license
//
//=================================================================================================

#include "ReShade.fxh"

uniform int NVTO_ResX <
	ui_type = "drag";
	ui_min = 160;
	ui_max = BUFFER_WIDTH;
	ui_step = 1;
	ui_label = "Virtual Width [NVTO CRT]";
> = 1300;

uniform int NVTO_ResY <
	ui_type = "drag";
	ui_min = 120;
	ui_max = BUFFER_HEIGHT;
	ui_step = 1;
	ui_label = "Virtual Height [NVTO CRT]";
> = 1030;

uniform bool NVTO_PixelSnap <
	ui_label = "Pixel Snap [NVTO CRT]";
> = true;

uniform float NVTO_EdgeFade <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.08;
	ui_step = 0.001;
	ui_label = "Edge Fade [NVTO CRT]";
> = 0.006;

uniform float NVTO_ScanlineAmount <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "Scanline Amount [NVTO CRT]";
> = 0.42;

uniform float NVTO_ScanlineSharpness <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 10.0;
	ui_step = 0.01;
	ui_label = "Scanline Sharpness [NVTO CRT]";
> = 2.50;

uniform float NVTO_ScanlineBrightness <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 1.5;
	ui_step = 0.001;
	ui_label = "Scanline Bright Boost [NVTO CRT]";
> = 1.05;

uniform float NVTO_MaskAmount <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "Phosphor Mask Amount [NVTO CRT]";
> = 0.32;

uniform float NVTO_MaskScale <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 6.0;
	ui_step = 0.01;
	ui_label = "Phosphor Mask Scale [NVTO CRT]";
> = 1.25;

uniform float NVTO_RGBOffset <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.01;
	ui_label = "RGB Offset [NVTO CRT]";
> = 0.55;

uniform float NVTO_GlowAmount <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.5;
	ui_step = 0.001;
	ui_label = "CRT Glow [NVTO CRT]";
> = 0.275;

uniform float NVTO_GlowSize <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 8.0;
	ui_step = 0.01;
	ui_label = "Glow Size [NVTO CRT]";
> = 2.2;

uniform float NVTO_NoiseAmount <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.15;
	ui_step = 0.001;
	ui_label = "Analog Noise [NVTO CRT]";
> = 0.012;

uniform float NVTO_LineWobble <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.5;
	ui_step = 0.001;
	ui_label = "Line Wobble [NVTO CRT]";
> = 0.018;

uniform float NVTO_Vignette <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
	ui_label = "Vignette [NVTO CRT]";
> = 0.0;

uniform float NVTO_Brightness <
	ui_type = "slider";
	ui_min = 0.25;
	ui_max = 3.0;
	ui_step = 0.001;
	ui_label = "Brightness [NVTO CRT]";
> = 1.08;

uniform float NVTO_Contrast <
	ui_type = "slider";
	ui_min = 0.25;
	ui_max = 3.0;
	ui_step = 0.001;
	ui_label = "Contrast [NVTO CRT]";
> = 1.10;

uniform float NVTO_Saturation <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.5;
	ui_step = 0.001;
	ui_label = "Saturation [NVTO CRT]";
> = 1.05;

uniform float NVTO_Gamma <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 2.5;
	ui_step = 0.001;
	ui_label = "Gamma [NVTO CRT]";
> = 1.0;

uniform float NVTO_Timer <
	source = "timer";
>;

float NVTO_Rand(float2 p)
{
	float3 q = frac(float3(p.x, p.y, p.x + p.y) * float3(139.31, 271.19, 419.73));
	q += dot(q, q.yzx + 23.17);
	return frac((q.x + q.y) * q.z);
}

float NVTO_LineNoise(float x)
{
	float a = floor(x);
	float b = frac(x);
	float v0 = NVTO_Rand(float2(a, a + 5.13));
	float v1 = NVTO_Rand(float2(a + 1.0, a + 6.13));
	float s = b * b * (3.0 - 2.0 * b);
	return lerp(v0, v1, s);
}

float NVTO_Border(float2 uv)
{
	float fade = max(NVTO_EdgeFade, 0.0001);

	float2 low = smoothstep(float2(0.0, 0.0), float2(fade, fade), uv);
	float2 high = smoothstep(float2(0.0, 0.0), float2(fade, fade), 1.0 - uv);

	return low.x * low.y * high.x * high.y;
}

float2 NVTO_SnapUV(float2 uv)
{
	if (!NVTO_PixelSnap)
	{
		return uv;
	}

	float2 grid = float2(NVTO_ResX, NVTO_ResY);
	return (floor(uv * grid) + 0.5) / grid;
}

float3 NVTO_Read(float2 uv)
{
	return tex2D(ReShade::BackBuffer, uv).rgb;
}

float3 NVTO_RGBSplit(float2 uv)
{
	float2 shift = float2(ReShade::PixelSize.x * NVTO_RGBOffset, 0.0);

	float rr = tex2D(ReShade::BackBuffer, uv + shift).r;
	float gg = tex2D(ReShade::BackBuffer, uv).g;
	float bb = tex2D(ReShade::BackBuffer, uv - shift).b;

	return float3(rr, gg, bb);
}

float3 NVTO_Glow(float2 uv)
{
	float2 stepv = ReShade::PixelSize * NVTO_GlowSize;

	float3 c = NVTO_Read(uv) * 0.28;

	c += NVTO_Read(uv + float2( stepv.x, 0.0)) * 0.13;
	c += NVTO_Read(uv + float2(-stepv.x, 0.0)) * 0.13;
	c += NVTO_Read(uv + float2(0.0,  stepv.y)) * 0.13;
	c += NVTO_Read(uv + float2(0.0, -stepv.y)) * 0.13;

	c += NVTO_Read(uv + float2( stepv.x,  stepv.y)) * 0.06;
	c += NVTO_Read(uv + float2(-stepv.x,  stepv.y)) * 0.06;
	c += NVTO_Read(uv + float2( stepv.x, -stepv.y)) * 0.06;
	c += NVTO_Read(uv + float2(-stepv.x, -stepv.y)) * 0.06;

	return c;
}

float NVTO_Scan(float2 uv)
{
	float phase = uv.y * float(NVTO_ResY);
	float wave = abs(sin(phase * 3.14159265));
	float shaped = pow(wave, NVTO_ScanlineSharpness);

	return lerp(1.0 - NVTO_ScanlineAmount, NVTO_ScanlineBrightness, shaped);
}

float3 NVTO_Triad(float2 uv)
{
	float columnBase = floor(uv.x * float(NVTO_ResX) * 3.0 * NVTO_MaskScale);
	float column = columnBase - 3.0 * floor(columnBase / 3.0);

	float3 triadR = float3(1.00, 0.72, 0.72);
	float3 triadG = float3(0.72, 1.00, 0.72);
	float3 triadB = float3(0.72, 0.72, 1.00);

	float3 triad = column < 1.0 ? triadR : column < 2.0 ? triadG : triadB;

	float rowBase = floor(uv.y * float(NVTO_ResY));
	float rowPair = rowBase - 2.0 * floor(rowBase / 2.0);
	float rowDarken = lerp(0.90, 1.0, rowPair);

	triad *= rowDarken;

	return lerp(float3(1.0, 1.0, 1.0), triad, NVTO_MaskAmount);
}

float3 NVTO_Grade(float3 c)
{
	float gray = dot(c, float3(0.2126, 0.7152, 0.0722));

	c = lerp(float3(gray, gray, gray), c, NVTO_Saturation);
	c = (c - 0.5) * NVTO_Contrast + 0.5;
	c *= NVTO_Brightness;

	float invGamma = 1.0 / max(NVTO_Gamma, 0.0001);
	c = pow(max(c, float3(0.0, 0.0, 0.0)), float3(invGamma, invGamma, invGamma));

	return c;
}

float NVTO_VignetteMask(float2 uv)
{
	float2 p = uv * (1.0 - uv);
	float v = clamp(p.x * p.y * 16.0, 0.0, 1.0);
	v = pow(v, 0.45);

	return lerp(1.0, v, NVTO_Vignette);
}

float4 PS_NVTO_CRT(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
	float time = NVTO_Timer * 0.001;

	float2 screenUV = uv;
	float visible = NVTO_Border(screenUV);

	if (visible <= 0.0001)
	{
		return float4(0.0, 0.0, 0.0, 1.0);
	}

	float2 sampleUV = screenUV;

	float line = floor(sampleUV.y * float(NVTO_ResY));
	float drift = NVTO_LineNoise(line * 0.21 + time * 24.0) - 0.5;
	sampleUV.x += drift * ReShade::PixelSize.x * 12.0 * NVTO_LineWobble;

	sampleUV = NVTO_SnapUV(sampleUV);

	float3 image = NVTO_RGBSplit(sampleUV);
	float3 bloom = NVTO_Glow(sampleUV);

	image += bloom * NVTO_GlowAmount;
	image = NVTO_Grade(image);

	image *= NVTO_Scan(screenUV);
	image *= NVTO_Triad(screenUV);

	float2 grainPixel = floor(uv * ReShade::ScreenSize);
	float grain = NVTO_Rand(grainPixel + float2(floor(time * 83.0), floor(time * 127.0))) - 0.5;
	image += grain * NVTO_NoiseAmount;

	image *= NVTO_VignetteMask(screenUV);
	image *= visible;

	return float4(clamp(image, 0.0, 1.0), 1.0);
}

technique NVTO_CRT
{
	pass NVTO_CRT
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_NVTO_CRT;
	}
}