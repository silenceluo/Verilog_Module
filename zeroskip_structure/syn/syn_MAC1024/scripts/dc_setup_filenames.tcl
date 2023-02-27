puts "RM-Info: Running script [info script]\n"

#################################################################################
# Design Compiler Reference Methodology Filenames Setup
# Script: dc_setup_filenames.tcl
# Version: N-2017.09-SP4 (April 23, 2018)
# Copyright (C) 2010-2017 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
# General Flow Files
#################################################################################

###############
# Input Files #
###############
set DCRM_CONSTRAINTS_INPUT_FILE                         ${DESIGN_NAME}_constraints.tcl

###########
# Reports #
###########

set DCRM_CHECK_LIBRARY_REPORT                           ${DESIGN_NAME}.check_library.rpt

set DCRM_CONSISTENCY_CHECK_ENV_FILE                     ${DESIGN_NAME}.compile_ultra.env
set DCRM_CHECK_DESIGN_REPORT                            ${DESIGN_NAME}.check_design.rpt
set DCRM_ANALYZE_DATAPATH_EXTRACTION_REPORT             ${DESIGN_NAME}.analyze_datapath_extraction.rpt

set DCRM_FINAL_QOR_REPORT                               ${DESIGN_NAME}.qor.rpt
set DCRM_FINAL_TIMING_REPORT                            ${DESIGN_NAME}.timing.rpt
set DCRM_FINAL_CLOCK_REPORT                             ${DESIGN_NAME}.clock.rpt
set DCRM_FINAL_AREA_REPORT                              ${DESIGN_NAME}.area.rpt
set DCRM_FINAL_HIER_AREA_REPORT                         ${DESIGN_NAME}.hier.area.rpt
set DCRM_FINAL_POWER_REPORT                             ${DESIGN_NAME}.power.rpt
set DCRM_FINAL_CLOCK_GATING_REPORT                      ${DESIGN_NAME}.clock_gating.rpt
set DCRM_FINAL_SELF_GATING_REPORT                       ${DESIGN_NAME}.self_gating.rpt
set DCRM_THRESHOLD_VOLTAGE_GROUP_REPORT                 ${DESIGN_NAME}.threshold.voltage.group.rpt
set DCRM_INSTANTIATE_CLOCK_GATES_REPORT                 ${DESIGN_NAME}.instatiate_clock_gates.rpt
set DCRM_FINAL_DESIGNWARE_AREA_REPORT                   ${DESIGN_NAME}.mapped.designware_area.rpt
set DCRM_FINAL_RESOURCES_REPORT                         ${DESIGN_NAME}.final_resources.rpt
set DCRM_FINAL_REFERENCE_REPORT                         ${DESIGN_NAME}.reference.rpt
################
# Output Files #
################

set DCRM_AUTOREAD_RTL_SCRIPT                            ${DESIGN_NAME}.autoread_rtl.tcl
set DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE              ${DESIGN_NAME}.elab.ddc
set DCRM_COMPILE_ULTRA_DDC_OUTPUT_FILE                  ${DESIGN_NAME}.compile_ultra.ddc
set DCRM_FINAL_DDC_OUTPUT_FILE                          ${DESIGN_NAME}.ddc
set DCRM_FINAL_PG_VERILOG_OUTPUT_FILE                   ${DESIGN_NAME}.pg.v
set DCRM_FINAL_VERILOG_OUTPUT_FILE                      ${DESIGN_NAME}.v
set DCRM_FINAL_SDC_OUTPUT_FILE                          ${DESIGN_NAME}.sdc


puts "RM-Info: Completed script [info script]\n"
