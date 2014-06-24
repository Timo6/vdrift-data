attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;
attribute vec4 VertexColor;

varying vec2 tu0coord;

#ifdef _LIGHTING_
varying vec3 normal;
#endif

#ifdef _VCOLOR_
varying vec4 vcolor;
#endif

void main()
{
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vec4(VertexPosition, 1.0));

	tu0coord = VertexTexCoord;

#ifdef _LIGHTING_
	normal = normalize(gl_NormalMatrix * VertexNormal);
#endif

#ifdef _VCOLOR_
	vcolor = VertexColor;
#endif
}
