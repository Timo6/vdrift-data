varying vec4 oldpos;
varying vec4 newpos;
varying vec2 texcoord_2d;

//uniform mat4 prev_modelview;
uniform mat4 prev_modelviewproj;

void main()
{
	vec4 new_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	vec4 old_Position = prev_modelviewproj * gl_Vertex; //TODO: should use old_Vertex passed in by CPU for dynamic objects
	
	gl_Position = new_Position;
	oldpos = old_Position;
	newpos = new_Position;
}
