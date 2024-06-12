source helpers.tcl
source function_mbff.tcl
source soce_func_or.tcl
set test_name $env(DESIGN)_$env(M)_2

##
read_lef <lef_file>

read_lib <lib_file>

## read mbffs 
read_verilog ./$env(DESIGN)/$env(DESIGN).v
link_design $env(DESIGN)
read_def -floorplan_initialize ./$env(DESIGN)/$env(DESIGN)_placed.def
read_sdc ./$env(DESIGN)/$env(DESIGN).sdc
read_spef ./$env(DESIGN)/$env(DESIGN).spef

set binary_name "clustering"
puts $binary_name
write_mean_shift_inputs input.txt

catch {
 puts "Execute Mean Shift"
 exec ./$binary_name
 exec grep "FF " clust_$env(DESIGN)_$env(M)_ms.log > mapping_$env(DESIGN)_$env(M).txt
 } exception

exec python3 post_process.py > new_output.txt
read_mbff_outputs ./new_output.txt
write_def ./$env(DESIGN)_$env(M)_ms.def
write_verilog ./$env(DESIGN)_$env(M)_ms.v

exit
