# See README.md
# See ../device.info

set VivadoPath  "/opt/xilinx/Vivado"  ;# auto-appended with version. see support_procs.tcl getDeviceInfo

# verify script is sourced from correct directory
set curDir [pwd]
if {[file tail $curDir] ne "scripts"} {
  puts "Script must be sourced from the 'scripts' directory. You are in $curDir. Exiting." 
  exit
}
source tcl/support_procs.tcl
#--------------------------------------------------------------------------------------------------
# get device and tool version from 'device.info' in project repo
#--------------------------------------------------------------------------------------------------
#set partNum             ""  ;# from device.info file. defaults to u96v2 device  
#set vivadoVersion       ""  ;# vivado/vitis version from device.info file. defaults to 2023.2
#set VivadoSettingsFile  ""  ;# auto populated
getDeviceInfo               ;# populates device part and tool version
#--------------------------------------------------------------------------------------------------
# set some vars for use in other sourced scripts
#--------------------------------------------------------------------------------------------------
set TOP_ENTITY  "top_io" ;# top entity name or image/bit file generated name...
set hdlDir      "../hdl"
set simDir      "../hdl/tb"
set ipDir       "../ip"
set xdcDir      "../xdc"
set bdDir       "../bd"
set topBD       [getBDs]          ;# default = "top_bd"
set topBDtcl    [getBDtclName]    ;# default = "top_bd" for top_bd.tcl
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
updateVersionInfo ;# populate git hashes
getArgsInfo       ;# set some vars based on input args


# if BD project / sim or DFX partial only, skip all this
if {!$bdProjOnly && !$simProj && !$RMabstract && !$fullProj && !$ipOnly} {
  if {("-forceCleanImg" in $argv)} {
    set imageFolder [outputDirGen]
  } elseif {("-noCleanImg" in $argv) || ("-skipSYN" in $argv) || ("-skipIMP" in $argv) || \
            ("-skipRM" in $argv) || ("-out" in $argv)} {
    puts "\n** Skipping clean output_products. **"
  } else {
    set imageFolder [outputDirGen]
  }
} else {
  if {$RMabstract} {
    puts "\n*** DFX Partial only ***"
  } else {
    puts "\n*** Generating project only ***"
  }
}

if {"-noIP" in $argv} { set noIP TRUE } else {set noIP [getIPs]};#returns TRUE if there are no IPs
if {"-clean" in $argv} {cleanProc} 
if {"-cleanIP" in $argv} {cleanIP}

#--------------------------------------------------------------------------------------------------
# vivado synth/impl commands
#--------------------------------------------------------------------------------------------------
# Generate non-BD IP
if {!("-skipIP" in $argv) && !$noIP} {
  vivadoCmd "gen_ip.tcl" $ipDir $partNum "-proj" "-gen"
}

# Generate BD
if {!("-skipBD" in $argv) && !$simProj && !$RMabstract && !$ipOnly} {
  vivadoCmd "bd_gen.tcl"  $hdlDir $partNum $bdDir $projName $topBD $topBDtcl \"$extraBDs\" $ipDir \
                          $multipleBDs
}

# Synthesize RMs OOC
if {!("-skipRM" in $argv) && !($RMs == "") && !$bdProjOnly && !$simProj && !$fullProj && !$ipOnly} {
  preSynthRMcheck ;#pre verify RPs/RMs from getDFXconfigs. If this doesn't fail, safe to synth RMs.
  vivadoCmd "syn_rm.tcl"  $hdlDir $partNum \"$RMs\" $outputDir \"$RPs\" $RPlen $RMmodName $RMfname \
                          $RMdir $buildTimeStamp \"$versionInfo\" $noIP
}

# Synthesize full design (static if DFX)
if {!("-skipSYN" in $argv) && !$bdProjOnly && !$simProj && !$RMabstract && !$ipOnly} {
  vivadoCmd "syn.tcl" $hdlDir $partNum $topBD $TOP_ENTITY $outputDir $xdcDir $projName \"$RPs\" \
                      $noIP $fullProj \"$extraBDs\" $buildTimeStamp \"$versionInfo\" $multipleBDs
}

# P&R + bitsream(s)
if {!("-skipIMP" in $argv) && !$bdProjOnly && !$simProj && !$fullProj && !$ipOnly} {
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

# check output_products folder at end
# packageImage

buildTimeEnd
endCleanProc
cleanProc

#close_project -delete

#set_param general.maxThreads <value>

