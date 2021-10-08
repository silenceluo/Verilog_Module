source -echo -verbose $lib_file
source -echo -verbose ./scripts/dc_setup_filenames.tcl

puts "RM-Info: Running script [info script]\n"

# The following setting removes new variable info messages from the end of the log file
set_app_var sh_new_variable_message false


#################################################################################
# Design Compiler Setup Variables
#################################################################################

# Change alib_library_analysis_path to point to a central cache of analyzed libraries
# to save runtime and disk space.  The following setting only reflects the
# default value and should be changed to a central location for best results.

set_app_var alib_library_analysis_path .

# The following variables are used by scripts in the rm_dc_scripts folder to direct 
# the location of the output files.

file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}

#################################################################################
# Search Path Setup
#
# Set up the search path to find the libraries and design files.
#################################################################################

set_app_var search_path ". ${ADDITIONAL_SEARCH_PATH} $search_path"

#################################################################################
# Library Setup
#
# This section is designed to work with the settings from common_setup.tcl
# without any additional modification.
#################################################################################
 

set ADDITIONAL_LINK_LIB_FILES     "gtech.db"  ;#  Extra link logical libraries not included in TARGET_LIBRARY_FILES

# Enabling the usage of DesignWare minPower Components requires additional DesignWare-LP license
set_app_var synthetic_library "dw_foundation.sldb"

if {$GTECH_ONLY} {
  set TARGET_LIBRARY_FILES "$ADDITIONAL_LINK_LIB_FILES $synthetic_library"
  set_app_var link_library "* $ADDITIONAL_LINK_LIB_FILES $synthetic_library"
} else {
  if {$CORNER=="FAST"} {
      set TARGET_LIBRARY_FILES $FAST_TARGET_LIBRARY_FILES
  } elseif {$CORNER=="TYPICAL"} { 
      set TARGET_LIBRARY_FILES $TYPICAL_TARGET_LIBRARY_FILES
  } else { 
      set TARGET_LIBRARY_FILES $SLOW_TARGET_LIBRARY_FILES
  }

  set_app_var link_library "* $TARGET_LIBRARY_FILES $synthetic_library"
}

set_app_var target_library ${TARGET_LIBRARY_FILES}
#source ../scripts/chip/se28fdsoi_mem.tcl
#source $LIBRARY_DONT_USE_FILE

puts "RM-Info: Completed script [info script]\n"

