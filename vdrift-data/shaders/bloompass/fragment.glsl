uniform sampler2DRect tu0_2DRect;
varying vec2 texcoord_2d;
uniform float bloomfactor;
uniform float screenw;
uniform float screenh;

void main()
{
	vec2 tc = texcoord_2d;
	tc.x *= screenw;
	tc.y *= screenh;
	vec4 tu0_2D_val = texture2DRect(tu0_2DRect, tc);
	//gl_FragColor = vec4(gl_FragColor.r*tu0_2D_val.r,gl_FragColor.g*tu0_2D_val.g,gl_FragColor.b*tu0_2D_val.b,0);
	vec3 orig = tu0_2D_val.rgb;
	vec3 blurred = orig;
	vec3 final = orig * blurred;
	gl_FragColor = vec4(final.r,final.g,final.b,0);
}
