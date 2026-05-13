//=================================================================================================
//
//  NVTO_ScreenZoom
//  by NIVIENTO 2026
//  Steam: https://steamcommunity.com/id/Niviento/
//
//  All code licensed under the MIT license
//
//=================================================================================================

#include "ReShade.fxh"

uniform float NVZ_Zoom <
	ui_type = "slider";
	ui_min = 0.50;
	ui_max = 2.00;
	ui_step = 0.001;
	ui_label = "Screen Zoom (or Zoom out)";
> = 1.0;

float2 NVZ_ZoomUV(float2 uv)
{
	float2 p = uv - 0.5;
	p /= NVZ_Zoom;
	return p + 0.5;
}

float4 PS_NVTO_ScreenZoom(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
	float2 zoomUV = NVZ_ZoomUV(uv);

	if (zoomUV.x < 0.0 || zoomUV.x > 1.0 || zoomUV.y < 0.0 || zoomUV.y > 1.0)
	{
		return float4(0.0, 0.0, 0.0, 1.0);
	}

	float3 col = tex2D(ReShade::BackBuffer, zoomUV).rgb;

	return float4(col, 1.0);
}

technique NVTO_ScreenZoom
{
	pass NVTO_ScreenZoom
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_NVTO_ScreenZoom;
	}
}