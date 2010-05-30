uniform sampler2D tu0_2D;

void main()
{
	vec2 screen = vec2(SCREENRESX,SCREENRESY);
	vec4 outcol = texture2D(tu0_2D, gl_FragCoord.xy/screen);
	
	gl_FragColor = outcol;
}
