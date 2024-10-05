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

set vpu_home $env(VPU_HOME)
set sv_root_path "$env(VPU_HOME)/sw/C/DPI/xsim.dir/work/xsc/"
set inputfile_path "/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt"
#
set_property SOURCE_SET sources_1 [get_filesets sim_1]
set_property include_dirs $search_path [get_filesets sim_1]
set_property top VPU_TOP_TB [get_filesets sim_1]
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]
#set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]
#set_property -name {xsim.elaborate.xelab.more_options} -value {-sv_root $vpu_home/sw/C/DPI/xsim.dir/work/xsc/ -sv_lib dpi} -objects [get_filesets sim_1]
#set_property -name {xsim.elaborate.xelab.more_options} -value {-sv_root [eval $vpu_home/sw/C/DPI/xsim.dir/work/xsc/] -sv_lib dpi} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options} -value "-sv_root $sv_root_path -sv_lib dpi" -objects [get_filesets sim_1]
#set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=1 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/add_out.txt"} -objects [get_filesets sim_1]
#set_property -name {xsim.simulate.xsim.more_options} -value "-testplusarg " -objects [get_filesets sim_1]

launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=2 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/sub_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=3 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/mul_out.txt"} -objects [get_filesets sim_1]
# launch_simulation
# 출력이 안나옴

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=4 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/div_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=5 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/add3_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=6 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/redsum_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=7 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/redmax_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=8 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/max_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=9 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/max3_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=10 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/avg_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=11 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/avg3_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=12 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/exp_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=13 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers_for_sqrt.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/sqrt_out.txt"} -objects [get_filesets sim_1]
# launch_simulation

# set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg "OPCODE=14 TESTVECTOR=/home/rhgksdma/VPU_Design/inputfile/bf16_numbers_for_sqrt.txt GOLDEN_FILE=/home/rhgksdma/VPU_Design/inputfile/rec_out.txt"} -objects [get_filesets sim_1]
# launch_simulation