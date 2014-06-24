varying vec2 tu0coord;
varying vec3 eyespace_view_direction;

void main()
{
	vec4 pos = gl_ModelViewMatrix * gl_Vertex;

	eyespace_view_direction = pos.xyz;

	#ifdef _INITIAL_
	eyespace_view_direction = vec3(gl_MultiTexCoord1);
	#endif

	tu0coord = vec2(gl_MultiTexCoord0);

	gl_Position = gl_ProjectionMatrix * pos;

	gl_FrontColor = gl_Color;
}
