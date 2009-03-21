varying vec2 tu0coord;
varying vec4 ecposition;

void main()
{
	// Transforming the vertex
	//ecposition = gl_TextureMatrixInverse[3] * gl_ModelViewMatrix * gl_Vertex;
	ecposition = gl_Vertex;
	gl_Position = ftransform();
	
	// Setting the color
	gl_FrontColor = gl_Color;
	
	tu0coord = vec2(gl_MultiTexCoord0);
}
