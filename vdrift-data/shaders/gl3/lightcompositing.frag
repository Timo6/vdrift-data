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

void main(void)
{
	vec4 lightBuffer = texture2D(lightBufferSampler, uv.xy);
	
	vec4 final = vec4(0,0,0,1);
	
	final.rgb = linearTonemap(lightBuffer.rgb);
	
	#ifdef USE_OUTPUTS
	outputColor.rgba = final;
	#else
	gl_FragColor = final;
	#endif
}
