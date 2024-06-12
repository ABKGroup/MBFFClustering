# note that the following tcl scirpt is an example of
# applying cadence gpdk45
#

############################
# set the FF2 and FF4 types
set mean_shift_ff2_master "DFFHQNV2Xx1_ASAP7_75t_L"
set mean_shift_ff4_master "DFFHQNV4Xx1_ASAP7_75t_L"
set mean_shift_ff8_master "DFFHQNV4H2Xx1_ASAP7_75t_L"
set mean_shift_ff16_master "DFFHQNV8H2Xx1_ASAP7_75t_L"

# solve delimiter issues in inst name
proc escape_delimiter {name} {
  set new_str [string map {"\[" "\\\["} $name]
  set new_str [string map {"\]" "\\\]"} $new_str]
  return  $new_str
}

# get net from inst and
# reconnect with new inst
#
proc get_pin_net_and_reconnect { ff_inst pin_name new_ff_inst master_term } {
  
  set ff_iterm [$ff_inst findITerm $pin_name]
  set prev_net [$ff_iterm getNet]

  # reconnect net with updated instance and master term
  while {$prev_net != {NULL}} {
    set new_pin_name [$master_term getName]
    set new_iterm [$new_ff_inst findITerm $new_pin_name]
    #if {$new_iterm != {NULL}} {
      odb::dbITerm_connect $new_iterm $prev_net
      puts "$new_pin_name is in a net"
      odb::dbITerm_disconnect $ff_iterm 
      set prev_net [$ff_iterm getNet]
      #odb::dbITerm_connect $new_ff_inst $prev_net $master_term  
    #}
  }
  
  # release nets.

  return $prev_net
}


proc get_power_master_term { master } {
  foreach master_term [$master getMTerms] {
    if {[$master_term getSigType] == "POWER"} {
      return $master_term
    }
  } 
  return {NULL}
}

proc get_ground_master_term { master } {
  foreach master_term [$master getMTerms] {
    if {[$master_term getSigType] == "GROUND"} {
      return $master_term
    }
  } 
  return {NULL}
}

proc get_power_inst_term { inst } {
  foreach inst_term [$inst getITerms] {
    if {[$inst_term getSigType] == "POWER"} {
      return $inst_term
    }
  } 
  return {NULL}
}

proc get_ground_inst_term { inst } {
  foreach inst_term [$inst getITerms] {
    if {[$inst_term getSigType] == "GROUND"} {
      return $inst_term
    }
  } 
  return {NULL}
}

# merge 2 ffs in opendb 
proc merge_2_ffs { fflist } {
  global mean_shift_ff2_master 
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  set ff1_inst [lindex $fflist 0]
  set ff2_inst [lindex $fflist 1]
 
  set new_ff_master [$db findMaster $mean_shift_ff2_master] 
  set new_q1_term [$new_ff_master findMTerm "QN0"]
  set new_q2_term [$new_ff_master findMTerm "QN1"]

  set new_d1_term [$new_ff_master findMTerm "D0"]
  set new_d2_term [$new_ff_master findMTerm "D1"]

  # set new_rn_term [$new_ff_master findMTerm "RN"]
  set new_clk_term [$new_ff_master findMTerm "CLK"]

  set new_ground_term [$new_ff_master findMTerm "VSS"]
  set new_power_term [$new_ff_master findMTerm "VDD"]

  set new_ff_name "[$ff1_inst getName]__[$ff2_inst getName]"
  set new_ff_inst [odb::dbInst_create $block $new_ff_master $new_ff_name]
  puts "Created 2FF Instance: $new_ff_name"

  puts "FF [$ff1_inst getName] to 0th slot of MBFF $new_ff_name"
  puts "FF [$ff2_inst getName] to 1th slot of MBFF $new_ff_name"

  # Q-pin reconnects
  set ff1_q_net [get_pin_net_and_reconnect $ff1_inst "QN" $new_ff_inst $new_q1_term]
  set ff2_q_net [get_pin_net_and_reconnect $ff2_inst "QN" $new_ff_inst $new_q2_term]
  # D-pin reconnects 
  set ff1_d_net [get_pin_net_and_reconnect $ff1_inst "D" $new_ff_inst $new_d1_term]
  set ff2_d_net [get_pin_net_and_reconnect $ff2_inst "D" $new_ff_inst $new_d2_term]

  
  set ff1_clk_net [get_pin_net_and_reconnect $ff1_inst "CLK" $new_ff_inst $new_clk_term]
  set ff2_clk_net [get_pin_net_and_reconnect $ff2_inst "CLK" $new_ff_inst $new_clk_term]

  set ff1_ground_net [get_pin_net_and_reconnect $ff1_inst "VSS" $new_ff_inst $new_ground_term]
  set ff2_ground_net [get_pin_net_and_reconnect $ff2_inst "VSS" $new_ff_inst $new_ground_term]

  set ff1_power_net [get_pin_net_and_reconnect $ff1_inst "VDD" $new_ff_inst $new_power_term]
  set ff2_power_net [get_pin_net_and_reconnect $ff2_inst "VDD" $new_ff_inst $new_power_term]
  
  set locs [$ff1_inst getLocation]  
  $new_ff_inst setPlacementStatus PLACED
  $new_ff_inst setLocation [lindex $locs 0] [lindex $locs 1] 
  $new_ff_inst setOrient R0 

  odb::dbInst_destroy $ff1_inst
  odb::dbInst_destroy $ff2_inst 

  #set net [$block findNet "VDD"]
  #foreach iterm [$net getITerms] {
  #  puts -nonewline "[[$iterm getMTerm] getName] "
  #}
  #puts ""
}

# merge 4 ffs in opendb
proc merge_4_ffs { fflist } {
  puts "getting 4-bit"
  global mean_shift_ff4_master 
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  set ff1_inst [lindex $fflist 0]
  set ff2_inst [lindex $fflist 1]
  set ff3_inst [lindex $fflist 2]
  set ff4_inst [lindex $fflist 3]
  
  set new_ff_master [$db findMaster $mean_shift_ff4_master] 
  set new_q1_term [$new_ff_master findMTerm "QN0"]
  set new_q2_term [$new_ff_master findMTerm "QN1"]
  set new_q3_term [$new_ff_master findMTerm "QN2"]
  set new_q4_term [$new_ff_master findMTerm "QN3"]

  set new_d1_term [$new_ff_master findMTerm "D0"]
  set new_d2_term [$new_ff_master findMTerm "D1"]
  set new_d3_term [$new_ff_master findMTerm "D2"]
  set new_d4_term [$new_ff_master findMTerm "D3"]

  # set new_rn_term [$new_ff_master findMTerm "RN"]
  set new_clk_term [$new_ff_master findMTerm "CLK"]
  set new_ground_term [$new_ff_master findMTerm "VSS"]
  set new_power_term [$new_ff_master findMTerm "VDD"]
  
  set new_ff_name "[$ff1_inst getName]__[$ff2_inst getName]__[$ff3_inst getName]__[$ff4_inst getName]"
  set new_ff_inst [odb::dbInst_create $block $new_ff_master $new_ff_name]
  puts "Created 4FF Instance: $new_ff_name"
  
  puts "FF [$ff1_inst getName] to 0th slot of MBFF $new_ff_name"
  puts "FF [$ff2_inst getName] to 1th slot of MBFF $new_ff_name"
  puts "FF [$ff3_inst getName] to 2th slot of MBFF $new_ff_name"
  puts "FF [$ff4_inst getName] to 3th slot of MBFF $new_ff_name"

  # D-pin reconnects 
  set ff1_d_net [get_pin_net_and_reconnect $ff1_inst "D" $new_ff_inst $new_d1_term]
  set ff2_d_net [get_pin_net_and_reconnect $ff2_inst "D" $new_ff_inst $new_d2_term]
  set ff3_d_net [get_pin_net_and_reconnect $ff3_inst "D" $new_ff_inst $new_d3_term]
  set ff4_d_net [get_pin_net_and_reconnect $ff4_inst "D" $new_ff_inst $new_d4_term]
 
  # Q-pin reconnects
  set ff1_q_net [get_pin_net_and_reconnect $ff1_inst "QN" $new_ff_inst $new_q1_term]
  set ff2_q_net [get_pin_net_and_reconnect $ff2_inst "QN" $new_ff_inst $new_q2_term]
  set ff3_q_net [get_pin_net_and_reconnect $ff3_inst "QN" $new_ff_inst $new_q3_term]
  set ff4_q_net [get_pin_net_and_reconnect $ff4_inst "QN" $new_ff_inst $new_q4_term]
  
  set ff1_clk_net [get_pin_net_and_reconnect $ff1_inst "CLK" $new_ff_inst $new_clk_term]
  set ff2_clk_net [get_pin_net_and_reconnect $ff2_inst "CLK" $new_ff_inst $new_clk_term]
  set ff3_clk_net [get_pin_net_and_reconnect $ff3_inst "CLK" $new_ff_inst $new_clk_term]
  set ff4_clk_net [get_pin_net_and_reconnect $ff4_inst "CLK" $new_ff_inst $new_clk_term]
  
  set ff1_ground_net [get_pin_net_and_reconnect $ff1_inst "VSS" $new_ff_inst $new_ground_term]
  set ff2_ground_net [get_pin_net_and_reconnect $ff2_inst "VSS" $new_ff_inst $new_ground_term]
  set ff3_ground_net [get_pin_net_and_reconnect $ff3_inst "VSS" $new_ff_inst $new_ground_term]
  set ff4_ground_net [get_pin_net_and_reconnect $ff4_inst "VSS" $new_ff_inst $new_ground_term]


  set ff1_power_net [get_pin_net_and_reconnect $ff1_inst "VDD" $new_ff_inst $new_power_term]
  set ff2_power_net [get_pin_net_and_reconnect $ff2_inst "VDD" $new_ff_inst $new_power_term]
  set ff3_power_net [get_pin_net_and_reconnect $ff3_inst "VDD" $new_ff_inst $new_power_term]
  set ff4_power_net [get_pin_net_and_reconnect $ff4_inst "VDD" $new_ff_inst $new_power_term]
  
  set locs [$ff1_inst getLocation]
  $new_ff_inst setPlacementStatus PLACED
  $new_ff_inst setLocation [lindex $locs 0] [lindex $locs 1] 
  $new_ff_inst setOrient R0 
  odb::dbInst_destroy $ff1_inst
  odb::dbInst_destroy $ff2_inst 
  odb::dbInst_destroy $ff3_inst
  odb::dbInst_destroy $ff4_inst 
  
}

proc merge_8_ffs { fflist } {
  puts "getting 8-bit"
  global mean_shift_ff8_master 
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  set ff1_inst [lindex $fflist 0]
  set ff2_inst [lindex $fflist 1]
  set ff3_inst [lindex $fflist 2]
  set ff4_inst [lindex $fflist 3]
  set ff5_inst [lindex $fflist 4]
  set ff6_inst [lindex $fflist 5]
  set ff7_inst [lindex $fflist 6]
  set ff8_inst [lindex $fflist 7]
  
  set new_ff_master [$db findMaster $mean_shift_ff8_master] 
  set new_q1_term [$new_ff_master findMTerm "QN0"]
  set new_q2_term [$new_ff_master findMTerm "QN1"]
  set new_q3_term [$new_ff_master findMTerm "QN2"]
  set new_q4_term [$new_ff_master findMTerm "QN3"]
  set new_q5_term [$new_ff_master findMTerm "QN4"]
  set new_q6_term [$new_ff_master findMTerm "QN5"]
  set new_q7_term [$new_ff_master findMTerm "QN6"]
  set new_q8_term [$new_ff_master findMTerm "QN7"]

  set new_d1_term [$new_ff_master findMTerm "D0"]
  set new_d2_term [$new_ff_master findMTerm "D1"]
  set new_d3_term [$new_ff_master findMTerm "D2"]
  set new_d4_term [$new_ff_master findMTerm "D3"]
  set new_d5_term [$new_ff_master findMTerm "D4"]
  set new_d6_term [$new_ff_master findMTerm "D5"]
  set new_d7_term [$new_ff_master findMTerm "D6"]
  set new_d8_term [$new_ff_master findMTerm "D7"]

  # set new_rn_term [$new_ff_master findMTerm "RN"]
  set new_clk_term [$new_ff_master findMTerm "CLK"]
  set new_ground_term [$new_ff_master findMTerm "VSS"]
  set new_power_term [$new_ff_master findMTerm "VDD"]
  
  set new_ff_name "[$ff1_inst getName]__[$ff2_inst getName]__[$ff3_inst getName]__[$ff4_inst getName]__[$ff5_inst getName]__[$ff6_inst getName]__[$ff7_inst getName]__[$ff8_inst getName]"
  set new_ff_inst [odb::dbInst_create $block $new_ff_master $new_ff_name]
  puts "Created 8FF Instance: $new_ff_name"
  
  puts "FF [$ff1_inst getName] to 0th slot of MBFF $new_ff_name"
  puts "FF [$ff2_inst getName] to 1th slot of MBFF $new_ff_name"
  puts "FF [$ff3_inst getName] to 2th slot of MBFF $new_ff_name"
  puts "FF [$ff4_inst getName] to 3th slot of MBFF $new_ff_name"
  puts "FF [$ff5_inst getName] to 4th slot of MBFF $new_ff_name"
  puts "FF [$ff6_inst getName] to 5th slot of MBFF $new_ff_name"
  puts "FF [$ff7_inst getName] to 6th slot of MBFF $new_ff_name"
  puts "FF [$ff8_inst getName] to 7th slot of MBFF $new_ff_name"

  # D-pin reconnects 
  set ff1_d_net [get_pin_net_and_reconnect $ff1_inst "D" $new_ff_inst $new_d1_term]
  set ff2_d_net [get_pin_net_and_reconnect $ff2_inst "D" $new_ff_inst $new_d2_term]
  set ff3_d_net [get_pin_net_and_reconnect $ff3_inst "D" $new_ff_inst $new_d3_term]
  set ff4_d_net [get_pin_net_and_reconnect $ff4_inst "D" $new_ff_inst $new_d4_term]
  set ff5_d_net [get_pin_net_and_reconnect $ff5_inst "D" $new_ff_inst $new_d5_term]
  set ff6_d_net [get_pin_net_and_reconnect $ff6_inst "D" $new_ff_inst $new_d6_term]
  set ff7_d_net [get_pin_net_and_reconnect $ff7_inst "D" $new_ff_inst $new_d7_term]
  set ff8_d_net [get_pin_net_and_reconnect $ff8_inst "D" $new_ff_inst $new_d8_term]
 
  # Q-pin reconnects
  set ff1_q_net [get_pin_net_and_reconnect $ff1_inst "QN" $new_ff_inst $new_q1_term]
  set ff2_q_net [get_pin_net_and_reconnect $ff2_inst "QN" $new_ff_inst $new_q2_term]
  set ff3_q_net [get_pin_net_and_reconnect $ff3_inst "QN" $new_ff_inst $new_q3_term]
  set ff4_q_net [get_pin_net_and_reconnect $ff4_inst "QN" $new_ff_inst $new_q4_term]
  set ff5_q_net [get_pin_net_and_reconnect $ff5_inst "QN" $new_ff_inst $new_q5_term]
  set ff6_q_net [get_pin_net_and_reconnect $ff6_inst "QN" $new_ff_inst $new_q6_term]
  set ff7_q_net [get_pin_net_and_reconnect $ff7_inst "QN" $new_ff_inst $new_q7_term]
  set ff8_q_net [get_pin_net_and_reconnect $ff8_inst "QN" $new_ff_inst $new_q8_term]
  
  set ff1_clk_net [get_pin_net_and_reconnect $ff1_inst "CLK" $new_ff_inst $new_clk_term]
  set ff2_clk_net [get_pin_net_and_reconnect $ff2_inst "CLK" $new_ff_inst $new_clk_term]
  set ff3_clk_net [get_pin_net_and_reconnect $ff3_inst "CLK" $new_ff_inst $new_clk_term]
  set ff4_clk_net [get_pin_net_and_reconnect $ff4_inst "CLK" $new_ff_inst $new_clk_term]
  set ff5_clk_net [get_pin_net_and_reconnect $ff5_inst "CLK" $new_ff_inst $new_clk_term]
  set ff6_clk_net [get_pin_net_and_reconnect $ff6_inst "CLK" $new_ff_inst $new_clk_term]
  set ff7_clk_net [get_pin_net_and_reconnect $ff7_inst "CLK" $new_ff_inst $new_clk_term]
  set ff8_clk_net [get_pin_net_and_reconnect $ff8_inst "CLK" $new_ff_inst $new_clk_term]
  
  set ff1_ground_net [get_pin_net_and_reconnect $ff1_inst "VSS" $new_ff_inst $new_ground_term]
  set ff2_ground_net [get_pin_net_and_reconnect $ff2_inst "VSS" $new_ff_inst $new_ground_term]
  set ff3_ground_net [get_pin_net_and_reconnect $ff3_inst "VSS" $new_ff_inst $new_ground_term]
  set ff4_ground_net [get_pin_net_and_reconnect $ff4_inst "VSS" $new_ff_inst $new_ground_term]
  set ff5_ground_net [get_pin_net_and_reconnect $ff5_inst "VSS" $new_ff_inst $new_ground_term]
  set ff6_ground_net [get_pin_net_and_reconnect $ff6_inst "VSS" $new_ff_inst $new_ground_term]
  set ff7_ground_net [get_pin_net_and_reconnect $ff7_inst "VSS" $new_ff_inst $new_ground_term]
  set ff8_ground_net [get_pin_net_and_reconnect $ff8_inst "VSS" $new_ff_inst $new_ground_term]


  set ff1_power_net [get_pin_net_and_reconnect $ff1_inst "VDD" $new_ff_inst $new_power_term]
  set ff2_power_net [get_pin_net_and_reconnect $ff2_inst "VDD" $new_ff_inst $new_power_term]
  set ff3_power_net [get_pin_net_and_reconnect $ff3_inst "VDD" $new_ff_inst $new_power_term]
  set ff4_power_net [get_pin_net_and_reconnect $ff4_inst "VDD" $new_ff_inst $new_power_term]
  set ff5_power_net [get_pin_net_and_reconnect $ff5_inst "VDD" $new_ff_inst $new_power_term]
  set ff6_power_net [get_pin_net_and_reconnect $ff6_inst "VDD" $new_ff_inst $new_power_term]
  set ff7_power_net [get_pin_net_and_reconnect $ff7_inst "VDD" $new_ff_inst $new_power_term]
  set ff8_power_net [get_pin_net_and_reconnect $ff8_inst "VDD" $new_ff_inst $new_power_term]
  
  
  set locs [$ff1_inst getLocation]
  $new_ff_inst setPlacementStatus PLACED
  $new_ff_inst setLocation [lindex $locs 0] [lindex $locs 1] 
  $new_ff_inst setOrient R0
  odb::dbInst_destroy $ff1_inst
  odb::dbInst_destroy $ff2_inst 
  odb::dbInst_destroy $ff3_inst
  odb::dbInst_destroy $ff4_inst  
  odb::dbInst_destroy $ff5_inst
  odb::dbInst_destroy $ff6_inst 
  odb::dbInst_destroy $ff7_inst
  odb::dbInst_destroy $ff8_inst 
} 

proc merge_16_ffs { fflist } {
  puts "getting 16-bit"
  global mean_shift_ff16_master 
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  set ff1_inst [lindex $fflist 0]
  set ff2_inst [lindex $fflist 1]
  set ff3_inst [lindex $fflist 2]
  set ff4_inst [lindex $fflist 3]
  set ff5_inst [lindex $fflist 4]
  set ff6_inst [lindex $fflist 5]
  set ff7_inst [lindex $fflist 6]
  set ff8_inst [lindex $fflist 7]
  set ff9_inst [lindex $fflist 8]
  set ff10_inst [lindex $fflist 9]
  set ff11_inst [lindex $fflist 10]
  set ff12_inst [lindex $fflist 11]
  set ff13_inst [lindex $fflist 12]
  set ff14_inst [lindex $fflist 13]
  set ff15_inst [lindex $fflist 14]
  set ff16_inst [lindex $fflist 15]
  
  set new_ff_master [$db findMaster $mean_shift_ff16_master] 
  set new_q1_term [$new_ff_master findMTerm "QN0"]
  set new_q2_term [$new_ff_master findMTerm "QN1"]
  set new_q3_term [$new_ff_master findMTerm "QN2"]
  set new_q4_term [$new_ff_master findMTerm "QN3"]
  set new_q5_term [$new_ff_master findMTerm "QN4"]
  set new_q6_term [$new_ff_master findMTerm "QN5"]
  set new_q7_term [$new_ff_master findMTerm "QN6"]
  set new_q8_term [$new_ff_master findMTerm "QN7"]
  set new_q9_term [$new_ff_master findMTerm "QN8"]
  set new_q10_term [$new_ff_master findMTerm "QN9"]
  set new_q11_term [$new_ff_master findMTerm "QN10"]
  set new_q12_term [$new_ff_master findMTerm "QN11"]
  set new_q13_term [$new_ff_master findMTerm "QN12"]
  set new_q14_term [$new_ff_master findMTerm "QN13"]
  set new_q15_term [$new_ff_master findMTerm "QN14"]
  set new_q16_term [$new_ff_master findMTerm "QN15"]

  set new_d1_term [$new_ff_master findMTerm "D0"]
  set new_d2_term [$new_ff_master findMTerm "D1"]
  set new_d3_term [$new_ff_master findMTerm "D2"]
  set new_d4_term [$new_ff_master findMTerm "D3"]
  set new_d5_term [$new_ff_master findMTerm "D4"]
  set new_d6_term [$new_ff_master findMTerm "D5"]
  set new_d7_term [$new_ff_master findMTerm "D6"]
  set new_d8_term [$new_ff_master findMTerm "D7"]
  set new_d9_term [$new_ff_master findMTerm "D8"]
  set new_d10_term [$new_ff_master findMTerm "D9"]
  set new_d11_term [$new_ff_master findMTerm "D10"]
  set new_d12_term [$new_ff_master findMTerm "D11"]
  set new_d13_term [$new_ff_master findMTerm "D12"]
  set new_d14_term [$new_ff_master findMTerm "D13"]
  set new_d15_term [$new_ff_master findMTerm "D14"]
  set new_d16_term [$new_ff_master findMTerm "D15"]

  # set new_rn_term [$new_ff_master findMTerm "RN"]
  set new_clk_term [$new_ff_master findMTerm "CLK"]
  set new_ground_term [$new_ff_master findMTerm "VSS"]
  set new_power_term [$new_ff_master findMTerm "VDD"]
  
  set new_ff_name "[$ff1_inst getName]__[$ff2_inst getName]__[$ff3_inst getName]__[$ff4_inst getName]__[$ff5_inst getName]__[$ff6_inst getName]__[$ff7_inst getName]__[$ff8_inst getName]__[$ff9_inst getName]__[$ff10_inst getName]__[$ff11_inst getName]__[$ff12_inst getName]__[$ff13_inst getName]__[$ff14_inst getName]__[$ff15_inst getName]__[$ff16_inst getName]"
  set new_ff_inst [odb::dbInst_create $block $new_ff_master $new_ff_name]
  puts "Created 16FF Instance: $new_ff_name"
  
  puts "FF [$ff1_inst getName] to 0th slot of MBFF $new_ff_name"
  puts "FF [$ff2_inst getName] to 1th slot of MBFF $new_ff_name"
  puts "FF [$ff3_inst getName] to 2th slot of MBFF $new_ff_name"
  puts "FF [$ff4_inst getName] to 3th slot of MBFF $new_ff_name"
  puts "FF [$ff5_inst getName] to 4th slot of MBFF $new_ff_name"
  puts "FF [$ff6_inst getName] to 5th slot of MBFF $new_ff_name"
  puts "FF [$ff7_inst getName] to 6th slot of MBFF $new_ff_name"
  puts "FF [$ff8_inst getName] to 7th slot of MBFF $new_ff_name"
  puts "FF [$ff9_inst getName] to 8th slot of MBFF $new_ff_name"
  puts "FF [$ff10_inst getName] to 9th slot of MBFF $new_ff_name"
  puts "FF [$ff11_inst getName] to 10th slot of MBFF $new_ff_name"
  puts "FF [$ff12_inst getName] to 11th slot of MBFF $new_ff_name"
  puts "FF [$ff13_inst getName] to 12th slot of MBFF $new_ff_name"
  puts "FF [$ff14_inst getName] to 13th slot of MBFF $new_ff_name"
  puts "FF [$ff15_inst getName] to 14th slot of MBFF $new_ff_name"
  puts "FF [$ff16_inst getName] to 15th slot of MBFF $new_ff_name"

  # D-pin reconnects 
  set ff1_d_net [get_pin_net_and_reconnect $ff1_inst "D" $new_ff_inst $new_d1_term]
  set ff2_d_net [get_pin_net_and_reconnect $ff2_inst "D" $new_ff_inst $new_d2_term]
  set ff3_d_net [get_pin_net_and_reconnect $ff3_inst "D" $new_ff_inst $new_d3_term]
  set ff4_d_net [get_pin_net_and_reconnect $ff4_inst "D" $new_ff_inst $new_d4_term]
  set ff5_d_net [get_pin_net_and_reconnect $ff5_inst "D" $new_ff_inst $new_d5_term]
  set ff6_d_net [get_pin_net_and_reconnect $ff6_inst "D" $new_ff_inst $new_d6_term]
  set ff7_d_net [get_pin_net_and_reconnect $ff7_inst "D" $new_ff_inst $new_d7_term]
  set ff8_d_net [get_pin_net_and_reconnect $ff8_inst "D" $new_ff_inst $new_d8_term]
  set ff9_d_net [get_pin_net_and_reconnect $ff9_inst "D" $new_ff_inst $new_d9_term]
  set ff10_d_net [get_pin_net_and_reconnect $ff10_inst "D" $new_ff_inst $new_d10_term]
  set ff11_d_net [get_pin_net_and_reconnect $ff11_inst "D" $new_ff_inst $new_d11_term]
  set ff12_d_net [get_pin_net_and_reconnect $ff12_inst "D" $new_ff_inst $new_d12_term]
  set ff13_d_net [get_pin_net_and_reconnect $ff13_inst "D" $new_ff_inst $new_d13_term]
  set ff14_d_net [get_pin_net_and_reconnect $ff14_inst "D" $new_ff_inst $new_d14_term]
  set ff15_d_net [get_pin_net_and_reconnect $ff15_inst "D" $new_ff_inst $new_d15_term]
  set ff16_d_net [get_pin_net_and_reconnect $ff16_inst "D" $new_ff_inst $new_d16_term]
 
  # Q-pin reconnects
  set ff1_q_net [get_pin_net_and_reconnect $ff1_inst "QN" $new_ff_inst $new_q1_term]
  set ff2_q_net [get_pin_net_and_reconnect $ff2_inst "QN" $new_ff_inst $new_q2_term]
  set ff3_q_net [get_pin_net_and_reconnect $ff3_inst "QN" $new_ff_inst $new_q3_term]
  set ff4_q_net [get_pin_net_and_reconnect $ff4_inst "QN" $new_ff_inst $new_q4_term]
  set ff5_q_net [get_pin_net_and_reconnect $ff5_inst "QN" $new_ff_inst $new_q5_term]
  set ff6_q_net [get_pin_net_and_reconnect $ff6_inst "QN" $new_ff_inst $new_q6_term]
  set ff7_q_net [get_pin_net_and_reconnect $ff7_inst "QN" $new_ff_inst $new_q7_term]
  set ff8_q_net [get_pin_net_and_reconnect $ff8_inst "QN" $new_ff_inst $new_q8_term]
  set ff9_q_net [get_pin_net_and_reconnect $ff9_inst "QN" $new_ff_inst $new_q9_term]
  set ff10_q_net [get_pin_net_and_reconnect $ff10_inst "QN" $new_ff_inst $new_q10_term]
  set ff11_q_net [get_pin_net_and_reconnect $ff11_inst "QN" $new_ff_inst $new_q11_term]
  set ff12_q_net [get_pin_net_and_reconnect $ff12_inst "QN" $new_ff_inst $new_q12_term]
  set ff13_q_net [get_pin_net_and_reconnect $ff13_inst "QN" $new_ff_inst $new_q13_term]
  set ff14_q_net [get_pin_net_and_reconnect $ff14_inst "QN" $new_ff_inst $new_q14_term]
  set ff15_q_net [get_pin_net_and_reconnect $ff15_inst "QN" $new_ff_inst $new_q15_term]
  set ff16_q_net [get_pin_net_and_reconnect $ff16_inst "QN" $new_ff_inst $new_q16_term]
  
  set ff1_clk_net [get_pin_net_and_reconnect $ff1_inst "CLK" $new_ff_inst $new_clk_term]
  set ff2_clk_net [get_pin_net_and_reconnect $ff2_inst "CLK" $new_ff_inst $new_clk_term]
  set ff3_clk_net [get_pin_net_and_reconnect $ff3_inst "CLK" $new_ff_inst $new_clk_term]
  set ff4_clk_net [get_pin_net_and_reconnect $ff4_inst "CLK" $new_ff_inst $new_clk_term]
  set ff5_clk_net [get_pin_net_and_reconnect $ff5_inst "CLK" $new_ff_inst $new_clk_term]
  set ff6_clk_net [get_pin_net_and_reconnect $ff6_inst "CLK" $new_ff_inst $new_clk_term]
  set ff7_clk_net [get_pin_net_and_reconnect $ff7_inst "CLK" $new_ff_inst $new_clk_term]
  set ff8_clk_net [get_pin_net_and_reconnect $ff8_inst "CLK" $new_ff_inst $new_clk_term]
  set ff9_clk_net [get_pin_net_and_reconnect $ff9_inst "CLK" $new_ff_inst $new_clk_term]
  set ff10_clk_net [get_pin_net_and_reconnect $ff10_inst "CLK" $new_ff_inst $new_clk_term]
  set ff11_clk_net [get_pin_net_and_reconnect $ff11_inst "CLK" $new_ff_inst $new_clk_term]
  set ff12_clk_net [get_pin_net_and_reconnect $ff12_inst "CLK" $new_ff_inst $new_clk_term]
  set ff13_clk_net [get_pin_net_and_reconnect $ff13_inst "CLK" $new_ff_inst $new_clk_term]
  set ff14_clk_net [get_pin_net_and_reconnect $ff14_inst "CLK" $new_ff_inst $new_clk_term]
  set ff15_clk_net [get_pin_net_and_reconnect $ff15_inst "CLK" $new_ff_inst $new_clk_term]
  set ff16_clk_net [get_pin_net_and_reconnect $ff16_inst "CLK" $new_ff_inst $new_clk_term]
  
  set ff1_ground_net [get_pin_net_and_reconnect $ff1_inst "VSS" $new_ff_inst $new_ground_term]
  set ff2_ground_net [get_pin_net_and_reconnect $ff2_inst "VSS" $new_ff_inst $new_ground_term]
  set ff3_ground_net [get_pin_net_and_reconnect $ff3_inst "VSS" $new_ff_inst $new_ground_term]
  set ff4_ground_net [get_pin_net_and_reconnect $ff4_inst "VSS" $new_ff_inst $new_ground_term]
  set ff5_ground_net [get_pin_net_and_reconnect $ff5_inst "VSS" $new_ff_inst $new_ground_term]
  set ff6_ground_net [get_pin_net_and_reconnect $ff6_inst "VSS" $new_ff_inst $new_ground_term]
  set ff7_ground_net [get_pin_net_and_reconnect $ff7_inst "VSS" $new_ff_inst $new_ground_term]
  set ff8_ground_net [get_pin_net_and_reconnect $ff8_inst "VSS" $new_ff_inst $new_ground_term]
  set ff9_ground_net [get_pin_net_and_reconnect $ff9_inst "VSS" $new_ff_inst $new_ground_term]
  set ff10_ground_net [get_pin_net_and_reconnect $ff10_inst "VSS" $new_ff_inst $new_ground_term]
  set ff11_ground_net [get_pin_net_and_reconnect $ff11_inst "VSS" $new_ff_inst $new_ground_term]
  set ff12_ground_net [get_pin_net_and_reconnect $ff12_inst "VSS" $new_ff_inst $new_ground_term]
  set ff13_ground_net [get_pin_net_and_reconnect $ff13_inst "VSS" $new_ff_inst $new_ground_term]
  set ff14_ground_net [get_pin_net_and_reconnect $ff14_inst "VSS" $new_ff_inst $new_ground_term]
  set ff15_ground_net [get_pin_net_and_reconnect $ff15_inst "VSS" $new_ff_inst $new_ground_term]
  set ff16_ground_net [get_pin_net_and_reconnect $ff16_inst "VSS" $new_ff_inst $new_ground_term]


  set ff1_power_net [get_pin_net_and_reconnect $ff1_inst "VDD" $new_ff_inst $new_power_term]
  set ff2_power_net [get_pin_net_and_reconnect $ff2_inst "VDD" $new_ff_inst $new_power_term]
  set ff3_power_net [get_pin_net_and_reconnect $ff3_inst "VDD" $new_ff_inst $new_power_term]
  set ff4_power_net [get_pin_net_and_reconnect $ff4_inst "VDD" $new_ff_inst $new_power_term]
  set ff5_power_net [get_pin_net_and_reconnect $ff5_inst "VDD" $new_ff_inst $new_power_term]
  set ff6_power_net [get_pin_net_and_reconnect $ff6_inst "VDD" $new_ff_inst $new_power_term]
  set ff7_power_net [get_pin_net_and_reconnect $ff7_inst "VDD" $new_ff_inst $new_power_term]
  set ff8_power_net [get_pin_net_and_reconnect $ff8_inst "VDD" $new_ff_inst $new_power_term]
  set ff9_power_net [get_pin_net_and_reconnect $ff9_inst "VDD" $new_ff_inst $new_power_term]
  set ff10_power_net [get_pin_net_and_reconnect $ff10_inst "VDD" $new_ff_inst $new_power_term]
  set ff11_power_net [get_pin_net_and_reconnect $ff11_inst "VDD" $new_ff_inst $new_power_term]
  set ff12_power_net [get_pin_net_and_reconnect $ff12_inst "VDD" $new_ff_inst $new_power_term]
  set ff13_power_net [get_pin_net_and_reconnect $ff13_inst "VDD" $new_ff_inst $new_power_term]
  set ff14_power_net [get_pin_net_and_reconnect $ff14_inst "VDD" $new_ff_inst $new_power_term]
  set ff15_power_net [get_pin_net_and_reconnect $ff15_inst "VDD" $new_ff_inst $new_power_term]
  set ff16_power_net [get_pin_net_and_reconnect $ff16_inst "VDD" $new_ff_inst $new_power_term]
  
  set locs [$ff1_inst getLocation]
  $new_ff_inst setPlacementStatus PLACED
  $new_ff_inst setLocation [lindex $locs 0] [lindex $locs 1] 
  $new_ff_inst setOrient R0
  odb::dbInst_destroy $ff1_inst
  odb::dbInst_destroy $ff2_inst 
  odb::dbInst_destroy $ff3_inst
  odb::dbInst_destroy $ff4_inst  
  odb::dbInst_destroy $ff5_inst
  odb::dbInst_destroy $ff6_inst 
  odb::dbInst_destroy $ff7_inst
  odb::dbInst_destroy $ff8_inst 
  odb::dbInst_destroy $ff9_inst
  odb::dbInst_destroy $ff10_inst 
  odb::dbInst_destroy $ff11_inst
  odb::dbInst_destroy $ff12_inst  
  odb::dbInst_destroy $ff13_inst
  odb::dbInst_destroy $ff14_inst 
  odb::dbInst_destroy $ff15_inst
  odb::dbInst_destroy $ff16_inst 
} 

proc write_mean_shift_inputs {text_file} {
  # get pointers from OpenDB
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]
  set dbu [$tech getDbUnitsPerMicron]
  puts "Writing mean_shift inputs from OpenROAD..."
  puts "DBU: $dbu"

  # set bbox [$block getBBox]
  set die_rect [$block getDieArea]
  
  set fid [open $text_file w]

  puts $fid "DIEAREA ( [$die_rect xMin] [$die_rect yMin] ) ( [$die_rect xMax] [$die_rect yMax] )"
  puts $fid "Register_Name X Y Max_Rise Max_Fall"
  set insts [$block getInsts]
  foreach inst $insts {
    set master_name [[$inst getMaster] getName]
    if {![string match DFFHQN* $master_name]} {
      continue
    }

    set locs [$inst getLocation]
    set x [lindex $locs 0]
    set y [lindex $locs 1]
    puts $fid "[$inst getName] [expr 1.0 * $x/$dbu] [expr 1.0 * $y/$dbu] * *" 
  }
  close $fid
  puts "Writing mean_shift inputs is done. Total #Inst = [llength $insts]"
}

proc write_flop_tray_inputs {} {
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]
  set dbu [$tech getDbUnitsPerMicron]
  puts "Writing flop_tray inputs from OpenROAD..."
  puts "DBU: $dbu"

  if {![file exists input]} {
    exec mkdir input/
  }
  
  set fid [open input/fp_info.txt w]
  set die_rect [$block getDieArea]
  puts $fid "[$die_rect xMin] [$die_rect yMin] [$die_rect xMax] [$die_rect yMax]"
  close $fid

  set fid [open input/ff_info.txt w]
  
  set insts [$block getInsts]
  foreach inst $insts {

    set master_name [[$inst getMaster] getName]
    if {![string match DFF_X* $master_name]} {
      continue
    }

    set locs [$inst getLocation]
    set x [lindex $locs 0]
    set y [lindex $locs 1]
    puts $fid "[$inst getName] [expr (1.0*$x)/$dbu] [expr (1.0*$y)/$dbu]" 
  }
  
  close $fid

  set fid [open input/path_info.txt w]
  puts $fid ""
  close $fid 

  puts "Writing flop_tray inputs is done. Total #Inst = [llength $insts]"
}



proc read_mbff_outputs {text_file} {
  global mean_shift_ff2_master 
  global mean_shift_ff4_master 
  global mean_shift_ff8_master 
  global mean_shift_ff16_master 

  # get pointers from OpenDB
  set db [ord::get_db]
  set tech [$db getTech]
  set libs [$db getLibs]
  set block [[$db getChip] getBlock]

  puts "Reading mean_shift outputs to OpenROAD..."

  set dbu [$tech getDbUnitsPerMicron]
  puts "DBU: $dbu"


  set ff2_master [$db findMaster $mean_shift_ff2_master]
  set ff4_master [$db findMaster $mean_shift_ff4_master]
  set ff8_master [$db findMaster $mean_shift_ff8_master]
  set ff16_master [$db findMaster $mean_shift_ff16_master]

  # MBFF lef check
  if {$ff2_master == {NULL}} {
    puts "Error: FF2 master cell: $mean_shift_ff2_master is not found! Please double check lef."
    return
  }
  
  # MBFF lef check
  if {$ff4_master == {NULL}} {
    puts "Error: FF4 master cell: $mean_shift_ff4_master 4s not found! Please double check lef."
    return
  }

  if {$ff8_master == {NULL}} {
    puts "Error: FF4 master cell: $mean_shift_ff8_master 8s not found! Please double check lef."
    return
  }

  if {$ff16_master == {NULL}} {
    puts "Error: FF4 master cell: $mean_shift_ff16_master 16s not found! Please double check lef."
    return
  }

  puts "Checking LEF Done."

  puts "Reading $text_file"
  set fid [open $text_file r]
  set lst_lines [split [read $fid] \n]
  close $fid

  set idx_dict {}

  set i 0
  foreach line $lst_lines { 
    # skip for DIEAREA / name column 
    if {$i <= 1} {
      incr i
      continue
    }
  
    # output always have four columns
    if {[llength $line] != 4} {
      incr i
      continue
    }
  
    # instance name
    set inst_name [lindex $line 0]
    
    # x, y coordinates
    set x [expr int([lindex $line 1] * $dbu)]
    set y [expr int([lindex $line 2] * $dbu)]

    # idx
    set idx [lindex $line 3]

    set inst [$block findInst $inst_name]
    if { $inst == {NULL} } {
      set inst [$block findInst [escape_delimiter $inst_name]]
    }

    if { $inst == {NULL} } {
      puts "Error: Cannot find Instance: $inst_name in OpenDB"
      return
    }

    $inst setLocation $x $y

    # append idx-inst list pair    
    # if already exists, just append inst to list
    if {[dict exists $idx_dict $idx]} {
      set new_list [dict get $idx_dict $idx] 
      lappend new_list $inst
      dict set idx_dict $idx $new_list
    # else, newly create 1-elem inst list
    } else {
      dict set idx_dict $idx [list $inst]
    }
    incr i
  }
  puts "Dictionary building is done. Total dict length = [expr [llength $idx_dict]/2]" 
  puts "NumInstances before merging: [llength [$block getInsts]]"

  ## have fun reading this!
  foreach idx [dict keys $idx_dict] { 
    set ff_list [dict get $idx_dict $idx]
    set ff_len [llength $ff_list]

    puts "Current ff_len [$ff_len]"
    # master cell type conversion
    if { $ff_len == 2 } {
      merge_2_ffs $ff_list
    } elseif { $ff_len == 3 } {
      merge_2_ffs [lrange $ff_list 0 end-1]
    } elseif { $ff_len == 4 } {
      merge_4_ffs $ff_list
    } elseif { $ff_len == 5 } {
      merge_4_ffs [lrange $ff_list 0 end-1]
    } elseif { $ff_len == 6 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_4_ffs [lrange $ff_list 2 end]
    } elseif { $ff_len == 7 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_4_ffs [lrange $ff_list 2 end-1]
    } elseif { $ff_len == 8 } {
      merge_8_ffs $ff_list
    } elseif { $ff_len == 9 } {
      merge_8_ffs [lrange $ff_list 0 end-1]
    } elseif { $ff_len == 10 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_8_ffs [lrange $ff_list 2 end]
    } elseif { $ff_len == 11 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_8_ffs [lrange $ff_list 2 end-1]
    } elseif { $ff_len == 12 } {
      merge_4_ffs [lrange $ff_list 0 3]
      merge_8_ffs [lrange $ff_list 4 end]
    } elseif { $ff_len == 13 } {
      merge_4_ffs [lrange $ff_list 0 3]
      merge_8_ffs [lrange $ff_list 4 end-1]
    } elseif { $ff_len == 14 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_4_ffs [lrange $ff_list 2 5]
      merge_8_ffs [lrange $ff_list 6 end]
    } elseif { $ff_len == 15 } {
      merge_2_ffs [lrange $ff_list 0 1]
      merge_4_ffs [lrange $ff_list 2 5]
      merge_8_ffs [lrange $ff_list 6 end-1]
    } elseif { $ff_len == 16 } {
      merge_16_ffs $ff_list
    }
    
  }
  puts "NumInstances after merging: [llength [$block getInsts]]"
  puts "Done!"
}
