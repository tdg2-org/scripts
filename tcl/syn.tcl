# TODO: - option for NO-BD (fabric only) 
#       - option for multiple separate BDs...

# synth script for non-DFX project, or for static portion of DFX project


#--------------------------------------------------------------------------------------------------
source tcl/support_procs.tcl

set hdlDir      [lindex $argv 0]
set partNum     [lindex $argv 1]
set topBD       [lindex $argv 2]
set topEntity   [lindex $argv 3]
set imageDir    [lindex $argv 4]
set xdcDir      [lindex $argv 5]
set projName    [lindex $argv 6]
set RPs         [lindex $argv 7]
set noIP        [lindex $argv 8]
set genProj     [lindex $argv 9]
set extraBDs    [lindex $argv 10]
set timeStamp   [lindex $argv 11]
set versionInfo [lindex $argv 12]

set_part $partNum

if {$genProj} {create_project $projName -part $partNum -in_memory} ;# only for full project generation

#--------------------------------------------------------------------------------------------------
# read non-BD IP
#--------------------------------------------------------------------------------------------------
# IP must be in ../ip/<ipName>/<ipName>.xci
# IP already generated in the gen_ip.tcl script
if {!$noIP} {
  set ipDir "../ip"
  set xciFiles [glob -nocomplain  $ipDir/**/*.xci]
  foreach x $xciFiles {
    set xciRootName [file rootname [file tail $x]]
    read_ip $ipDir/$xciRootName/$xciRootName.xci
    set_property generate_synth_checkpoint false [get_files $ipDir/$xciRootName/$xciRootName.xci]
    generate_target all [get_files $ipDir/$xciRootName/$xciRootName.xci] 
  }
}
#--------------------------------------------------------------------------------------------------
# read HDL/XDC 
#--------------------------------------------------------------------------------------------------
#set projName "DEFAULT_PROJECT"

# top file synthesized first. there are black box modules (module definitions in addition to instances)
# with these, if the top module that has these black boxes read first, if the actual module is read AFTER, 
# it will overwrite the black box with the ACTUAL module. Otherwise, if the module is read first, then the top 
# file where the module (blackbox) is defined, it will overwrite the actual module read first, and make it an 
# empty black box.
readHDL $hdlDir/top/$topEntity.sv 

# add HDL directories. adds verilog/systemverilog/vhd/vhd-2008/vhd-2019
# see tcl/support_procs.tcl 
addHDLdir $hdlDir
addHDLdir $hdlDir/bd 
addHDLdir $hdlDir/common 

# add submodule hdl directories here
addHDLdir ../sub/common/hdl
addHDLdir ../sub/common/hdl/bd

# constraints
set filesXDC [glob -nocomplain -tails -directory $xdcDir *.xdc]
foreach x $filesXDC {
  read_xdc  $xdcDir/$x
}

#--------------------------------------------------------------------------------------------------
# extra BDs
#--------------------------------------------------------------------------------------------------
foreach extraBDfile $extraBDs {
  # in-memory or saved BD project
  if {$projName == "DEFAULT_PROJECT"} {
    set bdFile        ".srcs/sources_1/bd/$extraBDfile/$extraBDfile.bd"
    set wrapperFile   ".gen/sources_1/bd/$extraBDfile/hdl/$extraBDfile\_wrapper.v"
  } else {
    set bdFile        "../$projName/$projName.srcs/sources_1/bd/$extraBDfile/$extraBDfile.bd"
    set wrapperFile   "../$projName/$projName.gen/sources_1/bd/$extraBDfile/hdl/$extraBDfile\_wrapper.v"
  }

  read_bd $bdFile
  read_verilog $wrapperFile
}

#--------------------------------------------------------------------------------------------------
# TOP BD (primary)
#--------------------------------------------------------------------------------------------------
# in-memory or saved BD project
if {$projName == "DEFAULT_PROJECT"} {
  set bdFile        ".srcs/sources_1/bd/$topBD/$topBD.bd"
  set wrapperFile   ".gen/sources_1/bd/$topBD/hdl/$topBD\_wrapper.v"
} else {
  set bdFile        "../$projName/$projName.srcs/sources_1/bd/$topBD/$topBD.bd"
  set wrapperFile   "../$projName/$projName.gen/sources_1/bd/$topBD/hdl/$topBD\_wrapper.v"
}

read_bd $bdFile
read_verilog $wrapperFile

;# only for full project generation (-proj -full)
if {$genProj} {
  set_property top $topEntity [current_fileset]
  set_property source_mgmt_mode All [current_project]
  save_project_as $projName ../$projName\_FULL -force
  exit; # done. no synth for this
} 
#--------------------------------------------------------------------------------------------------
# synth 
#--------------------------------------------------------------------------------------------------
synth_design -top $topEntity -part $partNum
if {!($RPs=="")} {foreach {ignore RP} $RPs {set_property HD.RECONFIGURABLE true [get_cells $RP\_inst]}}
populateVersion ;# uses variables timeStamp and versionInfo - support_procs.tcl
write_checkpoint -force $imageDir/dcp/top_synth.dcp

