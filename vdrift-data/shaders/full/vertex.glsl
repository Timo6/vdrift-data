varying vec2 texcoord_2d;
varying vec3 normal;
varying vec3 eyespacenormal;
varying vec3 eyecoords;
//varying vec3 lightposition;
//uniform mat4 light_modelviewproj;
varying vec4 projshadow;

void main()
{
	//transform the vertex
	gl_Position = ftransform();
	
	//setup for shadow pass
	//projshadow = light_modelviewproj * gl_Vertex;
	//projshadow = gl_TextureMatrix[2] * gl_TextureMatrix[1] * gl_Vertex;
	//projshadow = gl_TextureMatrix[2] * (gl_TextureMatrix[1] * gl_Position);
	//projshadow = gl_TextureMatrix[2] * ((gl_TextureMatrix[1] * gl_ModelViewMatrix) * gl_Vertex);
	projshadow = gl_TextureMatrix[2] * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	
	//set the color
	gl_FrontColor = gl_Color;
	
	//set the texture coordinates
	texcoord_2d = vec2(gl_MultiTexCoord0);
	
	//set the normal, eyespace normal, and eyespace position
	eyespacenormal = normalize(gl_NormalMatrix * gl_Normal);
	normal = (mat3(gl_TextureMatrix[1]) * gl_NormalMatrix) * gl_Normal;
	//normal = mat3(gl_TextureMatrix[1]) * (gl_NormalMatrix * gl_Normal);
	//normal = vec3(gl_TextureMatrix[1] * (gl_ModelViewProjectionMatrix * gl_Vertex));
	//normal = gl_NormalMatrix * gl_Normal;
	//normal = gl_Normal;
	//vec4 norm4 = vec4(gl_Normal.x,gl_Normal.y,gl_Normal.z,0.0);
	//normal = (gl_ModelViewMatrix * norm4).xyz;
	
	vec4 ecpos = gl_ModelViewMatrix * gl_Vertex;
	eyecoords = vec3(ecpos) / ecpos.w;
	eyecoords = normalize(eyecoords);
	
	//eyecoords = (gl_ModelViewMatrix * gl_Vertex).xyz;
	
	//eyecoords = normalize(mat3(gl_TextureMatrix[2]) * vec3(0,0,1));
	
	//lightposition = mat3(gl_TextureMatrix[1]) * (mat3(gl_ModelViewMatrix) * vec3(0,1,0));
	//lightposition = normalize(vec3(.1,1.0,.3));
}
