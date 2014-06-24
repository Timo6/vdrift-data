uniform float znear;

attribute vec3 VertexPosition;
attribute vec3 VertexNormal;

varying vec3 eyespace_view_direction;
varying float q; //equivalent to gl_ProjectionMatrix[2].z
varying float qn; //equivalent to gl_ProjectionMatrix[3].z

void main()
{
	// Transforming the vertex
	vec4 pos = gl_ModelViewMatrix * vec4(VertexPosition, 1.0);
	gl_Position = gl_ProjectionMatrix * pos;
	vec3 pos3 = pos.xyz;
	
	eyespace_view_direction = VertexNormal;
	
	float zfar = -VertexNormal.z;
	float depth = zfar - znear;
	q = -(zfar+znear)/depth;
	qn = -2.0*(zfar*znear)/depth;
}
