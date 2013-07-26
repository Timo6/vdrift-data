varying vec2 tu0coord;

void main()
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);

	gl_FrontColor = gl_Color;

	tu0coord = vec2(gl_MultiTexCoord0);
}
