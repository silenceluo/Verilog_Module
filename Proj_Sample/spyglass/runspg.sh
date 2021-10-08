#!/bin/sh

export PROJ_ROOT=`readlink -f ../../`

export AMZN_SPG_FILELIST=$PROJ_ROOT/hw/rtl/design_nosrams.f
export AMZN_SPG_WAIVER=$PROJ_ROOT/hw/spg/eac_aml_waiver_file.awl
export AMZN_SPG_TOP=eac_wrapper
export AMZN_SPG_LIBLIST="
  ${SRAM_DIR}/saculs0c4s2p320x128m2b1w1c0p1d0t0s2z1rw00/ssgnp_ccwt0p72vn40c/saculs0c4s2p320x128m2b1w1c0p1d0t0s2z1rw00.lib
  ${SRAM_DIR}/saculs0c4s2p1376x128m4b2w1c1p1d0t0s2z1rw00/ssgnp_ccwt0p72vn40c/saculs0c4s2p1376x128m4b2w1c1p1d0t0s2z1rw00.lib"

export EAC_AML_DIR=eac_aml
export EAC_FM_AML_DIR=eac_fm_aml

spyglass -project cmap_decoder.prj -batch -goal lint/lint_rtl -licqueue

#export AMZN_SPG_TOP=eac_fm_wrapper
#spyglass -project $PROJ_ROOT/hw/spg/eac_fm_aml.prj -batch -goal lint/lint_rtl -licqueue

