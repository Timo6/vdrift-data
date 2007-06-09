varying vec2 texcoord_2d;
varying vec3 normal;
varying vec3 eyespacenormal;
varying vec3 eyecoords;
varying vec3 lightposition;

void main()
{
	//transform the vertex
	gl_Position = ftransform();
	
	//set the color
	gl_FrontColor = gl_Color;
	
	//set the texture coordinates
	texcoord_2d = vec2(gl_MultiTexCoord0);
	
	normal = (mat3(gl_TextureMatrix[1]) * gl_NormalMatrix) * gl_Normal;
	lightposition = normalize(vec3(.1,1.0,.3));
}
