uniform vec3 lightposition;
varying float lightdotnorm;
varying vec2 texcoord;

void main()
{
	// Transforming the vertex
	gl_Position = ftransform();
	
	//correct surface acne
	vec3 normal = (mat3(gl_TextureMatrix[1]) * gl_NormalMatrix) * gl_Normal;
	float lightdotnorm = max(dot(lightposition,normal),0.0);
	texcoord = vec2(gl_MultiTexCoord0);
	//gl_Position.w = mix(0.95,0.999,lightdotnorm);
}
