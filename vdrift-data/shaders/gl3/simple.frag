#version 330

#ifndef NOTEXTURE
uniform sampler2D diffuseSampler;
#endif
uniform vec4 colorTint;

in vec3 normal;
in vec3 uv;

#define USE_OUTPUTS

#ifdef USE_OUTPUTS
out vec4 outputColor;
#endif

// doesn't include pow(x,1/2.2)
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
    #ifdef NOTEXTURE
	vec4 diffuseTexture = vec4(1,1,1,1);
    #else
	vec4 diffuseTexture = texture(diffuseSampler, uv.xy);
    #endif
	
	vec4 albedo;
	
	#ifdef CARPAINT
	albedo.rgb = mix(colorTint.rgb, diffuseTexture.rgb, diffuseTexture.a); // albedo is mixed from diffuse and object color
	albedo.a = 1;
	#else
	albedo = diffuseTexture * colorTint;
	#endif
	
	#ifdef ALPHATEST
	if (diffuseTexture.a < 0.5)
		discard;
	#endif

	#ifdef USE_OUTPUTS
	outputColor.rgba = albedo;
	#else
	gl_FragColor = albedo;
	#endif
}
