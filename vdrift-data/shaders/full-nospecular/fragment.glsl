varying vec2 texcoord_2d;
varying vec3 normal;
uniform sampler2D tu0_2D;
//uniform samplerCube tu1_cube;
//uniform sampler2D tu2_2D;

varying vec3 eyecoords;
varying vec3 eyespacenormal;

varying vec3 lightposition;

void main()
{
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec3 texcolor = tu0_2D_val.rgb;
	vec3 ambient = texcolor;
	vec3 diffuse = texcolor*clamp((dot(normal,lightposition)+1.0)*0.7,0.0,1.0);
	
	gl_FragColor.rgb = ambient*0.2 + diffuse*1.0;
	
	gl_FragColor.a = tu0_2D_val.a*gl_Color.a;
}
