#!BPY
# -*- coding: iso-8859-1 -*-

"""
Name: 'VDrift Tracks'
Blender: 249b
Group: 'Export'
Tooltip: 'Perform various track-authoring functions for VDrift'
"""
######################################################
# VDrift Tracks
# By:   Chris Guirl
# Date: 2010/08/24
# Ver:  001
######################################################

from Blender import Draw
from Blender import Window
from Blender import Text
from Blender import sys
from Blender import Registry
from Blender import Scene
from vdrift import *
import ConfigParser
import tempfile
import time
import os
import re

VERSION = "001"
metadata_text_id = "VDriftTracks." + VERSION


# script settings

settings = \
{
  "VDrift_data_directory": "",
  "VDrift_Tracks_version": VERSION
}


# track metadata

track_info = \
{
  "name": "Unnamed Track",
  "short_name": "unnamed_track",
  "credits": "",
  "license": "",
  "notes": "",
  "closed_loop": True,
  "road_mesh_name": "",
  "cull_faces": True,
  "num_surfaces": 0,
  "num_road_segments": 0,
  "num_lap_sequences": 0,
  "num_start_points": 0
}

track_lists = \
{
  "surfaces": [],
  "road_segments": [], #[((0.000000,0.000000,0.000000),(1.000000,0.000000,0.000000),(2.000000,0.000000,0.000000))],
  "lap_sequences": [], #[(0.000000,0.000000,0.000000),(0.000000,569.000000,0.000000)],
  "start_points": []
}


# main menu button definitions

menu_items = \
[
  {"name": "-", "tooltip": "VDrift Tracks [version %s]" % (VERSION)},
  {"name": "-", "tooltip": "Track Management"},
  {"name": "Track Info", "tooltip": "Set various information about the track"},
  {"name": "Surface Types", "tooltip": "Manage the types of surfaces in the track"},
  {"name": "Track Objects", "tooltip": "Add VDrift-specific properties to meshes"},
  {"name": "Start Points", "tooltip": "Define the race starting points for the track"},
  {"name": "Road Segments", "tooltip": "Map out the roadway for the track"},
  {"name": "Lap Sequences", "tooltip": "Define the types of surfaces in the track"},
  {"name": "-", "tooltip": "Input/Output"},
  {"name": "Import Track", "tooltip": "Import a track"},
  {"name": "Export Track", "tooltip": "Export the track to the VDrift data directory"},
  {"name": "-", "tooltip": "Script Stuff"},
  {"name": "Settings", "tooltip": "VDrift Tracks settings"},
  {"name": "Help", "tooltip": "Learn more about VDrift track data"},
  {"name": "Exit", "tooltip": "Exit VDrift Tracks"}
]


# create new start point

def new_track_start_point(name, object_id):
  track_start_point = \
  {
    # default track start point attribute values
    "name": name,
    "object_id": object_id
  }
  return track_start_point


# create new surface type

def new_track_surface_type(name):
  track_surface_type = \
  {
    # default surface attribute values
    "name": name,
    "type": "asphalt",
    "bump_wavelength": 1.0,
    "bump_amplitude": 0.0,
    "friction_treaded": 0.9,
    "friction_non_treaded": 1.0,
    "rolling_resistance": 1.0,
    "rolling_drag": 0.0
  }
  return track_surface_type


# create new track object

def new_track_object():
  track_object = \
  {
    # default track object attribute values
    "model_filename": "unnamed_model",
    "texture_filename": "unspecified_texture",
    "mipmap": True,
    "disable_lighting": False,
    "skybox": False,
    "texture_type": 0,
    "collide-able": True,
    "shadow": False,
    "clamp_texture": 0,
    "surface_type": 0
  }
  return track_object

#track_lists["surfaces"].append(new_track_surface_type("test"))
#track_lists["start_points"].append(new_track_start_point())


# get the path to export to - check for directory existence

def track_export_path():
  global settings, track_info
  tracks_dir = "%s/tracks" % (settings["VDrift_data_directory"])
  if not sys.exists(tracks_dir):
    raise Exception("Couldn't find VDrift tracks directory '%s'." % (tracks_dir))
  if not track_info["short_name"]:
    raise Exception("The short name is not set for this track. Set it in Track Info.")
  if re.search("[^a-zA-Z0-9-_\.]", track_info["short_name"]):
    raise Exception("The short name contains characters other than letters, numbers, '-', '_', and '.'.")
  path = "%s/%s" % (tracks_dir, track_info["short_name"])
  objects_path = "%s/objects" % (path)
  if not sys.exists(objects_path):
    os.makedirs(objects_path)
  return path


# export the track

def export_track():
  # check export path
  try:
    track_path = track_export_path()
  except Exception as e:
    print "Track could not be exported: %s" % (e)
    return False
  objects_path = "%s/objects" % (track_path)
  # check start points
  scene = Scene.GetCurrent()
  cameras = [obj for obj in scene.objects if obj.type == "Camera"]
  for start_point in track_lists["start_points"]:
    found_start_point_camera = False
    for camera in cameras:
      if camera.getName() == start_point["object_id"]:
        start_point["Blender_object"] = camera
        found_start_point_camera = True
    if not found_start_point_camera:
      print "Couldn't find camera '%s' with object id '%s'." % (start_point["name"], start_point["object_id"])
      return False
  # surfaces.txt output
  # export objects to jpk + list.txt
  # roads.trk
  # track.txt
  #   track info
  #   start points
  #   lap sequences
  return True


# script settings storage & retrieval

def save_settings():
  global settings
  Registry.SetKey(metadata_text_id, settings, True)

def load_settings():
  global settings
  if metadata_text_id not in Registry.Keys():
    save_settings()
    return
  new_settings = Registry.GetKey(metadata_text_id, True)
  found_all = True
  for key in settings.keys():
    if key not in new_settings:
      found_all = False
  if not found_all:
    raise Exception("couldn't find all my settings...")
  settings = new_settings
  Draw.Redraw(1)


# track metadata storage

def save_track_metadata():
  global track_info, track_lists
  config = ConfigParser.RawConfigParser()
  # load all the data into the ConfigParser object
  config.add_section("trackinfo")
  for key,value in track_info.iteritems():
    config.set("trackinfo", key, value)
  for track_list in track_lists.keys():
    i = 0
    config.set("trackinfo", "num_%s" % (track_list), len(track_lists[track_list]))
    if track_list == "lap_sequences" or track_list == "road_segments":
      section = track_list
      config.add_section(section)
      for track_list_item in track_lists[track_list]:
        key = "%s_%d" % (track_list.rstrip('s'), i)
        config.set(section, key, track_list_item)
        i += 1
    else:
      for track_list_item in track_lists[track_list]:
        section = "%s.%d" % (track_list, i)
        config.add_section(section)
        keys = []
        if track_list == "surfaces":
          keys = new_track_surface_type("").keys()
        elif track_list == "start_points":
          keys = new_track_start_point("", "").keys()
        for key in keys:
          config.set(section, str(key), track_list_item[key])
        i += 1
  temp_filename = "%s/%s.%s.%s.config" % \
    (tempfile.gettempdir(),
    tempfile.gettempprefix(),
    metadata_text_id,
    time.strftime("%Y%m%d-%H%M"))
  with open(temp_filename, 'wb') as temp_file:
    config.write(temp_file)
  track_metadata_text = Text.Load(temp_filename)
  os.unlink(temp_filename)
  track_metadata_text.fakeUser = True
  t = None
  try:
    t = Text.Get(metadata_text_id)
  except NameError as e:
    pass # doesn't exist, don't need to remove it
  else:
    Text.unlink(t)
  track_metadata_text.setName(metadata_text_id)


# track metadata retrieval

def load_track_metadata():
  global track_info, track_lists
  t = None
  try:
    t = Text.Get(metadata_text_id)
  except NameError as e:
    print "Error getting Text object %s: %s\n  Creating new text object..." % (metadata_text_id, e)
    save_track_metadata()
    return
  assert t != None
  config = ConfigParser.RawConfigParser()
  config.readfp(t)
  track_info_keys = track_info.keys()
  for key in track_info_keys:
    if not key.startswith("num_"):
      track_info[key] = config.get("trackinfo", key)
    else:
      track_list = key[4:]
      track_list_length = int(config.get("trackinfo", key))
      #print "section %s track list %s num items %d key %s data %s" % ("trackinfo", track_list, track_list_length, key, track_info[key])
      for i in range(track_list_length):
        if track_list == "lap_sequences":
          key = "%s_%d" % (track_list.rstrip('s'), i)
          track_lists[track_list].append(config.get(track_list, key))
        elif track_list == "road_segments":
          key = "%s_%d" % (track_list.rstrip('s'), i)
          track_lists[track_list].append(config.get(track_list, key))
        elif track_list == "surfaces":
          section = "%s.%d" % (track_list, i)
          keys = new_track_surface_type("").keys()
          track_list_data = {}
          for key in keys:
            value = config.get(section, key)
            if key != "name" and key != "type":
              value = float(value)
            track_list_data[key] = value
          track_lists[track_list].append(track_list_data)
        elif track_list == "start_points":
          section = "%s.%d" % (track_list, i)
          keys = new_track_start_point("", "").keys()
          track_list_data = {}
          for key in keys:
            track_list_data[key] = config.get(section, key)
          track_lists[track_list].append(track_list_data)
  track_info["closed_loop"] = track_info["closed_loop"] == "True"
  track_info["cull_faces"] = track_info["cull_faces"] == "True"
  Draw.Redraw(1)


# callbacks

def set_data_dir(path):
  global settings
  settings["VDrift_data_directory"] = path
  save_settings()

def event(evt, val):
  Draw.Redraw(1)

def menu_buttons(button_name):
  global settings, track_info
  popup = lambda msg: Draw.PupMenu(msg)
  if button_name == 'Exit':
    exit = popup("Exit VDrift Tracks?%t|Exit|Cancel")
    if exit == 1:
      #print settings
      Draw.Exit()
  elif button_name == "Help":
    popup("Not yet implemented")
  elif button_name == "Settings":
    # TODO: replace this with a UIBlock with some buttons, and room for other settings
    Window.FileSelector(set_data_dir, "Select VDrift Data Path", settings["VDrift_data_directory"])
  elif button_name == "Track Info":
    track_name_text = Draw.Create(track_info["name"])
    short_name_text = Draw.Create(track_info["short_name"])
    author_text = Draw.Create(track_info["credits"])
    license_text = Draw.Create(track_info["license"])
    notes_text = Draw.Create(track_info["notes"])
    closed_loop_tog = Draw.Create(track_info["closed_loop"])
    cull_faces_tog = Draw.Create(track_info["cull_faces"])
    track_info_block = []
    track_info_block.append(("Track Name: ", track_name_text, 0, 40, "Set the name of the track to be displayed in-game"))
    track_info_block.append(("Short Name: ", short_name_text, 0, 40, "Set the subdirectory name for the track in VDrift/data/tracks/"))
    track_info_block.append(("Author(s): ", author_text, 0, 80, "Who made this track?"))
    track_info_block.append(("License: ", license_text, 0, 40, "Name of the license for this track"))
    track_info_block.append(("Notes: ", notes_text, 0, 160, "Notes about this track"))
    track_info_block.append(("Closed Loop?", closed_loop_tog, "Is this track a closed loop?"))
    track_info_block.append(("Cull Faces?", cull_faces_tog, "Should faces be culled in this track?"))
    track_info_block_ok = Draw.PupBlock("Track Info", track_info_block)
    if track_info_block_ok:
      track_info["name"] = str(track_name_text).strip("'")
      track_info["short_name"] = str(short_name_text).strip("'")
      track_info["credits"] = str(author_text).strip("'")
      track_info["license"] = str(license_text).strip("'")
      track_info["notes"] = str(notes_text).strip("'")
      track_info["closed_loop"] = bool(int(str(closed_loop_tog)))
      track_info["cull_faces"] = bool(int(str(cull_faces_tog)))
      save_track_metadata()
  elif button_name == "Surface Types":
    surface_types_list_block = Draw.UIBlock(surface_types_list, 0)
  elif button_name == "Track Objects":
    track_objects_menu_block = Draw.UIBlock(track_objects_menu, 0)
  elif button_name == "Start Points":
    start_points_list_block = Draw.UIBlock(start_points_list, 0)
  elif button_name == "Road Segments":
    popup("Not yet implemented")
  elif button_name == "Lap Sequences":
    popup("Not yet implemented")
  elif button_name == "Import Track":
    popup("Not yet implemented")
  elif button_name == "Export Track":
    export_successful = export_track()
    if not export_successful:
      popup("Track was not exported. Check the console output for details.")

def button_pressed(val):
  global menu_items
  if val < len(menu_items):
    button_name = menu_items[val]["name"]
    menu_buttons(button_name)
  else:
    raise Exception("I don't have a way to handle button event value %d" % (val))

#add_new_start_point

def add_new_start_point(event, val):
  global track_lists
  num_start_points = str(len(track_lists["start_points"]))
  new_object_id = "start-" + num_start_points
  new_start_point = new_track_start_point(name=num_start_points, object_id=new_object_id)
  name_text = Draw.Create(new_start_point["name"])
  object_id_text = Draw.Create(new_start_point["object_id"])
  new_start_point_block = []
  new_start_point_block.append(("Name: ", name_text, 0, 40, "Set the name of the start point"))
  new_start_point_block.append(("Object: ", object_id_text, 0, 40, "Set the object id of the start point"))
  new_start_point_block_ok = Draw.PupBlock("Add New Start Point", new_start_point_block)
  if new_start_point_block_ok:
    new_start_point["name"] = str(name_text).strip("'")
    new_start_point["object_id"] = str(object_id_text).strip("'")
    track_lists["start_points"].append(new_start_point)
    save_track_metadata()

def edit_start_point(event, val):
  global track_lists
  index = (event - 200)
  if index >= 0 and index < 49:
    start_point = track_lists["start_points"][index]
    name_text = Draw.Create(start_point["name"])
    object_id_text = Draw.Create(start_point["object_id"])
    edit_start_point_block = []
    edit_start_point_block.append(("Name: ", name_text, 0, 40, "Set the name of the start point"))
    edit_start_point_block.append(("Object: ", object_id_text, 0, 40, "Set the object id of the start point"))
    edit_start_point_block_ok = Draw.PupBlock("Edit Start Point", edit_start_point_block)
    if edit_start_point_block_ok:
      start_point["name"] = str(name_text).strip("'")
      start_point["object_id"] = str(object_id_text).strip("'")
      save_track_metadata()
  else:
    raise Exception("Tried to edit start point that doesn't exist (#%d)" % (index))

def del_start_point(event, val):
  global track_lists
  index = (event - 250)
  if index >= 0 and index < 49:
    del_start = Draw.PupMenu("Delete start point '%s'?%s|Delete|Cancel" % (track_lists["start_points"][index]["name"], '%t'))
    if del_start == 1:
      del(track_lists["start_points"][index])
    #surface_types_list_block = Draw.UIBlock(surface_types_list, 0)
  else:
    raise Exception("Tried to delete start point that doesn't exist (#%d)" % (index))

def start_points_list_ok(event, val):
  # TODO: also provide a way to undo changes
  save_track_metadata()


def add_new_surface_type(event, val):
  global track_lists
  new_surface = new_track_surface_type("")
  name_text = Draw.Create(new_surface["name"])
  type_text = Draw.Create(new_surface["type"])
  bump_wavelength_float = Draw.Create(new_surface["bump_wavelength"])
  bump_amplitude_float = Draw.Create(new_surface["bump_amplitude"])
  friction_treaded_float = Draw.Create(new_surface["friction_treaded"])
  friction_non_treaded_float = Draw.Create(new_surface["friction_non_treaded"])
  rolling_resistance_float = Draw.Create(new_surface["rolling_resistance"])
  rolling_drag_float = Draw.Create(new_surface["rolling_drag"])
  new_surface_block = []
  new_surface_block.append(("Name: ", name_text, 0, 40, "Set the name of the surface type"))
  new_surface_block.append(("Sound: ", type_text, 0, 40, "Set the sound name of the surface (asphalt,grass)"))
  new_surface_block.append(("BumpWavelength: ", bump_wavelength_float, 0.0, 1.0, "Set the bumpiness wavelength"))
  new_surface_block.append(("BumpAmplitude: ", bump_amplitude_float, 0.0, 1.0, "Set the bumpiness amplitude"))
  new_surface_block.append(("FrictionTread: ", friction_treaded_float, 0.0, 1.0, "Set the friction coefficient for treaded tires"))
  new_surface_block.append(("FrictionNoTread: ", friction_non_treaded_float, 0.0, 1.0, "Set the friction coefficient for non-treaded tires"))
  new_surface_block.append(("RollingResistance: ", rolling_resistance_float, 0.0, 1.0, "Set the rolling resistance"))
  new_surface_block.append(("RollingDrag: ", rolling_drag_float, 0.0, 1.0, "Set the rolling drag"))
  new_surface_block_ok = Draw.PupBlock("Add New Surface Type", new_surface_block)
  if new_surface_block_ok:
    new_surface["name"] = str(name_text).strip("'")
    new_surface["type"] = str(type_text).strip("'")
    new_surface["bump_wavelength"] = float(str(bump_wavelength_float))
    new_surface["bump_amplitude"] = float(str(bump_amplitude_float))
    new_surface["friction_treaded"] = float(str(friction_treaded_float))
    new_surface["friction_non_treaded"] = float(str(friction_non_treaded_float))
    new_surface["rolling_resistance"] = float(str(rolling_resistance_float))
    new_surface["rolling_drag"] = float(str(rolling_drag_float))
    track_lists["surfaces"].append(new_surface)
    save_track_metadata()

def del_surface_type(event, val):
  global track_lists
  index = (event - 150)
  if index >= 0 and index < 49:
    del_surface = Draw.PupMenu("Delete surface '%s'?%s|Delete|Cancel" % (track_lists["surfaces"][index]["name"], '%t'))
    if del_surface == 1:
      del(track_lists["surfaces"][index])
    #surface_types_list_block = Draw.UIBlock(surface_types_list, 0)
  else:
    raise Exception("Tried to delete surface that doesn't exist (#%d)" % (index))

def edit_surface_type(event, val):
  global track_lists
  index = (event - 100)
  if index >= 0 and index < 49:
    surface = track_lists["surfaces"][index]
    name_text = Draw.Create(surface["name"])
    type_text = Draw.Create(surface["type"])
    bump_wavelength_float = Draw.Create(surface["bump_wavelength"])
    bump_amplitude_float = Draw.Create(surface["bump_amplitude"])
    friction_treaded_float = Draw.Create(surface["friction_treaded"])
    friction_non_treaded_float = Draw.Create(surface["friction_non_treaded"])
    rolling_resistance_float = Draw.Create(surface["rolling_resistance"])
    rolling_drag_float = Draw.Create(surface["rolling_drag"])
    edit_surface_block = []
    edit_surface_block.append(("Name: ", name_text, 0, 40, "Set the name of the surface type"))
    edit_surface_block.append(("Sound: ", type_text, 0, 40, "Set the sound name of the surface (asphalt,grass)"))
    edit_surface_block.append(("BumpWavelength: ", bump_wavelength_float, 0.0, 1.0, "Set the bumpiness wavelength"))
    edit_surface_block.append(("BumpAmplitude: ", bump_amplitude_float, 0.0, 1.0, "Set the bumpiness amplitude"))
    edit_surface_block.append(("FrictionTread: ", friction_treaded_float, 0.0, 1.0, "Set the friction coefficient for treaded tires"))
    edit_surface_block.append(("FrictionNoTread: ", friction_non_treaded_float, 0.0, 1.0, "Set the friction coefficient for non-treaded tires"))
    edit_surface_block.append(("RollingResistance: ", rolling_resistance_float, 0.0, 1.0, "Set the rolling resistance"))
    edit_surface_block.append(("RollingDrag: ", rolling_drag_float, 0.0, 1.0, "Set the rolling drag"))
    edit_surface_block_ok = Draw.PupBlock("Edit Surface Type", edit_surface_block)
    if edit_surface_block_ok:
      surface["name"] = str(name_text).strip("'")
      surface["type"] = str(type_text).strip("'")
      surface["bump_wavelength"] = float(str(bump_wavelength_float))
      surface["bump_amplitude"] = float(str(bump_amplitude_float))
      surface["friction_treaded"] = float(str(friction_treaded_float))
      surface["friction_non_treaded"] = float(str(friction_non_treaded_float))
      surface["rolling_resistance"] = float(str(rolling_resistance_float))
      surface["rolling_drag"] = float(str(rolling_drag_float))
      save_track_metadata()
  else:
    raise Exception("Tried to edit surface that doesn't exist (#%d)" % (index))

def surface_list_ok(event, val):
  # TODO: also provide a way to undo changes
  save_track_metadata()


# rendering

def start_points_list():
  global track_lists
  screen_w, screen_h = Window.GetScreenSize()
  mouse_x, mouse_y = Window.GetMouseCoords()
  block_width = 300
  item_height = 25
  item_spacing = 30
  block_height = item_spacing * (2 + len(track_lists["start_points"]))
  half_block_width = block_width / 2
  half_block_height = block_height / 2
  screen_width_edge_buffer = half_block_width + 15
  screen_height_edge_buffer = half_block_height + 15
  if mouse_x < screen_width_edge_buffer: mouse_x = screen_width_edge_buffer
  if mouse_x > (screen_w - screen_width_edge_buffer): mouse_x = screen_w - screen_width_edge_buffer
  if mouse_y < screen_height_edge_buffer: mouse_y = screen_height_edge_buffer
  if mouse_y > (screen_h - screen_height_edge_buffer): mouse_y = screen_h - screen_height_edge_buffer
  list_width = block_width - 30
  item_x = mouse_x - half_block_width
  item_y = mouse_y + half_block_height
  title_label = Draw.Label("Start Points", item_x, item_y, block_width, item_height)
  event_num = 199
  item_y -= item_spacing
  add_button = Draw.PushButton("Add New Start Point", event_num, item_x, item_y, list_width, item_height, "Add a new start point definition", add_new_start_point)
  start_point_edit_buttons = []
  del_button_width = item_height
  for start_point in track_lists["start_points"]:
    event_num += 1
    item_y -= item_spacing
    edit_button_width = list_width - del_button_width
    edit_button = Draw.PushButton(start_point["name"], event_num, item_x, item_y, edit_button_width, item_height, "Edit start point '%s'" % (start_point["name"]), edit_start_point)
    del_button_x = item_x + edit_button_width
    del_button = Draw.PushButton("X", event_num+50, del_button_x, item_y, del_button_width, item_height, "Delete start point '%s'" % (start_point["name"]), del_start_point)
    start_point_edit_buttons.append(edit_button)
  ok_button = Draw.PushButton("OK", 198, item_x + list_width + 5, item_y, item_height, item_spacing * (1 + len(track_lists["start_points"])), "Close this dialog and store changes", start_points_list_ok)

def surface_types_list():
  global track_lists
  screen_w, screen_h = Window.GetScreenSize()
  mouse_x, mouse_y = Window.GetMouseCoords()
  block_width = 200
  item_height = 25
  item_spacing = 30
  block_height = item_spacing * (2 + len(track_lists["surfaces"]))
  half_block_width = block_width / 2
  half_block_height = block_height / 2
  screen_width_edge_buffer = half_block_width + 15
  screen_height_edge_buffer = half_block_height + 15
  if mouse_x < screen_width_edge_buffer: mouse_x = screen_width_edge_buffer
  if mouse_x > (screen_w - screen_width_edge_buffer): mouse_x = screen_w - screen_width_edge_buffer
  if mouse_y < screen_height_edge_buffer: mouse_y = screen_height_edge_buffer
  if mouse_y > (screen_h - screen_height_edge_buffer): mouse_y = screen_h - screen_height_edge_buffer
  list_width = block_width - 30
  item_x = mouse_x - half_block_width
  item_y = mouse_y + half_block_height
  title_label = Draw.Label("Surface Types", item_x, item_y, block_width, item_height)
  event_num = 99
  item_y -= item_spacing
  add_button = Draw.PushButton("Add New Surface Type", event_num, item_x, item_y, list_width, item_height, "Add a new surface type definition", add_new_surface_type)
  surface_type_edit_buttons = []
  del_button_width = item_height
  for surface in track_lists["surfaces"]:
    event_num += 1
    item_y -= item_spacing
    edit_button_width = list_width - del_button_width
    edit_button = Draw.PushButton(surface["name"], event_num, item_x, item_y, edit_button_width, item_height, "Edit surface type '%s'" % (surface["name"]), edit_surface_type)
    del_button_x = item_x + edit_button_width
    del_button = Draw.PushButton("X", event_num+50, del_button_x, item_y, del_button_width, item_height, "Delete surface type '%s'" % (surface["name"]), del_surface_type)
    surface_type_edit_buttons.append(edit_button)
  ok_button = Draw.PushButton("OK", 98, item_x + list_width + 5, item_y, item_height, item_spacing * (1 + len(track_lists["surfaces"])), "Close this dialog and store changes", surface_list_ok)

def main_menu():
  global menu_items
  button_distance = 25
  min_width = 200
  min_height = button_distance * len(menu_items)
  width,height = Window.GetAreaSize()
  if width < min_width: width = min_width
  if height < min_height: height = min_height
  half_width = float(width) / 2.0
  half_height = float(height) / 2.0
  button_width = int(2.0 * float(width) / 3.0)
  button_height = 25
  button_x = int(half_width - button_width / 2.0)
  button_y = int(half_height + float(min_height) / 2.0) - button_height
  buttons = {}
  for i in range(len(menu_items)):
    name = menu_items[i]["name"]
    tooltip = menu_items[i]["tooltip"]
    if name == "-":
      Draw.Label(tooltip, button_x, button_y, button_width, button_height)
    else:
      buttons[name] = Draw.PushButton(name, i, button_x, button_y, button_width, button_height, tooltip)
    button_y -= button_distance



if __name__ == '__main__':
  load_settings()
  #print settings
  load_track_metadata()
  #settings["VDrift_data_directory"] = "/home/thelusiv/code/vdrift-sf.net/vdrift-data"
  Draw.Register(main_menu, event, button_pressed)

