# This script was written and developed by XXXX. However, the underlying commands and reports are copyrighted by Cadence. 
# We thank Cadence for granting permission to share our research to help promote and foster the next generation of innovators.

set DESIGN $env(design)
set handoff_dir $env(handoff_dir)

# Effort level during optimization in syn_generic -physical (i.e., generic) stage
# possible values are : high, medium or low
set GEN_EFF medium

# Effort level during optimization in syn_map -physical (i.e., mapping) stage
# possible values are : high, medium or low
set MAP_EFF high
#
set SITE "asap7sc7p5t"
set HALO_WIDTH 1
set TOP_ROUTING_LAYER 7
