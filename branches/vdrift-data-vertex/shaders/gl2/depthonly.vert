uniform vec3 light_direction;

attribute vec3 VertexPosition;
attribute vec3 VertexNormal;
attribute vec2 VertexTexCoord;

//varying float lightdotnorm;
varying vec2 texcoord;
varying vec3 eyespacenormal;

void main()
{
	// Transforming the vertex
	gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vec4(VertexPosition, 1.0));
	
	texcoord = VertexTexCoord;
	
	//correct surface acne
	/*float ldo = dot(VertexNormal.xyz,light_direction);
	ldo = max(ldo,0.0);
	ldo = ldo * 0.95 + 0.999;
	gl_Position.w = gl_Position.w * ldo;*/
	
	/*vec4 ldo;
	ldo.x = dot(gl_ModelViewMatrix[0].xyz,light_direction);
	ldo.y = dot(gl_ModelViewMatrix[1].xyz,light_direction);
	ldo.z = dot(gl_ModelViewMatrix[2].xyz,light_direction);
	ldo.w = dot((gl_NormalMatrix*VertexNormal).xyz,ldo.xyz);
	ldo.w = max(ldo.w,0.0);
	ldo.w = ldo.w * 0.95 + 0.999;
	gl_Position.w = gl_Position.w * ldo.w;*/
	
	/*mat3 tmat;
	tmat[0] = gl_TextureMatrix[1][0].xyz;
	tmat[1] = gl_TextureMatrix[1][1].xyz;
	tmat[2] = gl_TextureMatrix[1][2].xyz;
	vec3 normal = (tmat * gl_NormalMatrix) * VertexNormal;*/
	
	eyespacenormal = normalize(gl_NormalMatrix * VertexNormal);
	//gl_Position.xyz = gl_Position.xyz - eyespacenormal * 0.01;
	//float lightdotnorm = max(eyespacenormal.z,0.0);
	//lightdotnorm *= lightdotnorm;
	//gl_Position.w *= mix(0.98,0.999,lightdotnorm);
	
	//lightdotnorm = (1.0-lightdotnorm)*0.95 + 0.999*(lightdotnorm);
	//gl_Position.w = gl_Position.w * lightdotnorm;
	
	//gl_Position.w *= 0.95;
}
