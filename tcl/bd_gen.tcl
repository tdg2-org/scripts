# TODO: full in-memory project option?
#   inherently, this is running in non-project mode, then being saved at the end to disk.
#   however, the syn.tcl script is looking at the saved project, not the in-memory files.
#   need to arrange this and syn.tcl to run full in-memory...
#   if -name is provided: use saved proj, otherwise in-memory only
# - Need to add all xci IP files from the 'ip' folder. This is non-BD IP, however some
# of these may be used in common modules that have wrappers for use in BD, which will
# cause a failure in the BD project if missing. Also, it doesn't hurt just to add them
# to the BD project even if unused. 

# generate block design with associated dependencies
# UG994, UG892
#--------------------------------------------------------------------------------------------------
# procs
#--------------------------------------------------------------------------------------------------

proc readVerilog {dir} {
  set     files     [glob -nocomplain -tails -directory $dir *.v]
  append  files " " [glob -nocomplain -tails -directory $dir *.sv]
  foreach x $files {
    read_verilog  $dir/$x
  }
}

proc readHDL {fname} {
  set fType [file extension $fname]
  if {$fType eq ".v" || $fType eq ".sv"} {
    read_verilog $fname
  } elseif {[string match "2008/*" $fname]} {
    read_vhdl -library work -vhdl2008 $fname
  } elseif {[string match "2019/*" $fname]} {
    read_vhdl -library work -vhdl2019 $fname
  } else {
    read_vhdl -library work $fname
  }
}

proc getHDLfiles {dir} {
  set     filesHDL      [glob -nocomplain -tails -directory $dir *.v]
  append  filesHDL  " " [glob -nocomplain -tails -directory $dir *.sv]
  append  filesHDL  " " [glob -nocomplain -tails -directory $dir *.vhd]
  return $filesHDL
}

#--------------------------------------------------------------------------------------------------
# main script 
#--------------------------------------------------------------------------------------------------

set hdlDir    [lindex $argv 0]
set partNum   [lindex $argv 1]
set bdDir     [lindex $argv 2]
set projName  [lindex $argv 3]
set topBD     [lindex $argv 4]
set topBDtcl  [lindex $argv 5]

#set_part $partNum ;# might not need this
create_project $projName -part $partNum -in_memory
set_property TARGET_LANGUAGE Verilog [current_project]
#set_property BOARD_PART <board_part_name> [current_project]
set_property DEFAULT_LIB work [current_project]
set_property SOURCE_MGMT_MODE All [current_project]

#readVerilog $hdlDir/bd 
#readVerilog $hdlDir/common 

set filesHDL  [getHDLfiles $hdlDir/bd]
foreach x $filesHDL {readHDL  $hdlDir/bd/$x}

set filesHDL  [getHDLfiles $hdlDir/common]
foreach x $filesHDL {readHDL  $hdlDir/common/$x}

set filesHDL  [getHDLfiles $hdlDir/bd/2008]
foreach x $filesHDL {readHDL  $hdlDir/bd/2008/$x}

set filesHDL  [getHDLfiles $hdlDir/common/2008]
foreach x $filesHDL {readHDL  $hdlDir/common/2008/$x}

set filesHDL  [getHDLfiles $hdlDir/bd/2019]
foreach x $filesHDL {readHDL  $hdlDir/bd/2019/$x}

set filesHDL  [getHDLfiles $hdlDir/common/2019]
foreach x $filesHDL {readHDL  $hdlDir/common/2019/$x}


source $bdDir/$topBDtcl.tcl

# add XCI files here from IP folder

#--------------------------------------------------------------------------------------------------
# TODO: have option to to full in-memory build. Also build with already generated BD project:
# in-memory : ".srcs/..."
# project   : ../$projName/$projName.srcs/...
#   both need to work during later implementation...
#--------------------------------------------------------------------------------------------------
set bdFile        ".srcs/sources_1/bd/$topBD/$topBD.bd"
set wrapperFile   ".gen/sources_1/bd/$topBD/hdl/$topBD\_wrapper.v"

make_wrapper -files [get_files $bdFile] -top
read_verilog $wrapperFile
set_property synth_checkpoint_mode None [get_files $bdFile]
generate_target all [get_files $bdFile]

# for HLS module
#compile_c [get_ips -all *v_tpg*]
foreach ip_in_proj [get_ips] {compile_c [get_ips $ip_in_proj]}

set_property top [file rootname [file tail $wrapperFile]] [current_fileset]  

# if no -name arg is provided, BD proj not saved
if {!($projName == "DEFAULT_PROJECT")} {save_project_as $projName ../$projName -force}

