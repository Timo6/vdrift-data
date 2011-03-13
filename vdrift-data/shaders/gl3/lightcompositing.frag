#version 330

uniform sampler2D lightBufferSampler;

in vec3 uv;

#define USE_OUTPUTS

#ifdef USE_OUTPUTS
invariant out vec4 outputColor;
#endif

vec3 linearTonemap(vec3 color)
{
	return color;
}

vec3 reinhardTonemap(vec3 color)
{
	return color/(vec3(1,1,1)+color);
}

vec3 hableTonemap(vec3 x)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

void main(void)
{
	vec4 lightBuffer = texture2D(lightBufferSampler, uv.xy);
	
	vec4 final = vec4(0,0,0,1);
	
	//final.rgb = linearTonemap(lightBuffer.rgb);
	
	float exposureBias = 4.0;
	vec3 curr = hableTonemap(exposureBias*lightBuffer.rgb);
	const float W = 11.2;
	vec3 whiteScale = 1.0/hableTonemap(vec3(W));
	final.rgb = curr*whiteScale;
	
	#ifdef USE_OUTPUTS
	outputColor.rgba = final;
	#else
	gl_FragColor = final;
	#endif
}
