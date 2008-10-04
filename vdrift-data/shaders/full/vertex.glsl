uniform vec3 lightposition;

varying vec2 texcoord_2d;
varying vec3 normal;
varying vec3 viewdir;
varying vec4 projshadow_0;
varying vec4 projshadow_1;

void main()
{
	//transform the vertex
	gl_Position = ftransform();
	
	projshadow_0 = gl_TextureMatrix[2] * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	projshadow_1 = gl_TextureMatrix[3] * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	
	//set the color
	gl_FrontColor = gl_Color;
	
	//set the texture coordinates
	texcoord_2d = vec2(gl_MultiTexCoord0);
	
	//set the normal, eyespace normal, and eyespace position
	mat3 cam_rotation_inv = mat3(gl_TextureMatrix[1][0].xyz,gl_TextureMatrix[1][1].xyz,gl_TextureMatrix[1][2].xyz);
	normal = (cam_rotation_inv * gl_NormalMatrix) * gl_Normal;
	
	vec3 worldvert = (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex)).xyz;
	vec3 campos = gl_TextureMatrix[1][3].xyz;
	viewdir = worldvert - campos;
}
