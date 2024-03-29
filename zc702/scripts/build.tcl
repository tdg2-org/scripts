# vivado -mode batch -source build.tcl

set defaultProjName "prj0"

set partNum "xc7z020clg484-1"
set evalKit "xilinx.com:zc702:part0:1.4"

set topEntity "top_bd_wrapper"

set outputDir ../output_products
set hdlDir    ../hdl
set xdcDir    ../xdc 
set simDir    ../sim 

if {"-proj" in $argv} {
  set genProj true;
} else {
  set genProj false;
}

if {"-name" in $argv} {
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

#--------------------------------------------------------------------------------------------------
# project
#--------------------------------------------------------------------------------------------------

create_project $projName -part $partNum -in_memory
set_property target_language Verilog [current_project]
set_property source_mgmt_mode All [current_project] 

set_property BOARD_PART $evalKit [current_project]

# adding xilinx ip lib/repos:
## set ip_dir ../ip
## set repoList [list $ip_dir $fwLibRepo]
## set_property ip_repo_paths $repoList
## update_ip_catalog -rebuild

#--------------------------------------------------------------------------------------------------
# non-BD IP
#--------------------------------------------------------------------------------------------------

## source ip/<some ip>.tcl ;# get commands from gui manually
## set_property generate_synth_checkpoint 0 [get_files <some ip>.xci] ;# for ip instantiated in HDL

if {!$genProj} {
  ## generate_target all [get_files <some ip>.xci]
}

#--------------------------------------------------------------------------------------------------
# HDL source
#--------------------------------------------------------------------------------------------------
set vFiles    [glob -nocomplain $hdlDir/*.v]
set svFiles   [glob -nocomplain $hdlDir/*.sv]
set vhdFiles  [glob -nocomplain $hdlDir/*.vhd]
if {$vFiles=="" && $svFiles=="" && $vhdFiles==""} {
  puts "No files in directory \"$hdlDir\""
}
if {$vFiles !=""} {read_verilog $vFiles}
if {$svFiles !=""} {read_verilog -sv $svFiles}
if {$vhdFiles !=""} {read_verilog $vhdFiles}

#set_property used_in_simulation false [get_files $hdlDir/user_init_64b.sv]
#set_property used_in_simulation false [get_files $hdlDir/user_init_64b_wrapper.v]
#set_property used_in_simulation false [get_files $hdlDir/user_init_64b_wrapper_zynq.v]
#set_property used_in_simulation false [get_files $hdlDir/axil_reg32.v]


#--------------------------------------------------------------------------------------------------
# constraints
#--------------------------------------------------------------------------------------------------
set xdcFiles  [glob -nocomplain $xdcDir/*.xdc]
if {$xdcFiles==""} {
  puts "No files in directory \"$xdcFiles\""
}
if {$xdcFiles !=""} {read_xdc $xdcFiles}


#--------------------------------------------------------------------------------------------------
# sim sources
#--------------------------------------------------------------------------------------------------

##add_files -fileset sim_1 -norecurse $simDir/<TB file>.sv 
##set_property top <TB file> [get_filesets sim_1]
#read_verilog  $simDir/axis_stim_syn_vwrap_tb.sv 
#set_property used_in_synthesis      false [get_files $simDir/axis_stim_syn_vwrap_tb.sv ]


### Below will add the files with non-project commands
#--------------------------------------------------------------------
#set vFiles "";set svFiles "";set vhdFiles "";
#set vFiles    [glob -nocomplain $simDir/*.v]
#set svFiles   [glob -nocomplain $simDir/*.sv]
#set vhdFiles  [glob -nocomplain $simDir/*.vhd]
#if {$vFiles=="" && $svFiles=="" && $vhdFiles==""} {
#  puts "No files in directory \"$simDir\""
#}
#if {$vFiles !=""} {
#  read_verilog $vFiles
#  set_property used_in_synthesis false [get_files $vFiles]
#  set_property used_in_implementation false [get_files $vFiles]
#}
#if {$svFiles !=""} {
#  read_verilog -sv $svFiles
#  set_property used_in_synthesis false [get_files $svFiles]
#  set_property used_in_implementation false [get_files $svFiles]
#}
#if {$vhdFiles !=""} {
#  read_verilog $vhdFiles
#  set_property used_in_synthesis false [get_files $svFiles]
#  set_property used_in_implementation false [get_files $svFiles]
#}

#set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
#--------------------------------------------------------------------


#read_verilog  $simDir/gen_pulse_tb.sv
#set_property used_in_synthesis  false [get_files $simDir/gen_pulse_tb.sv ]
#set_property top gen_pulse_tb [get_filesets sim_1]



if {$genProj} {
  set vFiles "";set svFiles "";set vhdFiles "";
  set vFiles    [glob -nocomplain $simDir/*.v]
  set svFiles   [glob -nocomplain $simDir/*.sv]
  set vhdFiles  [glob -nocomplain $simDir/*.vhd]
  if {$vFiles=="" && $svFiles=="" && $vhdFiles==""} {
    puts "No files in directory \"$simDir\""
  }
  if {$vFiles !=""} {add_files -fileset sim_1 -norecurse $vFiles}
  if {$svFiles !=""} {add_files -fileset sim_1 -norecurse $svFiles}
  if {$vhdFiles !=""} {add_files -fileset sim_1 -norecurse $vhdFiles}

  #add_files -fileset sim_1 -norecurse /media/tony/TDG_512/projects/zc702_temp2/sim/dma_top_tb.sv

  set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
}
#--------------------------------------------------------------------------------------------------
# Debug. Save project & quit. Source BD files manually.
#--------------------------------------------------------------------------------------------------
if {"-no_bd" in $argv} {
  ##set_property -name {xsim.simulate.runtime}            -value {10 us}            -objects [get_filesets sim_1]
  ##set_property -name {xsim.simulate.log_all_signals}    -value {true}             -objects [get_filesets sim_1]
  ##set_property -name {xsim.compile.xvlog.more_options}  -value {-d SIM_SPEED_UP}  -objects [get_filesets sim_1]

  save_project_as $projName ../$projName -force
  close_project
  exit
}

#--------------------------------------------------------------------------------------------------
# <BDC1>
#--------------------------------------------------------------------------------------------------
##set BDC1_bdFile       ".srcs/sources_1/bd/BDC1/BDC1.bd"
##set BDC1_wrapperFile  ".gen/sources_1/bd/BDC1/hdl/BDC1_wrapper.v"
##source ../bd/BDC1.tcl 
##if {!$genProj} {
##  set_property synth_checkpoint_mode None [get_files $BDC1_bdFile]
##}
##
##make_wrapper -files [get_files $BDC1_bdFile] -top ;# leave as top, had issues without...
##read_verilog $BDC1_wrapperFile
##set_property used_in_synthesis      false [get_files $BDC1_wrapperFile]
##set_property used_in_implementation false [get_files $BDC1_wrapperFile]
##set_property source_mgmt_mode All [current_project]

#--------------------------------------------------------------------------------------------------
# <BDC2>
#--------------------------------------------------------------------------------------------------



#--------------------------------------------------------------------------------------------------
# Top level BD
#--------------------------------------------------------------------------------------------------
set bdFile        ".srcs/sources_1/bd/top_bd/top_bd.bd"
set wrapperFile   ".gen/sources_1/bd/top_bd/hdl/top_bd_wrapper.v"

source ../bd/top_bd.tcl 
if {!$genProj} {
  set_property synth_checkpoint_mode None [get_files $bdFile]
}

make_wrapper -files [get_files $bdFile] -top ;# leave as top, had issues without...
read_verilog $wrapperFile
set_property used_in_simulation false [get_files $wrapperFile]
set_property used_in_simulation false [get_files $bdFile]

if {!$genProj} {
  open_bd_design $bdFile
  generate_target all [get_files $bdFile]
}


#--------------------------------------------------------------------------------------------------
# Project Generation
#--------------------------------------------------------------------------------------------------

if {$genProj} {
  # for sim
  ##set_property -name {xsim.simulate.runtime}            -value {10 us}            -objects [get_filesets sim_1]
  ##set_property -name {xsim.simulate.log_all_signals}    -value {true}             -objects [get_filesets sim_1]
  ##set_property -name {xsim.compile.xvlog.more_options}  -value {-d SIM_SPEED_UP}  -objects [get_filesets sim_1]

  ##add_files -fileset sim_1 -norecurse $simDir/<waveforms>.wcfg

  set_property top $topEntity [current_fileset]
  save_project_as $projName ../$projName -force 
}

#--------------------------------------------------------------------------------------------------
# Build
#--------------------------------------------------------------------------------------------------
if {!$genProj} {
  synth_design -top $topEntity -part $partNum
  write_checkpoint -force $outputDir/post_synth
  #report_timing_summary
  #report_power

  opt_design
  place_design
  phys_opt_design
  #write_checkpoint -force $outputDir/post_place

  route_design
  write_checkpoint      -force $outputDir/post_route
  report_timing_summary -file $outputDir/timing_summary_post_route.rpt 
  #report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_route_timing.rpt
  #report_clock_utilization   -file $outputDir/clk_util.rpt                         
  #report_utilization         -file $outputDir/post_route_util.rpt              
  #report_power               -file $outputDir/power.rpt        
  #report_drc                 -file $outputDir/drc.rpt      

  if [expr {[get_property SLACK [get_timing_paths -delay_type min_max]] < 0}] {
    puts "\n *****************************************************************"
    puts " ** TIMING FAILURE - EXIT"
    puts "*******************************************************************\n"
  } else {
    open_checkpoint $outputDir/post_route.dcp 
    ## set githash_cells_path "usr_access_wrapper_inst/git_hash_hdl_inst"

    # Put catch here incase module not present, or name/path is different
    set githash_cells_path [get_cells -hierarchical *user_init_64b_inst*]
    source ./load_git_hash.tcl

    write_checkpoint    -force $outputDir/updated_post_route
    ##write_device_image ;# versal
    write_bitstream     -force $outputDir/$topEntity  ;#may need to add .bit
    write_debug_probes  -force $outputDir/$topEntity  ;#may need to add .ltx
    write_hw_platform   -fixed -force -file $outputDir/$topEntity.xsa ;#may need to add .xsa
  }
  close_project -delete
} else {
  close_project
}

