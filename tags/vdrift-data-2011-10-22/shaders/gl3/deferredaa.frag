#version 140

#define toggleFilter 1.0
#define visualizeNormal 0.0

uniform sampler2D samplerScene;
uniform float strength;
uniform float maxNorm;
uniform vec2 viewportSize;

in vec3 uv;
out vec4 color;

float GetColorLuminance( vec3 color )
{
	return dot( color, vec3( 0.2126f, 0.7152f, 0.0722f ) );
}

void main(void)
{
	//color.rgb = texture(samplerScene, uv.xy).rgb;
	
	vec2 filterStrength = vec2(strength);
	vec2 maxNormal = vec2(maxNorm);
	
	//vec2 pixelViewport = vec2(1.0/1131.0,1.0/758.0);
	vec2 pixelViewport = vec2(1.0,1.0)/viewportSize;
	
	// Normal, scale it up 3x for a better coverage area
	vec2 upOffset = vec2( 0.0, pixelViewport.y ) * filterStrength.x;
	vec2 rightOffset = vec2( pixelViewport.x, 0.0 ) * filterStrength.x;

	float topHeight = GetColorLuminance( texture( samplerScene, uv.xy+upOffset).rgb );
	float bottomHeight = GetColorLuminance( texture( samplerScene, uv.xy-upOffset).rgb );
	float rightHeight = GetColorLuminance( texture( samplerScene, uv.xy+rightOffset).rgb );
	float leftHeight = GetColorLuminance( texture( samplerScene, uv.xy-rightOffset).rgb );
	float leftTopHeight = GetColorLuminance( texture( samplerScene, uv.xy-rightOffset+upOffset).rgb );
	float leftBottomHeight = GetColorLuminance( texture( samplerScene, uv.xy-rightOffset-upOffset).rgb );
	float rightBottomHeight = GetColorLuminance( texture( samplerScene, uv.xy+rightOffset-upOffset).rgb );
	float rightTopHeight = GetColorLuminance( texture( samplerScene, uv.xy+rightOffset+upOffset).rgb );
	
	// Normal map creation
	/*float sum0 = rightTopHeight+ topHeight + rightBottomHeight;
	float sum1 = leftTopHeight + bottomHeight + leftBottomHeight;*/
	float sum0 = rightTopHeight+ topHeight + leftTopHeight;
	float sum1 = leftBottomHeight + bottomHeight + rightBottomHeight;
	float sum2 = leftTopHeight + leftHeight + leftBottomHeight;
	float sum3 = rightBottomHeight + rightHeight + rightTopHeight ;

	// Then for the final vectors, just subtract the opposite sample set.
	// The amount of "antialiasing" is directly related to "filterStrength".
	// Higher gives better AA, but too high causes artifacts.
	float v1 = (sum1 - sum0) * filterStrength.y;
	float v2 = (sum2 - sum3) * filterStrength.y;

	// Put them together and multiply them by the offset scale for the final result.
	vec2 Normal = vec2(v1, v2);
	/*float normLength = max(maxNormal.x,Normal.length());
	Normal /= normLength;
	Normal *= maxNormal.y;*/
	Normal = clamp(Normal, -vec2(1.,1.)*maxNormal.x, vec2(1.,1.)*maxNormal.y);
	
	// Color
	Normal.xy *= pixelViewport*toggleFilter;
	vec4 Scene0 = texture( samplerScene, uv.xy );
	vec4 Scene1 = texture( samplerScene, uv.xy + Normal.xy );
	vec4 Scene2 = texture( samplerScene, uv.xy - Normal.xy );
	vec4 Scene3 = texture( samplerScene, uv.xy + vec2(Normal.x, -Normal.y) );
	vec4 Scene4 = texture( samplerScene, uv.xy - vec2(Normal.x, -Normal.y) );

	// Final color
	color.rgb = ((Scene0 + Scene1 + Scene2 + Scene3 + Scene4) * 0.2).rgb;

	// To debug the normal image, use this:
	color.rgb = mix(color.rgb,normalize(vec3(v1,v2,1)*0.5+0.5),visualizeNormal);
	// using vec1 and vec2 for the debug output as Normal won't display anything (due to the pixel scale applied to it).
	
	color.a = 1.;
}
