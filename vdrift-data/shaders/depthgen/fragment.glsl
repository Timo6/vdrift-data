//varying float lightdotnorm;
//uniform float depthoffset;
uniform sampler2D tu0_2D;
varying vec2 texcoord;

void main()
{
	// Setting Each Pixel To Red
	//gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	//gl_FragDepth = gl_FragCoord.z+0.0009;
	//gl_FragDepth = gl_FragCoord.z+0.007;
	
	vec4 tu0color = texture2D(tu0_2D, texcoord);
	
	/*if (tu0color.a < 0.1)
		discard;
	else*/
	{
		//gl_FragDepth = gl_FragCoord.z+depthoffset + (1.0-tu0color.a)*100.0;
		gl_FragDepth = gl_FragCoord.z+0.001;
		gl_FragColor = tu0color;
	}
	
	//gl_FragDepth = gl_FragCoord.z + mix(0.007,0.0009,lightdotnorm);
	//gl_FragDepth = gl_FragCoord.z + mix(0.0009,0.007,lightdotnorm);
}
