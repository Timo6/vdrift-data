#ifdef _SHADOWS_
varying vec4 projshadow_0;
#ifdef _CSM2_
varying vec4 projshadow_1;
#endif
#ifdef _CSM3_
varying vec4 projshadow_2;
#endif
#endif

uniform vec3 lightposition;

varying vec2 tu0coord;
varying vec3 N;
varying vec3 V;

void main()
{
	// Transforming the vertex
	vec4 pos = gl_ModelViewMatrix * gl_Vertex;
	gl_Position = gl_ProjectionMatrix * pos;
	vec3 pos3 = pos.xyz;
	V = pos3;
	
	#ifdef _SHADOWS_
	projshadow_0 = gl_TextureMatrix[4] * gl_TextureMatrixInverse[3] * pos;
	#ifdef _CSM2_
	projshadow_1 = gl_TextureMatrix[5] * gl_TextureMatrixInverse[3] * pos;
	#endif
	#ifdef _CSM3_
	projshadow_2 = gl_TextureMatrix[6] * gl_TextureMatrixInverse[3] * pos;
	#endif
	#endif
	
	// Setting the color
	gl_FrontColor = gl_Color;
	
	tu0coord = vec2(gl_MultiTexCoord0);
	
	// transform normal into eye-space
	N = normalize(gl_NormalMatrix * gl_Normal);
}
