uniform mat4 ModelViewProjMatrix;
uniform mat4 ModelViewMatrix;

attribute vec3 VertexPosition;
attribute vec2 VertexTexCoord;
attribute vec3 VertexNormal;

varying vec2 tu0coord;
varying vec3 eyespace_view_direction;

void main()
{
	#ifdef _INITIAL_
	eyespace_view_direction = VertexNormal;
	#else
	eyespace_view_direction = vec3(ModelViewMatrix * vec4(VertexPosition, 1.0));
	#endif

	tu0coord = VertexTexCoord;

	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);
}
