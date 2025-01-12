set VivadoPath "/opt/xilinx/Vivado/2023.2"
set VivadoSettingsFile $VivadoPath/settings64.sh

set buildCmd "vivado -mode batch -source cmd_test.tcl -nojournal"

  if {[catch {exec /bin/bash -c "source $VivadoSettingsFile; $buildCmd" >@stdout} cmdErr]} {
    puts "COMMAND ERROR:\n$cmdErr"
    exit;
  }
