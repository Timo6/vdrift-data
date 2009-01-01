uniform sampler2D tu0_2D; //diffuse map
uniform sampler2D tu1_2D; //misc map (includes gloss on R channel, metallic on G channel, ...
#ifdef _SHADOWS_
#ifdef _SHADOWSULTRA_
uniform sampler2D tu4_2D; //close shadow map
#else
uniform sampler2DShadow tu4_2D; //close shadow map
#endif
#ifdef _CSM2_
uniform sampler2DShadow tu5_2D; //far shadow map
#endif
#ifdef _CSM3_
uniform sampler2DShadow tu6_2D; //far far shadow map
#endif
#endif
#ifndef _REFLECTIONDISABLED_
uniform samplerCube tu2_cube; //reflection map
#endif
uniform sampler2D tu3_2D; //additive map (for brake lights)

uniform vec3 lightposition;

varying vec2 texcoord_2d;
varying vec3 normal_eye;
varying vec3 viewdir;
#ifdef _SHADOWS_
varying vec4 projshadow_0;
#ifdef _CSM2_
varying vec4 projshadow_1;
#endif
#ifdef _CSM3_
varying vec4 projshadow_2;
#endif
#endif

#ifdef _SHADOWSULTRA_
#define    BLOCKER_SEARCH_NUM_SAMPLES 16
#define    PCF_NUM_SAMPLES 16
#define    NEAR_PLANE 9.5
#define    LIGHT_WORLD_SIZE .05
#define    LIGHT_FRUSTUM_WIDTH 3.75
// Assuming that LIGHT_FRUSTUM_WIDTH == LIGHT_FRUSTUM_HEIGHT
#define LIGHT_SIZE_UV (LIGHT_WORLD_SIZE / LIGHT_FRUSTUM_WIDTH)

float unpackFloatFromVec4i(const vec4 value)
{
	const vec4 bitSh = vec4(1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
	return(dot(value, bitSh));
}

float unpackFloatFromVec3i(const vec3 value)
{
	const vec3 bitSh = vec3(1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0);
	return(dot(value, bitSh));
}

float unpackFloatFromVec2i(const vec2 value)
{
	const vec2 unpack_constants = vec2(1.0/256.0, 1.0);
	return dot(unpack_constants,value);
}

float shadow_comparison(sampler2D tu, vec2 uv, float comparison)
{
	float lookupvalue = unpackFloatFromVec3i(texture2D(tu, uv).rgb);
	//if (lookupvalue < 0.5+1.5/256.0) lookupvalue -= 1.0/256.0;
	//return clamp((lookupvalue - comparison)*100.0,-0.5,0.5)+0.5;
	return lookupvalue > comparison ? 1.0 : 0.0;
}

float PenumbraSize(float zReceiver, float zBlocker) //Parallel plane estimation
{
	return (zReceiver - zBlocker) / zBlocker;
}

void FindBlocker(in vec2 poissonDisk[16], in sampler2D tu,
		 out float avgBlockerDepth,
		 out float numBlockers,
		 vec2 uv, float zReceiver )
{
	//This uses similar triangles to compute what
	//area of the shadow map we should search
	//float searchWidth = LIGHT_SIZE_UV * (zReceiver - NEAR_PLANE) / zReceiver;
	float searchWidth = 10.0/2048.0;
	//float searchWidth = LIGHT_SIZE_UV;
	float blockerSum = 0;
	numBlockers = 0;
	for( int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; ++i )
	{
		//float shadowMapDepth = tDepthMap.SampleLevel(PointSampler,uv + poissonDisk[i] * searchWidth,0);
		float shadowMapDepth = unpackFloatFromVec3i(texture2D(tu, uv + poissonDisk[i] * searchWidth).rgb);
		if ( shadowMapDepth < zReceiver ) {
			blockerSum += shadowMapDepth;
			numBlockers++;
		}
	}
	avgBlockerDepth = blockerSum / numBlockers;
}

float PCF_Filter( in vec2 poissonDisk[16], in sampler2D tu, in vec2 uv, in float zReceiver, in float filterRadiusUV )
{
	float sum = 0.0f;
	for ( int i = 0; i < PCF_NUM_SAMPLES; ++i )
	{
		vec2 offset = poissonDisk[i] * filterRadiusUV;
		sum += shadow_comparison(tu, uv + offset, zReceiver);
	}
	return sum / PCF_NUM_SAMPLES;
	//vec2 offset = vec2(1.0/2048.0,1.0/2048.0);
	//vec2 offset = vec2(0.0,0.0);
	//return unpackFloatFromVec4i(texture2D(tu, uv + offset)) >= zReceiver ? 1.0 : 0.0;
	//return unpackFloatFromVec3i(texture2D(tu, uv + offset).rgb) > zReceiver + 1.0/(256.0*256.0) ? 1.0 : 0.0;
	//return unpackFloatFromVec3i(texture2D(tu, uv + offset).rgb) > zReceiver + 1.0/(256.0*4.0) ? 1.0 : 0.0;
	//return unpackFloatFromVec2i(texture2D(tu, uv + offset).rg) >= zReceiver ? 1.0 : 0.0;
}

float PCSS ( in vec2 poissonDisk[16], in sampler2D tu, vec3 coords )
{
	vec2 uv = coords.xy;
	float zReceiver = coords.z; // Assumed to be eye-space z in this code
	// STEP 1: blocker search
	float avgBlockerDepth = 0;
	float numBlockers = 0;
	FindBlocker( poissonDisk, tu, avgBlockerDepth, numBlockers, uv, zReceiver );
	if( numBlockers < 1 )
		//There are no occluders so early out (this saves filtering)
		return 1.0f;
	// STEP 2: penumbra size
	float penumbraRatio = PenumbraSize(zReceiver, avgBlockerDepth);
	//float filterRadiusUV = penumbraRatio * LIGHT_SIZE_UV * NEAR_PLANE / coords.z;
	float filterRadiusUV = clamp(penumbraRatio*0.05,0,20.0/2048.0);
	//float filterRadiusUV = penumbraRatio*(256.0/2048.0);
	// STEP 3: filtering
	return PCF_Filter( poissonDisk, tu, uv, zReceiver, filterRadiusUV );
}

float shadow_lookup(sampler2D tu, vec3 coords)
#else
float shadow_lookup(sampler2DShadow tu, vec3 coords)
#endif
{
	#ifdef _SHADOWSULTRA_
	/*//3x3 PCF
	float notshadowfinal = 0.0;
	float radius = 0.0007324219;
	for (int v=-1; v<=1; v++)
		for (int u=-1; u<=1; u++)
		{
			notshadowfinal += float(shadow2D(tu,
				coords + radius*vec3(u, v, 0.0)).r);
		}
	notshadowfinal *= 0.1111;*/
	/*float notshadowfinal = 0.0;
	if (texture2D(tu, coords.xy).r > coords.z)
		notshadowfinal = 1.0;*/
	vec2 poissonDisk[16];
	poissonDisk[0] = vec2( -0.94201624, -0.39906216 );
	poissonDisk[1] = vec2( 0.94558609, -0.76890725 );
	poissonDisk[2] = vec2( -0.094184101, -0.92938870 );
	poissonDisk[3] = vec2( 0.34495938, 0.29387760 );
	poissonDisk[4] = vec2( -0.91588581, 0.45771432 );
	poissonDisk[5] = vec2( -0.81544232, -0.87912464 );
	poissonDisk[6] = vec2( -0.38277543, 0.27676845 );
	poissonDisk[7] = vec2( 0.97484398, 0.75648379 );
	poissonDisk[8] = vec2( 0.44323325, -0.97511554 );
	poissonDisk[9] = vec2( 0.53742981, -0.47373420 );
	poissonDisk[10] = vec2( -0.26496911, -0.41893023 );
	poissonDisk[11] = vec2( 0.79197514, 0.19090188 );
	poissonDisk[12] = vec2( -0.24188840, 0.99706507 );
	poissonDisk[13] = vec2( -0.81409955, 0.91437590 );
	poissonDisk[14] = vec2( 0.19984126, 0.78641367 );
	poissonDisk[15] = vec2( 0.14383161, -0.14100790 );
	//float notshadowfinal = unpackFloatFromVec3i(texture2D(tu, coords.xy).rgb) > coords.z ? 1.0 : 0.0;
	//float notshadowfinal = shadow_comparison(tu, coords.xy, coords.z);
	//float notshadowfinal = clamp((unpackFloatFromVec2i(texture2D(tu, coords.xy).rg) - coords.z)*100.0,-0.5,0.5)+0.5;
	//float notshadowfinal = texture2D(tu, coords.xy).b > coords.z ? 1.0 : 0.0;
	//float notshadowfinal = PCF_Filter(poissonDisk, tu, coords.xy, coords.z, 3.0/2048.0);
	float notshadowfinal = PCSS(poissonDisk, tu, coords);
	#else
	#ifdef _SHADOWSVHIGH_
	/*//2x2 PCF
	float notshadowfinal = 0.0;
	float radius = 0.0003662109;
	for (int v=-1; v<=1; v+=2)
		for (int u=-1; u<=1; u+=2)
		{
			notshadowfinal += float(shadow2D(tu,
				coords + radius*vec3(u, v, 0.0)).r);
		}
	notshadowfinal *= 0.25;*/
	/*float notshadowfinal = 0.0;
	float onepixel = 1.0/2048.0;
	notshadowfinal += float(shadow2D(tu,
				coords + vec3(-onepixel*0.5, -onepixel*0.5, 0.0)).r)*0.444444;
	notshadowfinal += float(shadow2D(tu,
				coords + vec3(onepixel, -onepixel*0.5, 0.0)).r)*0.222222;
	notshadowfinal += float(shadow2D(tu,
				coords + vec3(-onepixel*0.5, onepixel, 0.0)).r)*0.222222;
	notshadowfinal += float(shadow2D(tu,
				coords + vec3(onepixel, onepixel, 0.0)).r)*0.111111;*/
	/*vec2 poissonDisk[16];
	poissonDisk[0] = vec2( -0.94201624, -0.39906216 );
	poissonDisk[1] = vec2( 0.94558609, -0.76890725 );
	poissonDisk[2] = vec2( -0.094184101, -0.92938870 );
	poissonDisk[3] = vec2( 0.34495938, 0.29387760 );
	poissonDisk[4] = vec2( -0.91588581, 0.45771432 );
	poissonDisk[5] = vec2( -0.81544232, -0.87912464 );
	poissonDisk[6] = vec2( -0.38277543, 0.27676845 );
	poissonDisk[7] = vec2( 0.97484398, 0.75648379 );
	poissonDisk[8] = vec2( 0.44323325, -0.97511554 );
	poissonDisk[9] = vec2( 0.53742981, -0.47373420 );
	poissonDisk[10] = vec2( -0.26496911, -0.41893023 );
	poissonDisk[11] = vec2( 0.79197514, 0.19090188 );
	poissonDisk[12] = vec2( -0.24188840, 0.99706507 );
	poissonDisk[13] = vec2( -0.81409955, 0.91437590 );
	poissonDisk[14] = vec2( 0.19984126, 0.78641367 );
	poissonDisk[15] = vec2( 0.14383161, -0.14100790 );
	float radius = 3.0/2048.0;
	for (int i = 0; i < 16; i++)
		notshadowfinal += float(shadow2D(tu,coords + vec3(radius*poissonDisk[i],0.0)).r);*/
	float notshadowfinal = 0.0;
	vec3 poissonDisk[16];
	poissonDisk[0] = vec3( -0.81544232, -0.87912464, 0.0 );
	poissonDisk[1] = vec3( 0.94558609, -0.76890725, 0.0 );
	poissonDisk[2] = vec3( -0.91588581, 0.45771432, 0.0 );
	poissonDisk[3] = vec3( 0.97484398, 0.75648379, 0.0 );
	poissonDisk[4] = vec3( -0.94201624, -0.39906216, 0.0 );
	poissonDisk[5] = vec3( -0.094184101, -0.92938870, 0.0 );
	poissonDisk[6] = vec3( 0.34495938, 0.29387760, 0.0 );
	poissonDisk[7] = vec3( -0.38277543, 0.27676845, 0.0 );
	poissonDisk[8] = vec3( 0.44323325, -0.97511554, 0.0 );
	poissonDisk[9] = vec3( 0.53742981, -0.47373420, 0.0 );
	poissonDisk[10] = vec3( -0.26496911, -0.41893023, 0.0 );
	poissonDisk[11] = vec3( 0.79197514, 0.19090188, 0.0 );
	poissonDisk[12] = vec3( -0.24188840, 0.99706507, 0.0 );
	poissonDisk[13] = vec3( -0.81409955, 0.91437590, 0.0 );
	poissonDisk[14] = vec3( 0.19984126, 0.78641367, 0.0 );
	poissonDisk[15] = vec3( 0.14383161, -0.14100790, 0.0 );
	float radius = 3.0/2048.0;
	for (int i = 0; i < 16; i++)
		notshadowfinal += float(shadow2D(tu,coords + radius*poissonDisk[i]).r);
	notshadowfinal *= 1.0/16.0;
	/*for (int i = 0; i < 4; i++)
		notshadowfinal += float(shadow2D(tu,coords + radius*poissonDisk[i]).r);
	if (notshadowfinal == 0.0 || notshadowfinal == 4.0) //early out if all values are similar (commented out because it actually decreases performance)
		notshadowfinal *= 0.25;
	else
	{
		for (int i = 4; i < 16; i++)
			notshadowfinal += float(shadow2D(tu,coords + radius*poissonDisk[i]).r);
		notshadowfinal *= 1.0/16.0;
	}*/
	#else
	//no PCF
	float notshadowfinal = float(shadow2D(tu, coords).r);
	#endif
	#endif
	
	return notshadowfinal;
}

void main()
{
	#ifdef _SHADOWS_
	vec3 shadowcoords0 = projshadow_0.xyz;
	#ifdef _CSM2_
	vec3 shadowcoords1 = projshadow_1.xyz;
	#endif
	#ifdef _CSM3_
	vec3 shadowcoords2 = projshadow_2.xyz;
	#endif
	
	float bound = 1.0;
	float fade = 10000.0;
	
	bool effect0 = (shadowcoords0.x < 0.0 || shadowcoords0.x > 1.0) ||
		(shadowcoords0.y < 0.0 || shadowcoords0.y > 1.0) ||
		(shadowcoords0.z < 0.0 || shadowcoords0.z > 1.0);
	
	#ifdef _CSM2_
	bool effect1 = (shadowcoords1.x < 0.0 || shadowcoords1.x > 1.0) ||
		(shadowcoords1.y < 0.0 || shadowcoords1.y > 1.0) ||
		(shadowcoords1.z < 0.0 || shadowcoords1.z > 1.0);
	#endif
	#ifdef _CSM3_
	bool effect2 = (shadowcoords2.x < 0.0 || shadowcoords2.x > 1.0) ||
		(shadowcoords2.y < 0.0 || shadowcoords2.y > 1.0) ||
		(shadowcoords2.z < 0.0 || shadowcoords2.z > 1.0);
	#endif
	
	//bool effect0 = viewdir.z < -10;
	//bool effect1 = viewdir.z < -60;
	
	float notshadowfinal = 1.0;
	if (!effect0)
	{
		notshadowfinal = shadow_lookup(tu4_2D, shadowcoords0);
	}
	#ifdef _CSM2_
	else if (!effect1)
	{
		notshadowfinal = shadow2D(tu5_2D, shadowcoords1).r;
	}
	#endif
	#ifdef _CSM3_
	else if (!effect2)
	{
		notshadowfinal = shadow2D(tu6_2D, shadowcoords2).r;
	}
	#endif
	#else
	float notshadowfinal = 1.0;
	#endif
	
	vec3 normnormal = normalize(normal_eye);
	vec3 normviewdir = normalize(viewdir);
	vec3 normlightposition = normalize(lightposition);
	
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
	vec4 tu3_2D_val = texture2D(tu3_2D, texcoord_2d);
	
	vec3 texcolor = tu0_2D_val.rgb;
	float gloss = tu1_2D_val.r;
	float metallic = tu1_2D_val.g;
	
	float difdot = dot(normnormal,normlightposition);
	
	vec3 diffuse = texcolor*max(difdot,0.0)*notshadowfinal;
	
	vec3 ambient = texcolor;//*(1.0+min(difdot,0.0));
	
	float specval = max(dot(reflect(normviewdir,normnormal),normlightposition),0.0);
	//vec3 halfvec = normalize(normviewdir + normlightposition);
	//float specval = max(0.0,dot(normnormal,halfvec));
	
	float env_factor = min(pow(1.0-max(0.0,dot(-normviewdir,normnormal)),3.0),0.6)*0.75+0.2;
	
	float spec = ((max((pow(specval,512.0)-0.5)*2.0,0.0))*metallic+pow(specval,12.0)*(0.4+(1.0-metallic)*0.8))*gloss;
	
	#ifndef _REFLECTIONDISABLED_
	vec3 refmapdir = reflect(normviewdir,normnormal);
	refmapdir = mat3(gl_TextureMatrix[2]) * refmapdir;
	vec3 specular_environment = textureCube(tu2_cube, refmapdir).rgb*metallic*env_factor;
	#else
	vec3 specular_environment = vec3(0,0,0);
	#endif
	float inv_environment = 1.0 - (env_factor*metallic);
	
	float invgloss = (1.0-gloss);
	
	vec3 finalcolor = (ambient*0.5 + diffuse*0.8*max(0.7,invgloss))*(inv_environment*0.5+0.5) + vec3(spec)*notshadowfinal + specular_environment*max(0.5,notshadowfinal) + tu3_2D_val.rgb;
	
	//do post-processing
	finalcolor = clamp(finalcolor,0.0,1.0);
	finalcolor = ((finalcolor-0.5)*1.2)+0.5;
	
	gl_FragColor.rgb = finalcolor;
	/*float r = 0;
	if (!effect0)
	  r = 1;
	float g = 0;
	if (!effect1)
	  g = 1;
	gl_FragColor.rgb = vec3(r,g,0);*/
	//gl_FragColor.rgb = vec3(pow(specval,1.0));
	//gl_FragColor.rgb = textureCube(tu2_cube, refmapdir).rgb;
	//gl_FragColor.rgb = normviewdir;
	//gl_FragColor.rgb = normnormal;
	//gl_FragColor.rgb = vec3(max(dot(normnormal,normalize(vec3(gl_LightSource[0].position))),0.0));
	//gl_FragColor.rgb = normlightposition;
	//gl_FragColor.rgb = vec3(max(dot(normnormal,normlightposition),0.0));
	//gl_FragColor.rgb = tu0_2D_val.rgb;
	//gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	
	//vec2 debugcoords = vec2(gl_FragCoord.x/1024.0,gl_FragCoord.y/768.0);
	//gl_FragColor.rgb = texture2D(tu4_2D, debugcoords).rgb;
	//gl_FragColor.rgb = vec3(unpackFloatFromVec3i(texture2D(tu4_2D, debugcoords).rgb));
	//gl_FragColor.rgb = vec3(unpackFloatFromVec4i(texture2D(tu4_2D, debugcoords)));
	//gl_FragColor.rgb = vec3(unpackFloatFromVec2i(texture2D(tu4_2D, debugcoords).rg));
	
	gl_FragColor.a = tu0_2D_val.a*gl_Color.a;
}
