#version 140

uniform mat4 projectionMatrix;
uniform mat4 viewMatrix;
uniform mat4 modelMatrix;

in vec3 vertexPosition;
in vec3 vertexNormal;
in vec3 vertexTangent;
in vec3 vertexBitangent;
in vec3 vertexColor;
in vec3 vertexUv0;
in vec3 vertexUv1;
in vec3 vertexUv2;
out vec3 normal;
out vec3 uv;

void main(void)
{
	normal = vertexNormal;
	uv = vertexUv0;
	gl_Position = projectionMatrix*viewMatrix*modelMatrix*vec4(vertexPosition, 1.0);
}
