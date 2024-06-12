# This script was written and developed by XXXX. However, the underlying commands and reports are copyrighted by Cadence. 
# We thank Cadence for granting permission to share our research to help promote and foster the next generation of innovators.
source lib_setup.tcl
source design_setup.tcl

setMultiCpuUsage -localCpu 16

set netlist ${handoff_dir}/${DESIGN}.v
set sdc ${handoff_dir}/${DESIGN}.sdc 
source mmmc_setup.tcl

set rptDir summaryReport/ 
set encDir enc/

if {![file exists $rptDir/]} {
    exec mkdir $rptDir/
}

if {![file exists $encDir/]} {
    exec mkdir $encDir/
}

# default settings
set init_pwr_net VDD
set init_gnd_net VSS

# default settings
set init_verilog "$netlist"
set init_design_netlisttype "Verilog"
set init_design_settop 1
set init_top_cell "$DESIGN"
set init_lef_file "$lefs"

# MCMM setup
init_design -setup {WC_VIEW} -hold {BC_VIEW}
set_power_analysis_mode -leakage_power_view WC_VIEW -dynamic_power_view WC_VIEW

set_interactive_constraint_modes {CON}
setAnalysisMode -reset
setAnalysisMode -analysisType onChipVariation -cppr both

clearGlobalNets
globalNetConnect VDD -type pgpin -pin VDD -inst * -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -override
globalNetConnect VDD -type tiehi -inst * -override
globalNetConnect VSS -type tielo -inst * -override


setOptMode -powerEffort low -leakageToDynamicRatio 0.5
setGenerateViaMode -auto true
generateVias

# basic path groups
createBasicPathGroups -expanded

## Generate the floorplan ##
setFPlanMode -snapBlockGrid LayerTrack

## Read the placed def file
defIn ${handoff_dir}/${DESIGN}_placed.def

### Write postSynth report ###
echo "Physical Design Stage, Core Area (um^2), Standard Cell Area (um^2), Macro Area (um^2), Total Power (mW), Wirelength(um), WS(ns), TNS(ns), Congestion(H), Congestion(V)" > ${DESIGN}_DETAILS.rpt
source extract_report.tcl

saveDesign ${encDir}/${DESIGN}_input_placed.enc

setPlaceMode -place_detail_legalization_inst_gap 1
setPlaceMode -place_global_place_io_pins true
setFillerMode -fitGap true
setDesignMode -topRoutingLayer $TOP_ROUTING_LAYER
setDesignMode -bottomRoutingLayer 2

dbset [dbget top.insts.cell.name DFF* -p2 ].dontTouch sizeok
# place_opt_design -out_dir $rptDir -prefix place
place_opt_design -incremental
saveDesign $encDir/${DESIGN}_placed.enc

set rpt_pre_cts [extract_report preCTS]
echo "$rpt_pre_cts" >> ${DESIGN}_DETAILS.rpt

set_ccopt_property post_conditioning_enable_routing_eco 1
set_ccopt_property -cts_def_lock_clock_sinks_after_routing true
setOptMode -unfixClkInstForOpt false

create_ccopt_clock_tree_spec
ccopt_design

set_interactive_constraint_modes [all_constraint_modes -active]
set_propagated_clock [all_clocks]
set_clock_propagation propagated

saveDesign $encDir/${DESIGN}_cts.enc
set rpt_post_cts [extract_report postCTS]
echo "$rpt_post_cts" >> ${DESIGN}_DETAILS.rpt


# ------------------------------------------------------------------------------
# Routing
# ------------------------------------------------------------------------------
setNanoRouteMode -drouteVerboseViolationSummary 1
setNanoRouteMode -routeWithSiDriven true
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeUseAutoVia true

##Recommended by lib owners
# Prevent router modifying M1 pins shapes
setNanoRouteMode -routeWithViaInPin "1:1"
setNanoRouteMode -routeWithViaOnlyForStandardCellPin "1:1"

## limit VIAs to ongrid only for VIA1 (S1)
setNanoRouteMode -drouteOnGridOnly "via 1:1"
setNanoRouteMode -drouteAutoStop false
setNanoRouteMode -drouteExpAdvancedMarFix true
setNanoRouteMode -routeExpAdvancedTechnology true

#SM suggestion for solving long extraction runtime during GR
setNanoRouteMode -grouteExpWithTimingDriven false

routeDesign
#route_opt_design
saveDesign ${encDir}/${DESIGN}_route.enc


### Add V1 vias ###
setViaGenMode -reset
editPowerVia -top_layer M2 -bottom_layer M1 -orthogonal_only 0 -add_vias 1

### Run DRC and LVS ###
verify_connectivity -error 0 -geom_connect -no_antenna
verify_drc -limit 0

set rpt_post_route [extract_report postRoute]
echo "$rpt_post_route" >> ${DESIGN}_DETAILS.rpt

defOut -netlist -floorplan -routing ${DESIGN}_route.def

#route_opt_design
optDesign -postRoute
set rpt_post_route [extract_report postRouteOpt]
echo "$rpt_post_route" >> ${DESIGN}_DETAILS.rpt

summaryReport -noHtml -outfile summaryReport/post_route.sum
saveDesign ${encDir}/${DESIGN}.enc
defOut -netlist -floorplan -routing ${DESIGN}.def

exit
