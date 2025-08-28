## script to build : BUILD.tcl
> tclsh BUILD.tcl <args>

### easy mode - make
```
  make          : generate BD project and run full build  
  make project  : generate BD project only
  make full     : generate full project only
  make image    : run full build, BD project not saved
  run all       : generate BD project and full project separately, and run full build
```

#### Current tool/OS versions:
  - Vivado/Vitis 2025.1
  - Ubuntu 22.04.5 LTS

### TODO: 
- -skipIMP and -skipSYN args will not create the output_products folder, need to check if 
  exists first, create only if NOT exist
- A single module cannot be instantiated twice as two reconfigurable modules. Fix this.

### No spaces allowed in any filenames or folders. Scripts will fail.

### VHDL-2008/2019 now automated. 
  Non-2008/2019 VHDL files can be in the same directories as verilog/systemverilog. Any 
  VHDL-2008/2019 files must be in 2008 or 2019 folders.

### HDL Libraries now automated.
  Any HDL files required to be compiled/synthesized in custom libraries must be in folders
  named "lib_\<library-name>".
  VHDL-2008/2019 must be in 2008 or 2019 folders under the library folder:
  "hdl/lib_MyLibrary/2008/MyFile.vhd"

### Adding submodules
  update bd_gen.tcl, syn.tcl, syn_rm.tcl (if DFX) 

### Versioning ** DESCRIPTION OUT OF DATE **
  Populating git hashes and timestamps is automated. In BUILD.tcl, variable "versionInfo" is 
  manually updated by user per design with instance \<name> of each git hash and timestamp 
  module (user_init_64b,user_init_32b in the "common" submodule). See BUILD.tcl for example, \<name>
  entered by user will be appended with "_git_hash_inst" or "_timestamp_inst", so instantiation in
  the design must be "\<name>_git_hash_inst" and "\<name>_timestamp_inst". If these modules are in 
  separate repos (submodules), the variable contains a column for path to the repo, so the git 
  hash is parsed and populated appropriately.
  Example is for top, bd, scripts, common, other_submodules, etc.  
  My vision: Testing designs on an eval kit, before custom hardware. This would necessitate:  
    - two versions of top (IO will differ)  
    - two versions of BD (PS config and MIO will differ)  
    - scripts and all other reuse submodules will have identifiable versioning.  
  * versioning modules not required, if they don't exist versioning is ignored without error
  * equal number of git hash and timestamp modules are not required. any number of each is permitted
  * standard zynq+ USR_ACCESS is configured at P&R time with build timestamp, separate/independent 
    from this versioning automation. see imp.tcl for the USR_ACCESS config 

### Arguments
```
-clean      : cleans old generated files in scripts folder from previous builds.

-cleanIP    : clean all generated IP products in ip folder.

-noCleanImg : prevents cleaning/moving the output_products folder. Otherwise new builds will 
              rename the previous outputs_products folder to 'outputs_products_previous', and 
              start clean with an empty output_products folder. This function is automatic 
              when using -skipRM(only if DFX project), -skipSYN, -skipIMP arguments.

-skipIP     : skip generating IP, if already generated and no changes have been made.

-skipRM     : (DFX projects only) skip synthesizing RMs if they're already done and no changes
              have been made. This will be skipped automatically if there are no RM* folders 
              (non-DFX project).

-skipBD     : skip generating BD if already done and no changes made.

-skipSYN    : skip synthesis of full design (static if DFX proj), generally for debug, or if 
              only need to run implementation with previous synth DCP.

-skipIMP    : skip implementation and bitstream gen, generally for debug, or just desire other
              steps output products.

-noIP       : run as if there are no IP in the IP/tcl folder (even if there are).  
              * change this to ignoreIP

-ipOnly     : generate non-BD IP and project only. use with no other args.

-noRM       : run as if there are no RMs in the RM* folders (even if there are).  
              * change this to ignoreRM

-RM         : "-RM RM*/<RM_module>.sv" DFX abstract shell partial build for reconfigurable 
              module only. Full build of individual RM up to partial bitstream. Requires 
              initial full build for static region and abstract shell checkpoint.

-proj       : generate BD project only. must be run with -name option.

-full       : generate FULL project with all sources (buildable in GUI). must use with -proj 
              option. for debug or future use cases. will not work with DFX designs - project 
              will be generated but RMs will need to be manually loaded, and PRs will not be 
              configured in project mode. do NOT use -skipSYN with this option (synthesis will
              not be run, but syn.tcl is where the full project is populated)

-name       : name of BD project to be generated, "-name <project-name>". Independent of BD 
              name and BD tcl script name. prepend names with "PRJ" for git ignore.

-BDtcl      : name of BD tcl script. "-BDtcl <bd-script-name>". Default is "top_bd" if not 
              provided. Generally for debug and future. Script name doesn't need to match BD 
              name defined within the script.

-BDName     : name of BD within tcl script. "-BDname <bd-name>". Default is "top_bd" if not 
              provided.

-multBD     : this needs to be added if there are multiple BDs in the design. temporary fix
              for using the above -BDtcl,-BDName args, which implies multiple BD tcl files
              in the BD folder. adding -multBD arg assumes every tcl file in the BD folder
              will be processes and used in the design. without -multBD (default), only 
              a single BD will be used, "top_bd" as default, or BD that is given using the
              -BDtcl and/or -BDName args.

-verbose    : print script tcl for debug. prevent usage of -notrace for vivado commands.

-out        : "-out <output_products-directory-name>". Custom name of directory location for 
              image, dcp's, logs, etc. Default is "output_products" if not provided.  
              prepend custom name with "output_products" for git ignore.

-cfg        : "-cfg <cfg-name>". configuration that combines -name, -BDtcl, -out. requires 
              an existing BD tcl script named "top_bd_<cfg-name>". BD project will be 
              generated with name "PRJ_<cfg-name>". output_products/image folder will be 
              "output_products_<cfg-name>".

-sim        : generate vivado project for simulation only. use with -name.

-release    : "-release <type>". bit/xsa files will be tar/zipped. must be followed by -tar
              or -zip

-gs         : print git status of all repos. no build will run, all other options ignored

-gb         : print git branches of all repos. no build will run, all other options ignored

-debug_clk  : "-debug_clk <clock_name>". force specific debug hub clock. this is useful if ILAs  
              are running on slower clocks, and hw manager is having issues connecting. vivado 
              command: 'connect_debug_port dbg_hub/clk [get_nets $debug_clk]'
              only usable if there are ILAs in the design
```

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

#### Build with BD project PRJ0 already generated, clean and regenerate all IP in ip folder
> tclsh BUILD.tcl -name PRJ0 -skipBD -clean -cleanIP

#### Output products/image in folder "out_1080p_VTPG", name of BD tcl file is "top_bd_1080p_VTPG.tcl", generated BD project "PRJ_1080p_VTPG", no IP external to BD.
> tclsh BUILD.tcl -clean -out out_1080p_VTPG -BDtcl top_bd_1080p_VTPG -name PRJ_1080p_VTPG -noIP

#### With an existing BD tcl script named "top_bd_myBD1.tcl", generate BD project called "PRJ_myBD1", image and output products generated in "output_products_myBD1"
> tclsh BUILD.tcl -clean -cfg myBD1  

> tclsh BUILD.tcl -clean -noIP -cfg custPL_TPG720  
> tclsh BUILD.tcl -clean -noIP -cfg custPL_TPG1080  
> tclsh BUILD.tcl -clean -noIP -name PRJ_custPL_TPG1080 -out output_products_custPL_TPG1080 -BDtcl top_bd_custPL_TPG1080 -skipBD  
> tclsh BUILD.tcl -clean -noIP -name PRJ_custPL_TPG1080 -out out_custPL_TPG1080_addH2 -skipBD  
> tclsh BUILD.tcl -clean -cfg custPL_TPG1080_addsub  
> tclsh BUILD.tcl -clean -name PRJ_custPL_TPG1080_addsub -out output_products_custPL_TPG1080_addsub -skipBD -skipIP  

#### With a full DFX design already run, build a single RM only and generate partial bitstream. BD project and IP already generated. 
> tclsh BUILD.tcl -name PRJ1 -skipIP -skipBD -RM RM1/led_cnt2_D2.sv  
> tclsh BUILD.tcl -name PRJ1 -skipIP -skipBD -RM RM2/2008/led_cnt3_T.vhd  
> tclsh BUILD.tcl -name PRJ1 -skipIP -skipBD -RM RM2/2008/led_cnt3_T.vhd -skipRM  
> tclsh BUILD.tcl -name PRJ1 -skipIP -skipBD -RM RM2/2019/led_cnt3_U.vhd  
> tclsh BUILD.tcl -name PRJ0 -skipIP -skipBD -RM RM2/led_cnt3_vers.sv  
> tclsh BUILD.tcl -name PRJ2 -skipIP -skipBD -RM RM0/i2c_top.sv -clean  
> tclsh BUILD.tcl -name PRJ0 -skipIP -skipBD -RM RM0/i2c_top.sv -clean  
> tclsh BUILD.tcl -name PRJ0 -clean -skipBD -RM RM0/i2c_top.sv  
> tclsh BUILD.tcl -name PRJ0 -clean -skipBD -skipIP -RM RM0/i2c_top.sv
> tclsh BUILD.tcl -clean -name PRJ1 -skipBD -skipIP -RM RM0/i2c_top.sv

#### Build full project will all sources, no IP outside of BD
> tclsh BUILD.tcl -name PRJ2 -noIP -proj -full

#### Generate non-BD IP and project only
> tclsh BUILD.tcl -ipOnly

#### Generate vivado project only for simulation
> tclsh BUILD.tcl -sim -name PRJ_sim

#### MSK DFX tests
> cl;tclsh BUILD.tcl -name PRJ1 -skipBD -skipIP -debug_clk clk100  
> cl;tclsh BUILD.tcl -clean -name PRJ1 -skipIP -skipBD -RM RM0/RM_msk.sv  


#### Misc.
> cl;tclsh BUILD.tcl -name PRJ1 -skipIP -skipBD  
> cl;tclsh BUILD.tcl -name PRJ1 -skipIP -skipBD -RM RM2/led_cnt3_vers.sv  


# DFX
- Nested-DFX not supported.
- RMs must be in folders named RM* in hdl directory.
- * Only the top level RM file in the RM* folder. Multiple variations of each allowed with different filenames. All other necessary files placed in hdl folder or submodules as usual.
- Each RM must have same module/entity name.
- RM folders are parsed to get module/entity names.
- RP instance in static region MUST be named "\<RM_module/entity_name>_inst"
  - Ex. RM0 = "led_cnt_pr", instance in io_top must be "led_cnt_pr_inst".
- Currently, only one full config is built. This will be the 'first' RM for each RP which are sorted ASCII.
  - Empty static is not built, there is an option to enable this in 'imp.tcl' (not tested).
  - All partial bitstreams are generated, in addition to RMs not part of the single full config.
- Abstract shell checkpoints are generated for all RPs. Build new/modified RMs and partial bitsreams with -RM option.
- All HDL types including VHDL-2008/2019. Any 2008/2019 files must be in respective 2008/2019 folders.
- Steps to configure:
  1. Build first as non-DFX full design with RMs in hdl directory (NOT RM folders).
  2. Floorplan RMs and save constraints.
  3. Move RMs to RM folders.
  4. Include blackbox module declarations with RM instantiations, for building static.
  5. Build. First will be static + partials. After this, partials can be built independently.  

#### DFX TODO: 
- A single module cannot be instantiated twice as two reconfigurable modules, due to having  
  the same name. FIX THIS.


# Updates/Changes
- Added automation for multiple distinct BDs. Top/primary BD must be default "top_bd" or use -BDtcl. Works with BDCs as well.
- Added -ipOnly arg.  
- Added automation for versioning modules (git hash / timestamp).  
- Added -release arg to zip/tar xsa/bit files.  
- Added recursive hdl directory/file add:  
  * submods are parsed, 'ip' and 'sw' is skipped
  * 'mdl' and 'tb' folders are for testbenchs and non-synth hdl files only for sim, skipped for synth  
  * 'OFF' and 'OLD' folders are skipped completely, case-sensitive  
  * 'addHDLdirRecurs' proc will add recursively, 'addHDLdir' proc adds dir without recursion 
- Added debug hub clock arg -debug_clk  