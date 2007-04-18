#-------------#
# Import Vars #
#-------------#
Import('*')

#-----------------------#
# Distribute to src_dir #
#-----------------------#
env.Distribute (src_dir, 'SConscript.no_data')

#----------------#
# Subdirectories #
#----------------#
Export(['env', 'src_dir', 'bin_dir'])

env.Alias('install', Dir('$data_directory'))

#SConscript('carparts/SConscript')
SConscript('cars/SConscript')
SConscript('lists/SConscript')
SConscript('settings/SConscript')
SConscript('skins/SConscript')
SConscript('sounds/SConscript')
SConscript('textures/SConscript')
SConscript('tracks/SConscript')
