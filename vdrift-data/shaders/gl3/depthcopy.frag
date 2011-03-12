#version 330

uniform sampler2D depthSampler;
uniform vec2 viewportSize;

void main(void)
{
	gl_FragDepth = texture2D(depthSampler, gl_FragCoord.xy/viewportSize).r;
}
