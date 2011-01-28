#version 140

uniform sampler2D diffuseSampler;

in vec3 normal;
in vec3 uv;
out vec4 color;

void main(void)
{
	color.rgb = texture2D(diffuseSampler, uv.xy).rgb;
	color.a = 1.;
}
