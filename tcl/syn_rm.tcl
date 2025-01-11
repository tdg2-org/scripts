# Synth RMs OOC, for DFX only.

# Reconfigurable partitions are in the top/full design. Instance name in the full static region.
# Format for $RPs:  RM0 <RP0_module_name> RM1 <RP1_module_name> ... etc.
#                   RM0 led_cnt_pr RM1 led_cnt2_pr RM2 led_cnt3_pr RM4 axil_reg32_2
#
# Reconfigurable module is any module that coincides with a specific RP.
# Format for $RMs:  RM0 {RM0_A.sv RM0_B.sv RM0_C.sv} RM1 {RM1_A.sv RM1_B.sv} ... etc.
#                   RM0 {led_cnt_A.sv led_cnt_B.sv led_cnt_C.sv} RM1 {led_cnt2_A.sv led_cnt2_B.sv led_cnt2_C.sv} RM2 {led_cnt3_A.sv led_cnt3_HH.sv} RM4 {axil_reg32_A.v axil_reg32_B.v}


set hdlDir      [lindex $argv 0]
set partNum     [lindex $argv 1]
set RMs         [lindex $argv 2]
set rmDir       [lindex $argv 3]  ;# output products dir
set RPs         [lindex $argv 4]  ;# module name
set RPlen       [lindex $argv 5]
set RMmodName   [lindex $argv 6]
set RMfname     [lindex $argv 7]
set RMdir       [lindex $argv 8]

# files common to RMs and static in common folder
set     commonFilesVerilog      [glob -nocomplain -tails -directory $hdlDir/common *.v]
append  commonFilesVerilog " "  [glob -nocomplain -tails -directory $hdlDir/common *.sv]

foreach x $commonFilesVerilog {
  read_verilog  $hdlDir/common/$x
}

# DFX partial only
if {$RMmodName != ""} {
  read_verilog $hdlDir/$RMdir/$RMfname
  synth_design -mode out_of_context -top $RMmodName -part $partNum
  write_checkpoint -force $rmDir/dcp/$RMdir/$RMdir\_post_synth_[file rootname $RMfname].dcp
  return ;# done, return from this script
}


# loop through every RM per RP, and synthesize all
for {set idx 0} {$idx <$RPlen} {incr idx} {
  set curRPdir  [lindex $RPs [expr 2*$idx]]
  set curRPmod  [lindex $RPs [expr 2*$idx + 1]]
  set curRMs    [lindex $RMs [expr 2*$idx + 1]]
  puts "\n*** Running $curRPdir, RP module $curRPmod, with RMs: $curRMs ***\n"
  foreach x $curRMs {
    read_verilog $hdlDir/$curRPdir/$x
    synth_design -mode out_of_context -top $curRPmod -part $partNum
    write_checkpoint -force $rmDir/dcp/$curRPdir/$curRPdir\_post_synth_[file rootname $x].dcp
  }
}

