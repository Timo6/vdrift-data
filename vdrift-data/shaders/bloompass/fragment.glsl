#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tu0_2DRect;
uniform sampler2DRect tu1_2DRect;
varying vec2 texcoord_2d;
uniform float screenw;
uniform float screenh;

void main()
{
	vec2 tc = texcoord_2d;
	tc.x *= screenw;
	tc.y *= screenh;
	vec4 tu0_2D_val = texture2DRect(tu0_2DRect, tc);
	vec4 tu1_2D_val = texture2DRect(tu1_2DRect, tc);
	//gl_FragColor = vec4(gl_FragColor.r*tu0_2D_val.r,gl_FragColor.g*tu0_2D_val.g,gl_FragColor.b*tu0_2D_val.b,0);
	vec3 orig = tu0_2D_val.rgb;
	vec3 blurred = tu1_2D_val.rgb;
	
	//vec3 final = orig * blurred;
	float blurred_grey = (blurred.r*0.25+blurred.g*0.5+blurred.b*0.25)*0.8+0.2;
	blurred = vec3(blurred_grey,blurred_grey,blurred_grey);
	vec3 final = orig*(orig + 2.0*blurred*(1.0-orig)); //"OVERLAY"
	//vec3 final = blurred;
	gl_FragColor = vec4(final.r,final.g,final.b,0);
}
