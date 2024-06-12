#!/bin/bash
# This script was written and developed by XXXX. However, the underlying commands and reports are copyrighted by Cadence.
# We thank Cadence for granting permission to share our research to help promote and foster the next generation of innovators.
module unload genus
module load genus/21.1
module unload innovus
module load innovus/21.1

#
# To run the Physical Synthesis (iSpatial) flow - flow2
export PHY_SYNTH=0
export design=$1
export handoff_dir=$2

mkdir log -p
innovus -64 -overwrite -log log/innovus.log -files run_invs.tcl
