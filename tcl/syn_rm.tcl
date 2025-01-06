# Synth RMs OOC, for DFX only.

set hdlDir      [lindex $argv 0]
set partNum     [lindex $argv 1]
set RMs         [lindex $argv 2]
set rmDir       [lindex $argv 3]  ;# output products dir
set RPs         [lindex $argv 4]  ;# module name
set RPlen       [lindex $argv 5]


# files common to RMs and static in common folder
set     commonFilesVerilog      [glob -nocomplain -tails -directory $hdlDir/common *.v]
append  commonFilesVerilog " "  [glob -nocomplain -tails -directory $hdlDir/common *.sv]

foreach x $commonFilesVerilog {
  read_verilog  $hdlDir/common/$x
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

