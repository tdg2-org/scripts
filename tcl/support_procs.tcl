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
proc getBDs {} {
  upvar argv argv
  upvar argc argc
  upvar bdDir bdDir
  upvar extraBDs extraBDs
  set defaultTopBDName "top_bd"
  if {"-BDName" in $argv} {
    set BDNameIdx [lsearch $argv "-BDName"]
    set BDNameIdx [expr $BDNameIdx + 1]
    if {$BDNameIdx == $argc} {
      set topBDName $defaultTopBDName
    } else {
      set topBDName [lindex $argv $BDNameIdx]
    }
  } else {
    set topBDName $defaultTopBDName
  }

  # get all BD tcl files
  set extraBDs [glob -nocomplain -tails -directory $bdDir *.tcl]
  # strip tcl extension
  set extraBDs [lmap file $extraBDs {file rootname $file}]
  # remove top BD from list
  set index [lsearch -exact $extraBDs $topBDName]
  if {$index != -1} { 
    set extraBDs [lreplace $extraBDs $index $index]
  } else {
    puts "ERROR: Top level BD ($topBDName) not found in $bdDir. Quitting."
    exit
  }
  
  return $topBDName
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
# End of build print info
#--------------------------------------------------------------------------------------------------
proc buildTimeEnd {} {
  upvar startTime startTime
  upvar buildTimeStamp buildTimeStamp
  upvar ghash_msb ghash_msb
  upvar outputDir outputDir
  upvar projName projName
  upvar topBDtcl topBDtcl
  upvar topBD topBD
  upvar RMfname RMfname
  upvar RMmodName RMmodName
  upvar RMdir RMdir

  set endTime     [clock seconds]
  set buildTime   [expr $endTime - $startTime]
  set buildMin    [expr $buildTime / 60]
  set buildSecRem [expr $buildTime % 60]
  
  puts "\n------------------------------------------"
  if {$RMdir != ""} {
    puts "** DFX Partial BUILD COMPLETE **"
    puts "RM File Name    : $RMfname"
    puts "RM Module Name  : $RMmodName"
    puts "RM Directory    : $RMdir\n"
  } else {
    puts "** BUILD COMPLETE ** $buildTimeStamp\_$ghash_msb\n"
  }
  puts "Output products directory : $outputDir"
  if {$projName == "DEFAULT_PROJECT"} {
    puts "BD project name           : in_memory (not saved)"
  } else {
    puts "BD project name           : $projName"
  }
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
    set ghash_msb [string range $git_hash 0 15]
  }
  return [string toupper $ghash_msb]
}

#--------------------------------------------------------------------------------------------------
# Populates the versionInfo list with git hashes
#--------------------------------------------------------------------------------------------------
proc updateVersionInfo {} {
  upvar versionInfo versionInfo
  set idx 0;
  foreach vList $versionInfo {
    set curDir [pwd]
    cd [lindex $vList 2]
    set ghash [getGitHash]
    lset versionInfo $idx [lset vList 0 $ghash]
    incr idx 
    cd $curDir
  }
}

#--------------------------------------------------------------------------------------------------
# Populates the instances with git hash & timestamps. used on synthesized design
# used in syn.tcl, syn_rm.tcl.
# Requires versionInfo, timeStamp
#--------------------------------------------------------------------------------------------------
proc populateVersion {} {
  upvar versionInfo versionInfo
  upvar timeStamp timeStamp
  # if versionInfo is empty, this will be skipped.
  foreach verList $versionInfo {
    # git hash
    set initFF_data  [lindex $verList 0]
    set initFF_cells_path [get_cells -hierarchical *[lindex $verList 1]_git_hash_inst*] ;# append "_git_hash_inst" for git hash instance
    if {$initFF_cells_path != ""} {source ./tcl/initFF64.tcl}
    # timestamp
    set initFF_data $timeStamp
    set initFF_cells_path [get_cells -hierarchical *[lindex $verList 1]_timestamp_inst*] ;# append "_timestamp_inst" for timestamp instance
    if {$initFF_cells_path != ""} {source ./tcl/initFF32.tcl}
  }
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
# parse hdl file to get vhdl entity name
#--------------------------------------------------------------------------------------------------
proc findEntityName {fileName} {
  set fid [open $fileName r]
  set text [read $fid] 
  close $fid 
  if {[regexp -nocase {entity\s+(\S+)} $text match moduleName]} {
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
  upvar argv argv
  upvar argc argc
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
    set     filesVhdl         [glob -nocomplain -tails -directory $hdlDir/$x *.vhd]
    set     filesVhdl2008     [glob -nocomplain -tails -directory $hdlDir/$x/2008 *.vhd]
    set     filesVhdl2019     [glob -nocomplain -tails -directory $hdlDir/$x/2019 *.vhd]

    set result [list]
    foreach file $filesVhdl2008 {lappend result "2008/$file"}
    append  filesVhdl     " " $result

    set result [list]
    foreach file $filesVhdl2019 {lappend result "2019/$file"}
    append  filesVhdl     " " $result

    set     filesVerilog      [glob -nocomplain -tails -directory $hdlDir/$x *.v]
    append  filesVerilog  " " [glob -nocomplain -tails -directory $hdlDir/$x *.sv]
    set filesVerilog  [lsort $filesVerilog]
    set filesVhdl     [lsort $filesVhdl]
    set rmModName ""
    foreach vFile $filesVerilog {
      append rmModName " " [findModuleName $hdlDir/$x/$vFile] ;# parse file for module name
    }
    foreach vhdFile $filesVhdl {
      append rmModName " " [findEntityName $hdlDir/$x/$vhdFile] ;# parse file for entity name
    }
    verifyModuleNames $rmModName ;# verify all match otherwise error/quit
    set filesHDL $filesVerilog
    append filesHDL " " $filesVhdl
    if {[expr {[llength $filesHDL] > $MaxRMs}]} {set MaxRMs [llength $filesHDL]} ;# need number of RMs in RP that has the most RMs
    set RParray($x) $filesHDL 
    set RPname [lindex $rmModName 0]
    set RPinstArray($x) $RPname

  }
  set RMs [lsort -stride 2 -index 0 [array get RParray]]
  set RPs [lsort -stride 2 -index 0 [array get RPinstArray]]
  set RPlen [expr [llength $RMs]/2]

  #puts "RMs: $RMs"
  #puts "RPs: $RPs"

  # partial run only
  if {("-RM" in $argv)} {
    upvar RMfname RMfname
    upvar RMmodName RMmodName
    upvar RMdir RMdir
    getRMabstract
  }
}

#--------------------------------------------------------------------------------------------------
# single RM build, partial bit, abstract shell
#--------------------------------------------------------------------------------------------------
proc getRMabstract {} {
  upvar RMs RMs
  upvar RPs RPs 
  upvar argv argv
  upvar argc argc
  upvar RMfname RMfname
  upvar RMmodName RMmodName
  upvar RMdir RMdir

  set RMidx [lsearch $argv "-RM"]
  set RMidx [expr $RMidx + 1]
  if {$RMidx == $argc} {
    puts "ERROR in proc getRMabstract";exit; # this will only occur if -RM is last arg with nothing following
  } else {
    set RMvalue [lindex $argv $RMidx]
  }

  # split the dir and filename
  set RMdir  [string range $RMvalue 0 [expr {[string first "/" $RMvalue] - 1}]]
  set RMfname [string range $RMvalue [expr {[string first "/" $RMvalue] + 1}] end]

  # now search RMs and get the index of the file list that the user entered file falls under
  set RMidx -1;# reuse var
  set index 0 
  foreach rmVal $RMs {
    if {[lsearch $rmVal $RMfname] != -1} {
      set RMidx $index
      break
    }
    incr index
  }
  
  if {$RMidx == -1} {
    puts "ERROR in proc getRMabstract. Can't find RM file: $RMfname";exit;
  } else {
    set RMdirCheck [lindex $RMs [expr $RMidx - 1]]
    set RPdirCheck [lindex $RPs [expr $RMidx - 1]]
  }

  # error checking. the RM* directory entered by the user must be equal to what is parsed and set in RMs and RPs
  # and it must coincide with the correct file found in RMs
  if {!($RMdirCheck == $RMdir && $RPdirCheck == $RMdir)} {
    puts "ERROR in proc getRMabstract. RMdir ($RMdir) not matching values in RMs/RPs";exit;
  }

  # if the above error checks pass, this should too
  set RMmodName [lindex $RPs [expr $RMidx]]

  #puts "RMfname: $RMfname"
  #puts "RMmodName: $RMmodName"
  #puts "RMdir: $RMdir"
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

#--------------------------------------------------------------------------------------------------
# Procs for reading HDL
#--------------------------------------------------------------------------------------------------
# single file read_vhdl or read_verilog
proc readHDL {fname {lib "work"}} {
  set debug 0
  set fType [file extension $fname]
  if {$fType eq ".v"} {
    if {$debug} {puts "VERILOG ADD $fname $lib"}
    read_verilog -library $lib $fname
  } elseif {$fType eq ".sv"} {
    if {$debug} {puts "SYSTEMVERILOG ADD $fname $lib"}
    read_verilog -sv -library $lib $fname
  } elseif {[string match "*2008/*" $fname]} {
    if {$debug} {puts "VHDL-2008 ADD $fname $lib"}
    read_vhdl -library $lib -vhdl2008 $fname
  } elseif {[string match "*2019/*" $fname]} {
    if {$debug} {puts "VHDL-2019 ADD $fname $lib"}
    read_vhdl -library $lib -vhdl2019 $fname
  } else {
    if {$debug} {puts "VHDL ADD $fname $lib"}
    read_vhdl -library $lib $fname
  }
}

# get list of hdl files .v, .sv, .vhd
proc getHDLfiles {dir} {
  set     filesHDL      [glob -nocomplain -tails -directory $dir *.v]
  append  filesHDL  " " [glob -nocomplain -tails -directory $dir *.sv]
  append  filesHDL  " " [glob -nocomplain -tails -directory $dir *.vhd]
  return $filesHDL
}

# get all hdl files including vhd-2008/2019 in a directory
#proc addHDLdir {dir} {
proc addHDLdirFiles {dir {lib "work"}} {
  # .v, .sv, .vhd
  set filesHDL  [getHDLfiles $dir]
  foreach x $filesHDL {readHDL  $dir/$x $lib}
  # vhd-2008
  set filesHDL  [getHDLfiles $dir/2008]
  foreach x $filesHDL {readHDL  $dir/2008/$x $lib}
  # vhd-2019
  set filesHDL  [getHDLfiles $dir/2019]
  foreach x $filesHDL {readHDL  $dir/2019/$x $lib}
}

proc addHDLdir {dir} {
  # add hdl with custom library first
  set libDirs {}
  foreach folder [glob -nocomplain -directory $dir *] {
    if {[file isdirectory $folder] && [string match "*/lib_*" $folder]} {
      lappend libDirs $folder
    }
  }
  
  foreach libDir $libDirs {
    set lib [string range [file tail $libDir] 4 end]
    addHDLdirFiles $libDir $lib
  }
  
  # non-library hdl default 'work'
  addHDLdirFiles $dir
}