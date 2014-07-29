uniform mat4 ModelViewProjMatrix;

attribute vec3 VertexPosition;

void main()
{
	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);
}
