varying vec2 tu0coord;
uniform sampler2D tu0_2D;

void main()
{
	// Setting Each Pixel To Red
	//gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	
	gl_FragColor = texture2D(tu0_2D, tu0coord)*gl_Color;
}
