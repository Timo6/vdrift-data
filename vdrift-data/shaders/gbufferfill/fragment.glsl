uniform sampler2D tu0_2D; // diffuse
uniform sampler2D tu1_2D; //misc map (includes gloss on R channel, metallic on G channel, ...

varying vec2 tu0coord;

varying vec3 N;
varying vec3 V;

vec2 packFloatToVec2i(const float val)
{
	float value = clamp(val,0.0,0.9999);
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
	float notshadow = 1.0;
	
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
