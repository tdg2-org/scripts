# Synth RMs OOC, for DFX only.

# Reconfigurable partitions are in the top/full design. Instance name in the full static region.
# Format for $RPs:  RM0 <RP0_module_name> RM1 <RP1_module_name> ... etc.
#                   RM0 led_cnt_pr RM1 led_cnt2_pr RM2 led_cnt3_pr RM4 axil_reg32_2
#
# Reconfigurable module is any module that coincides with a specific RP.
# Format for $RMs:  RM0 {RM0_A.sv RM0_B.sv RM0_C.sv} RM1 {RM1_A.sv RM1_B.sv} ... etc.
#                   RM0 {led_cnt_A.sv led_cnt_B.sv led_cnt_C.sv} RM1 {led_cnt2_A.sv led_cnt2_B.sv led_cnt2_C.sv} RM2 {led_cnt3_A.sv led_cnt3_HH.sv} RM4 {axil_reg32_A.v axil_reg32_B.v}

#--------------------------------------------------------------------------------------------------
# procs
#--------------------------------------------------------------------------------------------------
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

#--------------------------------------------------------------------------------------------------
# main script 
#--------------------------------------------------------------------------------------------------


set hdlDir      [lindex $argv 0]
set partNum     [lindex $argv 1]
set RMs         [lindex $argv 2]
set outputDir   [lindex $argv 3]  ;# output products dir
set RPs         [lindex $argv 4]  ;# module name
set RPlen       [lindex $argv 5]
set RMmodName   [lindex $argv 6]
set RMfname     [lindex $argv 7]
set RMdir       [lindex $argv 8]

set_part $partNum

set     commonFilesHDL      [glob -nocomplain -tails -directory $hdlDir/common *.v]
append  commonFilesHDL  " " [glob -nocomplain -tails -directory $hdlDir/common *.sv]
append  commonFilesHDL  " " [glob -nocomplain -tails -directory $hdlDir/common *.vhd]
foreach x $commonFilesHDL {readHDL  $hdlDir/common/$x}

set  commonFilesHDL2008   [glob -nocomplain -tails -directory $hdlDir/common/2008 *.vhd]
foreach x $commonFilesHDL2008 {readHDL  $hdlDir/common/2008/$x}

set  commonFilesHDL2019   [glob -nocomplain -tails -directory $hdlDir/common/2019 *.vhd]
foreach x $commonFilesHDL2019 {readHDL  $hdlDir/common/2019/$x}

# DFX partial only
# RMmodName will contain 2008/2019 folder for vhdl as part of the filename, if it exists
if {$RMmodName != ""} {
  readHDL $hdlDir/$RMdir/$RMfname
  synth_design -mode out_of_context -top $RMmodName -part $partNum
  set fileRootName [file rootname $RMfname]
  if {[string match "2008/*" $fileRootName]} {set fileRootName [string trimleft $fileRootName "2008/"]}
  if {[string match "2019/*" $fileRootName]} {set fileRootName [string trimleft $fileRootName "2019/"]}
  write_checkpoint -force $outputDir/dcp/$RMdir/$RMdir\_post_synth_$fileRootName.dcp
  return ;# done, return from this script
}

# RMs will contain 2008/2019 folder for vhdl as part of the filename, if it exists
# loop through every RM per RP, and synthesize all
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
    write_checkpoint -force $outputDir/dcp/$curRPdir/$curRPdir\_post_synth_$fileRootName.dcp
  }
}

