varying vec2 tu0coord;
varying vec3 eyespace_view_direction;

void main()
{
	// Transforming the vertex
	vec4 pos = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * pos;
	vec3 pos3 = pos.xyz;
	eyespace_view_direction = pos3;
	
	tu0coord = vec2(gl_MultiTexCoord0);
	
	eyespace_view_direction = vec3(gl_MultiTexCoord1);
}
