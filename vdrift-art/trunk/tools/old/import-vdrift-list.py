#!BPY
# -*- coding: iso-8859-1 -*-

"""
Name: 'VDrift (list.txt)'
Blender: 239
Group: 'Import'
Tooltip: 'Import VDrift tracks. (list.txt)'
"""
######################################################
# JOE Importer
# By:   Rikard Öxler, based on JOE exporter by Joe Venzon
#      and   MD2 importer by Bob Holcomb
# Date:   1 NOV 08
# Ver:   0.1
######################################################
# This script imports a JOE file, textures,
# and animations from blender.
######################################################

import Blender
from Blender import Mesh, Object, sys
from Blender.BGL import *
from Blender.Draw import *
from Blender.Window import *
from Blender.Mathutils import Vector
import struct
import sys
from types import *


######################################################
# Main Body
######################################################

#returns the string from a null terminated string
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
JOE_MAX_FRAMES=512
JOE_MAX_SKINS=32
JOE_MAX_FRAMESIZE=(JOE_MAX_VERTICES * 4 + 128)

######################################################
# JOE data structures
######################################################
class joe_alias_triangle(object):
   __slots__ = 'vertices',
   binary_format="<fff" #little-endian (<), 3 Unsigned char
   
   def __init__(self):
      self.vertices=[0]*3


   def load(self, file):
      temp_data = file.read(struct.calcsize(self.binary_format))
      data = struct.unpack(self.binary_format, temp_data)
      self.vertices[0]=data[0]
      self.vertices[1]=data[1]
      self.vertices[2]=data[2]
      return self

   def dump(self):
      print "JOE Alias_Triangle Structure"
      print "vertex: ", self.vertices[0]
      print "vertex: ", self.vertices[1]
      print "vertex: ", self.vertices[2]
      print ""

class joe_face(object):
   
   binary_format="<3h3h3h" #little-endian (<), 3 short, 3 short
   
   __slots__ = 'vertex_index', 'normal_index', 'texture_index'
   
   def __init__(self):
      self.vertex_index = [ 0, 0, 0 ]
      self.normal_index = [ 0, 0, 0 ]
      self.texture_index = [ 0, 0, 0]

   def load (self, file):
      temp_data=file.read(struct.calcsize(self.binary_format))
      data=struct.unpack(self.binary_format, temp_data)
      self.vertex_index[0]=data[0]
      self.vertex_index[1]=data[1]
      self.vertex_index[2]=data[2]
      self.normal_index[0]=data[3]
      self.normal_index[1]=data[4]
      self.normal_index[2]=data[5]
      self.texture_index[0]=data[6]
      self.texture_index[1]=data[7]
      self.texture_index[2]=data[8]
      return self

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

class joe_tex_coord(object):
   __slots__ = 'u', 'v'
   binary_format="<2f" #little-endian (<), 2 float
   
   def __init__(self):
      self.u=0
      self.v=0

   def load (self, file):
      temp_data=file.read(struct.calcsize(self.binary_format))
      data=struct.unpack(self.binary_format, temp_data)
      self.u=data[0]
      self.v=data[1]
      return self

   def dump (self):
      print "JOE Texture Coordinate Structure"
      print "texture coordinate u: ",self.u
      print "texture coordinate v: ",self.v
      print ""


class joe_skin(object):
   __slots__ = 'name'
   binary_format="<64s" #little-endian (<), char[64]

   def __init__(self):
      self.name=""

   def load (self, file):
      temp_data=file.read(struct.calcsize(self.binary_format))
      data=struct.unpack(self.binary_format, temp_data)
      self.name=asciiz(data[0])
      return self

   def dump (self):
      print "JOE Skin"
      print "skin name: ",self.name
      print ""

class joe_alias_frame(object):
   __slots__ = 'faces', 'verts', 'texcoords', 'normals',\
   'num_vertices', 'num_normals', 'num_texcoords'
   '''
   num_vertices=0
   num_normals=0
   num_texcoords=0
   '''
   binary_format="<3i" #little-endian (<), 3 integers
   #num_vertices=0
   #num_texcoords=0
   #num_normals=0


   def __init__(self):
      self.faces=[]
      self.verts=[]
      self.texcoords=[]
      self.normals=[]

   def load (self, file):
      temp_data=file.read(struct.calcsize(self.binary_format))
      data=struct.unpack(self.binary_format, temp_data)
      self.num_vertices=data[0]
      self.num_texcoords=data[1]
      self.num_normals=data[2]
      for i in xrange(0, self.num_vertices):
         self.verts.append(joe_alias_triangle())
      for i in xrange(0, self.num_normals):
         self.normals.append(joe_alias_triangle())
      for i in xrange(0, self.num_texcoords):
         self.texcoords.append(joe_tex_coord())

      for i in xrange(0, self.num_vertices):
         self.verts[i].load(file)
         #self.verts[i].dump()
      for i in xrange(0, self.num_normals):
         self.normals[i].load(file)
         #self.normals[i].dump()
      for i in xrange(0, self.num_texcoords):
         self.texcoords[i].load(file)
         #self.texcoords[i].dump()
      return self

   def dump (self):
      print "JOE Alias Frame"
      print "number of verts: ",self.num_vertices
      print "number of texcoords",self.num_texcoords
      print "number of normals ",self.num_normals
      print ""

class joe_obj(object):
   __slots__ =\
   'frames',\
   'ident', 'version',\
   'num_faces',\
   'num_frames',\
   'skin_width', 'skin_height', 'num_skins',
   
   
   '''
   #Header Structure
   ident=0            #int 0   This is used to identify the file
   version=0         #int 1   The version number of the file (Must be 8)
   num_faces=0         #int 8   The number of faces (polygons)
   num_frames=0      #int 10   The number of animation frames
   '''
   binary_format="<4i"  #little-endian (<4> 0:
#      for i in xrange(0,joe.num_skins):
#         joe.skins[i].dump()
#         if (Blender.sys.exists(joe.skins[i].name)):
#            try:   return Blender.Image.Load(joe.skins[i].name)
#            except:   return -1
   

def animate_joe(joe, mesh):
   ######### Animate the verts through keyframe animation
   
   # Fast access to the meshes vertex coords
   verts = [v.co for v in mesh.verts]
   scale = g_scale.val
   
   for i in xrange(1, joe.num_frames):
      frame = joe.frames[i]
      #update the vertices
      for j in xrange(joe.num_vertices):
         x=(frame.verts[j].vertices[0]) * scale
         y=(frame.verts[j].vertices[1]) * scale
         z=(frame.verts[j].vertices[2]) * scale
         
         #put the vertex in the right spot
         verts[j][:] = y,-x,z
         
      mesh.insertKey(i,"absolute")
      # mesh.insertKey(i)
      
      #not really necissary, but I like playing with the frame counter
      Blender.Set("curframe", i)
   
   
   # Make the keys animate in the 3d view.
#   key = mesh.key
#   key.relative = False
   
   # Add an IPO to teh Key
#   ipo = Blender.Ipo.New('Key', 'joe')
#   key.ipo = ipo
   # Add a curve to the IPO
#   curve = ipo.addCurve('Basis')
   
   # Add 2 points to cycle through the frames.
#   curve.append((1, 0))
#   curve.append((joe.num_frames, (joe.num_frames-1)/10.0))
#   curve.interpolation = Blender.IpoCurve.InterpTypes.LINEAR
   


def load_joe(joe_filename, texture_filename):
   #sys.stdout.flush()
   #read the file in
   file=open(joe_filename,"rb")
   WaitCursor(1)
   DrawProgressBar(0.0, 'Loading JOE')
   joe=joe_obj()
   joe.load(file)
   joe.dump()
   file.close()

   ######### Creates a new mesh
   mesh = Mesh.New()

   uv_coord=[]
   uv_list=[]
   verts_extend = []
   #load the textures to use later
   #-1 if there is no texture to load
   mesh_image=load_textures(joe, texture_filename)
   if mesh_image == -1 and texture_filename:
      print 'JOE Import, Warning, texture "%s" could not load'

   if (mesh_image != -1 and texture_filename != ""):
      size=mesh_image.getSize()
      #is this really what the user wants
   #   if (size[0]!=256 or size[1]!=256):
   #      result=Blender.Draw.PupMenu("Texture map size is not 256x256, it's: "+str(size[0])+"x"+str(size[1])+": Continue?%t|Yes|No")
   #      if(result==2):
   #         Exit()
      joe.skin_width=size[0]
      joe.skin_height=size[1]
      joe.num_skins = 1


   ######### Make the verts
   DrawProgressBar(0.25,"Loading Vertex Data")
   frame = joe.frames[0]
   scale = g_scale.val
   
   def tmp_get_vertex(i):
      #use the first frame for the mesh vertices
      x=(frame.verts[i].vertices[0])*scale
      y=(frame.verts[i].vertices[1])*scale
      z=(frame.verts[i].vertices[2])*scale
      return x,y,z
   
   mesh.verts.extend( [tmp_get_vertex(i) for i in xrange(0,frame.num_vertices)] )
   del tmp_get_vertex
   
   ######## Make the UV list
   DrawProgressBar(0.50,"Loading UV Data")
   
   #w = float(joe.skin_width)
   #h = float(joe.skin_height)
   #if w <= 0.0: w = 1.0
   #if h <0>blender
   g_scale= Slider("Scale Factor: ", EVENT_NOEVENT, 10, 75, 210, 18,
               1.0, 0.001, 10.0, 1, "Scale factor for obj Model");

   ######### Draw and Exit Buttons
   Button("Load",EVENT_LOAD_JOE , 10, 10, 80, 18)
   Button("Exit",EVENT_EXIT , 170, 10, 80, 18)

def event(evt, val):   
   if (evt == QKEY and not val):
      Blender.Draw.Exit()

def bevent(evt):
   global g_joe_filename
   global g_texture_filename
   global EVENT_NOEVENT,EVENT_LOAD_JOE,EVENT_SAVE_JOE,EVENT_EXIT

   ######### Manages GUI events
   if (evt==EVENT_EXIT):
      Blender.Draw.Exit()
   elif (evt==EVENT_CHOOSE_FILENAME):
      FileSelector(filename_callback, "JOE File Selection")
   elif (evt==EVENT_CHOOSE_TEXTURE):
      FileSelector(texture_callback, "Texture Selection")
   elif (evt==EVENT_LOAD_JOE):
      if not Blender.sys.exists(g_joe_filename.val):
         PupMenu('Model file does not exist')
         return
      else:
         #sys.stdout.flush()
         nextline = True;
         nextline2 = False;
         model = ""
         texture = ""
         list_txt=g_joe_filename.val
         dir=Blender.sys.dirname(list_txt)
         file=open(list_txt,"rb")
         for line in file.readlines():
            if line.strip() == "":
               nextline = True
               continue
            if nextline2 == True:
               texture = line.strip()
               print "Texture:", texture
               if (Blender.sys.exists(Blender.sys.join(dir,model)) and  Blender.sys.exists(Blender.sys.join(dir,texture))):
                  load_joe(Blender.sys.join(dir,model), Blender.sys.join(dir,texture))
               nextline2 = False
            if nextline == True and line[:1] != "#":
               model = line.strip()
               print "Model:", model
               nextline = False
               nextline2 = True
         del line
         file.close()
         Blender.Redraw()
         Blender.Draw.Exit()
         return

if __name__ == '__main__':
   Register(draw_gui, event, bevent) 
