#!BPY
"""
Name: 'TRK (.trk)'
Blender: 249
Group: 'Export'
Tip: 'Export VDrift race track. (.trk)'
"""
######################################################
# VDrift Track Editor
# Date: 16 MAY 10
# Ver: 0.1
# Dumb track exporter. Meant to export from trk imported tracks only.
# Don't change anything except vertex positions. Else exported track will be invalid.
######################################################
import Blender
from Blender import *
from Blender.Draw import *
from Blender.Window import *

g_object = None

def save_trk(filename):
	WaitCursor(1)
	file = open(filename, 'w')
	try:
		mesh = Blender.Mesh.Get('~temp')
	except NameError:
		mesh = Blender.Mesh.New('~temp')
	mesh.getFromObject(g_object)
	
	n = len(mesh.verts)/16
	file.write('1\n\n'+str(n)+'\n\n')
	for j in range(n):
		for i in range(16):
			v = mesh.verts[i+j*16].co
			file.write('{0:.3f} {1:.3f} {2:.3f}\n'.format(v[1], v[2], v[0]))
		file.write('\n')
	
	file.close()
	WaitCursor(0)
	
if __name__ == '__main__':
	obs = Blender.Object.GetSelected()
	if len(obs) == 0 or obs[0].getType() != 'Mesh' or len(obs[0].getData().faces) == 0:
		PupMenu('Please select a Mesh')
	else:
		g_object = obs[0]
		FileSelector(save_trk, 'Export TRK')