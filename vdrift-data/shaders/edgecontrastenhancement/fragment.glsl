varying vec2 tu0coord;

uniform sampler2D tu0_2D;
uniform sampler2DShadow tu1_2D;

void main()
{
	//in a normal application these would be uniforms set by the host program
	const float x_resolution = 1024.0;
	const float y_resolution = 768.0;
	
	//const vec3 up = (up_screenspace.xyz / up_screenspace.w)*0.5+0.5;
	
	/*const vec3 up1 = (up_screenspace1.xyz / up_screenspace1.w)*0.5+0.5;
	const vec3 up2 = (up_screenspace2.xyz / up_screenspace2.w)*0.5+0.5;
	const vec3 up3 = (up_screenspace3.xyz / up_screenspace3.w)*0.5+0.5;
	const vec3 up4 = (up_screenspace4.xyz / up_screenspace4.w)*0.5+0.5;*/
	
	const vec3 shadowcoords = vec3(gl_FragCoord.x/x_resolution, gl_FragCoord.y/y_resolution, gl_FragCoord.z-0.001);
	
	/*//const vec3 shadowcoords = vec3(gl_FragCoord.x/x_resolution+up.x, gl_FragCoord.y/y_resolution+up.y, gl_FragCoord.z+up.z);
	//const vec3 shadowcoords = vec3(gl_FragCoord.x/1024.0, gl_FragCoord.y/768.0, gl_FragCoord.z);
	
	const vec3 shadowcoords1 = vec3(up1.x, up1.y, up1.z);
	const vec3 shadowcoords2 = vec3(up2.x, up2.y, up2.z);
	const vec3 shadowcoords3 = vec3(up3.x, up3.y, up3.z);
	const vec3 shadowcoords4 = vec3(up4.x, up4.y, up4.z);
	
	//"hemisphere" 2x2+1 PCF (the pixel above, and then 4 pixels above and in each direction
	float notshadowfinal = 0.0;
	notshadowfinal += min(1.0,(shadow2D(tu1_2D, shadowcoords1).r + (1.0-shadow2D(tu1_2D, shadowcoords1+vec3(0.0,0.0,-0.02)).r))); //2x2
	notshadowfinal += min(1.0,(shadow2D(tu1_2D, shadowcoords2).r + (1.0-shadow2D(tu1_2D, shadowcoords2+vec3(0.0,0.0,-0.02)).r))); //2x2
	notshadowfinal += min(1.0,(shadow2D(tu1_2D, shadowcoords3).r + (1.0-shadow2D(tu1_2D, shadowcoords3+vec3(0.0,0.0,-0.02)).r))); //2x2
	notshadowfinal += min(1.0,(shadow2D(tu1_2D, shadowcoords4).r + (1.0-shadow2D(tu1_2D, shadowcoords4+vec3(0.0,0.0,-0.02)).r))); //2x2
	notshadowfinal += min(1.0,(shadow2D(tu1_2D, shadowcoords).r + (1.0-shadow2D(tu1_2D, shadowcoords+vec3(0.0,0.0,-0.02)).r))); //+1
	notshadowfinal *= 0.2;*/
	
	/*//2x2 PCF
	float notshadowfinal = 0.0;
	const float radius = 1.5/512.0;
	for (int v=-1; v<=1; v+=2)
		for (int u=-1; u<=1; u+=2)
		{
			notshadowfinal += shadow2D(tu1_2D, shadowcoords + radius*vec3(u, v, 0.0)).r;
			//notshadowfinal += shadow2D(tu1_2D, vec3(shadowcoords.x,shadowcoords.y,-10.0)).r;
		}
	notshadowfinal *= 0.25;*/
	//float notshadowfinal = texture2D(tu1_2D, shadowcoords.xy).r;
	
	//8 point diamond
	float notshadowfinal = 0.0;
	const float radius = 1.5/512.0;
	for (int v=-1; v<=1; v+=2)
		for (int u=-1; u<=1; u+=2)
	{
		notshadowfinal += shadow2D(tu1_2D, shadowcoords + radius*vec3(u, v, 0.0)).r;
	}
	for (int u=-2; u<=2; u+=4)
	{
		notshadowfinal += shadow2D(tu1_2D, shadowcoords + radius*vec3(u, 0.0, 0.0)).r;
	}
	for (int v=-2; v<=2; v+=4)
	{
		notshadowfinal += shadow2D(tu1_2D, shadowcoords + radius*vec3(0.0, v, 0.0)).r;
	}
	notshadowfinal *= 0.125;
	
	/*//3x3 PCF
	float notshadowfinal = 0.0;
	const float radius = 1.5/512.0;
	//const float radius = 3.0/512.0;
	for (int v=-1; v<=1; v++)
		for (int u=-1; u<=1; u++)
		{
			notshadowfinal += shadow2D(tu1_2D,shadowcoords + radius*vec3(u, v, 0.0)).r;
		}
	notshadowfinal *= 0.1111;*/
	
	//no PCF
	//const float notshadowfinal = shadow2D(tu1_2D, up).r + (1.0-shadow2D(tu1_2D, up+vec3(0.0,0.0,-0.02)).r);
	//const float notshadowfinal = shadow2D(tu1_2D, shadowcoords).r;
	
	//const float notshadowfinal = shadow2D(tu1_2D, up).r;
	/*const vec3 up_step = up - gl_FragCoord.xyz;
	const int samples = 4;
	float notshadowfinal = 0.0;
	for (int i = 0; i < samples; i++)
	{
		notshadowfinal += shadow2D(tu1_2D, gl_FragCoord.xyz+up_step*1.0).r;
		//notshadowfinal += shadow2D(tu1_2D, up).r;
	}
	notshadowfinal /= float (samples);*/
	
	//float notshadowfinal = 0.0;
	//const float out_offset = -0.08/gl_FragCoord.z;
	/*const float out_offset = -0.08;
	notshadowfinal += min(1.0,shadow2D(tu1_2D, up1).r + (1.0-shadow2D(tu1_2D, up1+vec3(0.0,0.0,out_offset)).r));
	notshadowfinal += min(1.0,shadow2D(tu1_2D, up2).r + (1.0-shadow2D(tu1_2D, up2+vec3(0.0,0.0,out_offset)).r));
	notshadowfinal += min(1.0,shadow2D(tu1_2D, up3).r + (1.0-shadow2D(tu1_2D, up3+vec3(0.0,0.0,out_offset)).r));
	notshadowfinal += min(1.0,shadow2D(tu1_2D, up4).r + (1.0-shadow2D(tu1_2D, up4+vec3(0.0,0.0,out_offset)).r));*/
	
	/*notshadowfinal += shadow2D(tu1_2D, up1).r;
	notshadowfinal += shadow2D(tu1_2D, up2).r;
	notshadowfinal += shadow2D(tu1_2D, up3).r;
	notshadowfinal += shadow2D(tu1_2D, up4).r;*/
	
	//notshadowfinal *= 0.25;
	
	/*const float sdiff = shadow2D(tu1_2D, shadowcoords+vec3(0.0,-0.005,0.0)).r - shadow2D(tu1_2D, shadowcoords).r;
	notshadowfinal = 1.0-min(1.0,max(0.0,sdiff)*100.0);*/
	/*float notshadowfinal = 0.0;
	if (gl_FragCoord.z <= shadow2D(tu1_2D, shadowcoords).r)
		notshadowfinal = 1.0;*/
	
	//const float blendfactor = shadow2D(tu1_2D, shadowcoords+vec3(0.0,0.0,-0.015)).r;
	//const float ao = mix(1.0,notshadowfinal,blendfactor);
	//shadow: G && !R
	//shadow: blendfactor && !notshadow
	//notshadow: !blendfactor || notshadow
	//const float ao = 0.5+0.05*(-0.5+notshadowfinal);
	const float ao = 0.75+0.25*notshadowfinal;
	//const float ao = 0.5+0.25*(-0.5+notshadowfinal);
	
	//gl_FragColor = gl_Color*ao;
	//gl_FragColor = vec4(notshadowfinal,blendfactor,0.0,1.0);
	//gl_FragColor = vec4(up.x, up.y, 0.0, 1.0);
	//gl_FragColor = vec4(gl_FragCoord.x/x_resolution, gl_FragCoord.y/y_resolution, 0.0, 1.0);
	//gl_FragColor = vec4(shadowcoords.x, shadowcoords.y, 0.0, 1.0);
	//gl_FragColor = vec4(ao);
	gl_FragColor = texture2D(tu0_2D, tu0coord)*ao;
}
