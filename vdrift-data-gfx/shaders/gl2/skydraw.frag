varying vec3 view_direction;

uniform samplerCube sky_sampler;

void main()
{
    gl_FragColor = textureCube(sky_sampler, view_direction);
}
