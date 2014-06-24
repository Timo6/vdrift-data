uniform vec3 light_direction;
uniform mat3 reflection_matrix;

attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;

#ifdef _SHADOWS_
varying vec4 projshadow_0;
#ifdef _CSM2_
varying vec4 projshadow_1;
#endif
#ifdef _CSM3_
varying vec4 projshadow_2;
#endif
#endif

varying vec2 texcoord_2d;
varying vec3 V, N;
varying vec3 refmapdir, ambientmapdir;

void main()
{
	//transform the vertex
    vec4 pos = gl_ModelViewMatrix * vec4(VertexPosition, 1.0);
	gl_Position = gl_ProjectionMatrix * pos;
    vec3 pos3 = pos.xyz;
 
	#ifdef _SHADOWS_
	projshadow_0 = gl_TextureMatrix[4] * gl_TextureMatrixInverse[3] * pos;
	#ifdef _CSM2_
	projshadow_1 = gl_TextureMatrix[5] * gl_TextureMatrixInverse[3] * pos;
	#endif
	#ifdef _CSM3_
	projshadow_2 = gl_TextureMatrix[6] * gl_TextureMatrixInverse[3] * pos;
	#endif
	#endif
	
	//set the texture coordinates
	texcoord_2d = VertexTexCoord;
	
	//compute the eyespace normal
	N = normalize(gl_NormalMatrix * VertexNormal);
    V = normalize(-pos3);
    //R = normalize(reflect(pos3,N));
    
    #ifndef _REFLECTIONDISABLED_
    refmapdir = reflection_matrix * reflect(pos3, N);
    #else
    refmapdir = vec3(0.);
    #endif
    
    ambientmapdir = reflection_matrix * N;
}
