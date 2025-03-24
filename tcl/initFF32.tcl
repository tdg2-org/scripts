#

puts "Init data: $initFF_data"
set initFF_msb [string range $initFF_data 0 7]
#scan %x: read hex val, set as int
set initFF_msb [scan $initFF_msb %x]

# set/init each flop
for {set i 0} {$i < 32} {incr i} {
  # bitwise AND, only true if LSB is 1
  set initFF_bit [expr $initFF_msb & 1]
  # init the flop
  set_property INIT "1'b$initFF_bit" [get_cells ${initFF_cells_path}/genblk1[$i].FDRE_inst]
  #shift right
  set initFF_msb [expr $initFF_msb >> 1]
}

puts "*** Initialized $initFF_cells_path to $initFF_msb ***\n"
