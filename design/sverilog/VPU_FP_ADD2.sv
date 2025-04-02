`include "VPU_PKG.svh"

module VPU_FP_ADD2
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_1,
    input                                   start_i,
    input                                   sub,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;

    wire                                    tvalid;
    wire    [OPERAND_WIDTH-1:0]             a_tdata, b_tdata;
    wire    [OPERAND_WIDTH-1:0]             result_data;
    wire                                    result_tvalid;

    floating_point_add_sub fp_add_sub_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (tvalid),
        .s_axis_a_tdata                     (a_tdata),
        .s_axis_b_tvalid                    (tvalid),
        .s_axis_b_tdata                     (b_tdata),
        .s_axis_operation_tvalid            (tvalid),
        .s_axis_operation_tdata             (sub),
        .m_axis_result_tvalid               (result_tvalid),
        .m_axis_result_tdata                (result_data),
        .m_axis_result_tuser                ()
    );

    // Assignment
    assign  a_tdata                         = operand_0;
    assign  b_tdata                         = operand_1;
    assign  tvalid                          = start_i;
    assign  result_o                        = result_data;
    assign  done_o                          = result_tvalid;

endmodule

