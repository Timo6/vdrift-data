attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;

varying vec2 tu0coord;
varying vec3 ecposition;
varying vec3 normal_eye;

void main()
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vec4(VertexPosition, 1.0));

	normal_eye = gl_NormalMatrix * VertexNormal;

	ecposition = VertexPosition;

	tu0coord = VertexTexCoord;
}
