uniform mat4 ModelViewProjMatrix;
uniform mat4 ModelViewMatrix;
uniform mat3 ReflectionMatrix;
uniform vec3 light_direction;

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
varying vec3 V;
varying vec3 N;
varying vec3 refmapdir;
varying vec3 ambientmapdir;

void main()
{
	// transform the vertex
	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);
    vec3 pos3 = ModelViewMatrix * vec4(VertexPosition, 1.0);
 
	#ifdef _SHADOWS_
	projshadow_0 = gl_TextureMatrix[4] * gl_TextureMatrixInverse[3] * pos;
	#ifdef _CSM2_
	projshadow_1 = gl_TextureMatrix[5] * gl_TextureMatrixInverse[3] * pos;
	#endif
	#ifdef _CSM3_
	projshadow_2 = gl_TextureMatrix[6] * gl_TextureMatrixInverse[3] * pos;
	#endif
	#endif

	// set the texture coordinates
	texcoord_2d = VertexTexCoord;

	// compute the eyespace normal (assuming no non-uniform scale)
	N = normalize(vec3(ModelViewMatrix * vec4(VertexNormal, 0.0)));
    V = normalize(-pos3);

    #ifndef _REFLECTIONDISABLED_
    refmapdir = ReflectionMatrix * reflect(pos3, N);
    #else
    refmapdir = vec3(0.);
    #endif

    ambientmapdir = ReflectionMatrix * N;
}
