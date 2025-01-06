### TODO: 
- -skipIMP and -skipSYN args will not create the output_products folder, need to check if exists first, create only if NOT exist
- Many updates not verified with DFX build, need to test.
- helpMsg needs update.

### No spaces allowed in any filenames or folders. Scripts will fail.

## script to build : BUILD.tcl
> tclsh BUILD.tcl

### Arguments
-clean      : cleans old generated files in scripts folder from previous builds.

-cleanIP    : clean all generated IP products in ip folder.

-noCleanImg : prevents cleaning/moving the output_products folder. Otherwise new builds will rename
              the previous outputs_products folder to 'outputs_products_previous', and start clean 
              with an empty output_products folder. This function is automatic when using 
              -skipRM(only if DFX project), -skipSYN, -skipIMP arguments.

-skipIP     : skip generating IP, if already generated and no changes have been made.

-skipRM     : (DFX projects only) skip synthesizing RMs if they're already done and no changes have
              been made. This will be skipped automatically if there are no RM* folders (non-DFX project).

-skipBD     : skip generating BD if already done and no changes made.

-skipSYN    : skip synthesis of full design (static if DFX proj), generally for debug, or if only need
              to run implementation with previous synth DCP.

-skipIMP    : skip implementation and bitstream gen, generally for debug, or just desire other steps
              output products.

-noIP       : run as if there are no IP in the IP/tcl folder (even if there are).

-noRM       : run as if there are no RMs in the RM* folders (even if there are).

-proj       : generate BD project only. must be run with -name option.

-name       : name of BD project to be generated, "-name \<project-name>". Independent of BD name 
              and BD tcl script name.

-BDtcl      : name of BD tcl script. "-BDtcl \<bd-script-name>". Default is "top_bd" if not provided.
              Generally for debug and future. Script name doesn't need to match BD name defined 
              within the script.

-BDName     : name of BD within tcl script. "-BDname \<bd-name>". Default is "top_bd" if not provided.

-verbose    : print script tcl for debug. prevent usage of -notrace for vivado commands.

-out        : "-out \<output_products-directory-name>". Custom name of directory location for image,
              dcp's, logs, etc. Default is "output_products" if not provided.

-cfg        : "-cfg \<cfg-name>". configuration that combines -name, -BDtcl, -out. requires an 
              existing BD tcl script named "top_bd_\<cfg-name>". BD project will be generated
              with name "PRJ_\<cfg-name>". output_products/image folder will be "output_products_\<cfg-name>".


## Examples / Quick copies
#### Build full design generating new BD project with name PRJ2, and generate IP in the ip folder. This would also build DFX partials if there were any present.
> tclsh BUILD.tcl -clean -name PRJ2

#### Build full design generating new BD project with name PRJ0, there are IP tcl files in IP folder not in use for this design (-noIP).
> tclsh BUILD.tcl -clean -name PRJ0 -noIP

#### Build with BD project PRJ0 already generated, there are IP tcl files in IP folder not in use for this design (-noIP).
> tclsh BUILD.tcl -clean -name PRJ0 -skipBD -noIP

#### Generate BD project only
> tclsh BUILD.tcl -clean -proj -name PRJ1

#### Build with BD project PRJ2 already generated, only up to synth for review of synth dcp.
> tclsh BUILD.tcl -clean -name PRJ2 -skipBD -noIP -skipIMP

#### Build with BD project PRJ2 already generated, skip synth and use previous synth dcp (output_products) to continue with imp.
> tclsh BUILD.tcl -clean -name PRJ2 -skipBD -noIP -skipSYN

#### Generate IP and IP project only
> tclsh BUILD.tcl -clean -skipBD -skipRM -skipSYN -skipIMP

#### Build with BD project PRJ0 already generated, clean and regenerate all IP in ip folder
> tclsh BUILD.tcl -name PRJ0 -skipBD -clean -cleanIP

#### Output products/image in folder "out_1080p_VTPG", name of BD tcl file is "top_bd_1080p_VTPG.tcl", generated BD project "PRJ_1080p_VTPG", no IP external to BD.
> tclsh BUILD.tcl -clean -out out_1080p_VTPG -BDtcl top_bd_1080p_VTPG -name PRJ_1080p_VTPG -noIP

#### With an existing BD tcl script named "top_bd_myBD1.tcl", generate BD project called "PRJ_myBD1", image and output products generated in "output_products_myBD1"
> tclsh BUILD.tcl -clean -cfg myBD1

> tclsh BUILD.tcl -clean -noIP -cfg custPL_TPG720

# DFX
- This version is automated. Verified on U96 with three RPs and three RMs each.
- RMs must be in folders named RM* in hdl directory.
- Each RM must have same module name.
- RM folders are parsed to get module names.
- RP instance in static region MUST be named "\<RM module name>_inst"
  - Ex. RM0 = "led_cnt_pr", instance in io_top must be "led_cnt_pr_inst".
- Currently, only one full config is built. This will be the 'first' RM for each RP which are sorted ASCII.
  - Empty static is not built, there is an option to enable this in 'imp.tcl'.
  - All partial bitstreams are generated.
- No VHDL. Verilog and systemverilog only.
