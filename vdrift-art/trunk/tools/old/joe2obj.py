#!/usr/bin/python

# EXTENSIONS  : "joe" "JOE"               # Accepted file extentions
# OSTYPES     : "****"                  # Accepted file types
# ROLE        : Editor                  # Role (Editor, Viewer, None)
# SERVICEMENU : Joe2/Examine Joe file      # Name of Service menu item

"""
This script takes a .joe file
and currently outputs an equivalent .obj (and .mtl) file.

"""

import sys, string, math, struct

######################################################
# JOE Model Constants
######################################################
JOE_MAX_TRIANGLES=4096
JOE_MAX_VERTICES=2048
JOE_MAX_TEXCOORDS=2048
JOE_MAX_NORMALS=2048
JOE_MAX_FRAMES=512
JOE_VERSION=3

######################################################
# JOE data structures
######################################################
class joe_vertex:
   vertex=[]
   binary_format="<fff"
   def __init__(self):
      self.vertex=[0]*3
   def save(self, file):
      temp_data=[0]*3
      temp_data[0]=self.vertex[0]
      temp_data[1]=self.vertex[1]
      temp_data[2]=self.vertex[2]
      data=struct.pack(self.binary_format, temp_data[0], temp_data[1], temp_data[2])
      file.write(data)
   def write_obj_vertex(self, file):
      file.write('v %.8f %.8f %.8f\n' % (-self.vertex[0], self.vertex[2], self.vertex[1]))
   def write_obj_normal(self, file):
      file.write('vn %.8f %.8f %.8f\n' % (-self.vertex[0], self.vertex[2], self.vertex[1]))
   def load(self, data):
      start, stop = 0, struct.calcsize(self.binary_format)
      self.vertex[0], self.vertex[1], self.vertex[2] = struct.unpack(self.binary_format, data[start:stop])
      #self.dump()
      return data[stop:]
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
      #swap vertices around so they draw right
      temp_data[0]=self.vertex_index[0]
      temp_data[1]=self.vertex_index[2]
      temp_data[2]=self.vertex_index[1]
      #normals
      temp_data[3]=self.normal_index[0]
      temp_data[4]=self.normal_index[2]
      temp_data[5]=self.normal_index[1]
      #swap texture vertices around so they draw right
      temp_data[6]=self.texture_index[0]
      temp_data[7]=self.texture_index[2]
      temp_data[8]=self.texture_index[1]
      data=struct.pack(self.binary_format,temp_data[0],temp_data[1],temp_data[2],temp_data[3],temp_data[4],temp_data[5],temp_data[6],temp_data[7],temp_data[8])
      file.write(data)
   def write_obj_face(self, file):
      temp_data=[0]*9
      #vertices
      temp_data[0]=self.vertex_index[0] + 1
      temp_data[3]=self.vertex_index[1] + 1
      temp_data[6]=self.vertex_index[2] + 1
      #texture vertices
      temp_data[1]=self.texture_index[0] + 1
      temp_data[4]=self.texture_index[1] + 1
      temp_data[7]=self.texture_index[2] + 1
      #normals
      temp_data[2]=self.normal_index[0] + 1
      temp_data[5]=self.normal_index[1] + 1
      temp_data[8]=self.normal_index[2] + 1
      file.write('f %d/%d/%d %d/%d/%d %d/%d/%d\n' % (temp_data[0],temp_data[1],temp_data[2],temp_data[3],temp_data[4],temp_data[5],temp_data[6],temp_data[7],temp_data[8]))
   def load(self, data):
      start, stop = 0, struct.calcsize(self.binary_format)
      self.vertex_index[0], self.vertex_index[2], self.vertex_index[1], self.normal_index[0], self.normal_index[2], self.normal_index[1], self.texture_index[0], self.texture_index[2], self.texture_index[1] = struct.unpack(self.binary_format, data[start:stop])
      #self.dump()
      return data[stop:]
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
   def write_obj_uv(self, file):
      file.write('vt %.8f %.8f\n' % (self.u, 1.0 - self.v))
   def load(self, data):
      start, stop = 0, struct.calcsize(self.binary_format)
      self.u, self.v = struct.unpack(self.binary_format, data[start:stop])
      #self.dump()
      return data[stop:]
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
   def append_vertex(self, x, y, z):
      self.verts.append( joe_vertex())
      self.verts[-1].vertex = [x, y, z]
      self.num_vertices = len(self.verts)
      #self.verts[-1].dump()
   def append_normal(self, x, y, z):
      self.normals.append( joe_vertex())
      self.normals[-1].vertex = [x, y, z]
      self.num_normals = len(self.normals)
      #self.normals[-1].dump()
   def append_texcoord(self, u, v):
      self.texcoords.append( joe_tex_coord())
      self.texcoords[-1].u = u
      self.texcoords[-1].v = v
      self.num_texcoords = len(self.texcoords)
      #self.texcoords[-1].dump()
   def append_face(self, v0, v1, v2, n0, n1, n2, t0, t1, t2):
      self.faces.append( joe_face())
      self.faces[-1].vertex_index = [v0, v1, v2]
      self.faces[-1].normal_index = [n0, n1, n2]
      self.faces[-1].texture_index = [t0, t1, t2]
      self.faces[-1].dump()
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
   def write_obj_frame(self, file):
      for i in xrange(0, self.num_vertices):
         self.verts[i].write_obj_vertex(file)
      for i in xrange(0, self.num_normals):
         self.normals[i].write_obj_normal(file)
      for i in xrange(0, self.num_texcoords):
         self.texcoords[i].write_obj_uv(file)
   def load(self, data):
      start, stop = 0, struct.calcsize(self.binary_format)
      self.num_vertices, self.num_texcoords, self.num_normals = struct.unpack(self.binary_format, data[start:stop])
      #self.dump()
      data = data[stop:]
      for i in xrange(0, self.num_vertices):
         self.verts.append( joe_vertex())
         data = self.verts[i].load(data)
      for i in xrange(0, self.num_normals):
         self.normals.append( joe_vertex())
         data = self.normals[i].load(data)
      for i in xrange(0, self.num_texcoords):
         self.texcoords.append( joe_tex_coord())
         data = self.texcoords[i].load(data)
      return data
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
   ident=8441211611   #int 0   This is used to identify the file
   version=JOE_VERSION   #int 1   The version number of the file
   num_faces=0         #int 8   The number of faces (polygons)
   num_frames=0      #int 10   The number of animation frames
   binary_format="<4i"   #little-endian (<), 4 integers (4i)
   #joe data objects
   frames=[]
   def __init__ (self):
      self.frames=[]
   def append_vertex(self, x, y, z):
      if (self.num_frames < 1):
         self.frames.append( joe_frame())
         self.num_frames = 1
      self.frames[-1].append_vertex( x, y, z)
   def append_normal(self, x, y, z):
      if (self.num_frames < 1):
         self.frames.append( joe_frame())
         self.num_frames = 1
      self.frames[-1].append_normal( x, y, z)
   def append_texcoord(self, u, v):
      if (self.num_frames < 1):
         self.frames.append( joe_frame())
         self.num_frames = 1
      self.frames[-1].append_texcoord( u, v)
   def append_face(self, v0, v1, v2, n0, n1, n2, t0, t1, t2):
      if (self.num_frames < 1):
         self.frames.append( joe_frame())
         self.num_frames = 1
      self.frames[-1].append_face(v0, v1, v2, n0, n1, n2, t0, t1, t2)
      self.num_faces = len(self.frames[-1].faces)
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
   def write_obj(self, file):
      # write only the first frame
      self.frames[0].write_obj_frame(file)
      for j in xrange(0, self.num_faces):
         self.frames[0].faces[j].write_obj_face(file)
   def load(self, file):
      data = open(file).read()
      start, stop = 0, struct.calcsize(self.binary_format)
      self.ident, self.version, self.num_faces, self.num_frames = struct.unpack(self.binary_format, data[start:stop])
      data = data[stop:]
      #self.dump()
      #load the frames
      for i in xrange(0, self.num_frames):
         self.frames.append( joe_frame())
         for j in xrange(0, self.num_faces):
            self.frames[i].faces.append( joe_face())
            data = self.frames[i].faces[j].load(data)
         data = self.frames[i].load(data)
      #
   def dump (self):
      print "Header Information"
      print "ident: ", self.ident
      print "version: ", self.version
      print "number of faces: ", self.num_faces
      print "number of frames: ", self.num_frames
      print ""
      
def write_mtl_file(filename):
   mtllibname = string.split(filename, "/")[-1]
   mtlname = mtllibname.replace(".mtl","_auv")
   materialfile = open(filename, "w")
   materialfile.write('# exported using joe2j.py (C) Giles Williams 2008\n')
   materialfile.write('newmtl %s\nNs 100.000\nd 1.00000\nillum 2\n' % mtlname)
   materialfile.write('Kd 1.00000 1.00000 1.00000\nKa 1.00000 1.00000 1.00000\nKs 1.00000 1.00000 1.00000\nKe 0.00000e+0 0.00000e+0 0.00000e+0\n')
   materialfile.write('map_Kd textures/%s\n\n' % mtllibname.replace(".mtl",".png"))
   materialfile.close()

def export_joe_2_obj(filename):
   outputfilename = filename.lower().replace(".joe", ".obj")
   if (outputfilename == filename):
      outputfilename = outputfilename.append(".1")
   materialfilename = outputfilename.lower().replace(".obj",".mtl")
   write_mtl_file(materialfilename)
   mtllibname = string.split(materialfilename, "/")[-1]
   mtlname = mtllibname.replace(".mtl","_auv")
   print inputfilename+"->"+outputfilename+" & "+materialfilename
   joe = joe_obj()
   joe.load(inputfilename)
   joe.dump()   
   outputfile = open( outputfilename, "w")
   outputfile.write('# Converted from JOE file '+inputfilename+' \n');
   outputfile.write('mtllib %s\n' % mtllibname)
   outputfile.write('usemtl %s\n' % mtlname)
   joe.write_obj(outputfile)
   outputfile.close()

def vertex_reference(n, nv):
   if (n < 0):
      return n + nv
   return n - 1

def export_obj_2_joe(filename):
   outputfilename = filename.lower().replace(".obj", ".joe")
   #
   inputfile = open( inputfilename, "r")
   lines = inputfile.read().splitlines(0)
   #
   joe = joe_obj()
   #
   for line in lines:
      tokens = string.split(line.lower())
      if (tokens != []):
         if (tokens[0] == 'v'):
            joe.append_vertex( -float(tokens[1]), float(tokens[3]), float(tokens[2]))
         if (tokens[0] == 'vn'):
            joe.append_normal( -float(tokens[1]), float(tokens[3]), float(tokens[2]))
         if (tokens[0] == 'vt'):
            joe.append_texcoord( float(tokens[1]), 1.0 - float(tokens[2]))
         if (tokens[0] == 'f'):
            vx = [-1] * 3
            vn = [-1] * 3
            vt = [-1] * 3
            for i in [1,2,3]:
               refs = string.split(tokens[i], '/')
               vx[i - 1] = vertex_reference(int(refs[0]), joe.frames[-1].num_vertices)
               if (refs[1] > ''):
                  vt[i - 1] = vertex_reference(int(refs[1]), joe.frames[-1].num_vertices)
               if (refs[2] > ''):
                  vn[i - 1] = vertex_reference(int(refs[2]), joe.frames[-1].num_vertices)
            joe.append_face( vx[0], vx[1], vx[2], vn[0], vn[1], vn[2], vt[0], vt[1], vt[2])
   outputfile = open( outputfilename, "w")
   joe.save(outputfile)      
   outputfile.close()      


#
#   MAIN
#
inputfilenames = sys.argv[1:]
print "examining..."
print inputfilenames
for inputfilename in inputfilenames:
   print inputfilename+" :: "+inputfilename.lower()[-4:]
   if (inputfilename.lower()[-4:] == ".joe"):
      export_joe_2_obj(inputfilename)
   if (inputfilename.lower()[-4:] == ".obj"):
      export_obj_2_joe(inputfilename)
print "done"
print ""
#
#   end
#