varying vec2 tu0coord;
varying vec3 eyespace_view_direction;

uniform sampler2D tu0_2D;
uniform sampler2D tu1_2D;
uniform sampler2D tu2_2D;
uniform sampler2D tu3_2D;

#ifndef _REFLECTIONDISABLED_
uniform samplerCube tu4_cube; //reflection map
#endif

// shadowed directional light
uniform vec3 directlight_eyespace_direction;

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
	float gbuf_depth = texture2D(tu3_2D, tu0coord).r;
	
	// early discard
	if (gbuf_depth == 1)
		discard;
	
	vec4 gbuf_material_properties = texture2D(tu0_2D, tu0coord);
	vec4 gbuf_normal_xy = texture2D(tu1_2D, tu0coord);
	vec4 gbuf_diffuse_albedo = texture2D(tu2_2D, tu0coord);
	
	// decode g-buffer
	vec3 cdiff = GammaCorrect(gbuf_diffuse_albedo.rgb); //diffuse reflectance
	float notshadow = gbuf_diffuse_albedo.a; //direct light occlusion multiplier
	vec3 Rf0 = GammaCorrect(gbuf_material_properties.rgb); //fresnel reflectance value at zero degrees
	float m = gbuf_material_properties.a*256.0+1.0; //micro-scale roughness
	float mpercent = gbuf_material_properties.a;
	vec3 normal;
	//normal.x = (unpackFloatFromVec2i(gbuf_normal_xy.xy)-0.5)*2.0;
	//normal.y = (unpackFloatFromVec2i(gbuf_normal_xy.za)-0.5)*2.0;
	//normal.z = -sqrt(1.0-dot(normal.xy,normal.xy));
	vec2 normal_spherical = vec2(unpackFloatFromVec2i(gbuf_normal_xy.xy),unpackFloatFromVec2i(gbuf_normal_xy.za))*2.0-vec2(1.0,1.0);
	normal = sphericalToXYZ(normal_spherical);
	
	// determine view vector
	vec3 V = normalize(-eyespace_view_direction);
	
	// determine half vector
	vec3 H = normalize(V+directlight_eyespace_direction);
	
	// determine reflection vector and lookup into reflection texture
	vec3 R = reflect(-V,normal);
	vec3 reflection = vec3(0,0,0);
	vec3 ambient = vec3(0.5,0.5,0.5);
	float ambient_reflection_lod = 5;
	vec3 refmapdir = R;
	#ifdef _REFLECTIONDYNAMIC_
	vec3 refmapdir = vec3(-R.z, R.x, -R.y);
	#endif
	
	#ifndef _REFLECTIONDISABLED_
	reflection = GammaCorrect(textureCubeLod(tu4_cube, R, mix(ambient_reflection_lod,0.0,mpercent)).rgb);
	ambient = GammaCorrect(textureCubeLod(tu4_cube, normal, ambient_reflection_lod).rgb);
	#endif
	
	// generate parameters for directional light
	const float sunstrength = 2.0;
	const float ambientstrength = 0.7;
	const float reflectionstrength = 0.5;
	vec3 E_l = vec3(1,1,0.8)*notshadow*sunstrength; //incoming light intensity/color
	float alpha_h = dot(V,H); //cosine of angle between half vector and view direction
	float omega_h = cos_clamped(H,normal); //clamped cosine of angle between half vector and normal
	float omega_i = cos_clamped(directlight_eyespace_direction,normal); //clamped cosine of angle between incoming light direction and surface normal
	
	vec4 final;
	//final.rgb = cdiff*(notshadow*0.5+0.5)*(max(0.0,dot(directlight_eyespace_direction,normal))*0.5+0.5);
	//final.rgb = vec3(1.0,1.0,1.0)*max(0.0,dot(directlight_eyespace_direction,normal));
	final.rgb = CommonBRDF(RealTimeRenderingBRDF(cdiff, m, Rf0, alpha_h, omega_h),E_l,omega_i);
	final.rgb += FresnelEquation(vec3(0,0,0),cos_clamped(V,normal))*Rf0*reflection*reflectionstrength;
	final.rgb += ambient*cdiff*ambientstrength;
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
	//final.rgb = vec3(1.,1.,1.)*(pow(omega_h,gbuf_material_properties.a));
	//final.rgb = vec3(1.,1.,1.)*(gbuf_material_properties.a);
	//final.rgb = vec3(1.,1.,1.)*(omega_h);
	//final.rgb = vec3(1.,1.,1.)*(pow(0.0,0.0));
	//final.rgb = vec3(1.,1.,1.)*(pow(omega_h,max(gbuf_material_properties.a*100.0,1.0)));
	//final.rgb = reflection;
	//final.rgb = ambient;
	//final.rgb = FresnelEquation(vec3(1,1,1)*0.05,alpha_h);
	//vec3 L = directlight_eyespace_direction;
	//Rf0 = vec3(1,1,1)*0.05;
	//final.rgb = vec3(1,1,1)*pow(1.0-cos_clamped(V,normal),2.0);//Rf0 + (vec3(1.,1.,1.)-Rf0)*pow(1.0-alpha_h,5.0);
	//final.rgb = FresnelEquation(vec3(0,0,0),cos_clamped(V,normal))*Rf0*reflection;
	//final.rgb = pow(1.-cos_clamped(V,normal),5.0)*Rf0*reflection;
	//final.rgb = vec3(1,1,1)*pow(1.0-normal.z,1.0);
	//float ny = (unpackFloatFromVec2i(gbuf_normal_xy.za)-0.5)*2.0;
	//final.rgb = vec3(1,1,1)*sqrt(1.0-ny*ny)*4.0;
	//final.rgb = vec3(1,1,1)*notshadow;
	//final.rgb = vec3(1,1,1)*dot(V,normal);
	//final.rgb = vec3(1,1,1)*(V.z*normal.z*0.5+0.5);
	//final.r = notshadow;
	//final.g = (normal.z*0.5+0.5);
	//final.g = dot(V,normal);
	//final.b = final.g;
	//final.rgb = reflection*pow(1.0-cos_clamped(V,normal), 5.0);
	//final.rgb = vec3(1,0,0);
	
	gl_FragColor = final;
	//gl_FragDepth = (gbuf_depth < 1) ? 0.0 : 1.0;
}
