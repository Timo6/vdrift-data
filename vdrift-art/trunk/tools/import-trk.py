#!BPY
"""
Name: 'TRK (.trk)'
Blender: 249
Group: 'Import'
Tip: 'Import VDrift race track. (.trk)'
"""
######################################################
# VDrift Track Editor
# Date: 16 MAY 10
# Ver: 0.1
# Dumb track importer. Assumes a valid file. No error checking
######################################################
import Blender
from Blender import *
from Blender.Draw import *
from Blender.Window import *
from Blender.Mathutils import *

def load_trk(filename):
	WaitCursor(1)
	file = open(filename)
	lines = file.readlines()
	mesh = Blender.Mesh.New()
	
	n = 0
	verts = []
	faces = []
	for k in range(4,len(lines),17):
		for j in range(16):
			point = [float(i) for i in lines[k+j].split(' ')]
			verts.append(Vector(point[2], point[0], point[1]))
		for j in [0,1,2,4,5,6,8,9,10]:
			face = [n+j+0,n+j+1,n+j+5,n+j+4]
			faces.append(face)
		n = n + 16
	
	mesh.verts.extend(verts)
	mesh.faces.extend(faces)
	Blender.Scene.GetCurrent().objects.new(mesh, 'road')
	file.close()
	WaitCursor(0)
	
if __name__ == '__main__':
	FileSelector(load_trk, 'Import TRK')