#################################################################################
# Load dc_config.tcl for variable settings
#################################################################################
source -echo -verbose ./scripts/dc_config.tcl

#################################################################################
# Load dc_setup.tcl for setup settings
#################################################################################
source -echo -verbose ./scripts/dc_setup.tcl

#################################################################################
# Read in the RTL Design
#################################################################################
define_design_lib WORK -path ./WORK

###Helps verification with DC and FM while inferring logical hierarchies 
set hdlin_enable_hier_map true

lappend hdlin_autoread_sverilog_extensions .e 
#read_file ../../rtl -autoread -top $DESIGN_NAME > ${DESIGN_NAME}.read_log

#################################################################################
# Load dc_analyze.tcl for all files in flist
#################################################################################
source -echo -verbose ./scripts/dc_analyze.tcl

elaborate ${DESIGN_NAME} -parameters ${PARAMS}

write -hierarchy -format ddc -output ${REPORTS_DIR}/${DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE}
link > ${REPORTS_DIR}/${DESIGN_NAME}.link.rpt

##Extract RAMs from the design and place into a list
#set design_ram_list  [amzn_get_ram_list]

#################################################################################
# Apply Logical Design Constraints
#################################################################################
source -echo -verbose ./scripts/${DESIGN_NAME}_constraints.tcl

#################################################################################
# Set operating_conditions
#################################################################################
if {$GTECH_ONLY == 0} {
  if {$CORNER == "FAST"} {
      set_operating_conditions -max $FAST_OPERATING_CONDITIONS
  } elseif {$CORNER=="TYPICAL"} { 
      set_operating_conditions -max $TYPICAL_OPERATING_CONDITIONS
  } else { 
      set_operating_conditions -max $SLOW_OPERATING_CONDITIONS
  }
}

##################################################################################
## Create Default Path Groups
##################################################################################
#set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
#
#group_path -name REGIN       -from [remove_from_collection [all_inputs] ${ports_clock_root}] 
#group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] ${ports_clock_root}] -to [all_outputs]
#group_path -name REGOUT                                                                      -to [all_outputs] 
#
#
##############################################################################
## Clock Gating Setup
##############################################################################
#set_clock_gating_style    \
#    -max_fanout 32        \
#    -pos integrated       \
#    -control_point before \
#    -control_signal scan_enable

#set compile_clock_gating_through_hierarchy true 


#################################################################################
## Make Sure any User Instantiated Gates aren't touched
#################################################################################
#amzn_dont_touch_pic
#
#################################################################################
## Apply Synthesis Derates
#################################################################################
##Cell Derate
#set_timing_derate -data -early -cell_delay ${DERATE_CELLS_EARLY}
#set_timing_derate -data -late  -cell_delay ${DERATE_CELLS_LATE}
##Memory Derate
#set_timing_derate -data -early -cell_delay ${DERATE_MEMS_EARLY} $design_ram_list
#set_timing_derate -data -late  -cell_delay ${DERATE_MEMS_LATE} 	$design_ram_list
#
##################################################################################
## Apply Additional Optimization Constraints
##################################################################################
## Prevent assignment statements in the Verilog netlist.
#set_fix_multiple_port_nets -all -buffer_constants

#################################################################################
# Check for Design Problems 
#################################################################################
# Check the current design for consistency
check_design -summary
check_design > ${REPORTS_DIR}/${DCRM_CHECK_DESIGN_REPORT}

set_verification_top


################################################################################
# Synthesize the Design!
################################################################################
#compile_ultra -gate_clock -no_seq_output_inversion -no_boundary_optimization
#compile
#compile -map_effort medium
compile -map_effort low
################################################################################
# Remove the path groups generated by create_path_groups command. 
# This does not remove user created path groups
################################################################################
#remove_auto_path_groups
#
##################################################################################
## High-effort area optimization
##
## The command performs monotonic gate-to-gate optimization on mapped designs to 
## improve area without impacting timing or leakage. 
##################################################################################
#optimize_netlist -area
#
#m
##################################################################################
## Write Out Final Design and Reports
##################################################################################
change_names -rules verilog -hierarchy

#################################################################################
# Write out Design and SDC
#################################################################################
write -format verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}
write -format ddc     -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}
#write_sdc -nosplit                       ${REPORTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}

#################################################################################
# Generate Final Reports
#################################################################################
report_timing -max 200 -transition_time -nets -attributes -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_TIMING_REPORT}
report_area         -nosplit            > ${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT}
report_area         -designware         > ${REPORTS_DIR}/${DCRM_FINAL_DESIGNWARE_AREA_REPORT}
report_area         -hierarchy          > ${REPORTS_DIR}/${DCRM_FINAL_HIER_AREA_REPORT}
report_resources    -hierarchy          > ${REPORTS_DIR}/${DCRM_FINAL_RESOURCES_REPORT}
report_clock_gating -nosplit            > ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_GATING_REPORT}
report_clock                            > ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_REPORT}
#report_power        -nosplit            > ${REPORTS_DIR}/${DCRM_FINAL_POWER_REPORT}
#report_clock_gating -nosplit            > ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_GATING_REPORT}
report_qor                              > ${REPORTS_DIR}/${DCRM_FINAL_QOR_REPORT}
report_reference    -nosplit -hierarchy > ${REPORTS_DIR}/${DCRM_FINAL_REFERENCE_REPORT}


exit
