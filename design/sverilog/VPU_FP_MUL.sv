`include "VPU_PKG.svh"

module VPU_FP_MUL
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_1,
    input                                   start_i,

    //From VPU_CONTROLLER
    //input                                   en,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;
    
    logic   [OPERAND_WIDTH-1:0]             result, result_valid;
    
    
    floating_point_mul fp_mul_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (start_i),
        .s_axis_a_tdata                     (op_0),
        .s_axis_b_tvalid                    (start_i),
        .s_axis_b_tdata                     (op_1),
        .m_axis_result_tvalid               (result_valid),
        .m_axis_result_tdata                (result),
        .m_axis_result_tuser                (done_o)
    );
    

    // Assign
    assign result_o                         = result;

endmodule