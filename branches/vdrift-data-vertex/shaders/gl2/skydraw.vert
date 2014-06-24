varying vec3 view_direction;

void main(void)
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);

	view_direction = gl_MultiTexCoord2.xyz;
}
