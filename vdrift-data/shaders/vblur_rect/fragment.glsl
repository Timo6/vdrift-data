uniform sampler2DRect tu0_2DRect;
varying vec2 texcoord_2d;
uniform float screenw;
uniform float screenh;

void main()
{
	vec2 tc = texcoord_2d;
	tc.x *= screenw;
	tc.y *= screenh;
	
	vec4 tu0_2D_val = texture2DRect(tu0_2DRect, tc);
	
	vec4 final = vec4(0.0, 0.0, 0.0, 0.0);

	/*final += 0.015625 * texture2DRect(tu0_2DRect, tc + vec2(0.0, -3.0) );
	final += 0.09375 * texture2DRect(tu0_2DRect, tc + vec2(0.0, -2.0) );
	final += 0.234375 * texture2DRect(tu0_2DRect, tc + vec2(0.0, -1.0) );
	final += 0.3125 * texture2DRect(tu0_2DRect, tc + vec2(0.0, 0.0) );
	final += 0.234375 * texture2DRect(tu0_2DRect, tc + vec2(0.0, 1.0) );
	final += 0.09375 * texture2DRect(tu0_2DRect, tc + vec2(0.0, 2.0) );
	final += 0.015625 * texture2DRect(tu0_2DRect, tc + vec2(0.0, 3.0) );*/
	
	/*final += 0.015625 * texture2DRect(tu0_2DRect, tc + vec2(-3.0*d, 0.0) );
	final += 0.09375 * texture2DRect(tu0_2DRect, tc + vec2(-2.0*d, 0.0) );
	final += 0.234375 * texture2DRect(tu0_2DRect, tc + vec2(-1.0*d, 0.0) );
	final += 0.3125 * texture2DRect(tu0_2DRect, tc + vec2(0.0, 0.0) );
	final += 0.234375 * texture2DRect(tu0_2DRect, tc + vec2(1.0*d, 0.0) );
	final += 0.09375 * texture2DRect(tu0_2DRect, tc + vec2(2.0*d, 0.0) );
	final += 0.015625 * texture2DRect(tu0_2DRect, tc + vec2(3.0*d, 0.0) );*/
	
	const float samples = 9.0;
	const float sinv = 1.0 / samples;
	
	for (float i = -4.0; i < 5.0; i++)
	{
		final += sinv * texture2DRect(tu0_2DRect, tc + vec2(0.0, i) );
	}
	
	gl_FragColor = final;
}
