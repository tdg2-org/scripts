#

puts "Retrieved git hash: $git_hash_load"
set ghash_msb [string range $git_hash_load 0 7]
set ghash_lsb [string range $git_hash_load 8 15]
puts "Partial git hash to load: $ghash_msb$ghash_lsb"
#scan %x: read hex val, set as int
set ghash_msb [scan $ghash_msb %x]
set ghash_lsb [scan $ghash_lsb %x]

# set/init each flop
for {set i 0} {$i < 32} {incr i} {
  # bitwise AND, only true if LSB is 1
  set ghash_init_lsb [expr $ghash_lsb & 1]
  # init the flop
  set_property INIT "1'b$ghash_init_lsb" [get_cells ${githash_cells_path}/genblk1[$i].FDRE_inst]
  #shift right
  set ghash_lsb [expr $ghash_lsb >> 1]
}

for {set i 32} {$i < 64} {incr i} {
  set ghash_init_lsb [expr $ghash_msb & 1]
  set_property INIT "1'b$ghash_init_lsb" [get_cells ${githash_cells_path}/genblk1[$i].FDRE_inst]
  set ghash_msb [expr $ghash_msb >> 1]
}

puts "Git Hash Load complete."
