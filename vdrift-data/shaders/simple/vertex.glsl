varying vec2 tu0coord;

void main()
{
	// Transforming The Vertex
	// gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	gl_Position = ftransform();
	
	tu0coord = vec2(gl_MultiTexCoord0);
}
