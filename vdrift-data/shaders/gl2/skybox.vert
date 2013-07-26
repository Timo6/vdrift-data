varying vec2 tu0coord;
varying vec4 ecposition;
varying vec3 normal_eye;

void main()
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);

	gl_FrontColor = gl_Color;

	normal_eye = gl_NormalMatrix * gl_Normal;

	ecposition = gl_Vertex;

	tu0coord = vec2(gl_MultiTexCoord0);
}
