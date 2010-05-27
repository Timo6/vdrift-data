#extension GL_ARB_texture_rectangle : enable

varying vec2 tu0coord;
varying vec3 eyespace_view_direction;

uniform sampler2DRect tu0_2DRect;
uniform sampler2DRect tu1_2DRect;
uniform sampler2DRect tu2_2DRect;
uniform sampler2DRect tu3_2DRect;

// shadowed directional light
uniform vec3 directlight_eyespace_direction;

float unpackFloatFromVec2i(const vec2 value)
{
	const vec2 unpack_constants = vec2(1.0/256.0, 1.0);
	return dot(unpack_constants,value);
}

#define GAMMA 2.2

vec3 UnGammaCorrect(vec3 color)
{
	return pow(color, vec3(1.0/GAMMA,1.0/GAMMA,1.0/GAMMA));
}

vec3 GammaCorrect(vec3 color)
{
	return pow(color, vec3(GAMMA,GAMMA,GAMMA));
}

#undef GAMMA

#define PI 3.14159265

float cos_clamped(const vec3 V1, const vec3 V2)
{
	return max(0.0,dot(V1,V2));
}

vec3 CommonBRDF(const vec3 input, const vec3 E_l, const float omega_i)
{
	return input * E_l * omega_i;
}

vec3 FresnelEquation(const vec3 Rf0, const float omega_i)
{
	return Rf0 + (vec3(1.,1.,1.)-Rf0)*pow(1.0-omega_i,5.0);
}

// equation 7.49, Real-Time Rendering (third edition) by Akenine-Moller, Haines, Hoffman
vec3 RealTimeRenderingBRDF(const vec3 cdiff, const float m, const vec3 Rf0, const float alpha_h, const float omega_h)
{
	return cdiff/PI + ((m+8)/(8*PI))*FresnelEquation(Rf0,alpha_h)*pow(omega_h,m);
}

void main()
{
	// retrieve g-buffer
	vec4 gbuf_material_properties = texture2DRect(tu0_2DRect, tu0coord);
	vec4 gbuf_normal_xy = texture2DRect(tu1_2DRect, tu0coord);
	vec4 gbuf_diffuse_albedo = texture2DRect(tu2_2DRect, tu0coord);
	float gbuf_depth = texture2DRect(tu3_2DRect, tu0coord).r;
	
	// decode g-buffer
	vec3 Rf0 = GammaCorrect(gbuf_material_properties.rgb); //fresnel reflectance value at zero degrees
	float m = gbuf_material_properties.a; //micro-scale roughness
	vec3 normal;
	normal.x = (unpackFloatFromVec2i(gbuf_normal_xy.xy)-0.5)*2.0;
	normal.y = (unpackFloatFromVec2i(gbuf_normal_xy.za)-0.5)*2.0;
	normal.z = sqrt(1.0-normal.x*normal.x-normal.y*normal.y);
	vec3 cdiff = GammaCorrect(gbuf_diffuse_albedo.rgb); //diffuse reflectance
	float notshadow = gbuf_diffuse_albedo.a; //direct light occlusion multiplier
	
	// determine view vector
	vec3 V = normalize(-eyespace_view_direction);
	
	// determine half vector
	vec3 H = normalize(V+directlight_eyespace_direction);
	
	// generate parameters for directional light
	vec3 E_l = vec3(1,1,1)*notshadow; //incoming light intensity/color
	float alpha_h = cos_clamped(directlight_eyespace_direction,H); //clamped cosine of angle between half vector and incoming light direction
	float omega_h = cos_clamped(H,normal); //clamped cosine of angle between half vector and normal
	float omega_i = cos_clamped(directlight_eyespace_direction,normal); //clamped cosine of angle between incoming light direction and surface normal
	
	vec4 final;
	//final.rgb = cdiff*(notshadow*0.5+0.5)*(max(0.0,dot(directlight_eyespace_direction,normal))*0.5+0.5);
	//final.rgb = vec3(1.0,1.0,1.0)*max(0.0,dot(directlight_eyespace_direction,normal));
	m *= 100;
	vec3 ambient = cdiff*0.2;
	final.rgb = CommonBRDF(RealTimeRenderingBRDF(cdiff, m, Rf0, alpha_h, omega_h),E_l,omega_i)+ambient;
	//final.rgb = CommonBRDF(cdiff,E_l,omega_i)+ambient;
	final.a = 1.0;
	
	final.rgb = UnGammaCorrect(final.rgb);
	
	//final.rgb = vec3(1.0,1.0,1.0)*normal.x;
	//final.rgb = vec3(gbuf_normal_xy.x, gbuf_normal_xy.y,0.0);
	//final.rgb = normal;
	//final.rgb = directlight_eyespace_direction;
	//final.rgb = vec3(1.0,1.0,1.0)*gbuf_depth;
	//final.rgb = normalize(eyespace_view_direction);
	//final.rgb = gbuf_diffuse_albedo.rgb;
	
	gl_FragColor = final;
}
