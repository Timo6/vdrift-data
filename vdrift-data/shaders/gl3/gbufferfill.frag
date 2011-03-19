#version 330

uniform sampler2D diffuseSampler;
uniform sampler2D materialPropertiesSampler;
uniform vec4 colorTint;
uniform float depthOffset;

in vec3 normal;
#ifdef TANGENTSPACE
in vec3 tangent;
in vec3 bitangent;
#endif

in vec3 uv;

#define USE_OUTPUTS

#ifdef USE_OUTPUTS
out vec4 materialProperties;
out vec4 normalXY;
out vec4 diffuseAlbedo;
#endif

vec2 packFloatToVec2i(const float val)
{
	float value = clamp(val,0.0,0.9999);
	vec2 bitSh = vec2(256.0, 1.0);
	vec2 bitMsk = vec2(0.0, 1.0/256.0);
	vec2 res = fract(value * bitSh);
	res -= res.xx * bitMsk;
	return res;
}

vec2 TweakTextureCoordinates(vec2 incoord, float textureSize)
{
	vec2 t = incoord * textureSize - .5;
	vec2 frc = fract(t);
	vec2 flr = t - frc;
	frc = frc*frc*(3.-2.*frc);//frc*frc*frc*(10+frc*(6*frc-15));
	return (flr + frc + .5)*(1./textureSize);
}

mat3 MatrixInverse(mat3 inMatrix)
{  
	float det = dot(cross(inMatrix[0], inMatrix[1]), inMatrix[2]);
	mat3 T = transpose(inMatrix);
	return mat3(cross(T[1], T[2]),
		cross(T[2], T[0]),
		cross(T[0], T[1])) / det;
}

// viewdir and normal MUST BE UNIT LENGTH
//http://www.gamedev.net/community/forums/topic.asp?topic_id=521915
mat3 GetTangentBasis(vec3 normal, vec3 viewdir, vec2 tucoord)
{
	// get edge vectors of the pixel triangle
	vec3 dp1  = dFdx(viewdir);
	vec3 dp2  = dFdy(viewdir);   
	vec2 duv1 = dFdx(tucoord);
	vec2 duv2 = dFdy(tucoord);  

	// solve the linear system
	mat3 M = mat3(dp1, dp2, cross(dp1, dp2));
	mat3 inverseM = MatrixInverse(M);
	vec3 T = inverseM * vec3(duv1.x, duv2.x, 0.0);
	vec3 B = inverseM * vec3(duv1.y, duv2.y, 0.0);

	// construct tangent frame  
	float maxLength = max(length(T), length(B));
	T = T / maxLength;
	B = B / maxLength;

	//vec3 tangent = normalize(T);
	//vec3 binormal = normalize(B);  

	return mat3(T, B, normal);
}

void main()
{
	vec4 albedo = texture(diffuseSampler, uv.xy);
	float carpaintMask = 0.0;
	
	#ifdef CARPAINT
	albedo.rgb = mix(colorTint.rgb, albedo.rgb, albedo.a); // albedo is mixed from diffuse and object color
	#else
	// emulate alpha testing
	if (albedo.a < 0.5)
		discard;
	#endif
	
	vec4 materialPropertyMap = texture(materialPropertiesSampler, uv.xy);
	
	vec3 eyeSpaceNormal = normalize(normal);
	vec2 normalToPack = vec2(atan(eyeSpaceNormal.y,eyeSpaceNormal.x)/3.14159265358979323846, eyeSpaceNormal.z)*0.5+vec2(0.5,0.5);
	vec2 normalX = packFloatToVec2i(normalToPack.x);
	vec2 normalY = packFloatToVec2i(normalToPack.y);
	
	// compatibility with old miscmap1 packing of gloss on R channel, metallic on G channel
	float m = materialPropertyMap.a;
	vec3 Rf0 = materialPropertyMap.rgb;
	//m = 1.0;
	//Rf0 = vec3(1,0,0);
	
	#ifdef CARPAINT
	carpaintMask = 1-albedo.a;
	#endif
	
	#ifdef USE_OUTPUTS
	materialProperties = vec4(Rf0, m);
	normalXY = vec4(normalX, normalY);
	diffuseAlbedo = vec4(albedo.rgb, carpaintMask);
	#else
	gl_FragData[0] = vec4(Rf0, m);
	gl_FragData[1] = vec4(normalX, normalY);
	gl_FragData[2] = vec4(albedo.rgb, carpaintMask);
	#endif
	
	gl_FragDepth = gl_FragCoord.z + depthOffset;
}
