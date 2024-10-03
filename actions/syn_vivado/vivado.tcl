# Create a project
create_project -force lint $env(VPU_HOME)/vivado/lint_project -part xcvh1582-vsva3697-2MP-e-S

# Set target board
set_property board_part xilinx.com:vhk158:part0:1.1 [current_project]
set_property target_language Verilog [current_project]
# Read designs
## Source environment variables
set env_map {}
lappend env_map "\${VPU_HOME}" $env(VPU_HOME)

set design_files ""
## Parse the filelist and analyze
set fp [open "$env(VPU_HOME)/design/filelist.f" r]
set data [split [read $fp] "\n"]
foreach line2 $data {
    set line [string map $env_map $line2]
    if {[string first "+incdir" $line] != -1} {
        set words [split $line "+"]
        set inc_path [lindex $words 2]
        lappend search_path $inc_path
    } elseif {[string first ".sv" $line] != -1} {
        lappend design_files $line
    } elseif {[string first ".v" $line] != -1} {
        lappend design_files $line
    }
}

add_files $design_files
source $env(VPU_HOME)/design/xilinx_ip/gen_ip.tcl
synth_design -top $env(DESIGN_TOP) -part xcvh1582-vsva3697-2MP-e-S

quit