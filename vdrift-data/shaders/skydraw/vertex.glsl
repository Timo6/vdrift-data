varying vec3 view_direction;

void main(void)
{
	vec4 pos = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * pos;
	
	view_direction = gl_MultiTexCoord2.xyz;
}
