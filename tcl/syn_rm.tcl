# Synth RMs OOC, for DFX only.

# Reconfigurable partitions are in the top/full design. Instance name in the full static region.
# Format for $RPs:  RM0 <RP0_module_name> RM1 <RP1_module_name> ... etc.
#                   RM0 led_cnt_pr RM1 led_cnt2_pr RM2 led_cnt3_pr RM4 axil_reg32_2
#
# Reconfigurable module is any module that coincides with a specific RP.
# Format for $RMs:  RM0 {RM0_A.sv RM0_B.sv RM0_C.sv} RM1 {RM1_A.sv RM1_B.sv} ... etc.
#                   RM0 {led_cnt_A.sv led_cnt_B.sv led_cnt_C.sv} RM1 {led_cnt2_A.sv led_cnt2_B.sv led_cnt2_C.sv} RM2 {led_cnt3_A.sv led_cnt3_HH.sv} RM4 {axil_reg32_A.v axil_reg32_B.v}


#--------------------------------------------------------------------------------------------------
source tcl/support_procs.tcl

set hdlDir      [lindex $argv 0]
set partNum     [lindex $argv 1]
set RMs         [lindex $argv 2]
set outputDir   [lindex $argv 3]  ;# output products dir
set RPs         [lindex $argv 4]  ;# module name
set RPlen       [lindex $argv 5]
set RMmodName   [lindex $argv 6]
set RMfname     [lindex $argv 7]
set RMdir       [lindex $argv 8]
set timeStamp   [lindex $argv 9]
set versionInfo [lindex $argv 10]
set noIP        [lindex $argv 11]
set ipDir       [lindex $argv 12]

set_part $partNum

# add HDL directories. adds verilog/systemverilog/vhd/vhd-2008/vhd-2019
# see tcl/support_procs.tcl 
#addHDLdir $hdlDir/common

# add submodule hdl directories here
#addHDLdir ../sub/crc_gen/hdl
addHDLdir ../sub/common/hdl

#--------------------------------------------------------------------------------------------------
# read non-BD IP
#--------------------------------------------------------------------------------------------------
# IP must be in ../ip/<ipName>/<ipName>.xci
# IP already generated in the gen_ip.tcl script
if {!$noIP} {
  #set ipDir "../ip"
  set xciFiles [glob -nocomplain  $ipDir/**/*.xci]
  foreach x $xciFiles {
    set xciRootName [file rootname [file tail $x]]
    read_ip $ipDir/$xciRootName/$xciRootName.xci
    set_property generate_synth_checkpoint false [get_files $ipDir/$xciRootName/$xciRootName.xci]
    generate_target all [get_files $ipDir/$xciRootName/$xciRootName.xci] 
  }
}

#--------------------------------------------------------------------------------------------------
# DFX partial only
# RMmodName will contain 2008/2019 folder for vhdl as part of the filename, if it exists
#--------------------------------------------------------------------------------------------------
if {$RMmodName != ""} {
  readHDL $hdlDir/$RMdir/$RMfname ;# single file only
  synth_design -mode out_of_context -top $RMmodName -part $partNum
  set fileRootName [file rootname $RMfname]
  if {[string match "2008/*" $fileRootName]} {set fileRootName [string trimleft $fileRootName "2008/"]}
  if {[string match "2019/*" $fileRootName]} {set fileRootName [string trimleft $fileRootName "2019/"]}
  populateVersion ;# uses variables timeStamp and versionInfo - support_procs.tcl
  write_checkpoint -force $outputDir/dcp/$RMdir/$RMdir\_post_synth_$fileRootName.dcp
  return ;# done, return from this script
}

#--------------------------------------------------------------------------------------------------
# RMs will contain 2008/2019 folder for vhdl as part of the filename, if it exists
# loop through every RM per RP, and synthesize all
#--------------------------------------------------------------------------------------------------
for {set idx 0} {$idx <$RPlen} {incr idx} {
  set curRPdir  [lindex $RPs [expr 2*$idx]]
  set curRPmod  [lindex $RPs [expr 2*$idx + 1]]
  set curRMs    [lindex $RMs [expr 2*$idx + 1]]
  puts "\n*** Running $curRPdir, RP module $curRPmod, with RMs: $curRMs ***\n"
  foreach x $curRMs {
    readHDL $hdlDir/$curRPdir/$x
    synth_design -mode out_of_context -top $curRPmod -part $partNum
    set fileRootName [file rootname $x]
    if {[string match "2008/*" $fileRootName]} {set fileRootName [string trimleft $fileRootName "2008/"]}
    if {[string match "2019/*" $fileRootName]} {set fileRootName [string trimleft $fileRootName "2019/"]}
    populateVersion ;# uses variables timeStamp and versionInfo - support_procs.tcl
    write_checkpoint -force $outputDir/dcp/$curRPdir/$curRPdir\_post_synth_$fileRootName.dcp
  }
}

