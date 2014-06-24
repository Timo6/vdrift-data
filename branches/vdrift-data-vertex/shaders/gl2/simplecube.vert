attribute vec3 VertexPosition;
attribute vec2 VertexTexCoord;

varying vec3 tu0coord;

void main()
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vec4(VertexPosition, 1.0));

	vec2 screenpos = (VertexTexCoord - vec2(0.5, 0.5)) * 2.0;
	tu0coord = vec3(screenpos.x, screenpos.y, -0.5);
}
