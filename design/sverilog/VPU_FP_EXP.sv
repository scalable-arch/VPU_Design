`include "VPU_PKG.svh"

module VPU_FP_EXP
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_0,
    input                                   start_i,

    //From VPU_CONTROLLER
    //input                                   en,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;
    
    logic   [(OPERAND_WIDTH*2)-1:0]         result;
    logic   [(OPERAND_WIDTH*2)-1:0]         extended_op_0;
    assign  extended_op_0                   = {{op_0},{16{1'b0}}};
    
    (* black_box *)
    floating_point_exp fp_exp_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (start_i),
        .s_axis_a_tdata                     (extended_op_0),
        .m_axis_result_tvalid               (done_o),
        .m_axis_result_tdata                (result),
        .m_axis_result_tuser                ()
    );
    

    // Assign
    assign result_o                         = result[(OPERAND_WIDTH*2)-1:OPERAND_WIDTH];

endmodule