#version 140

uniform sampler2D diffuseSampler;
uniform vec4 colorTint;

in vec3 normal;
in vec3 uv;
out vec4 outputColor;

void main(void)
{
	outputColor.rgba = texture2D(diffuseSampler, uv.xy)*colorTint;
}
