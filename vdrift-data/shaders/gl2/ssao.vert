uniform mat4 ModelViewProjMatrix;
uniform float znear;

attribute vec3 VertexPosition;
attribute vec3 VertexNormal;

varying vec3 eyespace_view_direction;
varying float q;  // equivalent to ProjectionMatrix[2].z
varying float qn; // equivalent to ProjectionMatrix[3].z

void main()
{
	gl_Position = ModelViewProjMatrix * vec4(VertexPosition, 1.0);

	eyespace_view_direction = VertexNormal;

	float zfar = -VertexNormal.z;
	float depth = zfar - znear;
	q = -(zfar + znear) / depth;
	qn = -2.0 * (zfar * znear) / depth;
}
