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
