uniform sampler2D tu0_2D; //diffuse map
uniform sampler2D tu1_2D; //misc map (includes gloss on R channel, ...
uniform sampler2DShadow tu4_2D; //close shadow map
uniform sampler2DShadow tu5_2D; //far shadow map
uniform samplerCube tu2_cube; //reflection map
uniform sampler2D tu6_2D; //additive map (for brake lights)

uniform vec3 lightposition;

varying vec2 texcoord_2d;
varying vec3 normal;
varying vec3 viewdir;
varying vec4 projshadow_0;
varying vec4 projshadow_1;

void main()
{
	vec3 shadowcoords[2];
	shadowcoords[0] = projshadow_0.xyz;
	shadowcoords[1] = projshadow_1.xyz;
	
	const float bound = 1.0;
	const float fade = 10000.0;
	bool effect[2];
		
	for (int i = 0; i < 2; ++i)
	{
		effect[i] = (shadowcoords[i].x < 0.0 || shadowcoords[i].x > 1.0) ||
				(shadowcoords[i].y < 0.0 || shadowcoords[i].y > 1.0) ||
				(shadowcoords[i].z < 0.0 || shadowcoords[i].z > 1.0);
	}
	
	float notshadowfinal = 1.0;
	if (!effect[0])
	{
		//no PCF
		notshadowfinal = shadow2D(tu4_2D, shadowcoords[0]).r;
		
		//2x2 PCF
		/*notshadowfinal = 0.0;
		const float radius = 0.000977;
		for (int v=-1; v<=1; v+=2)
			for (int u=-1; u<=1; u+=2)
			{
				notshadowfinal += shadow2D(tu4_2D,
					shadowcoords[0] + radius*vec3(u, v, 0.0)).r;
			}
		notshadowfinal *= 0.25;*/
		
		//3x3 PCF
		/*notshadowfinal = 0.0;
		const float radius = 0.000977;
		for (int v=-1; v<=1; v++)
			for (int u=-1; u<=1; u++)
			{
				notshadowfinal += shadow2D(tu4_2D,
					shadowcoords[0] + radius*vec3(u, v, 0.0)).r;
			}
		notshadowfinal *= 0.1111;*/
	}
	else if (!effect[1])
	{
		notshadowfinal = shadow2D(tu5_2D, shadowcoords[1]).r;
	}
	
	vec3 normnormal = normalize(normal);
	
	float specval = max(dot(normalize(reflect(viewdir,normnormal)),normalize(lightposition)),0.0);
	
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
	vec4 tu6_2D_val = texture2D(tu6_2D, texcoord_2d);
	
	vec3 texcolor = tu0_2D_val.rgb;
	float difdot = max(dot(normnormal,lightposition),0.0);
	difdot *= notshadowfinal;
	
	const vec3 edge_paint_color = texcolor*0.0;
	float gloss = tu1_2D_val.r;
	float metallic = tu1_2D_val.g;
	
	vec3 diffuse = texcolor*difdot;
	
	vec3 ambient = texcolor;
	
	float env_factor = min(pow(1.0-max(0.0,dot(normalize(-viewdir),normnormal)),3.0),0.6)*0.75+0.2;
	float spec = ((max((pow(specval,512.0)-0.5)*2.0,0.0))*metallic+pow(specval,12.0)*(0.4+(1.0-metallic)*0.8))*gloss;
	vec3 specular_sun = vec3(spec);
	vec3 refmapdir = reflect(viewdir,normnormal);
	
	vec3 specular_environment = textureCube(tu2_cube, refmapdir).rgb*metallic*env_factor;
	
	float invgloss = (1.0-gloss);
	
	vec3 finalcolor = ambient*0.5 + diffuse*0.8*max(0.7,invgloss) + specular_sun*notshadowfinal + specular_environment*max(0.5,notshadowfinal) + tu6_2D_val.rgb;
	
	//do post-processing
	finalcolor = clamp(finalcolor,0.0,1.0);
	finalcolor = ((finalcolor-0.5)*1.2)+0.5;
	
	gl_FragColor.rgb = finalcolor;
	//gl_FragColor.rgb = vec3(env_factor);
	
	gl_FragColor.a = tu0_2D_val.a*gl_Color.a;
}
