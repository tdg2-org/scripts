# implementation & bitstream(s)
# includes DFX - multiple RPs
#--------------------------------------------------------------------------------------------------
# proc for P&R commands
#--------------------------------------------------------------------------------------------------
proc place_n_route {name} {
  opt_design
  place_design
  phys_opt_design
  route_design
  # update git hash for every config, TODO: add catch for instance existance
  #set githash_cells_path [get_cells -hierarchical *user_init_64b_inst*]
  #source ./tcl/load_git_hash.tcl
  #report_timing_summary -file $outputDir/dcp/timing_summary_$name.rpt
}

#--------------------------------------------------------------------------------------------------
# main script 
#--------------------------------------------------------------------------------------------------

set RMs       [lindex $argv 0]
set outputDir [lindex $argv 1]
set RPs       [lindex $argv 2]
set RPlen     [lindex $argv 3]
set buildTime [lindex $argv 4]
set MaxRMs    [lindex $argv 5]

set staticDFX false ;# temporary - run empty static build for DFX runs? arg for this option?

if {$RMs==""} {set DFXrun false} else {set DFXrun true}
#--------------------------------------------------------------------------------------------------

#open_checkpoint $outputDir/dcp/static_synth.dcp
open_checkpoint $outputDir/dcp/top_synth.dcp

for {set config 0} {$config < $MaxRMs} {incr config} { ;# skipped if no MaxRMs i.e. no RMs/RPs i.e. no DFX
  set cfgName "CONFIG"
  for {set x 1} {$x < [llength $RPs]} {incr x 2} {
    set curRPinst "[lindex $RPs $x]_inst"
    set curRPdir [lindex $RPs [expr $x-1]]  
    if {[lindex [lindex $RMs $x] $config] == ""} {
      continue  ;# next is empty (no more RMs for this RP), so leave as previous and skip read_checkpoint
    } else {
      set RM [file rootname [lindex [lindex $RMs $x] $config]]
    }
    
    #puts "assembling config RP:$curRPinst in $curRPdir with $RM"
    # check if RP is blackbox. If not, set as blackbox
    set cellProperty [report_property [get_cells $curRPinst] IS_BLACKBOX -return_string]
    #if {[lindex $cellProperty 7] == "0"} index 7 of the return string is the boolean 1/0 denoting if blackbox or not
    if {!([lsearch $cellProperty "0"] == "-1")} {
      update_design   -cell $curRPinst -black_box ;# necessary for subsequent loops after fully populated with RMs in each RP, replacing with new RM must first declare blackbox on the RP
    }
    read_checkpoint -cell $curRPinst $outputDir/dcp/$curRPdir/$curRPdir\_post_synth_$RM.dcp ;# populate RP with next RM synth dcp
    append cfgName "-" $curRPdir\_$RM
  }
  # now have a config all RPs populated with RMs. time to P&R
  place_n_route $cfgName
  # this is where updates necessary if other configurations are desired. currently only one (first) config is built
  if {$config == 0} { ;# this is a full config run so need timestamp and githash
    set githash_cells_path [get_cells -hierarchical *user_init_64b_inst*]                  
    source ./tcl/load_git_hash.tcl                                                             
    set_property BITSTREAM.CONFIG.USR_ACCESS $buildTime [current_design]                   
    write_checkpoint -force $outputDir/dcp/$cfgName.dcp
    if {![file exists $outputDir/bit]} {file mkdir $outputDir/bit} ;# write_bitstream won't create folder even with -force
    write_bitstream -force -no_partial_bitfile $outputDir/bit/$cfgName.bit
  }
  
  #loop thru again for assembled config partials
  for {set x 1} {$x < [llength $RPs]} {incr x 2} {
    set curRPinst "[lindex $RPs $x]_inst"
    set curRPdir [lindex $RPs [expr $x-1]]  
    if {[lindex [lindex $RMs $x] $config] == ""} {
      # next is empty, so leave as previous and skip read_checkpoint
      continue
    } else {
      set RM [file rootname [lindex [lindex $RMs $x] $config]]
      if {![file exists $outputDir/bit/$curRPdir]} {file mkdir $outputDir/bit/$curRPdir}
      write_bitstream -force -cell $curRPinst $outputDir/bit/$curRPdir/$curRPdir\_$RM\_partial.bit
    }
  }
  #puts ""
}
 # DFX full config and partials done. Now only need empty static (don't 'need', maybe add arg if desired)

#open_checkpoint $outputDir/dcp/CONFIG-RM0_led_cnt_A-RM1_led_cnt2_A-RM2_led_cnt3_A.dcp
#--------------------------------------------------------------------------------------------------

# for DFX run, implemented config is already live, so just blackbox every RP and generate bit
# for non-DFX, synth checkpoint is open from above, p&r will be run
if {$DFXrun && $staticDFX} { ;# skip this if empty static not desired for DFX projects
  puts "DFX IMPLEMENTATION STATIC"
  set idx 0
  foreach RP $RPs {
    if {[expr {$idx % 2}] == 0 } {incr idx;continue} else {
      update_design -cell "$RP\_inst" -black_box
      incr idx
    }
  }
  lock_design -level routing                                                        
  set githash_cells_path [get_cells -hierarchical *user_init_64b_inst*]                  
  source ./tcl/load_git_hash.tcl                                                             
  set_property BITSTREAM.CONFIG.USR_ACCESS $buildTime [current_design]                   
  if {![file exists $outputDir/bit]} {file mkdir $outputDir/bit}
  write_bitstream   -force -no_partial_bitfile $outputDir/bit/static ;# static with empty RPs 
  write_checkpoint  -force $outputDir/dcp/static_route.dcp ;# static with empty RPs 
  report_timing_summary -file $outputDir/dcp/timing_summary_static_route.rpt
  report_utilization    -file $outputDir/dcp/utilization_static_route.rpt
} elseif {!$DFXrun} { ;# non-DFX                                                                       
  puts "NON-DFX IMPLEMENTATION"
  place_n_route "top"                                                                  
  set githash_cells_path [get_cells -hierarchical *user_init_64b_inst*]                  
  source ./tcl/load_git_hash.tcl                                                             
  set_property BITSTREAM.CONFIG.USR_ACCESS $buildTime [current_design]                   
  if {![file exists $outputDir/bit]} {file mkdir $outputDir/bit}
  write_bitstream   -force -no_partial_bitfile $outputDir/bit/top                            
  write_checkpoint  -force $outputDir/dcp/top_route.dcp ;# complete checkpoint if non-DFX run 
  report_timing_summary -file $outputDir/dcp/timing_summary_top_route.rpt
  report_utilization    -file $outputDir/dcp/utilization_top_route.rpt
}

# this may need updates - what if ILAs inside RPs...?
write_debug_probes  -force $outputDir/ila_probes

# what if RPs include AXI I/Fs? difference between static and configs? Shouldn't be...
write_hw_platform   -fixed -force $outputDir/platform.xsa


#--------------------------------------------------------------------------------------------------
# If DFX, at least one full configuration, and empty static...
#if {$DFXrun} {
#  open_checkpoint $outputDir/dcp/config_1_routed.dcp 
#  update_design     -cell $rpCell -black_box  
#  lock_design       -level routing            
#} else {
#  open_checkpoint $outputDir/dcp/static_synth.dcp    
#  place_n_route "static"                      
#}

###report_timing_summary -file $outputDir/dcp/timing_summary_static_route.rpt
#report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/dcp/static_route_timing.rpt
#report_clock_utilization   -file $outputDir/dcp/static_route_clk_util.rpt
#report_utilization         -file $outputDir/dcp/static_route_post_route_util.rpt
#report_power               -file $outputDir/dcp/static_route_power.rpt
#report_drc                 -file $outputDir/dcp/static_route_drc.rpt

###set githash_cells_path [get_cells -hierarchical *user_init_64b_inst*]                  
###source ./tcl/load_git_hash.tcl                                                             
###set_property BITSTREAM.CONFIG.USR_ACCESS $buildTime [current_design]                   
###write_bitstream   -force -no_partial_bitfile $outputDir/static                            
###write_checkpoint  -force $outputDir/dcp/static_route.dcp ;# complete checkpoint if non-DFX run 


#  open_checkpoint $outputDir/dcp/post_route.dcp ;# should this be static_route?
#  set githash_cells_path [get_cells -hierarchical *user_init_64b_inst*] ;# do this on the the first (post_route/config1) so later will be based on it...
#  source ./tcl/load_git_hash.tcl
#  # this is just config1 updated with githash, need to do this with static too.
#  # need to do this with static and ALL configs... or they won't have the githash...
#  write_checkpoint -force $outputDir/dcp/static_route_UPDATED.dcp ;



