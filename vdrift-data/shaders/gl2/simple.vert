varying vec2 tu0coord;

#ifdef _LIGHTING_
varying vec3 normal;
#endif

void main()
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * gl_Vertex);

	gl_FrontColor = gl_Color;

	tu0coord = gl_MultiTexCoord0.xy;

#ifdef _LIGHTING_
	normal = normalize(gl_NormalMatrix * gl_Normal);
#endif
}
