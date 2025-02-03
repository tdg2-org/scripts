# full build + BD project
build: BUILD.tcl
	tclsh BUILD.tcl -clean -name PRJ_BD

# BD project only
project: BUILD.tcl
	tclsh BUILD.tcl -clean -name PRJ_BD -proj

# generate FULL project only
full: BUILD.tcl
	tclsh BUILD.tcl -clean -name PRJ -proj -full

# image / output_products only, BD project not saved
image: BUILD.tcl
	tclsh BUILD.tcl -clean

# full build + BD project + generate FULL project
all: build full

#
clean:
	rm -rf ../PRJ_BD ../PRJ_FULL ../output_products ../output_products_previous
