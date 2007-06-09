varying vec2 texcoord_2d;
varying vec3 normal;
uniform sampler2D tu0_2D;
uniform sampler2D tu1_2D;
//uniform samplerCube tu1_cube;
//uniform sampler2D tu2_2D;

varying vec3 eyecoords;
varying vec3 eyespacenormal;

varying vec3 lightposition;

void main()
{
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
	vec3 texcolor = tu0_2D_val.rgb;
	vec3 ambient = texcolor;
	vec3 diffuse = texcolor*clamp((dot(normal,lightposition)+1.0)*0.7,0.0,1.0);
	//vec3 diffuse = texcolor*clamp(dot(normal,lightposition),0.0,1.0);
	vec3 refnorm = normalize(reflect(eyecoords,eyespacenormal));
	//vec3 halfvec = normalize(eyecoords + lightposition);
	//vec3 specular = vec3(pow(clamp(dot(refnorm,lightposition),0.0,1.0),8.0)*0.2);
	float specval = max(dot(refnorm, lightposition),0.0);
	//vec3 specular = vec3(pow(specval,4.0)*0.2);
	float gloss = tu1_2D_val.r;
	//vec3 specular = vec3(pow(specval,4.0)*0.6*gloss);
	vec3 specular = vec3(specval*0.5*gloss);
	//vec3 specular = vec3(pow(specval,16.0)*0.2);
	
	//vec3 reflight = reflect(lightposition,normal);
	//vec3 specular = vec3(max(dot(eyecoords, reflight),0.0));
	
	//gl_FragColor.rgb = diffuse;
	gl_FragColor.rgb = ambient*0.2 + diffuse*1.0 + specular;
	//gl_FragColor.rgb = specular;
	//gl_FragColor.rgb = eyecoords;
	//vec3 halfvec = normalize(eyecoords + lightposition);
	//float NdotHV = max(dot(normal, halfvec),0.0);
	//gl_FragColor.rgb = vec3(specular);
	//gl_FragColor.rgb = vec3(dot(lightposition,normal));
	//gl_FragColor.rgb = vec3(normal.y);
	
	gl_FragColor.a = tu0_2D_val.a*gl_Color.a;
}
