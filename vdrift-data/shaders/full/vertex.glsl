#ifdef _SHADOWS_
varying vec4 projshadow_0;
varying vec4 projshadow_1;
#endif

varying vec2 texcoord_2d;
varying vec3 normal_eye;
varying vec3 viewdir;

void main()
{
	//transform the vertex
	gl_Position = ftransform();
	
	#ifdef _SHADOWS_
	projshadow_0 = gl_TextureMatrix[2] * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	projshadow_1 = gl_TextureMatrix[3] * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	#endif
	
	//set the color
	gl_FrontColor = gl_Color;
	
	//set the texture coordinates
	texcoord_2d = vec2(gl_MultiTexCoord0);
	
	//compute the eyespace normal
	normal_eye = gl_NormalMatrix * gl_Normal;
	
	//compute the eyespace position
	vec4 ecposition = gl_ModelViewMatrix * gl_Vertex;
	
	//compute the eyespace view direction
	viewdir = vec3(ecposition)/ecposition.w;
}
