varying vec2 tu0coord;

uniform sampler2D tu0_2D; //full scene color
uniform sampler2D tu1_2D; //log luminance map

#define GAMMA 2.2
vec3 UnGammaCorrect(vec3 color)
{
	return pow(color, vec3(1.0/GAMMA,1.0/GAMMA,1.0/GAMMA));
}
vec3 GammaCorrect(vec3 color)
{
	return pow(color, vec3(GAMMA,GAMMA,GAMMA));
}
#undef GAMMA

const vec3 LUMINANCE = vec3(0.2125, 0.7154, 0.0721);

const float scale = 0.1;
const float offset = 5.;
const float scale_tiny = 3.0;
const float offset_tiny = -0.12;

void main()
{
	vec3 color = texture2D(tu0_2D, tu0coord).rgb;
	
	//float lod = 8;
	float geometric_mean = exp((texture2D(tu1_2D, tu0coord).r/scale_tiny-offset_tiny)/scale-offset);
	//gl_FragColor.rgb = texture2DLod(tu0_2D, tu0coord, lod).rgb;
	
	// reinhard eq 3
	float a = 0.18;
	float scalefactor = a/geometric_mean;
	color *= scalefactor;
	
	gl_FragColor.rgb = UnGammaCorrect(color);
	//gl_FragColor.rgb = texture2D(tu1_2D, tu0coord).rgb;
	gl_FragColor.a = 1.;
}
