varying vec3 tu0coord;

void main()
{
	gl_Position = ftransform();

	gl_FrontColor = gl_Color;

	vec2 screenpos = (vec2(gl_MultiTexCoord0) - vec2(0.5, 0.5)) * 2.0;
	tu0coord = vec3(screenpos.x, screenpos.y, -0.5);
}
