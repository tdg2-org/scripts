# See README.md
# See ../device.info

# TODO add this somewhere:   set_param general.maxThreads <value>

set VivadoPath  "/opt/xilinx/Vivado"  ;# auto-appended with version. see support_procs.tcl getDeviceInfo

# verify script is sourced from correct directory
set curDir [pwd]
if {[file tail $curDir] ne "scripts"} {
  puts "Script must be sourced from the 'scripts' directory. You are in $curDir. Exiting." 
  exit
}

source tcl/support_procs.tcl

getDeviceInfo ;# populates device part and tool version from 'device.info' in primary project repo
#--------------------------------------------------------------------------------------------------
# set some vars for use in other sourced scripts
#--------------------------------------------------------------------------------------------------
set TOP_ENTITY  "top_io" ;# top entity name or image/bit file generated name...
set hdlDir      "../hdl"
set simDir      "../hdl/tb"
set ipDir       "../sub/ip"
set xdcDir      "../xdc"
set bdDir       "../bd"
set topBDtcl    [getBDtclName]    ;# default = "top_bd" for top_bd.tcl
set topBD       [getBDs]          ;# default = "top_bd"
set projName    [getProjName]
set outputDir   [getOutputDir]

#--------------------------------------------------------------------------------------------------
# Pre-build stuff
#--------------------------------------------------------------------------------------------------
# custom timestamp function instead of xilinx built-in. This ensures timestamp matches exactly
# across bitstream configs and partials when using PR
set startTime [clock seconds]
set buildTimeStamp [getTimeStamp $startTime]
puts "\n*** BUILD TIMESTAMP: $buildTimeStamp ***\n"
puts "TCL Version : $tcl_version\n"

# cd out of scripts up one level. assumes scripts is a submod in top level primary repo for design.
# get the git hash of this primary design repo
cd ../ 
set ghash_msb [getGitHash]
cd $curDir

getDFXconfigs     ;# auto config DFX. don't touch. will return clean if non-DFX
getSubMods        ;# parse .gitmodules
updateVersionInfo ;# populate git hashes. exits clean if none instantiated in design
getArgsInfo       ;# set some vars based on input args
outputDirGen      ;# generate output products directory

#--------------------------------------------------------------------------------------------------
# vivado synth/impl commands
#--------------------------------------------------------------------------------------------------
# Generate non-BD IP
if {!("-skipIP" in $argv) && !$noIP} {
  vivadoCmd "gen_ip.tcl" $ipDir $partNum "-proj" "-gen"
}

# Generate BD
if {!$skipBD && !$simProj && !$RMabstract && !$ipOnly} {
  vivadoCmd "bd_gen.tcl"  $hdlDir $partNum $bdDir $projName $topBD $topBDtcl \"$extraBDs\" $ipDir \
                          $multipleBDs
}

# Synthesize RMs OOC
if {!$skipRM && !($RMs == "") && !$bdProjOnly && !$simProj && !$fullProj && !$ipOnly} {
  preSynthRMcheck ;#pre verify RPs/RMs from getDFXconfigs. If this doesn't fail, safe to synth RMs.
  vivadoCmd "syn_rm.tcl"  $hdlDir $partNum \"$RMs\" $outputDir \"$RPs\" $RPlen $RMmodName $RMfname \
                          $RMdir $buildTimeStamp \"$versionInfo\" $noIP $ipDir
}

# Synthesize full design (static if DFX)
if {!$skipSYN && !$bdProjOnly && !$simProj && !$RMabstract && !$ipOnly} {
  vivadoCmd "syn.tcl" $hdlDir $partNum $topBD $TOP_ENTITY $outputDir $xdcDir $projName \"$RPs\" \
                      $noIP $fullProj \"$extraBDs\" $buildTimeStamp \"$versionInfo\" $multipleBDs \
                      $ipDir
}

# P&R + bitsream(s)
if {!$skipIMP && !$bdProjOnly && !$simProj && !$fullProj && !$ipOnly} {
  vivadoCmd "imp.tcl" \"$RMs\" $outputDir \"$RPs\" $RPlen $buildTimeStamp $MaxRMs $RMmodName \
                      $RMfname $RMdir
}

# simulation project
if {$simProj} { ;# arg = "-sim"
  vivadoCmd "sim.tcl" $hdlDir $partNum $simDir $projName
}

#--------------------------------------------------------------------------------------------------
# Post-build stuff
#--------------------------------------------------------------------------------------------------

packageImage ;# if -release argv is used, bit/xsa will be tar/zipped
buildTimeEnd
endCleanProc
cleanProc

