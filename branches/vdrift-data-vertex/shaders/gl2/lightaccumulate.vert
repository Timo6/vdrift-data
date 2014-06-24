attribute vec3 VertexPosition;
attribute vec2 VertexTexCoord;
attribute vec3 VertexNormal;

varying vec2 tu0coord;
varying vec3 eyespace_view_direction;

void main()
{
	vec4 pos = gl_ModelViewMatrix * vec4(VertexPosition, 1.0);

	eyespace_view_direction = pos.xyz;

	#ifdef _INITIAL_
	eyespace_view_direction = VertexNormal;
	#endif

	tu0coord = VertexTexCoord;

	gl_Position = gl_ProjectionMatrix * pos;
}
