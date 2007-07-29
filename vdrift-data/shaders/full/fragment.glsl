varying vec2 texcoord_2d;
varying vec3 normal;
uniform sampler2D tu0_2D;
uniform sampler2D tu1_2D;
uniform sampler2DShadow tu2_2D;
uniform sampler2DShadow tu3_2D;
//uniform sampler2DRect tu2_2DRect;

uniform float screenw;
uniform float screenh;

varying vec3 eyecoords;
varying vec3 eyespacenormal;
uniform vec3 eyelightposition;
varying vec4 ecpos;

uniform vec3 lightposition;
//varying vec3 halfvector;

varying vec4 projshadow_0;
varying vec4 projshadow_1;

//uniform mat4 light_matrix_0;
//uniform mat4 light_matrix_1;

void main()
{
	vec3 shadowcoords[2];
	shadowcoords[0] = projshadow_0.xyz;
	shadowcoords[1] = projshadow_1.xyz;
	//shadowcoords[0] = (light_matrix_0 * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_FragCoord))).xyz;
	//shadowcoords[1] = (light_matrix_1 * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_FragCoord))).xyz;
	float notshadow[2];
	notshadow[0] = shadow2D(tu2_2D, shadowcoords[0]).r;
	notshadow[1] = shadow2D(tu3_2D, shadowcoords[1]).r;
	
	const float bound = 1.0;
	const float fade = 10.0;
	float effect[2];
	
	for (int i = 0; i < 2; ++i)
	//for (int i = 3; i < 4; ++i)
	{
		shadowcoords[i] = clamp(shadowcoords[i], 0.0, bound);
		float xf1 = 1.0-min(1.0,shadowcoords[i].x*fade);
		float xf2 = max(0.0,shadowcoords[i].x*fade-(fade-1.0));
		float yf1 = 1.0-min(1.0,shadowcoords[i].y*fade);
		float yf2 = max(0.0,shadowcoords[i].y*fade-(fade-1.0));
		float zf1 = 1.0-min(1.0,shadowcoords[i].z*fade);
		float zf2 = max(0.0,shadowcoords[i].z*fade-(fade-1.0));
		effect[i] = max(xf1,max(xf2,max(yf1,max(yf2,max(zf1,zf2)))));
		//notshadow[i] = max(notshadow[i],effect[i]);
	}
	
	float notshadowfinal = notshadow[0];
	notshadowfinal = mix(notshadowfinal,notshadow[1],effect[0]);
	notshadowfinal = max(notshadowfinal,effect[1]);
	/*notshadowfinal = mix(notshadowfinal,notshadow[1],effect[0]);
	notshadowfinal = mix(notshadowfinal,notshadow[2],effect[1]);
	notshadowfinal = max(notshadowfinal,effect[2]);*/
	
	
	
	
	//float notshadow = texture2DRect(tu2_2DRect, gl_FragCoord.xy*0.5).r;
	//float notshadow = texture2DRect(tu2_2DRect, gl_FragCoord.xy).r;
	
	vec3 normnormal = normalize(normal);
	
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
	
	vec3 texcolor = tu0_2D_val.rgb;
	vec3 ambient = texcolor;
	//vec3 diffuse = texcolor*clamp((dot(normal,lightposition)+1.0)*0.7,0.0,1.0);
	float difdot = max(dot(normnormal,lightposition),0.0);
	//notshadow *= min(difdot*10.0,1.0);
	//notshadow *= 1.0-difdot;
	difdot *= notshadowfinal;
	vec3 diffuse = texcolor*difdot;
	
	float gloss = tu1_2D_val.r;
	
	//vec3 L = normalize(lightposition - vec3(ecpos));
	vec3 L = normalize(eyelightposition);
	vec3 V = vec3(normalize(-ecpos));
	vec3 halfvec = normalize(L + V);
	float specval = max(dot(halfvec, normalize(eyespacenormal)),0.0);
	
	/*vec3 refnorm = normalize(reflect(normalize(eyecoords),normalize(eyespacenormal)));
	float specval = max(dot(refnorm, normalize(eyelightposition)),0.0);*/
	
	vec3 specular = vec3((pow(specval,128.0)*0.4+pow(specval,4.0)*0.2)*gloss);
	
	gl_FragColor.rgb = ambient*0.5 + diffuse*1.0 + specular*notshadowfinal;
	
	//gl_FragColor.rgb = diffuse;
	//gl_FragColor.rgb = texture2DRect(tu2_2DRect, gl_FragCoord.xy).rgb;
	//gl_FragColor.rgb = vec3(1,1,1)*(projshadow.z/projshadow.w);
	//gl_FragColor.rgb = projshadow.xyz/projshadow.w;
	//gl_FragColor = texture2DProj(tu2_2D,projshadow);
	//gl_FragColor.rgb = specular;
	//gl_FragColor.rgb = eyecoords;
	//vec3 halfvec = normalize(eyecoords + lightposition);
	//float NdotHV = max(dot(normal, halfvec),0.0);
	//gl_FragColor.rgb = vec3(specular);
	//gl_FragColor.rgb = vec3(dot(lightposition,normal));
	//gl_FragColor.rgb = vec3(normal.y);
	
	gl_FragColor.a = tu0_2D_val.a*gl_Color.a;
}
