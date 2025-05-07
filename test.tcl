
set versionInfo ""

set versionInfo [list \
  {"" top       ../           }\
  {"" bd        ../           } 
]

lappend versionInfo {"" common ../sub/common}

puts $versionInfo 
puts "\n"




set filename "../.gitmodules"
set fp [open $filename r]

set currentPath ""
while {[gets $fp line] >= 0} {
  set line [string trim $line]
  if {[string match "path =*" $line]} {
    set currentPath [string trim [string range $line 6 end]]
    # Extract final component of the path
    set name [file tail $currentPath]
    puts "name: $name"
    puts "path: $currentPath"
    lappend versionInfo [list "" $name ../$currentPath]
  }
}
close $fp

puts $versionInfo 
puts "\n"
