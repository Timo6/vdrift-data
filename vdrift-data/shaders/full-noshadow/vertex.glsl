varying vec2 texcoord_2d;
varying vec3 normal_eye;
varying vec3 viewdir;

void main()
{
	//transform the vertex
	gl_Position = ftransform();
	
	//set the color
	gl_FrontColor = gl_Color;
	
	//set the texture coordinates
	texcoord_2d = vec2(gl_MultiTexCoord0);
	
	//set the normal, eyespace normal, and eyespace position
	/*mat3 cam_rotation_inv = mat3(gl_TextureMatrix[1][0].xyz,gl_TextureMatrix[1][1].xyz,gl_TextureMatrix[1][2].xyz);
	normal = (cam_rotation_inv * gl_NormalMatrix) * gl_Normal;
	
	vec3 worldvert = (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex)).xyz;
	vec3 campos = gl_TextureMatrix[1][3].xyz;
	viewdir = worldvert - campos;*/
	
	normal_eye = gl_NormalMatrix * gl_Normal;
	//normal_eye = gl_Normal;
	//normal_eye = normalize (vec3 (gl_ModelViewMatrix * vec4 (gl_Normal, 0.0))); //alternative to using gl_NormalMatrix; some drivers doesn't work because of bugs
	vec4 ecposition = gl_ModelViewMatrix * gl_Vertex;
	viewdir = vec3(ecposition)/ecposition.w;
	//lightpos_eye = normalize (vec3 (gl_ModelViewMatrix * vec4 (lightposition, 0.0)));
	//lightpos_eye = gl_NormalMatrix * lightposition;
	//lightpos_eye = lightposition;
	//lightpos_eye = vec3(gl_LightSource[0].position);
}
