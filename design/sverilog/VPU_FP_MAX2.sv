`include "VPU_PKG.svh"

module VPU_FP_MAX2
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_1,
    input                                   start_i,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;
    
    wire                                    tvalid;
    wire    [OPERAND_WIDTH-1:0]             a_tdata, b_tdata;
    wire    [3:0]                           result_tdata;
    wire                                    result_tvalid;

    floating_point_cmp fp_max2 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (tvalid),
        .s_axis_a_tdata                     (a_tdata),
        .s_axis_b_tvalid                    (tvalid),
        .s_axis_b_tdata                     (b_tdata),
        .m_axis_result_tvalid               (result_tvalid),
        .m_axis_result_tdata                (result_tdata),
        .m_axis_result_tuser                ()
    );

    // Assignment
    assign  a_tdata                         = operand_0;
    assign  b_tdata                         = operand_1;
    assign  tvalid                          = start_i;
    assign  result_o                        = (result_tdata == 4'b0010) ? operand_1 : operand_0;
    assign  done_o                          = result_tvalid;
endmodule