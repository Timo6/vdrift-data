#version 330

uniform sampler2D diffuseSampler;
uniform mat4 projectionMatrix;

in vec3 normal;
in vec3 uv;
in vec3 eyespacePosition;

#define USE_OUTPUTS

#ifdef USE_OUTPUTS
out vec4 outputDepth;
#endif

void main(void)
{
	vec4 diffuseTexture = texture(diffuseSampler, uv.xy);
	
	vec4 albedo;
	
	/*// the equation below only works for perspective projections
	//float zfar = projectionMatrix[3][2]/(projectionMatrix[2][2]+1);
	
	// this only works for orthographic projections
	float zfar = (projectionMatrix[3][2]-1)/projectionMatrix[2][2];
	
	float linearz = clamp(-eyespacePosition.z/zfar,0,1);*/
	
	float linearz = clamp(gl_FragCoord.z*gl_FragCoord.w,0,1);
	
	albedo = vec4(linearz,linearz*linearz,0,1);
	
	#ifdef USE_OUTPUTS
	outputDepth.rgba = albedo;
	#else
	gl_FragColor = albedo;
	#endif
}
