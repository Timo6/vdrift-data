attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;

varying vec2 texcoord_2d;
varying vec3 normal_eye;
varying vec3 viewdir;

void main()
{
	//set the texture coordinates
	texcoord_2d = VertexTexCoord;
	
	//compute the eyespace normal
	normal_eye = gl_NormalMatrix * VertexNormal;
	
	//compute the eyespace position
	vec4 ecposition = gl_ModelViewMatrix * vec4(VertexPosition, 1.0);
	
	//compute the eyespace view direction
	viewdir = vec3(ecposition)/ecposition.w;
	
	//transform the vertex
	gl_Position = gl_ProjectionMatrix * ecposition;
}
