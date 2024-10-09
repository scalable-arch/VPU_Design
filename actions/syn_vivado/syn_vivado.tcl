global env_map

# receives a list of filelist (e.g., filelist.f)
# and provide list of files in the filelists
proc get_filename_arr {filelists env} {
    global search_path
    global defines 
    set results {}

    foreach filelist $filelists {
        set fp [open $filelist r]
        set lines [split [read $fp] "\n"]
        foreach line $lines {
            set line2 [string map $env $line]
            if {[string first "+incdir" $line] != -1} {
                # incdir
                set words [split $line2 "+"]
                set inc_path [lindex $words 2]
                lappend search_path $inc_path
            } elseif {[string first "+define" $line] != -1} {
                # define
                set words [split $line2 "+"]
                lappend defines [lindex $words 2]
            } elseif {[string first ".sv" $line2] != -1} {
                # SystemVerilog
                lappend results $line2
            } elseif {[string first ".v" $line2] != -1} {
                # Verilog
                lappend results $line2
            }  elseif {[string first ".xci" $line2] != -1} {
                # Xilinx IP
                lappend results $line2
            }  elseif {[string first ".xdc" $line2] != -1} {
                # Xilinx IP
                lappend results $line2
            }
        }
    }
    return $results
}

##############################################################################
# Create a project
##############################################################################
create_project -force sim $env(VPU_HOME)/vivado/sim_project -part xcvh1582-vsva3697-2MP-e-S

# Set target board
set_property board_part xilinx.com:vhk158:part0:1.1 [current_project]

##############################################################################
# Read designs
##############################################################################
set_property target_language Verilog [current_project]

## Source environment variables
set env_map {}
lappend env_map "\${VPU_HOME}"         $env(VPU_HOME)
lappend env_map "\${VPU_SIM_HOME}"     $env(VPU_HOME)/sim

set design_filelists "$env(VPU_HOME)/design/filelist.f"
set sim_filelists "$env(VPU_HOME)/sim/filelist.f"

# Add design files
add_files -fileset sources_1 [get_filename_arr $design_filelists $env_map]

update_compile_order -fileset sources_1

# Gen IPs
source $env(VPU_HOME)/design/xilinx_ip/gen_ip.tcl

# Add simulation files
add_files -fileset sim_1 [get_filename_arr $sim_filelists $env_map]

update_compile_order -fileset sim_1 

# Add constraint file
add_files -fileset constrs_1 $env(VPU_HOME)/syn/constraint_1.xdc

#
set_property SOURCE_SET sources_1 [get_filesets sim_1]
set_property include_dirs $search_path [get_filesets sim_1]
set_property top VPU_TOP_WRAPPER [get_filesets sim_1]
set_property target_constrs_file $env(VPU_HOME)/syn/constraint_1.xdc [current_fileset -constrset]
synth_design -top $env(DESIGN_TOP) -part xcvh1582-vsva3697-2MP-e-S

update_compile_order -fileset sources_1

report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -file $env(VPU_HOME)/work.syn/vpu_top.timing.rpt
report_utilization -file $env(VPU_HOME)/work.syn/vpu_top.util.rpt -name utilization_1

quit
