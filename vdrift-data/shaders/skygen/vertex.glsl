varying vec3 vViewDirection;

void main(void)
{
	gl_Position = gl_Vertex;
   	vViewDirection = gl_MultiTexCoord0.xyz;
}
