# ---------------------------------------
# Step 1: Specify libraries
# ---------------------------------------
set link_library \
[list /media/0/LogicLibraries/UMC/28nm/35uhd/udl/hvt/2.01a/liberty/ecsm/um28nchhlogl35udl140f_sswc0p81v125c.db ]

set target_library \
[list /media/0/LogicLibraries/UMC/28nm/35uhd/udl/hvt/2.01a/liberty/ecsm/um28nchhlogl35udl140f_sswc0p81v125c.db ]

# ---------------------------------------
# Step 2: Read designs
# ---------------------------------------

analyze -format sverilog $env(LAB_PATH)/RTL/VPU_IF.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_CONTROLLER.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_DECODER.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_EXEC_UNIT.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_LANE.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_REDUCTION_UNIT.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_SRC_PORT_CONTROLLER.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_SRC_PORT.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_CNTR.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_WB_UNIT.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_TOP.sv
analyze -format sverilog $env(LAB_PATH)/RTL/VPU_TOP_WRAPPER.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Unsigned_Int/VPU_ALU_UI_ADD_SUB.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Unsigned_Int/VPU_ALU_UI_DIV.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Unsigned_Int/VPU_ALU_UI_MUL.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Unsigned_Int/VPU_ALU_UI_MAX.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Unsigned_Int/VPU_ALU_UI_AVG.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Signed_Int/VPU_ALU_SI_ADD_SUB.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Signed_Int/VPU_ALU_SI_DIV.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Signed_Int/VPU_ALU_SI_MUL.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Signed_Int/VPU_ALU_SI_MAX.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Signed_Int/VPU_ALU_SI_AVG.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/VPU_FP_ADD_SUB.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/FP_ADD_SUB.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/FP_MUL.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/float_break.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/float_combine.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/float_lzc.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/float_swap.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/float_native_lzc.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/VPU_FP_MAX.sv
analyze -format sverilog $env(LAB_PATH)/RTL/ALU/Float/VPU_FP_MUL.sv

set design_name         VPU_TOP
elaborate $design_name

# connect all the library components and designs
link

# renames multiply references designs so that each
# instance references a unique design
uniquify

# ---------------------------------------
# Step 3: Define design environments
# ---------------------------------------
#
# ---------------------------------------
# Step 4: Set design constraints
# ---------------------------------------
# ---------------------------------------
# Clock
# ---------------------------------------
set clk_name clk
set clk_freq            200

# Reduce clock period to model wire delay (60% of original period)
set clk_period [expr 1000 / double($clk_freq)]
create_clock -period $clk_period $clk_name
set clk_uncertainty [expr $clk_period * 0.35]
set_clock_uncertainty -setup $clk_uncertainty $clk_name

# Set infinite drive strength
set_drive 0 $clk_name
set_ideal_network rst_n

# ---------------------------------------
# Input/Output
# ---------------------------------------
# Apply default timing constraints for modules
set_input_delay  1.0 [all_inputs]  -clock $clk_name
set_output_delay 1.0 [all_outputs] -clock $clk_name

# ---------------------------------------
# Area
# ---------------------------------------
# If max_area is set 0, DesignCompiler will minimize the design as small as possible
set_max_area 0 

# ---------------------------------------
# Step 5: Synthesize and optimzie the design
# ---------------------------------------
compile -map_effort high

# ---------------------------------------
# Step 6: Analyze and resolve design problems
# ---------------------------------------
check_design  > $design_name.check_design.rpt

report_constraint -all_violators -verbose -sig 10 > $design_name.all_viol.rpt

report_design                             > $design_name.design.rpt
report_area -physical -hierarchy          > $design_name.area.rpt
report_timing -nworst 10 -max_paths 10    > $design_name.timing.rpt
report_power -analysis_effort high        > $design_name.power.rpt
report_cell                               > $design_name.cell.rpt
report_qor                                > $design_name.qor.rpt
report_reference                          > $design_name.reference.rpt
report_resources                          > $design_name.resources.rpt
report_hierarchy -full                    > $design_name.hierarchy.rpt
report_threshold_voltage_group            > $design_name.vth.rpt

# ---------------------------------------
# Step 7: Save the design database
# ---------------------------------------
write -hierarchy -format verilog -output  $design_name.netlist.v
write -hierarchy -format ddc     -output  $design_name.ddc
write_sdf -version 1.0                    $design_name.sdf
write_sdc                                 $design_name.sdc

exit
