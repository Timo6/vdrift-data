varying vec2 texcoord_2d;
varying vec3 normal;
uniform sampler2D tu0_2D;
uniform sampler2D tu1_2D;
//uniform sampler2DShadow tu2_2D;
uniform sampler2DRect tu2_2DRect;

uniform float screenw;
uniform float screenh;

varying vec3 eyecoords;
varying vec3 eyespacenormal;
uniform vec3 eyelightposition;
//varying vec4 ecpos;

uniform vec3 lightposition;
//varying vec3 halfvector;

void main()
{
	vec3 normnormal = normalize(normal);
	
	vec4 tu0_2D_val = texture2D(tu0_2D, texcoord_2d);
	vec4 tu1_2D_val = texture2D(tu1_2D, texcoord_2d);
	
	//float notshadow = texture2DRect(tu2_2DRect, gl_FragCoord.xy*0.5).r;
	float notshadow = texture2DRect(tu2_2DRect, gl_FragCoord.xy*0.5).r;
	//notshadow = (1.0-notshadow)*(tu0_2D_val.a);
	//notshadow = tu0_2D_val.a;
	//float notshadow = shadow2D(tu2_2D, projshadow).r;
	/*float notshadow = 0.0;
	const float ep = 0.000488;
	vec3 projshadow3 = vec3(projshadow);
	
	//2X2 PCF
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(ep,ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(ep,-ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(-ep,-ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(-ep,ep,0.0)).r;
	notshadow *= 0.25;*/
	
	//3X3 PCF
	/*notshadow += shadow2D(tu2_2D, projshadow3+vec3(ep,ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(ep,0.0,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(ep,-ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(0.0,-ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(-ep,-ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(-ep,0.0,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(-ep,ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(0.0,ep,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3).r;
	notshadow *= 0.11111111;*/
	
	/*//2X2 dithered PCF
	vec2 o = mod(floor(gl_FragCoord.xy),2.0)*ep*2.0;
	const float ep3 = ep*3.0;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(-ep3+o.x,ep3+o.y,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(ep+o.x,ep3+o.y,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(-ep3+o.x,-ep+o.y,0.0)).r;
	notshadow += shadow2D(tu2_2D, projshadow3+vec3(ep3+o.x,-ep+o.y,0.0)).r;
	notshadow *= 0.25;*/
	/*const float bound = 1.0;
	vec2 shadowcoords = projshadow.xy;
	const float fade = 10.0;
	shadowcoords.x = clamp(shadowcoords.x, 0.0, bound);
	shadowcoords.y = clamp(shadowcoords.y, 0.0, bound);
	float xf1 = 1.0-min(1.0,shadowcoords.x*fade);
	float xf2 = max(0.0,shadowcoords.x*fade-(fade-1.0));
	float yf1 = 1.0-min(1.0,shadowcoords.y*fade);
	float yf2 = max(0.0,shadowcoords.y*fade-(fade-1.0));
	notshadow = max(notshadow,max(xf1,max(xf2,max(yf1,yf2))));*/
	
	vec3 texcolor = tu0_2D_val.rgb;
	vec3 ambient = texcolor;
	//vec3 diffuse = texcolor*clamp((dot(normal,lightposition)+1.0)*0.7,0.0,1.0);
	float difdot = max(dot(normnormal,lightposition),0.0);
	//notshadow *= min(difdot*10.0,1.0);
	//notshadow *= 1.0-difdot;
	difdot *= notshadow;
	vec3 diffuse = texcolor*difdot;
	vec3 refnorm = normalize(reflect(normalize(eyecoords),normalize(eyespacenormal)));
	//vec3 refnorm = normalize(reflect(normalize(ecpos.xyz/ecpos.w),normalize(eyespacenormal)));
	//vec3 halfvec = normalize(eyecoords + lightposition);
	//vec3 specular = vec3(pow(clamp(dot(refnorm,lightposition),0.0,1.0),8.0)*0.2);
	float specval = max(dot(refnorm, normalize(eyelightposition)),0.0);
	//vec3 specular = vec3(pow(specval,4.0)*0.2);
	
	//float specval = max(dot(normnormal, normalize(halfvector)),0.0);
	
	float gloss = tu1_2D_val.r;
	vec3 specular = vec3((pow(specval,128.0)*0.4+pow(specval,4.0)*0.2)*gloss);
	//vec3 specular = vec3(pow(specval,128.0)*1.0);
	
	//vec3 reflight = reflect(lightposition,normal);
	//vec3 specular = vec3(max(dot(eyecoords, reflight),0.0));
	
	gl_FragColor.rgb = ambient*0.5 + diffuse*1.0 + specular*notshadow;
	
	//gl_FragColor.rgb = diffuse;
	//gl_FragColor.rgb = texture2DRect(tu2_2DRect, gl_FragCoord.xy).rgb;
	//gl_FragColor.rgb = vec3(1,1,1)*(projshadow.z/projshadow.w);
	//gl_FragColor.rgb = projshadow.xyz/projshadow.w;
	//gl_FragColor = texture2DProj(tu2_2D,projshadow);
	//gl_FragColor.rgb = specular;
	//gl_FragColor.rgb = eyecoords;
	//vec3 halfvec = normalize(eyecoords + lightposition);
	//float NdotHV = max(dot(normal, halfvec),0.0);
	//gl_FragColor.rgb = vec3(specular);
	//gl_FragColor.rgb = vec3(dot(lightposition,normal));
	//gl_FragColor.rgb = vec3(normal.y);
	
	gl_FragColor.a = tu0_2D_val.a*gl_Color.a;
}
