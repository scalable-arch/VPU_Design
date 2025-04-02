`include "VPU_PKG.svh"

module VPU_FP_AVG3
#(
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_1,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    operand_2,
    input                                   start_i,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o,
    output                                  done_o
);
    import VPU_PKG::*;

    wire   [OPERAND_WIDTH-1:0]              a_tdata;
    wire                                    tvalid;
    wire    [OPERAND_WIDTH-1:0]             result_tdata;
    wire                                    result_tvalid;

    VPU_FP_ADD3 # (
    ) fp_add3 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_0),
        .operand_1                          (operand_1),
        .operand_2                          (operand_2),
        .start_i                            (start_i),
        .result_o                           (a_tdata),
        .done_o                             (tvalid)
    );

    floating_point_div fp_div_0 (
        .aclk                               (clk),
        .s_axis_a_tvalid                    (tvalid),
        .s_axis_a_tdata                     (a_tdata),
        .s_axis_b_tvalid                    (tvalid),
        .s_axis_b_tdata                     ('b0_10000000_1000000),
        .m_axis_result_tvalid               (result_tvalid),
        .m_axis_result_tdata                (result_tdata),
        .m_axis_result_tuser                ()
    );

    // Assign
    assign  result_o                        = result_tdata;
    assign  done_o                          = result_tvalid;
endmodule