uniform vec3 light_direction;

varying vec2 tu0coord;
varying vec3 N;
varying vec3 V;

void main()
{
	vec4 pos = gl_ModelViewMatrix * gl_Vertex;
	
	// position eye-space
	V = pos.xyz;

	// normal in eye-space
	N = normalize(gl_NormalMatrix * gl_Normal);

	tu0coord = vec2(gl_MultiTexCoord0);

	gl_Position = gl_ProjectionMatrix * pos;

	gl_FrontColor = gl_Color;
}
