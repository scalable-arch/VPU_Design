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
set_property simulator_language Verilog [current_project]


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

#puts $search_path
#puts $defines

#
set_property SOURCE_SET sources_1 [get_filesets sim_1]
set_property include_dirs $search_path [get_filesets sim_1]
set_property top VPU_TOP_TB [get_filesets sim_1]
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]

set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=13 TESTVECTOR=/home/sg05060/example.txt GOLDEN_FILE=/home/sg05060/example_out.txt"} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {1000000ns} -objects [get_filesets sim_1]

#set_property verilog_define $defines [get_filesets sim_1]

launch_simulation