//varying float lightdotnorm;
//uniform float depthoffset;
uniform sampler2D tu0_2D;
varying vec2 texcoord;
varying vec3 eyespacenormal;

void main()
{
	// Setting Each Pixel To Red
	//gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	//gl_FragDepth = gl_FragCoord.z+0.0009;
	//gl_FragDepth = gl_FragCoord.z+0.007;
	
	/*if (eyespacenormal.z > 0.0)
		discard;*/
	
	vec4 tu0color = texture2D(tu0_2D, texcoord);
	
	//float depthoffset = mix(0.01,0.0001,eyespacenormal.z*eyespacenormal.z);
	//float depthoffset = mix(0.005,0.001,eyespacenormal.z);
	float depthoffset = mix(0.0025,0.0005,eyespacenormal.z);
	//depthoffset = 0.0;
	
	/*if (tu0color.a < 0.1)
		discard;
	else*/
	{
		//gl_FragDepth = gl_FragCoord.z+depthoffset + (1.0-tu0color.a)*100.0;
		//gl_FragDepth = gl_FragCoord.z+0.001;
		gl_FragDepth = gl_FragCoord.z+depthoffset;
		gl_FragColor = tu0color;
	}
	
	//gl_FragDepth = gl_FragCoord.z + mix(0.007,0.0009,lightdotnorm);
	//gl_FragDepth = gl_FragCoord.z + mix(0.0009,0.007,lightdotnorm);
}
