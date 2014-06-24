attribute vec3 VertexPosition;
attribute vec3 VertexTangent;

varying vec3 view_direction;

void main(void)
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vec4(VertexPosition, 1.0));

	view_direction = VertexTangent;
}
