varying vec2 tu0coord;

void main()
{
	// Transforming the vertex
	gl_Position = ftransform();
	
	// Setting the color
	gl_FrontColor = gl_Color;
	
	tu0coord = vec2(gl_MultiTexCoord0);
}
