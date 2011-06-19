#!BPY
# -*- coding: iso-8859-1 -*-
"""
Name: 'JOE'
Blender: 233
Group: 'Export'
Tip: 'Export to JOE file format. (.joe)'
"""
######################################################
# JOE Exporter
# By:  Joe Venzon, based on MD2 exporter by Bob Holcomb
# Date: 1 FEB 05
# Ver: 0.1
######################################################
# This script exports a JOE file, textures, 
# and animations from blender.
######################################################
import Blender
from Blender import NMesh, Object
from Blender.BGL import *
from Blender.Draw import *
from Blender.Window import *
from Blender.Image import *
from Blender import Registry

import sys, struct, string, math
from types import *

import os
from os import path


######################################################
# Main Body
######################################################

def vector_normalize(v):
  l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
  if l != 0:
  	return v[0] / l, v[1] / l, v[2] / l
  else:
	#print v
  	return 0,0,0

def vector_dotproduct(v1, v2):
  return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]

def vector_crossproduct(v1, v2):
  return [
    v1[1] * v2[2] - v1[2] * v2[1],
    v1[2] * v2[0] - v1[0] * v2[2],
    v1[0] * v2[1] - v1[1] * v2[0],
    ]


def asciiz (s):
  n = 0
  while (ord(s[n]) != 0):
    n = n + 1
  return s[0:n]

  
######################################################
# JOE Model Constants
######################################################
JOE_MAX_TRIANGLES=4096
JOE_MAX_VERTICES=2048
JOE_MAX_TEXCOORDS=2048
JOE_MAX_NORMALS=2048
JOE_MAX_FRAMES=512
JOE_VERSION=3
#JOE_MAX_FRAMESIZE=(JOE_MAX_VERTICES * 24 + 128)



######################################################
# JOE data structures
######################################################
class joe_vertex:
	vertex=[]
	binary_format="<fff"
	def __init__(self):
		self.vertices=[0]*3
	def save(self, file):
		temp_data=[0]*3
		temp_data[0]=self.vertex[0]
		temp_data[1]=self.vertex[1]
		temp_data[2]=self.vertex[2]
		data=struct.pack(self.binary_format, temp_data[0], temp_data[1], temp_data[2])
		file.write(data)
	def dump(self):
		print "Vertex"
		print "x: ", self.vertex[0]
		print "y: ", self.vertex[1]
		print "z: ", self.vertex[2]
		print ""
		
class joe_face:
	vertex_index=[]
	normal_index=[]
	texture_index=[]
	binary_format="<3h3h3h"
	def __init__(self):
		self.vertex_index = [ 0, 0, 0 ]
		self.normal_index = [ 0, 0, 0 ]
		self.texture_index = [ 0, 0, 0 ]
	def save(self, file):
		temp_data=[0]*9

		temp_data[0]=self.vertex_index[0]
		temp_data[1]=self.vertex_index[1]
		temp_data[2]=self.vertex_index[2]

		temp_data[3]=self.normal_index[0]
		temp_data[4]=self.normal_index[1]
		temp_data[5]=self.normal_index[2]

		temp_data[6]=self.texture_index[0]
		temp_data[7]=self.texture_index[1]
		temp_data[8]=self.texture_index[2]
		data=struct.pack(self.binary_format,temp_data[0],temp_data[1],temp_data[2],temp_data[3],temp_data[4],temp_data[5],temp_data[6],temp_data[7],temp_data[8])
		file.write(data)
	def dump (self):
		print "JOE Face Structure"
		print "vertex index: ", self.vertex_index[0]
		print "vertex index: ", self.vertex_index[1]
		print "vertex index: ", self.vertex_index[2]
		print "normal index: ", self.normal_index[0]
		print "normal index: ", self.normal_index[1]
		print "normal index: ", self.normal_index[2]
		print "texture index: ", self.texture_index[0]
		print "texture index: ", self.texture_index[1]
		print "texture index: ", self.texture_index[2]
		print ""
		
class joe_tex_coord:
	u=0
	v=0
	binary_format="<ff"
	def __init__(self):
		self.u=0
		self.v=0
	def save(self, file):
		temp_data=[0]*2
		temp_data[0]=self.u
		temp_data[1]=self.v
		data=struct.pack(self.binary_format, temp_data[0], temp_data[1])
		file.write(data)
	def dump (self):
		print "Texture Coordinate"
		print "texture coordinate u: ",self.u
		print "texture coordinate v: ",self.v
		print ""

class joe_frame:
	num_vertices=0
	num_texcoords=0
	num_normals=0
	binary_format="<3i"
	faces=[]
	verts=[]
	texcoords=[]
	normals=[]
	def __init__ (self):
		self.faces=[]
		self.verts=[]
		self.texcoords=[]
		self.normals=[]
	def save(self, file):
		temp_data=[0]*3
		temp_data[0]=self.num_vertices
		temp_data[1]=self.num_texcoords
		temp_data[2]=self.num_normals
		data=struct.pack(self.binary_format, temp_data[0],temp_data[1],temp_data[2])
		file.write(data)
		#save the mesh data
		for i in xrange(0, self.num_vertices):
			self.verts[i].save(file)
		for i in xrange(0, self.num_normals):
			self.normals[i].save(file)
		for i in xrange(0, self.num_texcoords):
			self.texcoords[i].save(file)
	def dump (self):
		print "Frame"
		print "number of verts: ", self.num_vertices
		print "number of texcoords: ", self.num_texcoords
		print "number of normals: ", self.num_normals
		print ""

class joe_tempfacenormals:
	normals=[]
	def __init__ (self):
		self.normals=[]
						
class joe_obj:
	#Header Structure
	ident=0				#int 0	This is used to identify the file
	version=JOE_VERSION			#int 1	The version number of the file
	num_faces=0			#int 8	The number of faces (polygons)
	num_frames=0		#int 10	The number of animation frames
	binary_format="<4i"  #little-endian (<), 4 integers (4i)
	#joe data objects
	frames=[]
	def __init__ (self):
		self.frames=[]
	def save(self, file):
		temp_data=[0]*4
		temp_data[0]=self.ident
		temp_data[1]=self.version
		temp_data[2]=self.num_faces
		temp_data[3]=self.num_frames
		data=struct.pack(self.binary_format, temp_data[0],temp_data[1],temp_data[2],temp_data[3])
		file.write(data)
		#save the frames
		for i in xrange(0, self.num_frames):
			for j in xrange(0, self.num_faces):
				self.frames[i].faces[j].save(file)
			self.frames[i].save(file)
	def dump (self):
		print "Header Information"
		print "ident: ", self.ident
		print "version: ", self.version
		print "number of faces: ", self.num_faces
		print "number of frames: ", self.num_frames
		print ""
		
######################################################
# Export functions
######################################################
def save_joe(filename, mesh_obj):
	is_edit_mode = EditMode()
	if is_edit_mode:
		EditMode(False)
	#intermediate data structures
	vert_list={}
	vert_count=0
	tex_list={}
	tex_count=0
	norm_list={}
	norm_count=0
	face_list={}
	face_count=0
		
	#check if it's a mesh object
	if mesh_obj.getType()!="Mesh":
		print "Fatal Error: Must select a mesh to output as JOE"
		print "Found: ", mesh_obj.getType()
		result=Blender.Draw.PupMenu("Selected Object must be a mesh to output as JOE?%t|OK")
		Exit()
	
	# create a temporary mesh to hold actual (modified) mesh data
	temp_mesh_name = '~tmp'
	containerMesh = meshName = tempMesh = None
	for meshName in Blender.NMesh.GetNames():
		if meshName.startswith(temp_mesh_name):
			containerMesh = Blender.Mesh.Get(meshName)
			break
#	somehow, our temporary mesh always has a user, even if blender won't show it
#			if not tempMesh.users:
#				containerMesh = tempMesh
	if not containerMesh:
		containerMesh = Blender.Mesh.New(temp_mesh_name)
	
	#get access to the mesh data
	mesh = containerMesh # temporary mesh to hold actual (modified) mesh data
	mesh.getFromObject(mesh_obj)
	
	#convert quads to tris
	scn = Blender.Scene.GetCurrent()
	oldmode = Blender.Mesh.Mode()
	Blender.Mesh.Mode(Blender.Mesh.SelectModes['FACE'])
	mesh.sel = True
	tempob = scn.objects.new(mesh)
	mesh.quadToTriangle(0) # more=0 shortest length
	oldmode = Blender.Mesh.Mode(oldmode)
	scn.objects.unlink(tempob)
	Blender.Mesh.Mode(oldmode)
	
	#transform the mesh
	mesh.transform(mesh_obj.matrixWorld)
	
	#mesh.getRawFromObject(mesh_obj.name)
	#mesh=mesh_obj.getData()
	
	istris = 1
	for face in mesh.faces:
		face_count=face_count+1
		if len(face.v)!=3:
			istris = 0
			print "Face has "+`len(face.v)`+" verts:"
			for fnum in xrange(len(face.v)):
				print face.v[fnum].co
	
	if istris!=1:
		print "Model not made entirely of triangles"
		result=Blender.Draw.PupMenu("Model not made entirely out of Triangles?%t|OK")
		Exit()
				
		
	#make a blank joe class and start filling it in
	joe=joe_obj()
	
	#header information
	joe.ident=844121161
	joe.version=JOE_VERSION
	
	#setup other important numbers
	#joe.num_vertices=vert_count
	#joe.num_tex_coords=tex_count
	face_count = len(mesh.faces)
	joe.num_faces=face_count
	
	#don't support exporting skins just yet.
	#get the skin information
	#use the first faces' image for the texture information
	
	#if there is a texture map
	mesh_image=mesh.faces[0].image
	#print "Texture filename: " + os.path.basename(mesh_image.getFilename())
	"""
	size=mesh_image.getSize()
	#is this really what the user wants
	if (size[0]!=256 or size[1]!=256):
		result=Blender.Draw.PupMenu("Texture map size is not 256x256, it's: "+size[0]+"x"size[1]+": Continue?%t|Yes|No")
		if(result==2):
			Exit()
	joe.skin_width=size[0]
	joe.skin_height=size[1]
	joe.num_skins=1
	#add a skin node to the joe data structure
	joe.skins.append(joe_skin())
	joe.skins[0].name=os.path.basename(mesh_image.getFilename())
	"""
	
	


	#get the frame data
	#one frame=frame header and all the verticies for that frame
	#the number of verticies is constant between frames
	#frame format=3f 3f 16s=12+12+16=40 bytes
	#a vertex format=3BB=3+1=4 bytes
	
	#calculate 1 frame size  + (1 vert size*num_verts)
	#joe.frame_size=40+(vert_count*24) #in bytes
	
	#fill in each frame with frame info and all the vertices for that frame
	user_frame_list=get_frame_list()
	
	#if user_frame_list=="default":
	#	joe.num_frames=198
	#else:
	#	temp=user_frame_list[len(user_frame_list)-1]
	#	joe.num_frames=temp[2]+1
	
	joe.num_frames = g_frames.val

	#print "number of frames: ", joe.num_frames

	for frame_counter in range(0,joe.num_frames):
		#add a frame
		joe.frames.append(joe_frame())		
		#update the mesh objects vertex positions for the animation
		#set blender to the correct frame
		Blender.Set("curframe", frame_counter)
		
		#update the mesh in blender to get the vertices modified by the animation
		#mesh=NMesh.GetRawFromObject(mesh_obj.name)
		#print len(mesh.faces)
		mesh.getFromObject(mesh_obj)
		#convert quads to tris
		scn = Blender.Scene.GetCurrent()
		oldmode = Blender.Mesh.Mode()
		Blender.Mesh.Mode(Blender.Mesh.SelectModes['FACE'])
		mesh.sel = True
		tempob = scn.objects.new(mesh)
		mesh.quadToTriangle(0) # more=0 shortest length
		oldmode = Blender.Mesh.Mode(oldmode)
		scn.objects.unlink(tempob)
		Blender.Mesh.Mode(oldmode)
		
		#transform the mesh
		mesh.transform(mesh_obj.matrixWorld)
		#print len(mesh.faces)
		#mesh.getRawFromObject(mesh_obj.name)

		#clear temp data		
		vert_list={}
		vert_count=0
		tex_list={}
		tex_count=0
		norm_list={}
		norm_count=0
		face_list={}
		
		facenorms=[]
		
		for this_face in xrange(0, joe.num_faces):
			facenorms.append(joe_tempfacenormals())
			facenorms[this_face].normals.append(joe_vertex())
			facenorms[this_face].normals.append(joe_vertex())
			facenorms[this_face].normals.append(joe_vertex())
			#print joe.num_faces
			#print this_face
			#print len(mesh.faces)
			if not mesh.faces[this_face].smooth:
				p1 = mesh.faces[this_face].v[0].co
				p2 = mesh.faces[this_face].v[1].co
				p3 = mesh.faces[this_face].v[2].co
				normal = vector_normalize(vector_crossproduct(
					[p3[0] - p2[0], p3[1] - p2[1], p3[2] - p2[2]],
					[p1[0] - p2[0], p1[1] - p2[1], p1[2] - p2[2]],
					))
				facenorms[this_face].normals[0].vertex = normal
				facenorms[this_face].normals[1].vertex = normal
				facenorms[this_face].normals[2].vertex = normal
				print "not smooth: "
				print normal
			else:
				facenorms[this_face].normals[0].vertex = mesh.faces[this_face].v[0].no
				facenorms[this_face].normals[1].vertex = mesh.faces[this_face].v[1].no
				facenorms[this_face].normals[2].vertex = mesh.faces[this_face].v[2].no
				print "smooth: "
		
		for this_face in xrange(0, joe.num_faces):
			for this_vert in range(0, 3):
				n = (facenorms[this_face].normals[this_vert].vertex)
				norm_key=(n[0], n[1], n[2]);
				if not norm_list.has_key(norm_key):
					norm_list[norm_key] = norm_count
					norm_count = norm_count + 1

		#load up some intermediate data structures
		for vertex in mesh.verts:
			v = (vertex.co)
			vert_key=(v[0], v[1], v[2])
			if not vert_list.has_key(vert_key):
				vert_list[vert_key] = vert_count
				vert_count = vert_count + 1
				#print "added vert #",vert_count,": ", v
				
		#if mesh.hasVertexUV():
		if mesh.vertexUV:
			#print "I have Vertex UV"
			for vertex in mesh.verts:
				#are there UV coordinates?
				if(len(vertex.uvco)>0):
					t = (vertex.uvco)
					tex_key=(t[0], t[1])
					if not tex_list.has_key(tex_key):
						tex_list[tex_key]=tex_count
						tex_count=tex_count+1
						#print "added tex_vert #",tex_count,": ", t
				else:
					tex_key=(0.0,0.0)
					tex_list=[tex_key]=tex_count
					tex_count=tex_count+1
						
		elif mesh.faceUV:
			#print "I have Face UV"
			for face in mesh.faces:
				#face_count=face_count+1
				for i in range(0,3):
					#are there UV coordinates?
					if (len(face.uv)>0):
						t=(face.uv[i])
						tex_key=(t[0], t[1])
						if not tex_list.has_key(tex_key):
							tex_list[tex_key]=tex_count
							tex_count=tex_count+1
							#print "added tex_vert #",tex_count,": ", t
					else:
						tex_key=(0.0,0.0)
						tex_list=[tex_key]=tex_count
						tex_count=tex_count+1
		
		else:
			print "I don't have any UV"
			for vertex in mesh.verts:
				tex_key=(0.0,0.0)
				if len(tex_list) > 0:
					tex_list=[tex_key]=tex_count
					tex_count=tex_count+1
		
		joe.frames[frame_counter].num_vertices = vert_count
		joe.frames[frame_counter].num_texcoords = tex_count
		joe.frames[frame_counter].num_normals = norm_count
		
		#get the texture coordinates
		#print "tex_count: ", tex_count
		for this_tex in range (0, joe.frames[frame_counter].num_texcoords):
			joe.frames[frame_counter].texcoords.append(joe_tex_coord())
			
		for coord, index in tex_list.iteritems():
			#fill it with information
			#joe.tex_coords[index].u=int(coord[0]*joe.skin_width)
			joe.frames[frame_counter].texcoords[index].u=coord[0]
			#joe.tex_coords[index].v=int((1-coord[1])*joe.skin_height)
			joe.frames[frame_counter].texcoords[index].v=1-coord[1]
	
		for this_vert in range (0, joe.frames[frame_counter].num_vertices):
			joe.frames[frame_counter].verts.append(joe_vertex())
		for vert, index in vert_list.iteritems():
			joe.frames[frame_counter].verts[index].vertex = vert
		
		for this_norm in range (0, joe.frames[frame_counter].num_normals):
			joe.frames[frame_counter].normals.append(joe_vertex())
		for norm, index in norm_list.iteritems():
			joe.frames[frame_counter].normals[index].vertex = norm
	
			
		#get the face info
		for this_face in xrange(0, joe.num_faces):
			#add another blankface to the face list
			joe.frames[frame_counter].faces.append(joe_face())
			for i in range (0,3):
				#build the keys
				vert=(mesh.faces[this_face].v[i].co)
				vert_key=(vert[0], vert[1], vert[2])
				vert_index=vert_list[vert_key]
				#print "vet_index: ", vert_index
				#print mesh.faces[this_face].smooth, ":", mesh.faces[this_face].v[i].no[0], ",", mesh.faces[this_face].v[i].no[1], ",", mesh.faces[this_face].v[i].no[2]
				joe.frames[frame_counter].faces[this_face].vertex_index[i]=vert_index
				#norm=(mesh.faces[this_face].v[i].no)
				norm=facenorms[this_face].normals[i].vertex
				norm_key=(norm[0], norm[1], norm[2])
				norm_index=norm_list[norm_key]
				joe.frames[frame_counter].faces[this_face].normal_index[i]=norm_index
				if mesh.vertexUV:
					uv_coord=(mesh.faces[this_face].v[i].uvco)
					tex_key=(uv_coord[0],uv_coord[1])
					#print "Vertex uv: ", uv
					tex_index=tex_list[tex_key]
					#print "tex_index: ", tex_index
					joe.frames[frame_counter].faces[this_face].texture_index[i]=tex_index
				elif mesh.faceUV:
					uv_coord=(mesh.faces[this_face].uv[i])
					tex_key=(uv_coord[0],uv_coord[1])
					#print "Face uv: ", uv
					tex_index=tex_list[tex_key]
					#print "tex_index: ", tex_index
					joe.frames[frame_counter].faces[this_face].texture_index[i]=tex_index
		
		#if not mesh.faces[mesh.verts[vert_counter].index].smooth:
		#	p1 = mesh.faces[mesh.verts[vert_counter].index].v[0].co
		#	p2 = mesh.faces[mesh.verts[vert_counter].index].v[1].co
		#	p3 = mesh.faces[mesh.verts[vert_counter].index].v[2].co
		#	normal = vector_normalize(vector_crossproduct(
		#		[p3[0] - p2[0], p3[1] - p2[1], p3[2] - p2[2]],
		#		[p1[0] - p2[0], p1[1] - p2[1], p1[2] - p2[2]],
		#		))
		

			

	#compute these after everthing is loaded into a joe structure
	#header_size=17*4 #17 integers, and each integer is 4 bytes
	#skin_size=64*joe.num_skins #64 char(or bytes) per skin * number of skins
	#tex_coord_size=8*joe.num_tex_coords #2 floats (4 bytes each) * number of texture coords
	#face_size=12*joe.num_faces #3 shorts (2 bytes each=6 total) for vertex index, 3 shorts (2 bytes each=6 total) for tex index
	#frames_size=(((12+12+16)+(24*joe.num_vertices))*joe.num_frames)
	#3 floats, 3 floats, 16 char for the frame header
	#24 bytes per vertex * number of vertex
	#all that times the number of frames
	
	#not worried about GL commands at this time
	#GL_command_size=0
	
	#fill in the info about offsets
	#joe.offset_skins=0+header_size
	
	
	#joe.offset_tex_coords=joe.offset_skins+skin_size
	
	#joe.offset_faces=joe.offset_tex_coords+tex_coord_size
	
	#joe.offset_frames=joe.offset_faces+face_size
	
	#joe.offset_GL_commands=joe.offset_frames+frames_size
	
	#joe.offset_end=joe.offset_GL_commands+GL_command_size

	#actually write it to disk
	file=open(filename,"wb")
	joe.save(file)
	joe.dump()
	file.close()
	print "Closed the file"
	
	if is_edit_mode:
		EditMode(True)

def get_frame_list():
	global g_frame_filename
	frame_list=[]

	if g_frame_filename.val=="default":
		print "found default filename from GUI"
		return "default"

	else:
	#check for file
		if (os.path.isfile(g_frame_filename.val)):
			print "os.path says filename is valid"
			#open file and read it in
			file=open(g_frame_filename.val,"r")
			lines=file.readlines()
			file.close()
			print "opened and read ", len(lines), " lines"

			#check header (first line)
			if lines[0]<>"# JOE Frame Name List\n":
				print "its not a valid file"
				return "default"
			else:
				#read in the data
				num_frames=0
				for counter in range(1, len(lines)):
					current_line=lines[counter]
					print "current line: ", current_line
					print "current_line[0]: ", current_line[0]

					if current_line[0]=="#":
						#found a comment
						pass

					else:
						data=current_line.split()
						print "data: ", data
						frame_list.append([data[0],num_frames+1, num_frames+int(data[1])])
						num_frames+=int(data[1])

				print "returning: "
				print	frame_list
				return frame_list
		
		else:
			return "default"
		
######################################################
# Registry functions
######################################################

def load_settings():
	global joe_settings

	joe_settings = Registry.GetKey('JOE_Settings', True)
	if not joe_settings:
		joe_settings = {}

	if not 'filename' in joe_settings:
		joe_settings['filename'] = "/home/joe/3d/test.joe"

def save_settings():
	global joe_settings
	Blender.Registry.SetKey('JOE_Settings', joe_settings, True)

######################################################
# GUI Loader
######################################################

# Get registry settings
load_settings()

# Import globals
g_filename=Create(joe_settings['filename'])
g_frame_filename=Create("default")

g_filename_search=Create("model")
g_frame_search=Create("default")

#Globals
g_scale=Create(1.0)
g_frames=Create(1)
g_useSelected=Create(0)

# Events
EVENT_NOEVENT=1
EVENT_SAVE_JOE=2
EVENT_CHOOSE_FILENAME=3
EVENT_CHOOSE_FRAME=4
EVENT_EXIT=100

######################################################
# Callbacks for Window functions
######################################################
def filename_callback(input_filename):
	global g_filename, joe_settings
	g_filename.val=input_filename
	joe_settings['filename'] = input_filename
	save_settings()

def frame_callback(input_frame):
	global g_frame_filename
	g_frame_filename.val=input_frame


def draw_gui():
	global g_scale
	global g_frames
	global g_filename
	global g_frame_filename
	global g_useSelected, g_writeList
	global EVENT_NOEVENT,EVENT_SAVE_JOE,EVENT_CHOOSE_FILENAME,EVENT_CHOOSE_FRAME,EVENT_EXIT

	########## Titles
	glClear(GL_COLOR_BUFFER_BIT)
	glRasterPos2d(8, 103)
	Text("JOE Export")

	######### Parameters GUI Buttons
	g_filename = String("JOE file to save: ", EVENT_NOEVENT, 10, 55, 210, 18,
                            g_filename.val, 255, "JOE file to save")
	########## JOE File Search Button
	Button("Search",EVENT_CHOOSE_FILENAME,220,55,80,18)

	#g_frame_filename = String("Frame List file to load: ", EVENT_NOEVENT, 10, 35, 210, 18,
        #                        g_frame_filename.val, 255, "Frame List to load-overrides JOE file")
	########## Texture Search Button
	#Button("Search",EVENT_CHOOSE_FRAME,220,35,80,18)

	########## Scale slider-default is 1/8 which is a good scale for joe->blender
	#g_scale= Slider("Scale Factor: ", EVENT_NOEVENT, 10, 75, 210, 18,
        #            1.0, 0.001, 10.0, 1, "Scale factor for obj Model");
	
	g_frames = Number("No. of frames: ", EVENT_NOEVENT, 10, 75, 210, 18,
		1, 1, JOE_MAX_FRAMES, "The number of animation frames to export");
		
	g_useSelected = Toggle	("Export only the selected object", 7, 10,  125, 280, 19, g_useSelected.val, "Export only selected items")

	######### Draw and Exit Buttons
	Button("Export",EVENT_SAVE_JOE , 10, 10, 80, 18)
	Button("Exit",EVENT_EXIT , 170, 10, 80, 18)

def event(evt, val):	
	if (evt == QKEY and not val):
		Exit()

def bevent(evt):
	global g_filename
	global g_frame_filename
	global EVENT_NOEVENT,EVENT_SAVE_JOE,EVENT_EXIT

	######### Manages GUI events
	if (evt==EVENT_EXIT):
		Blender.Draw.Exit()
	elif (evt==EVENT_CHOOSE_FILENAME):
		FileSelector(filename_callback, "JOE File Selection")
	#elif (evt==EVENT_CHOOSE_FRAME):
#		FileSelector(frame_callback, "Frame Selection")
	elif (evt==EVENT_SAVE_JOE):
		if (g_filename.val == "model"):
			Blender.Draw.Exit()
		else:
			saved_num = 0
			if (g_useSelected.val == 1):
				mesh_obj = Blender.Object.GetSelected()
				#get the currently selected data structure
				mesh_obj = Blender.Object.GetSelected()
				#check if an object is selected
				if len(mesh_obj)==0:
					print "Fatal Error: Must select a mesh to output as JOE"
					print "Found nothing"
					result=Blender.Draw.PupMenu("Select an object to export%t|OK")
					Exit()
				save_joe(g_filename.val,mesh_obj[0])
			else:
				listfile = open (g_filename.val + "-list.txt", "w")
				listfile.write ("# File generated by export-all-joe-0.3.py\n\n17\n\n")
				ObjList = Blender.Object.Get()
				for nextObject in ObjList:		# otherwise handle each item in the list
					if (nextObject.getType()=="Mesh"):
						if (len(nextObject.getData().faces) > 0):
							if (nextObject.getData().faces[0].image is not None):
								if not nextObject.name.startswith("~tmp"):
									listfile.write("# Object " + nextObject.name + "\n")
									listfile.write(os.path.basename(g_filename.val) + "-object-" + nextObject.name + ".joe\n")
									listfile.write(os.path.basename(nextObject.getData().faces[0].image.getFilename())+"\n")
									listfile.write("1\n0\n0\n0\n2.0\n0.0\n0\n1\n1.0\n1.0\n1.0\n0.0\n0\n0\n1\n\n")
									save_joe(g_filename.val + "-object-" + nextObject.name + ".joe", nextObject)
			
			print "ended save_JOE"
			print "wrote " + str(saved_num) + " objects"
			Blender.Draw.Exit()
			print "Blender.Draw.Exit() called"

Register(draw_gui, event, bevent)
