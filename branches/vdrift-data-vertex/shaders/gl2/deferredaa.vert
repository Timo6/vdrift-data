attribute vec3 VertexPosition;

void main()
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vec4(VertexPosition, 1.0));
}
