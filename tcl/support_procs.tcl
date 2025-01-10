# support procedures

#--------------------------------------------------------------------------------------------------
# Vivado command
#--------------------------------------------------------------------------------------------------
proc vivadoCmd {fileName args} {
  upvar VivadoSettingsFile VivadoSettingsFile
  upvar argv argv
  if {"-verbose" in $argv} {
    set buildCmd "vivado -mode batch -source tcl/$fileName -nojournal -tclargs $args" ;# is there a better way...?
  } else {
    set buildCmd "vivado -mode batch -source tcl/$fileName -nojournal -notrace -tclargs $args" 
  }

  ## sh points to dash instead of bash by default in Ubuntu
  #if {[catch {exec sh -c "source $VivadoSettingsFile; $buildCmd" >@stdout} cmdErr]} 
  if {[catch {exec /bin/bash -c "source $VivadoSettingsFile; $buildCmd" >@stdout} cmdErr]} {
    puts "COMMAND ERROR:\n$cmdErr"
    puts "FAILED in $fileName"
    puts "args : \n$args"
    exit;
  }
}
#--------------------------------------------------------------------------------------------------
# project name follows directly after '-name' input arg
#--------------------------------------------------------------------------------------------------
proc getProjName {} {
  upvar argv argv
  upvar argc argc
  set defaultProjName "DEFAULT_PROJECT"
  if {"-cfg" in $argv} {
    set projNameIdx [lsearch $argv "-cfg"]
    set projNameIdx [expr $projNameIdx + 1]
    if {$projNameIdx == $argc} {
      set projName $defaultProjName
    } else {
      set projName [lindex $argv $projNameIdx]
      set projName "PRJ_$projName"
    }
  } elseif {"-name" in $argv} {
    set projNameIdx [lsearch $argv "-name"]
    set projNameIdx [expr $projNameIdx + 1]
    if {$projNameIdx == $argc} {
      set projName $defaultProjName
    } else {
      set projName [lindex $argv $projNameIdx]
    }
  } else {
    set projName $defaultProjName
  }
  return $projName
}

#--------------------------------------------------------------------------------------------------
# BD tcl script name follows directly after '-BDtcl' input arg
#--------------------------------------------------------------------------------------------------
proc getBDtclName {} {
  upvar argv argv
  upvar argc argc
  set defaultBDtclName "top_bd"
  if {"-cfg" in $argv} {
    set BDtclNameIdx [lsearch $argv "-cfg"]
    set BDtclNameIdx [expr $BDtclNameIdx + 1]
    if {$BDtclNameIdx == $argc} {
      set BDtclName $defaultBDtclName
    } else {
      set BDtclName [lindex $argv $BDtclNameIdx]
      set BDtclName "top_bd_$BDtclName"
    }
  } elseif {"-BDtcl" in $argv} {
    set BDtclNameIdx [lsearch $argv "-BDtcl"]
    set BDtclNameIdx [expr $BDtclNameIdx + 1]
    if {$BDtclNameIdx == $argc} {
      set BDtclName $defaultBDtclName
    } else {
      set BDtclName [lindex $argv $BDtclNameIdx]
    }
  } else {
    set BDtclName $defaultBDtclName
  }
  return $BDtclName
}

#--------------------------------------------------------------------------------------------------
# BD name follows directly after '-BDName' input arg
#--------------------------------------------------------------------------------------------------
proc getBDName {} {
  upvar argv argv
  upvar argc argc
  set defaultBDName "top_bd"
  if {"-BDName" in $argv} {
    set BDNameIdx [lsearch $argv "-BDName"]
    set BDNameIdx [expr $BDNameIdx + 1]
    if {$BDNameIdx == $argc} {
      set BDName $defaultBDName
    } else {
      set BDName [lindex $argv $BDNameIdx]
    }
  } else {
    set BDName $defaultBDName
  }
  return $BDName
}

#--------------------------------------------------------------------------------------------------
# output products/image directory follows after '-out' input arg. default if not provided
#--------------------------------------------------------------------------------------------------
proc getOutputDir {} {
  upvar argv argv
  upvar argc argc
  set defaultOutputDir "output_products"
  if {"-cfg" in $argv} {
    set outDirIdx [lsearch $argv "-cfg"]
    set outDirIdx [expr $outDirIdx + 1]
    if {$outDirIdx == $argc} {
      set outDirName $defaultOutputDir
    } else {
      set outDirName [lindex $argv $outDirIdx]
      set outDirName "output_products_$outDirName"
    }
  } elseif {"-out" in $argv} {
    set outDirIdx [lsearch $argv "-out"]
    set outDirIdx [expr $outDirIdx + 1]
    if {$outDirIdx == $argc} {
      set outDirName $defaultOutputDir
    } else {
      set outDirName [lindex $argv $outDirIdx]
    }
  } else {
    set outDirName $defaultOutputDir
  }
  return "../$outDirName"
}

#--------------------------------------------------------------------------------------------------
# 
#--------------------------------------------------------------------------------------------------
proc buildTimeEnd {} {
  upvar startTime startTime
  upvar buildTimeStamp buildTimeStamp
  upvar ghash_msb ghash_msb
  upvar outputDir outputDir
  upvar projName projName
  upvar topBDtcl topBDtcl
  upvar topBD topBD

  set endTime     [clock seconds]
  set buildTime   [expr $endTime - $startTime]
  set buildMin    [expr $buildTime / 60]
  set buildSecRem [expr $buildTime % 60]
  
  puts "\n------------------------------------------"
  puts "** BUILD COMPLETE ** $buildTimeStamp\_$ghash_msb\n"
  puts "Output products directory : $outputDir"
  puts "BD project name           : $projName"
  puts "BD project tcl script     : $topBDtcl.tcl"
  puts "BD name                   : $topBD"
  puts "\nTimestamp: $buildTimeStamp"
  puts "Git Hash: $ghash_msb"
  puts "\nBuild Time: $buildMin min:$buildSecRem sec"
  puts "------------------------------------------"

}

#--------------------------------------------------------------------------------------------------
# parse log file for Xilinx generated TIMESTAMP
#--------------------------------------------------------------------------------------------------
proc getTimeStampXlnx {} {
  set searchVal "Overwriting \"TIMESTAMP\" with"
  set trimRVal "\" for option USR_ACCESS"
  set timeStampVal "FFFFFFFF"
  catch {set fid [open vivado.log r]}
  while {[gets $fid line] > -1} {
    set idx [string first $searchVal $line 0]
    if {$idx > -1} {
      set timeStampVal [string range $line 30 37]
    }
  }
  close $fid
  return $timeStampVal
}

#--------------------------------------------------------------------------------------------------
# 
#--------------------------------------------------------------------------------------------------
proc getGitHash {} {
  if {[catch {exec git rev-parse HEAD}]} {
    set ghash_msb "GIT_ERROR"
  } else {
    set git_hash  [exec git rev-parse HEAD]
    set ghash_msb [string range $git_hash 0 7]
  }
  return [string toupper $ghash_msb]
}

#--------------------------------------------------------------------------------------------------
# cleans old generated files prior to build if previous failed/exited abnormaly
#--------------------------------------------------------------------------------------------------
proc cleanProc {} {
  puts "\nCLEANING TEMP FILES"
  set dirs2Clean ".tmpCRC .Xil .srcs .gen hd_visual clockInfo.txt"
  append files2Clean [glob -nocomplain *.log] " " [glob -nocomplain *.jou] $dirs2Clean
  foreach x $files2Clean {file delete -force $x}
}

#--------------------------------------------------------------------------------------------------
# moves generated files into output dir at end of successful build
#--------------------------------------------------------------------------------------------------
proc endCleanProc {} {
  upvar outputDir outputDir
  set cleanFiles "tight_setup_hold_pins.txt cascaded_blocks.txt wdi_info.xml clockInfo.txt hd_visual"
  # append will not add spaces automatically, so must add them manually
  append cleanFiles " " [glob -nocomplain *.log] " " [glob -nocomplain *.jou]
  file mkdir $outputDir/gen
  foreach x $cleanFiles {
    if {[file exists $x]} {
      #file rename -force $x $outputDir/gen/$x
      if {[catch {file rename -force $x $outputDir/gen/$x} err]} {
        puts "WARNING. Problem in endCleanProc: $err"
      }
    }
  }
}
#--------------------------------------------------------------------------------------------------
# If output_products exists from previous build, keep and rename to previous, delete old previous
#--------------------------------------------------------------------------------------------------
proc outputDirGen {} {
  upvar outputDir outputDir
  upvar buildTimeStamp timeStampVal
  upvar ghash_msb ghash_msb
  upvar TOP_ENTITY TOP_ENTITY
  upvar RPs RPs 

  if {[file exists $outputDir]} {
    append newOutputDir $outputDir "_previous"
    file delete -force $newOutputDir
    file rename -force $outputDir $newOutputDir
  }
  file mkdir $outputDir
  set buildFolder $timeStampVal\_$ghash_msb
  file mkdir $outputDir/$buildFolder

  return "$outputDir/$buildFolder"
}

#--------------------------------------------------------------------------------------------------
# TODO: not tested this won't work yet
# need 
#--------------------------------------------------------------------------------------------------
proc packageImage {} {
  upvar outputDir outputDir
  upvar imageFolder imageFolder
  
  puts "packageImage WONT WORK YET, FIX IT **************";exit;
  
  # Stop and exit if no xsa
  if {![file exists $outputDir/$TOP_ENTITY.xsa]} {puts "ERROR: $TOP_ENTITY.xsa not found!";exit}

  set bitFiles [glob -nocomplain *.bit]
  foreach x $bitFiles {
    file rename -force $outputDir/$x $outputDirImage/$buildFolder/$TOP_ENTITY.bit
  }

  ###catch {file rename -force $outputDir/$TOP_ENTITY.ltx $outputDirImage/$buildFolder/$TOP_ENTITY.ltx}
  ###catch {file rename -force $outputDir/$TOP_ENTITY.bit $outputDirImage/$buildFolder/$TOP_ENTITY.bit}
  ###catch {file rename -force $outputDir/$TOP_ENTITY.xsa $outputDirImage/$buildFolder/$TOP_ENTITY.xsa}

}

#--------------------------------------------------------------------------------------------------
# get time custom, same format as xilinx USR_ACCESS TIMESTAMP 
#--------------------------------------------------------------------------------------------------
proc getTimeStamp {startTime} {
  # Get the current time
  #set now [clock seconds]
  set now $startTime

  # Extract date and time components and convert to integers
  scan [clock format $now -format %d] %d dayNum
  scan [clock format $now -format %m] %d monthNum
  scan [clock format $now -format %Y] %d yearNum
  scan [clock format $now -format %H] %d hourNum
  scan [clock format $now -format %M] %d minuteNum
  scan [clock format $now -format %S] %d secondNum

  # Adjust the components as per your requirements
  set day    [expr {$dayNum}]            ;# Days from 1 to 31 (5 bits)
  set month  [expr {$monthNum}]          ;# Months from 1 to 12 (4 bits)
  set year   [expr {$yearNum - 2000}]    ;# Years from 0 to 63 (6 bits)
  set hour   $hourNum                    ;# Hours from 0 to 23 (5 bits)
  set minute $minuteNum                  ;# Minutes from 0 to 59 (6 bits)
  set second $secondNum                  ;# Seconds from 0 to 59 (6 bits)

  # Ensure all values are within their expected ranges
  foreach {var maxVal} {
      day    31
      month  12
      year   63
      hour   23
      minute 59
      second 59
  } {
      if {[set $var] > $maxVal || [set $var] < 0} {
          error "$var is out of range (0-$maxVal). getTime proc in support_procs.tcl";exit
      }
  }

  # Calculate the final 32-bit value by shifting and masking components
  set finalValue [expr {
      ((($day & 0x1F)    << 27) |
      (($month  & 0xF)   << 23) |
      (($year   & 0x3F)  << 17) |
      (($hour   & 0x1F)  << 12) |
      (($minute & 0x3F)  << 6)  |
      ($second  & 0x3F))
  }]
  
  return [format "%08X" $finalValue]
}

#--------------------------------------------------------------------------------------------------
# helper for getDFXconfigs
# parse hdl file to get module name
#--------------------------------------------------------------------------------------------------
proc findModuleName {fileName} {
  set fid [open $fileName r]
  set text [read $fid] 
  close $fid 
  if {[regexp -nocase {module\s+(\S+)} $text match moduleName]} {
    return $moduleName
  } else {
    error "ERROR parsing for module name in $fileName. EXITING"
  }
}

#--------------------------------------------------------------------------------------------------
# helper for getDFXconfigs
# every RM hdl file in a DFX directory (RM*,) must have identical module names. This verifies
#--------------------------------------------------------------------------------------------------
proc verifyModuleNames {moduleList} {
  if {[llength $moduleList] <= 1} {return} ;# only one module so just return
  set firstFile [lindex $moduleList 0] 
  foreach modFile $moduleList {
    if {$modFile ne $firstFile} {
      error "ERROR: each module name in RM directories must be identical."
    }
  }
  return
}

#--------------------------------------------------------------------------------------------------
# get RPs, RMs, RP instance(s), etc.
# parse RM* folders, each folder representing individual RPs
#   -get RM name from file parsing each file in RM*
#   -verify all modules same name, error if not
#   -if no RM folders, or empty, no DFX
#   - get RP name as RM name concat with "_inst"
#       search static design for RP name to verify? or just assume...?
#       > get_cells -hierarchical *module_name_inst*
#       easy when in top file. needs to work in lower level instances
# 
# return/set rpCell, RMs, RPs
#   need to loop through RPs (multiple DFX regions)
#--------------------------------------------------------------------------------------------------
proc getDFXconfigs {} {
  upvar hdlDir hdlDir
  upvar RMs RMs
  upvar RPs RPs 
  upvar RPlen RPlen
  upvar MaxRMs MaxRMs
  # first get all directories in hdl that have 'RM*' name
  set RMDirs [glob -nocomplain -tails -directory $hdlDir -type d RM*]
  if {$RMDirs==""} {return} ;# no RMs therefore no DFX - DONE

  # now search each RM Dir to get RMs for each
  foreach x $RMDirs {
    set     filesVerilog      [glob -nocomplain -tails -directory $hdlDir/$x *.v]
    append  filesVerilog " "  [glob -nocomplain -tails -directory $hdlDir/$x *.sv]
    set filesVerilog [lsort $filesVerilog]
    set rmModName ""
    foreach vFile $filesVerilog {
      append rmModName " " [findModuleName $hdlDir/$x/$vFile] ;# parse file for module name
    }
    verifyModuleNames $rmModName ;# verify all match otherwise error/quit
    if {[expr {[llength $filesVerilog] > $MaxRMs}]} {set MaxRMs [llength $filesVerilog]} ;# need number of RMs in RP that has the most RMs
    set RParray($x) $filesVerilog 
    set RPname [lindex $rmModName 0]
    set RPinstArray($x) $RPname

  }
  set RMs [lsort -stride 2 -index 0 [array get RParray]]
  set RPs [lsort -stride 2 -index 0 [array get RPinstArray]]
  set RPlen [expr [llength $RMs]/2]
}

#--------------------------------------------------------------------------------------------------
# prep for DFX RM synth runs, before running vivado command 
# this loops through as if running synth, and error/quits if necessary DFX config/arrays are not
# correct. Mostly for debug/check before running actual vivado command - faster for debug
#--------------------------------------------------------------------------------------------------
proc preSynthRMcheck {} {
  upvar RMs RMs
  upvar RPs RPs 
  upvar RPlen RPlen 

  #set RPlen [llength $RMs] 
  if {[expr 2*$RPlen] ne [llength $RPs]} {error "RPs and RMs lengths don't match. EXITING"}
  #set RPlen [expr $RPlen/2]
  #puts $RPlen

  # this loop is just running for the error check. will be repeated in RM synth script with actual build commands
  for {set idx 0} {$idx <$RPlen} {incr idx} {
    set curRPdir  [lindex $RPs [expr 2*$idx]]
    if {$curRPdir ne [lindex $RMs [expr 2*$idx]]} {error "PROBLEM, STOPPING"}
    #set curRPinst [lindex $RPs [expr 2*$idx + 1]]
    #set curRMs    [lindex $RMs [expr 2*$idx + 1]]
    #puts "Running $curRPdir, RP module $curRPinst, with RMs: $curRMs"
  }
}

#--------------------------------------------------------------------------------------------------
# check if non-BD IP exists for this design
#--------------------------------------------------------------------------------------------------
proc getIPs {} {
  upvar ipDir ipDir

  if {![file exists $ipDir]} {return TRUE} ;# if no IP for project, done.
  set files [glob -nocomplain -tails -directory $ipDir/tcl *.tcl]
  if {$files == ""} {return TRUE} ;# no tcl files, done.

  return FALSE
}

#--------------------------------------------------------------------------------------------------
# delete all generated IP & project
#--------------------------------------------------------------------------------------------------
proc cleanIP {} {
  upvar ipDir ipDir
  set files [glob -nocomplain -tails -directory $ipDir *] 
  foreach x $files {
    if {$x == "tcl"} {continue} else {file delete -force $ipDir/$x}
  }
}
