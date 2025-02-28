#--------------------------------------------------------------------------------------------------
source tcl/support_procs.tcl

set hdlDir    [lindex $argv 0]
set partNum   [lindex $argv 1]
set simDir    [lindex $argv 2]
set projName  [lindex $argv 3]

create_project $projName -part $partNum -in_memory
set_property TARGET_LANGUAGE Verilog [current_project]
#set_property BOARD_PART <board_part_name> [current_project]
set_property DEFAULT_LIB work [current_project]
set_property SOURCE_MGMT_MODE All [current_project]


set ipDir "../ip"
set xciFiles [glob -nocomplain  $ipDir/**/*.xci]
foreach x $xciFiles {
  set xciRootName [file rootname [file tail $x]]
  read_ip $ipDir/$xciRootName/$xciRootName.xci
  set_property generate_synth_checkpoint false [get_files $ipDir/$xciRootName/$xciRootName.xci]
  generate_target all [get_files $ipDir/$xciRootName/$xciRootName.xci] 
}

addHDLdir $hdlDir
addHDLdir $hdlDir/bd 
addHDLdir $hdlDir/common 
addHDLdir $hdlDir/mdl 
addHDLdir $simDir


set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

#if {!($projName == "DEFAULT_PROJECT")} {save_project_as $projName ../$projName -force}
save_project_as $projName ../$projName -force


