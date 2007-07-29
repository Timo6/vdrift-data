varying vec2 texcoord_2d;
varying vec3 normal;
varying vec3 eyespacenormal;
varying vec3 eyecoords;
varying vec4 ecpos;
varying vec3 eyelightposition;
//uniform mat4 light_modelviewproj;
//varying vec4 projshadow;
//varying vec3 halfvector;
uniform vec3 lightposition;

varying vec4 projshadow_0;
varying vec4 projshadow_1;

uniform mat4 light_matrix_0;
uniform mat4 light_matrix_1;

void main()
{
	//transform the vertex
	gl_Position = ftransform();
	
	//setup for shadow pass
	//projshadow = light_modelviewproj * gl_Vertex;
	//projshadow = gl_TextureMatrix[2] * gl_TextureMatrix[1] * gl_Vertex;
	//projshadow = gl_TextureMatrix[2] * (gl_TextureMatrix[1] * gl_Position);
	//projshadow = gl_TextureMatrix[2] * ((gl_TextureMatrix[1] * gl_ModelViewMatrix) * gl_Vertex);
	//projshadow = gl_TextureMatrix[2] * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	
	projshadow_0 = light_matrix_0 * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	projshadow_1 = light_matrix_1 * (gl_TextureMatrix[1] * (gl_ModelViewMatrix * gl_Vertex));
	
	//set the color
	gl_FrontColor = gl_Color;
	
	//set the texture coordinates
	texcoord_2d = vec2(gl_MultiTexCoord0);
	
	//viewvector = mat3(gl_TextureMatrix[1]) * (gl_Position.xyz/gl_Position.w);
	//halfvector = normalize(normalize(mat3(gl_TextureMatrix[1]) * (gl_Position.xyz/gl_Position.w))+lightposition);
	//vec4 viewvector = gl_TextureMatrix[1] * gl_Position;
	//halfvector = normalize(normalize(viewvector.xyz/viewvector.w)+lightposition);
	
	//set the normal, eyespace normal, and eyespace position
	//normal = (mat3(gl_TextureMatrix[1]) * gl_NormalMatrix) * gl_Normal;
	normal = (mat3(gl_TextureMatrix[1][0].xyz,gl_TextureMatrix[1][1].xyz,gl_TextureMatrix[1][2].xyz) * gl_NormalMatrix) * gl_Normal;
	//normal = mat3(gl_TextureMatrix[1]) * (gl_NormalMatrix * gl_Normal);
	//normal = vec3(gl_TextureMatrix[1] * (gl_ModelViewProjectionMatrix * gl_Vertex));
	//normal = gl_NormalMatrix * gl_Normal;
	//normal = gl_Normal;
	//vec4 norm4 = vec4(gl_Normal.x,gl_Normal.y,gl_Normal.z,0.0);
	//normal = (gl_ModelViewMatrix * norm4).xyz;
	
	eyespacenormal = normalize(gl_NormalMatrix * gl_Normal);
	ecpos = gl_ModelViewMatrix * gl_Vertex;
	eyecoords = vec3(ecpos) / ecpos.w;
	eyecoords = normalize(eyecoords);
	eyelightposition = mat3(gl_TextureMatrix[1]) * lightposition;
	
	//eyecoords = (gl_ModelViewMatrix * gl_Vertex).xyz;
	
	//eyecoords = normalize(mat3(gl_TextureMatrix[2]) * vec3(0,0,1));
	
	//lightposition = mat3(gl_TextureMatrix[1]) * (mat3(gl_ModelViewMatrix) * vec3(0,1,0));
	//lightposition = normalize(vec3(.1,1.0,.3));
}
