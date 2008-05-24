varying vec2 tu0coord;
uniform sampler2D tu0_2D;

void main()
{
	// Setting Each Pixel To Red
	//gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	
	vec4 texcolor = texture2D(tu0_2D, tu0coord);
	const float width = 0.05;
	texcolor.a = smoothstep(0.5-width, 0.5+width, texcolor.a);
	
	gl_FragColor = texcolor*gl_Color;
	
	//gl_FragColor.rg = tu0coord*0.5+0.5;
	//gl_FragColor.ba = vec2(1.0);
}
