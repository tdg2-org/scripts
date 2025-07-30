#--------------------------------------------------------------------------------------------------
source tcl/support_procs.tcl

set hdlDir    [lindex $argv 0]
set partNum   [lindex $argv 1]
set projName  [lindex $argv 2]
set subMods   [lindex $argv 3]


create_project $projName -part $partNum -in_memory
set_property TARGET_LANGUAGE Verilog [current_project]
#set_property BOARD_PART <board_part_name> [current_project]
set_property DEFAULT_LIB work [current_project]
set_property SOURCE_MGMT_MODE All [current_project]

#--------------------------------------------------------------------------------------------------
# add IP
#--------------------------------------------------------------------------------------------------
set ipDir "../sub/ip"
set xciFiles [glob -nocomplain  $ipDir/**/*.xci]
foreach x $xciFiles {
  set xciRootName [file rootname [file tail $x]]
  read_ip $ipDir/$xciRootName/$xciRootName.xci
  set_property generate_synth_checkpoint false [get_files $ipDir/$xciRootName/$xciRootName.xci]
  generate_target all [get_files $ipDir/$xciRootName/$xciRootName.xci] 
}

#--------------------------------------------------------------------------------------------------
# add main repo hdl (not top - not simulating top file or anyting in top folder)
# adding indiscriminately whether synthesizable or not. this script is meant for sim only
#--------------------------------------------------------------------------------------------------
addHDL $hdlDir SIM
#addHDLdir $hdlDir/bd 
#addHDLdir $hdlDir/mdl 
#addHDLdir $hdlDir/tb 

#--------------------------------------------------------------------------------------------------
# add submodule hdl, any subs in '../sub' directory
# must follow format with hdl,mdl,sim dirs
# skip sw & ip dirs
#--------------------------------------------------------------------------------------------------
foreach entry $subMods {
  set subDir [lindex $entry 2]
  if {[string match "../sub*" $subDir] && $subDir ne "../sub/sw" && $subDir ne "../sub/ip"} {
    addHDL $subDir/hdl SIM
    #addHDLdir $subDir/hdl/bd 
    #addHDLdir $subDir/hdl/mdl 
    #addHDLdir $subDir/hdl/tb
    #addHDLdir $subDir/hdl/rx ;# temporary NEED BETTER WAY, do all folders recursively
  }
}

#--------------------------------------------------------------------------------------------------
# save proj
#--------------------------------------------------------------------------------------------------
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

#if {!($projName == "DEFAULT_PROJECT")} {save_project_as $projName ../$projName -force}
save_project_as $projName ../$projName -force


