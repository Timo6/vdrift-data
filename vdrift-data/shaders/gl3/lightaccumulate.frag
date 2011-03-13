#version 330

uniform sampler2D diffuseAlbedoSampler;
uniform sampler2D depthSampler;
uniform sampler2D normalSampler;
uniform sampler2D materialSampler;
uniform sampler2D emissiveSampler;
uniform vec2 viewportSize;
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform vec4 colorTint;
uniform vec4 directionalLightColor;
uniform vec4 ambientLightColor;
uniform vec3 eyespaceLightDirection;

in vec3 eyespacePosition;
in vec3 uv;

#define USE_OUTPUTS

#ifdef USE_OUTPUTS
invariant out vec4 outputColor;
#endif

float unpackFloatFromVec2i(const vec2 value)
{
	const vec2 unpack_constants = vec2(1.0/256.0, 1.0);
	return dot(unpack_constants,value);
}

vec3 sphericalToXYZ(const vec2 spherical)
{
	vec3 xyz;
	float theta = spherical.x*3.14159265358979323846;
	vec2 sincosTheta = vec2(sin(theta),cos(theta));
	vec2 sincosPhi = vec2(sqrt(1.0-spherical.y*spherical.y), spherical.y);
	xyz.x = sincosTheta.y*sincosPhi.x;
	xyz.y = sincosTheta.x*sincosPhi.x;
	xyz.z = spherical.y;
	return xyz;
}

float cos_clamped(const vec3 V1, const vec3 V2)
{
	return max(0.0,dot(V1,V2));
}

vec3 CommonBRDF(const vec3 brdf, const vec3 E_l, const float omega_i)
{
	return brdf * E_l * omega_i;
}

vec3 FresnelEquation(const vec3 Rf0, const float omega_i)
{
	//return Rf0 + (vec3(1.,1.,1.)-Rf0)*pow(1.0-omega_i,5.0);
	return Rf0 + (vec3(1.,1.,1.)-Rf0)*pow(1.0-omega_i,3.0);
}

// equation 7.49, Real-Time Rendering (third edition) by Akenine-Moller, Haines, Hoffman
vec3 RealTimeRenderingBRDF(const vec3 cdiff, const float m, const vec3 Rf0, const float alpha_h, const float omega_h)
{
	return cdiff + (m/8.0)*FresnelEquation(Rf0,alpha_h)*pow(omega_h,m);
}

// 9-coefficient spherical harmonics; see
// http://graphics.stanford.edu/papers/envmap/
// I generated these coefficients from a vdrift screenshot cubemap
vec3 genericAmbient(vec3 n)
{
	const vec3 L00 = vec3(0.127828, 0.134996, 0.143064);
	const vec3 L1_1 = vec3(0.0782191, 0.0846895, 0.0914452);
	const vec3 L10 = vec3(0.00262751, 0.00178929, 0.00131505);
	const vec3 L11 = vec3(-0.00115066, 0.00039037, 0.0013798);
	const vec3 L2_2 = vec3(-0.00269112, -0.000918181, 0.000237999);
	const vec3 L2_1 = vec3(0.00206233, 0.000806966, 0.000123036);
	const vec3 L20 = vec3(-0.0067301, -0.00879927, -0.0111885);
	const vec3 L21 = vec3(-0.00129254, -0.000877234, -0.0001961);
	const vec3 L22 = vec3(-0.00720356, -0.00989728, -0.0131989);
	
	const float c1 = 0.429043 ;
	const float c2 = 0.511664 ;
	const float c3 = 0.743125 ;
	const float c4 = 0.886227 ;
	const float c5 = 0.247708 ;

	float x = n[0];
	float y = n[1];
	float z = n[2];

	float x2 = x*x;
	float y2 = y*y;
	float z2 = z*z;
	float xy = x*y;
	float yz = y*z;
	float xz = x*z;

	return c1*L22*(x2-y2) + c3*L20*z2 + c4*L00 - c5*L20 
		+ 2*c1*(L2_2*xy + L21*xz + L2_1*yz) 
		+ 2*c2*(L11*x+L1_1*y+L10*z);
}

#ifdef AMBIENT
	#define SCREENSPACE
#endif

#ifdef DIRECTIONAL
	#define SCREENSPACE
#endif

void main(void)
{
	#ifdef SCREENSPACE
		vec2 screencoord = uv.xy;
	#else
		vec2 screencoord = gl_FragCoord.xy/viewportSize;
	#endif
	
	// retrieve g-buffer
	float gbuf_depth = texture2D(depthSampler, screencoord).r;
	
	// early discard
	#ifndef EMISSIVE
		if (gbuf_depth == 1) discard;
	#endif
	
	vec4 gbuf_material_properties = texture2D(materialSampler, screencoord);
	vec4 gbuf_normal_xy = texture2D(normalSampler, screencoord);
	vec4 gbuf_diffuse_albedo = texture2D(diffuseAlbedoSampler, screencoord);
	
	// decode g-buffer
	vec3 cdiff = gbuf_diffuse_albedo.rgb; //diffuse reflectance
	float notshadow = gbuf_diffuse_albedo.a; // light occlusion multiplier
	vec3 Rf0 = gbuf_material_properties.rgb; //fresnel reflectance value at zero degrees
	float mpercent = gbuf_material_properties.a;
	float m = mpercent*mpercent*256.0; //micro-scale roughness
	vec2 normal_spherical = vec2(unpackFloatFromVec2i(gbuf_normal_xy.xy),unpackFloatFromVec2i(gbuf_normal_xy.zw))*2.0-vec2(1.0,1.0);
	vec3 normal = sphericalToXYZ(normal_spherical);
	
	// determine view vector
	vec3 V = normalize(-eyespacePosition);
	
	// flip back-pointing face normals to point out the other direction
	//normal *= -sign(dot(V,normal));
	//normal.z = abs(normal.z);
	//normal.z = -normal.z;
	
	vec3 final = vec3(0,0,0);
	
	#ifdef AMBIENT
		final = cdiff*genericAmbient(normal)*ambientLightColor.rgb;
	#endif
	
	#ifdef DIRECTIONAL
		vec3 E_l = directionalLightColor.rgb;
		vec3 light_direction = normalize(eyespaceLightDirection);
		float omega_i = cos_clamped(light_direction,normal); //clamped cosine of angle between incoming light direction and surface normal
		vec3 H = normalize(V+light_direction);
		float alpha_h = clamp(dot(V,H),-1.0,1.0); //cosine of angle between half vector and view direction
		float omega_h = cos_clamped(H,normal); //clamped cosine of angle between half vector and normal
		final = CommonBRDF(RealTimeRenderingBRDF(cdiff, m, Rf0, alpha_h, omega_h),E_l,omega_i);
	#endif
	
	#ifdef OMNI
		float eyespace_z = projectionMatrix[3].z / (gbuf_depth * -2.0 + 1.0 - projectionMatrix[2].z); //http://www.opengl.org/discussion_boards/ubbthreads.php?ubb=showflat&Number=277938
		vec3 gbuf_eyespace_pos = vec3(eyespacePosition.xy/eyespacePosition.z*eyespace_z,eyespace_z); //http://lumina.sourceforge.net/Tutorials/Deferred_shading/Point_light.html
		vec3 light_center = (viewMatrix*modelMatrix[3]).xyz;
		float light_scale = length(modelMatrix[0].xyz);
		float attenuation_radius = light_scale*.707;
		float falloff_radius = attenuation_radius;
		//attenuation_radius = 1;
		//falloff_radius = 1;
		float dist = max(0.1*light_scale,distance(gbuf_eyespace_pos,light_center));
		float attenuation = max(0.0,(-dist/falloff_radius+1.0)*attenuation_radius/dist);
		//float attenuation = max(0.0,(-dist/falloff_radius+1.0));
		vec3 E_l = colorTint.rgb*attenuation;
		vec3 light_direction = -normalize(gbuf_eyespace_pos - light_center);
		
		//light_direction=normalize(vec3(0,0,1));
		//E_l = vec3(1,1,1);
		
		float omega_i = cos_clamped(light_direction,normal); //clamped cosine of angle between incoming light direction and surface normal
		vec3 H = normalize(V+light_direction);
		float alpha_h = clamp(dot(V,H),-1.0,1.0); //cosine of angle between half vector and view direction
		float omega_h = cos_clamped(H,normal); //clamped cosine of angle between half vector and normal
		final = CommonBRDF(RealTimeRenderingBRDF(cdiff, m, Rf0, alpha_h, omega_h),E_l,omega_i);
	#endif
	
	#ifdef EMISSIVE
		final = texture2D(emissiveSampler, uv.xy).rgb*colorTint.rgb;
	#endif
	
	/*#ifndef DIRECTIONAL
		final *= 0;
	#endif*/
	
	// add source light
	#ifdef USE_OUTPUTS
	outputColor.a = 1;
	outputColor.rgb = final;
	//outputColor.rgb = gbuf_material_properties.rgb;
		#ifdef OMNI
		//outputColor.rgb = cos_clamped(light_direction,normal)*vec3(1,1,1);
		#endif
	#else
	gl_FragColor.a = 1;
	gl_FragColor.rgb = final;
	//gl_FragColor.rgb = gbuf_material_properties.rgb;
	#endif
}
