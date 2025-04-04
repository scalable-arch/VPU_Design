`include "VPU_PKG.svh"

module VPU_FP_MAX3
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
    logic                                   operand_queue_rden;
    wire    [OPERAND_WIDTH-1:0]             operand_queue_rdata;
    wire    [OPERAND_WIDTH-1:0]             dout_0, dout_1;
    wire                                    done_0, done_1;

    VPU_FP_MAX2 # (
    ) fp_max2_0 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (operand_0),
        .operand_1                          (operand_1),
        .start_i                            (start_i),
        .result_o                           (dout_0),
        .done_o                             (done_0)
    );

    VPU_FP_MAX2 # (
    ) fp_max2_1 (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .operand_0                          (dout_0),
        .operand_1                          (operand_queue_rdata),
        .start_i                            (done_0),
        .result_o                           (dout_1),
        .done_o                             (done_1)
    );

    SAL_FIFO
    #(
        .DEPTH_LG2                      (1),
        .DATA_WIDTH                     (OPERAND_WIDTH)
    )
    operand_1_queue
    (
        .clk                            (clk)
      , .rst_n                          (rst_n)

      , .full_o                         ()
      , .afull_o                        ()
      , .wren_i                         (start_i)
      , .wdata_i                        (operand_2)

      , .empty_o                        ()
      , .aempty_o                       (/* NC */)
      , .rden_i                         (done_0)
      , .rdata_o                        (operand_queue_rdata)

      , .debug_o                        ()
    );

    // Assign
    assign  result_o                        = dout_1;
    assign  done_o                          = done_1;
endmodule