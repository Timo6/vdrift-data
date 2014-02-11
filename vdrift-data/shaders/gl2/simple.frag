varying vec2 tu0coord;
uniform sampler2D tu0_2D;

#ifdef _GAMMA_
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
#endif

void main()
{
	vec4 color = texture2D(tu0_2D, tu0coord);
	#ifdef _GAMMA_
	color.rgb = GammaCorrect(color.rgb);
	#endif

	#ifdef _CARPAINT_
	// albedo mixed from diffuse and object color
	color.rgb = mix(gl_Color.rgb, color.rgb, color.a); 
	color.a = 1;
	#else
	// albedo modulated by object color
	color = color * gl_Color;
	#endif

	#ifdef _PREMULTIPLY_ALPHA_
	color.rgb *= color.a;
	#endif

	gl_FragColor = color;
}
