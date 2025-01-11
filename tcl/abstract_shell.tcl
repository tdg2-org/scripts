# notes only


# open initial full routed config
# write_abstract_shell for each RP
# 
# write_abstract_shell -cell curRPinst
# 
# led_cnt_pr_inst
# led_cnt2_pr_inst
# led_cnt3_pr_inst
# axil_reg32_2_inst

set_part xczu3eg-sbva484-1-i

#------------------------------------------------------------------------------

open_checkpoint CONFIG-RM0_led_cnt_A-RM1_led_cnt2_A-RM2_led_cnt3_A-RM4_axil_reg32_A.dcp

write_abstract_shell -cell led_cnt_pr_inst    RM0/led_cnt_pr_AbSh
write_abstract_shell -cell led_cnt2_pr_inst   RM1/led_cnt2_pr_AbSh
write_abstract_shell -cell led_cnt3_pr_inst   RM2/led_cnt3_pr_AbSh
write_abstract_shell -cell axil_reg32_2_inst  RM4/axil_reg32_2_AbSh


open_checkpoint led_cnt_pr_AbSh.dcp
read_checkpoint -cell led_cnt_pr_inst RM0/RM0_post_synth_led_cnt_B.dcp
  opt_design
  place_design
  phys_opt_design
  route_design

#write_checkpoint 
# compare the routed version currently in memory (routed with RM version B) to the original AbShel that contained routed RM version A
pr_verify -in_memory -additional led_cnt_pr_AbSh.dcp

write_bitstream -cell led_cnt_pr_inst RM0_B_partial.bit



#------------------------------------------------------------------------------
# create/modify RM

read_verilog ../common/led_cnt.sv
read_verilog led_cnt3_HH.sv

synth_design -mode out_of_context -top led_cnt3_pr -part xczu3eg-sbva484-1-i
write_checkpoint -force ../../output_products/dcp/RM2/RM2_post_synth_led_cnt3_HH.dcp

#------------------------------------------------------------------------------
# build only new RM
# open the absract shell for the RM
open_checkpoint led_cnt3_pr_AbSh.dcp
# load the synth dcp of the RM
read_checkpoint -cell led_cnt3_pr_inst RM2_post_synth_led_cnt3_HH.dcp

  opt_design
  place_design
  phys_opt_design
  route_design

  write_bitstream -force -cell led_cnt3_pr_inst led_cnt3_HH.bit

#------------------------------------------------------------------------------
# New RM or modified RM only, in full BUILD (full design already run once for static region)

tclsh BUILD.tcl -RP led_cnt3_pr -RM led_cnt3_HH.sv RM2  ;# -RP <moduleName> -RM <filename> <RMdir>
tclsh BUILD.tcl -RM RM2/led_cnt3_HH.sv
# this will be partial RP/RM command
# add error checking: -RP / -RM must coincide
#                     each must be compatible with each other
#                     check for full static DCP

# first synth the new/modified module
# syn_rm.tcl, dont loop, just the one module

# RMmodName = led_cnt3_pr   argv
# RMfname = led_cnt3_HH.sv  argv
# RMdir  = RM2  ** need to get this automatically somehow from populated RPs/RMs
if {$RMmodName != ""} {
  read_verilog $hdlDir/$RMdir/$RMfname
  synth_design -mode out_of_context -top $RMmodName -part $partNum
  write_checkpoint -force $rmDir/dcp/$RMdir/$RMdir\_post_synth_[file rootname $RMfname].dcp
}

# skip synth
# imp.tcl
# open abs shell only
#open_checkpoint led_cnt3_pr_AbSh.dcp
open_checkpoint $RMmodName\_AbSh.dcp
#read_checkpoint -cell led_cnt3_pr_inst RM2_post_synth_led_cnt3_HH.dcp
read_checkpoint -cell $RMmodName\_inst $outputDir/dcp/$RMdir\_post_synth_[file rootname $RMfname].dcp
  
  opt_design
  place_design
  phys_opt_design
  route_design

  #write_bitstream -force -cell led_cnt3_pr_inst led_cnt3_HH.bit
  write_bitstream -force -cell $RMmodName\_inst $outputDir/bit/$RMdir/$RMdir\_[file rootname $RMfname]_partial.bit




#------------------------------------------------------------------------------

# Format for $RPs:  RM0 <RP0_module_name> RM1 <RP1_module_name> ... etc.
#                   RM0 led_cnt_pr RM1 led_cnt2_pr RM2 led_cnt3_pr RM4 axil_reg32_2
#
# Reconfigurable module is any module that coincides with a specific RP.
# Format for $RMs:  RM0 {RM0_A.sv RM0_B.sv RM0_C.sv} RM1 {RM1_A.sv RM1_B.sv} ... etc.
#                   RM0 {led_cnt_A.sv led_cnt_B.sv led_cnt_C.sv} RM1 {led_cnt2_A.sv led_cnt2_B.sv led_cnt2_C.sv} RM2 {led_cnt3_A.sv led_cnt3_HH.sv} RM4 {axil_reg32_A.v axil_reg32_B.v}
