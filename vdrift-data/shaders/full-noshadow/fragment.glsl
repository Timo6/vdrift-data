varying vec2 texcoord_2d;
varying vec3 normal;
uniform sampler2D tu0_2D; //diffuse map
uniform sampler2D tu1_2D; //misc map (includes gloss on R channel, ...
uniform sampler2DShadow tu4_2D; //close shadow map
uniform sampler2DShadow tu5_2D; //far shadow map
uniform samplerCube tu2_cube; //reflection map
uniform sampler2D tu6_2D; //additive map (for brake lights)
//uniform sampler2DRect tu2_2DRect;

//varying vec3 eyecoords;
varying vec3 eyespacenormal;
varying vec3 eyelightposition;
varying vec4 ecpos;
varying vec3 viewdir;

uniform vec3 lightposition;
//varying vec3 halfvector;

//uniform mat4 light_matrix_0;
//uniform mat4 light_matrix_1;

void main()
{
	float notshadowfinal = 1.0;
	
	vec3 normnormal = normalize(normal);
	
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
	vec4 tu6_2D_val = texture2D(tu6_2D, texcoord_2d);
	
	vec3 texcolor = tu0_2D_val.rgb;
	//vec3 diffuse = texcolor*clamp((dot(normal,lightposition)+1.0)*0.7,0.0,1.0);
	float difdot = max(dot(normnormal,lightposition),0.0);
	//notshadow *= min(difdot*10.0,1.0);
	//notshadow *= 1.0-difdot;
	difdot *= notshadowfinal;
	vec3 diffuse = texcolor*difdot;
	
	/*vec3 lightmapdir = mix(-lightposition,normal,notshadowfinal);
	vec3 ambient = texcolor * textureCube(tu3_cube, lightmapdir).rgb;*/
	vec3 ambient = texcolor;
	
	float gloss = tu1_2D_val.r;
	
	//vec3 L = normalize(lightposition - vec3(ecpos));
	vec3 L = normalize(eyelightposition);
	vec3 V = vec3(normalize(-ecpos));
	vec3 halfvec = normalize(L + V);
	vec3 eyespacenormal_norm = normalize(eyespacenormal);
	float specval = max(dot(halfvec, eyespacenormal_norm),0.0);
	
	/*vec3 refnorm = normalize(reflect(normalize(eyecoords),normalize(eyespacenormal)));
	float specval = max(dot(refnorm, normalize(eyelightposition)),0.0);*/
	
	float env_factor = 1.0-max(0.0,eyespacenormal_norm.z*0.9);
	vec3 specular_sun = vec3((pow(specval,128.0)*0.4+pow(specval,4.0)*0.2)*gloss);
	//vec3 refmapdir = reflect(eyespacenormal_norm,halfvec);
	vec3 refmapdir = reflect(viewdir,normnormal);
	vec3 specular_environment = textureCube(tu2_cube, refmapdir).rgb*gloss*env_factor;
	
	float invgloss = (1.0-gloss);
	
	gl_FragColor.rgb = ambient*0.5 + diffuse*0.8*max(0.7,invgloss) + specular_sun*notshadowfinal + specular_environment*max(0.5,notshadowfinal) + tu6_2D_val.rgb;
	//gl_FragColor.rgb = ambient*0.8 + diffuse*0.5 + specular_sun*notshadowfinal + specular_environment*notshadowfinal;
	//gl_FragColor.rgb = ambient*1.0 + specular_sun*notshadowfinal + specular_environment*notshadowfinal;
	
	//gl_FragColor.rgb = specular_environment;
	//gl_FragColor.rgb = viewdir;
	
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
	//gl_FragColor.rgb = vec3(env_factor,env_factor,env_factor);
	
	gl_FragColor.a = tu0_2D_val.a*gl_Color.a;
}
