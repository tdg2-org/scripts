
proc readVhdl {dir {lib work} {tb FALSE}} {
  set     files     [glob -nocomplain -tails -directory $dir *.vhd]
  foreach x $files {
    read_vhdl -library $lib  $dir/$x
    if {$tb} {set_property used_in_synthesis false [get_files $dir/$x]}
    #read_vhdl ‑vhdl2008 $dir/$x
    #read_vhdl ‑vhdl2019 $dir/$x    
  }
}

proc readVerilog {dir {tb FALSE}} {
  set     files     [glob -nocomplain -tails -directory $dir *.v]
  append  files " " [glob -nocomplain -tails -directory $dir *.sv]
  foreach x $files {
    read_verilog  $dir/$x
    if {$tb} {set_property used_in_synthesis false [get_files $dir/$x]}
  }
}
#--------------------------------------------------------------------------------------------------
# 
#--------------------------------------------------------------------------------------------------

set hdlDir    [lindex $argv 0]
set partNum   [lindex $argv 1]
set simDir    [lindex $argv 2]
set projName  [lindex $argv 3]

create_project $projName -part $partNum -in_memory
set_property TARGET_LANGUAGE Verilog [current_project]
#set_property BOARD_PART <board_part_name> [current_project]
set_property DEFAULT_LIB work [current_project]
set_property SOURCE_MGMT_MODE All [current_project]

readVerilog $hdlDir/common 
readVerilog $hdlDir
readVerilog $simDir TRUE

readVhdl $hdlDir crc_lib
readVhdl $simDir sim TRUE


set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

#if {!($projName == "DEFAULT_PROJECT")} {save_project_as $projName ../$projName -force}
save_project_as $projName ../$projName -force


