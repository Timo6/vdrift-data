//varying float lightdotnorm;
//uniform float depthoffset;
uniform sampler2D tu0_2D;
varying vec2 texcoord;
varying vec3 eyespacenormal;

void main()
{
	//float depthoffset = mix(0.01,0.0001,eyespacenormal.z*eyespacenormal.z);
	//float depthoffset = mix(0.005,0.001,eyespacenormal.z);
	
#ifdef _SHADOWSLOW_
	//float depthoffset = mix(0.01,0.002,eyespacenormal.z);
	float depthoffset = mix(0.005,0.001,eyespacenormal.z);
#else
#ifdef _SHADOWSMEDIUM_
	float depthoffset = mix(0.00375,0.00075,eyespacenormal.z);
#else
	float depthoffset = mix(0.0025,0.0005,eyespacenormal.z);
#endif
#endif
	//gl_FragColor = vec4(1);
	gl_FragDepth = gl_FragCoord.z+depthoffset;
	vec4 tu0color = texture2D(tu0_2D, texcoord);
	gl_FragColor = tu0color;
	
	//gl_FragDepth = gl_FragCoord.z + mix(0.007,0.0009,lightdotnorm);
	//gl_FragDepth = gl_FragCoord.z + mix(0.0009,0.007,lightdotnorm);
}
