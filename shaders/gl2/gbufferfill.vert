attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;

varying vec2 tu0coord;
varying vec3 N;
varying vec3 V;

void main()
{
	vec4 pos = gl_ModelViewMatrix * vec4(VertexPosition, 1.0);
	
	// position eye-space
	V = pos.xyz;

	// normal in eye-space
	N = normalize(gl_NormalMatrix * VertexNormal);

	tu0coord = VertexTexCoord;

	gl_Position = gl_ProjectionMatrix * pos;
}
