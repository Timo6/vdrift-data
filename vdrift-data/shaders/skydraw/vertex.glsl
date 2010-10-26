varying vec2 TexCoord;

void main(void)
{
   gl_Position = vec4(gl_Vertex.xy, 0.0, 1.0);
   gl_Position = sign(gl_Position);
   TexCoord = gl_Position.xy;
}
