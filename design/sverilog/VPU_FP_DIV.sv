`include "VPU_PKG.svh"

module VPU_FP_DIV
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
    
    logic   [OPERAND_WIDTH-1:0]             result;
    
    (* black_box *)
    floating_point_div fp_div_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (start_i),
        .s_axis_a_tdata                     (op_0),
        .s_axis_b_tvalid                    (start_i),
        .s_axis_b_tdata                     (op_1),
        .m_axis_result_tvalid               (done_o),
        .m_axis_result_tdata                (result),
        .m_axis_result_tuser                ()
    );
    

    // Assign
    assign result_o                         = result;

endmodule