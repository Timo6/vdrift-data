#version 330

uniform sampler2D depthSampler;
uniform sampler2D shadowSampler1;
uniform vec2 viewportSize;
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform vec3 eyespaceLightDirection;
uniform mat4 invProjectionMatrix;
uniform mat4 invViewMatrix;
uniform mat4 shadowMatrix1;

in vec3 eyespacePosition;
in vec3 uv;

#define USE_OUTPUTS

#ifdef USE_OUTPUTS
out vec4 outputColor;
#endif

void main(void)
{
	vec2 screencoord = uv.xy;
	
	// retrieve g-buffer
	float gbuf_depth = texture(depthSampler, screencoord).r;
	
	vec3 final = vec3(0,0,0);
	
	vec3 normalizedDevicePosition = vec3(screencoord.x, screencoord.y, gbuf_depth)*2.0-vec3(1.0);
	
	// transform from NDCs to eyespace
	vec4 reconstructedEyespacePosition = invProjectionMatrix * 
		vec4(normalizedDevicePosition.x,
			normalizedDevicePosition.y,
			normalizedDevicePosition.z,
			1.0);
	reconstructedEyespacePosition.xyz /= reconstructedEyespacePosition.w;
	vec3 V = -normalize(reconstructedEyespacePosition.xyz);
	
	// compute shadows
	// the shadowMatrix should transform from view to world, then from world to shadow view, then from shadow view to shadow clip space
	vec4 shadowClipspacePosition = shadowMatrix1*vec4(reconstructedEyespacePosition.xyz,1);
	//shadowClipspacePosition.xyz /= shadowClipspacePosition.w; // TODO: delete this line; not necessary for orthographic shadows
	// look up from the shadow map
	vec2 shadowSampleUV = shadowClipspacePosition.xy*0.5+vec2(0.5,0.5);
	vec4 shadowMap1 = texture(shadowSampler1, shadowSampleUV);
	
	// conventional shadow mapping
	const float shadowBias = 0.00001;
	float shadowLinearz1 = (shadowClipspacePosition.z*0.5+0.5);
	
	//float shadowLinearz1 = shadowClipspacePosition.z;
	float notShadow = 1;
	
	if (shadowLinearz1 > 0 && shadowLinearz1 < 1)
	{
		notShadow = shadowLinearz1-shadowMap1.x<=shadowBias ? 1 : 0;
		
		// "variance shadow map" technique to refine notShadow
		const float light_vsm_epsilon = shadowBias;
		vec2 moments = shadowMap1.xy;
		float E_x2 = moments.y;
		float Ex_2 = moments.x * moments.x;
		float variance = min(max(E_x2 - Ex_2, 0.0) + light_vsm_epsilon*10, 1.0);
		float m_d = (moments.x - shadowLinearz1);
		float p = variance / (variance + m_d * m_d);
		notShadow = max(notShadow, p);
		//notShadow = 1-min((1-notShadow)*4,1);
	}
	
	final = vec3(notShadow);
	
	#ifdef USE_OUTPUTS
	outputColor.a = 1;
	outputColor.rgb = final;
	#else
	gl_FragColor.a = 1;
	gl_FragColor.rgb = final;
	#endif
}
