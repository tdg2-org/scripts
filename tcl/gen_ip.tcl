# vivado command script
# > vivado -mode batch -source gen_ip.tcl -tclargs xczu3eg-sbva484-1-i ../ip -proj

puts "HEREHERE1"
puts [pwd]
set curDir [pwd]

set ipDir   [lindex $argv 0]
set partNum [lindex $argv 1]

cd $ipDir
puts [pwd]


set_part $partNum
set ipProjName "PROJECT"

#set files [glob -nocomplain -tails -directory $ipDir/tcl *.tcl]
#if {"-proj" in $argv} {create_project -force $ipProjName $ipDir/$ipProjName -part $partNum -ip}
#foreach x $files {source $ipDir/tcl/$x}

set files [glob -nocomplain -tails -directory ./tcl *.tcl]
if {"-proj" in $argv} {create_project -force $ipProjName ./$ipProjName -part $partNum -ip}
foreach x $files {source ./tcl/$x}

cd $curDir 

