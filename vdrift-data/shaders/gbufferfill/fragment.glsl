uniform sampler2D tu0_2D; // diffuse
uniform sampler2D tu1_2D; //misc map (includes gloss on R channel, metallic on G channel, ...

varying vec2 tu0coord;

#ifdef _SHADOWS_
uniform sampler2DShadow tu4_2D; //close shadow map
#ifdef _CSM2_
uniform sampler2DShadow tu5_2D; //far shadow map
#endif
#ifdef _CSM3_
uniform sampler2DShadow tu6_2D; //far far shadow map
#endif
#endif

varying vec3 N;
varying vec3 V;

#ifdef _SHADOWS_
varying vec4 projshadow_0;
#ifdef _CSM2_
varying vec4 projshadow_1;
#endif
#ifdef _CSM3_
varying vec4 projshadow_2;
#endif
#endif

float shadow_lookup(sampler2DShadow tu, vec3 coords)
{
	float notshadowfinal = float(shadow2D(tu, coords).r);
	
	return notshadowfinal;
}

float GetShadows()
{
#ifdef _SHADOWS_
	
	#ifdef _CSM3_
	const int numcsm = 3;
	#else
		#ifdef _CSM2_
	const int numcsm = 2;
		#else
	const int numcsm = 1;
		#endif
	#endif
	
	vec3 shadowcoords[numcsm];
	
	shadowcoords[0] = projshadow_0.xyz;
	#ifdef _CSM2_
	shadowcoords[1] = projshadow_1.xyz;
	#endif
	#ifdef _CSM3_
	shadowcoords[2] = projshadow_2.xyz;
	#endif
	
	const float boundmargin = 0.1;
	const float boundmax = 1.0 - boundmargin;
	const float boundmin = 0.0 + boundmargin;
	
	bool effect[numcsm];
	
	for (int i = 0; i < numcsm; i++)
	{
		effect[i] = (shadowcoords[i].x < boundmin || shadowcoords[i].x > boundmax) ||
		(shadowcoords[i].y < boundmin || shadowcoords[i].y > boundmax) ||
		(shadowcoords[i].z < boundmin || shadowcoords[i].z > boundmax);
	}
	
	//shadow lookup that works better with ATI cards:  no early out
	float notshadow[numcsm];
	notshadow[0] = shadow_lookup(tu4_2D, shadowcoords[0]);
	#ifdef _CSM2_
	notshadow[1] = shadow_lookup(tu5_2D, shadowcoords[1]);
	#endif
	#ifdef _CSM3_
	notshadow[2] = shadow_lookup(tu6_2D, shadowcoords[2]);
	#endif
	
	//simple shadow mixing, no shadow fade-in
	//float notshadowfinal = notshadow[0];
	float notshadowfinal = max(notshadow[0],float(effect[0]));
	#ifdef _CSM3_
	notshadowfinal = mix(notshadowfinal,mix(notshadow[1],notshadow[2],float(effect[1])),float(effect[0]));
	notshadowfinal = max(notshadowfinal,float(effect[2]));
	#else
		#ifdef _CSM2_
	notshadowfinal = mix(notshadowfinal,notshadow[1],float(effect[0]));
	notshadowfinal = max(notshadowfinal,float(effect[1]));
		#endif
	#endif
	
	#else //no SHADOWS
	float notshadowfinal = 1.0;
	#endif

	return notshadowfinal;
}

vec2 packFloatToVec2i(const float value)
{
	vec2 bitSh = vec2(256.0, 1.0);
	vec2 bitMsk = vec2(0.0, 1.0/256.0);
	vec2 res = fract(value * bitSh);
	res -= res.xx * bitMsk;
	return res;
}

void main()
{
	vec4 albedo = texture2D(tu0_2D, tu0coord);
	
	#ifdef _CARPAINT_
	albedo.rgb = mix(gl_Color.rgb, albedo.rgb, albedo.a); // albedo is mixed from diffuse and object color
	#else
	// emulate alpha testing
	if (albedo.a < 0.5)
		discard;
	#endif
	
	vec4 miscmap = texture2D(tu1_2D, tu0coord);
	#ifdef _FORWARD_SHADOWS_
	float notshadow = GetShadows();
	#else
	float notshadow = 1.0;
	#endif
	
	vec3 normal = normalize(N);
	//vec2 normal_x = packFloatToVec2i(normal.x*0.5+0.5);
	//vec2 normal_y = packFloatToVec2i(normal.y*0.5+0.5);
	vec2 normal_topack = vec2(atan(normal.y,normal.x)/3.14159265358979323846, normal.z)*0.5+vec2(0.5,0.5);
	vec2 normal_x = packFloatToVec2i(normal_topack.x);
	vec2 normal_y = packFloatToVec2i(normal_topack.y);
	
	float m = miscmap.r;
	//vec3 Rf0 = vec3(1.0,1.0,1.0)*(miscmap.g*0.5+);
	vec3 Rf0 = vec3(1.0,1.0,1.0)*(min(1.0,m*2.0));
	//m = 1;
	//Rf0 = vec3(1.0,1.0,1.0)*0.1;
	//m = 1;
	//Rf0 = vec3(1.0,1.0,1.0)*0.05;
	
	gl_FragData[0] = vec4(Rf0.r,Rf0.g,Rf0.b,m);
	gl_FragData[1] = vec4(normal_x.x, normal_x.y, normal_y.x, normal_y.y);
	gl_FragData[2] = vec4(albedo.rgb,notshadow);

	//gl_FragData[2].a = -normal.z*4.0;//;sqrt(1.0-normal.x*normal.x-normal.y*normal.y)*4.0;
	//gl_FragData[2].a = dot(normal,normalize(-V));
	//gl_FragData[2].a = normal.z*normalize(-V).z*0.5+0.5;
	//gl_FragData[2].a = normal.z*0.5+0.5;
	//gl_FragData[2].rgb = normalize(-V);

	/*vec3 Vv = normalize(V);
	//Vv.b = -Vv.b;
	gl_FragData[2] = vec4(Vv,1);*/
}
