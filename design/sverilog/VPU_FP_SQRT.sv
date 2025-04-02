`include "VPU_PKG.svh"

module VPU_FP_SQRT
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
    
    logic   [OPERAND_WIDTH-1:0]             result, result_valid;
    
    (* black_box *)
    floating_point_sqrt fp_sqrt_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (start_i),
        .s_axis_a_tdata                     (op_0),
        .m_axis_result_tvalid               (done_o),
        .m_axis_result_tdata                (result),
        .m_axis_result_tuser                ()
    );
    

    // Assign
    assign result_o                         = result;

endmodule