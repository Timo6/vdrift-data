#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tu0_2DRect;
uniform sampler2D tu1_2D;
varying vec2 texcoord_2d;

void main()
{
	vec2 tc0 = vec2(texcoord_2d.x*SCREENRESX, texcoord_2d.y*SCREENRESY);
	vec2 tc1 = texcoord_2d;
	
	vec4 tu0_2D_val = texture2DRect(tu0_2DRect, tc0);
	vec4 tu1_2D_val = texture2D(tu1_2D, tc1);
	
	vec3 orig = tu0_2D_val.rgb;
	vec3 blurred = tu1_2D_val.rgb;
	
	//vec3 final = orig * blurred;
	/*float blurred_grey = (blurred.r*0.25+blurred.g*0.5+blurred.b*0.25)*0.8+0.2;
	blurred = vec3(blurred_grey,blurred_grey,blurred_grey);
	vec3 final = orig*(orig + 2.0*blurred*(1.0-orig)); //"OVERLAY"*/
	//vec3 final = blurred;
	//vec3 final = orig*(orig + 2.0*blurred*(1.0-orig));
	vec3 final = orig + blurred;
	
	gl_FragColor = vec4(final,1.);
}
