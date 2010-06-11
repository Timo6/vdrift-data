uniform sampler2D tu0_2D; // diffuse
uniform sampler2D tu1_2D; //misc map 1 (specular color in RGB, specular power in A)
uniform sampler2D tu2_2D; //misc map 2 (nothing in RGB yet, bump map in A)

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

// surf_norm MUST BE UNIT LENGTH
vec3 PerturbNormal(vec3 surf_pos, vec3 surf_norm, float height)
{
	vec3 vSigmaS = dFdx(surf_pos);
	vec3 vSigmaT = dFdy(surf_pos);
	vec3 vN = surf_norm;
	
	vec3 vR1 = cross(vSigmaT, vN) ;
	vec3 vR2 = cross(vN, vSigmaS) ;
	float fDet = dot(vSigmaS, vR1) ;
	float dBs = dFdx(height);
	float dBt = dFdy(height);
	vec3 vSurfGrad = sign(fDet) * (dBs * vR1 + dBt * vR2);
	return normalize(abs(fDet) * vN - vSurfGrad);
}

vec3 PerturbNormalWithdxdy(vec3 surf_pos, vec3 surf_norm, float scale, float heightdx, float heightdy)
{
	vec3 vSigmaS = dFdx(surf_pos);
	vec3 vSigmaT = dFdy(surf_pos);
	vec3 vN = surf_norm;
	
	vec3 vR1 = cross(vSigmaT, vN) ;
	vec3 vR2 = cross(vN, vSigmaS) ;
	float fDet = dot(vSigmaS, vR1) ;
	float dBs = heightdx*scale;
	float dBt = heightdy*scale;
	vec3 vSurfGrad = sign(fDet) * (dBs * vR1 + dBt * vR2);
	return normalize(abs(fDet) * vN - vSurfGrad);
}

vec2 TweakTextureCoordinates(vec2 incoord, float textureSize)
{
	vec2 t = incoord * textureSize - .5;
	vec2 frc = fract(t);
	vec2 flr = t - frc;
	frc = frc*frc*(3.-2.*frc);//frc*frc*frc*(10+frc*(6*frc-15));
	return (flr + frc + .5)*(1./textureSize);
}

vec2 moveTexcoordsOneTexelX(vec2 tucoord, float texsize)
{
	return tucoord + normalize(dFdx(tucoord))/texsize;
	//return tucoord + dFdx(tucoord);
}

vec2 moveTexcoordsOneTexelY(vec2 tucoord, float texsize)
{
	return tucoord + normalize(dFdy(tucoord))/texsize;
	//return tucoord + dFdy(tucoord);
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
	
	vec4 miscmap1 = texture2D(tu1_2D, tu0coord);
	//vec4 miscmap2 = texture2D(tu2_2D, TweakTextureCoordinates(tu0coord, 512.0));
	vec4 miscmap2 = texture2D(tu2_2D, tu0coord);
	vec4 miscmap2x = texture2D(tu2_2D, moveTexcoordsOneTexelX(tu0coord, 512.));
	vec4 miscmap2y = texture2D(tu2_2D, moveTexcoordsOneTexelY(tu0coord, 512.));
	float heightdx = (miscmap2x.a - miscmap2.a)*length(dFdx(tu0coord)*512.0);
	float heightdy = (miscmap2y.a - miscmap2.a)*length(dFdy(tu0coord)*512.0);
	float notshadow = 1.0;
	
	vec3 normal = normalize(N);
	//normal = PerturbNormal(V, normal, miscmap2.a);
	normal = PerturbNormalWithdxdy(V, normal, 1.0, heightdx, heightdy);
	//vec2 normal_x = packFloatToVec2i(normal.x*0.5+0.5);
	//vec2 normal_y = packFloatToVec2i(normal.y*0.5+0.5);
	vec2 normal_topack = vec2(atan(normal.y,normal.x)/3.14159265358979323846, normal.z)*0.5+vec2(0.5,0.5);
	vec2 normal_x = packFloatToVec2i(normal_topack.x);
	vec2 normal_y = packFloatToVec2i(normal_topack.y);
	
	// compatibility with old miscmap1 packing of gloss on R channel, metallic on G channel
	float m = miscmap1.r;
	vec3 Rf0 = vec3(1.0,1.0,1.0)*(min(1.0,m*2.0));
	
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
