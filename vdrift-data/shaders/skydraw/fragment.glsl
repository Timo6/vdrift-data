varying vec2 TexCoord;

vec3 DecodeRGBE8(vec4 rgbe)
{
  return rgbe.rgb * exp2(rgbe.a * 255 - 128);
}

vec2 Paraboloid(vec3 dir)
{
	float t = 1 / (1 + abs(dir.y));	// mirrored: y >= 0
	return 0.5f * vec2(1 + t * dir.x, 1 - t * dir.z);
}

void main()
{
	vec3 ViewDir = Paraboloid(TexCoord);
	gl_FragColor = DecodeRGBE8(Color);
}
