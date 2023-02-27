#!/usr/bin/python3
#
########################################################################
#Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
########################################################################

import sys, getopt
import sys
import re
import os
import copy
import subprocess


class run_syn():

    def __init__(self):
        self.a = 1

    def dc_config(self, design, lib, corner, parameters, reports, results):
        f_config = open("scripts/dc_config.tcl", "w+")
        f_config.write("set DESIGN_NAME \"" + design + "\"\n")
        f_config.write("set lib_file /data/shared/dss_common/synth/lib_scr/" + lib + ".tcl\n")
        if corner == "GTECH_ONLY":
            f_config.write("set GTECH_ONLY 1\n") 
        else:
            f_config.write("set GTECH_ONLY 0\n") 
            f_config.write("set CORNER " + corner + "\n")
        f_config.write("set PARAMS \"" + parameters + "\"\n")
        f_config.write("set REPORTS_DIR \"./" + reports + "\"\n")
        f_config.write("set RESULTS_DIR \"./" + results + "\"\n")
        f_config.close()
        print("generate ./scripts/dc_config.tcl")

    def dc_shell(self, curdir):
        f_que = open("dc_shell.que", "w+")
        f_que.write("")

        f_que.write("#!/bin/bash\n\n")
        f_que.write("#PBS -N dc_shell\n")
        f_que.write("#PBS -V -j oe -o dc_shell.qlog\n")
        f_que.write("#PBS -q synopsys_now\n")
        f_que.write("#PBS -l nodes=1,instance_type=c5.12xlarge\n")
        f_que.write("#PBS -P ACE_synthesis\n\n")
        f_que.write("cd " + curdir + "\n")
        f_que.write("dc_shell -f scripts/dc.tcl")
        subprocess.call("chmod +x dc_shell.que", shell=True)
        print("generate ./dc_shell.que")


# START HERE
runSyn = run_syn()
curdir = os.getcwd()

design = "ebpc_encoder"
flist = "rtl.f"
lib = "tsmc_12nm"	#gf_14nm.tcl, tsmc_07nm.tcl, tsmc_12nm.tcl
corner = "FAST"		#SLOW, TYPICAL, FAST, GTECH_ONLY
reports = "reports"
results = "results"
parameters = ""
defines = ""
flist = 0
path = "../../rtl"

if len(sys.argv) < 2 :
    print ("\nUsage:\t ./scripts/run_syn.py /data/shared/dss_common/synth/scripts/syn_config\n")
    print ("\t 1. you can update default syn_config file or create you own config file follow syn_config")
    print ("\t 2. in the config file, design and flist are required, all others are optional")
    print ("\t 3. designer also need to provide ./scripts/${DESIGN_NAME}_constraints.tcl")
    print ("\t 4. lib can choose from: gf_14nm, tsmc_07nm, tsmc_12nm. The default is set to tsmc_07nm")
    print ("\t 5. corner can choose from: SLOW, TYPICAL, FAST, GTECH_ONLY. The default is set to SLOW")
    print ("\t 6. you can specify reports output directory name otherwise it will take \"reports\" as default")
    print ("\t 7. you can specify results output directory name otherwise it will take \"results\" as default")
    print ("\t 8. you can specify parameters(use \",\" for multipule parameters) which will be after \"elaborate ${DESIGN_NAME} -parameters\" ")
    print ("\t 9. you can specify defines(use \",\" for multipule defines) which will be used when loading the flist")
    print ("\t 10. you need to provide search_path for flist, all files from flist are in the search_path")
    print ("\t 11. flist should be at the bottom of the config file with each file in a new line")
    exit()

for arg in sys.argv:
    syn_config = sys.argv[1]
    try:
        fin = open(syn_config, "r")
    except IOError:
        print ("Could not open config file " + syn_config)
        exit()

f_analyze = open("scripts/dc_analyze.tcl", "w+")
f_analyze.write("set search_path \"../../rtl $search_path\"\n\n")
f_analyze.write("analyze -format sverilog {\n")

for line in fin:
    if re.match("design", line):
        design_line = re.split('= |\t|\n| ', line)
        design = design_line[2]
    if re.match("lib", line):
        lib_line = re.split('= |\t|\n| ', line)
        lib = lib_line[2]
    if re.match("corner", line):
        corner_line = re.split('= |\t|\n| ', line)
        corner = corner_line[2] 
    if re.match("parameters", line):
        parameters_line = re.split('= |\t|\n| ', line)
        parameters = parameters_line[2] 
    if re.match("defines", line):
        defines_line = re.split('= |\t|\n| ', line)
        defines = defines_line[2] 
    if re.match("reports", line):
        reports_line = re.split('= |\t|\n| ', line)
        reports = reports_line[2] 
    if re.match("results", line):
        results_line = re.split('= |\t|\n| ', line)
        results = results_line[2] 
    if re.match("search_path", line):
        path_line = re.split('= |\t|\n| ', line)
        path = path_line[2] 
        f_analyze = open("scripts/dc_analyze.tcl", "w+")
        f_analyze.write("set search_path \"" + path + " $search_path\"\n\n")
        if defines == "":
            f_analyze.write("analyze -format sverilog {\n")
        else:
            f_analyze.write("analyze -format sverilog -define " + defines + " {\n")
    if flist == 1:
        f_analyze.write(" " + line)
    if re.match("flist", line):
        flist = 1

f_analyze.write("}")
f_analyze.close() 
print("generate ./scripts/dc_analyze.tcl")

runSyn.dc_config(design, lib, corner, parameters, reports, results)
runSyn.dc_shell(curdir)
print("To run synthesis, please use: ./dc_shell.que")
