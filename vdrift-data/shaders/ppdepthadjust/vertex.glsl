varying vec2 tu0coord;
varying vec3 eyespace_view_direction;

void main()
{
	// Transforming the vertex
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * gl_Vertex;
	
	tu0coord = vec2(gl_MultiTexCoord0);
}
