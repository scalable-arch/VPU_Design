`include "VPU_PKG.svh"

module VPU_SRC_PORT
#(

)
(   
    input   wire                                    clk,
    input   wire                                    rst_n,

    //From REQ_IF.dst
    input   wire                                    rvalid_i,
    input   wire [OPERAND_ADDR_WIDTH-1:0]           raddr_i,
    input   wire                                    valid_i,
    output  logic                                   ready_o,

    // From/TO VPU_CONTROLLER
    input   wire                                    reset_cmd_i,
    output  logic                                   done_o,

    //SRAM_IF
    SRAM_R_PORT_IF.host                             sram_rd_if,

    //From/To VLANE
    input   wire                                    rden_i,
    output  logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   rdata_o,
    output  logic                                   rdempty_o,
    output  logic                                   rdfull_o
);
    import VPU_PKG::*;

    logic   [DIM_SIZE-1:0]                          wdata;
    logic                                           wren;
    logic                                           wrempty;
    logic                                           wrfull;

    VPU_SRC_PORT_CONTOLLER #(
        //...
    ) VPU_SRC_PORT_CTRL (
        .clk                                        (clk),
        .rst_n                                      (rst_n),
        .rvalid_i                                   (rvalid_i),
        .raddr_i                                    (raddr_i),
        .valid_i                                    (valid_i),
        .ready_o                                    (ready_o),
        .reset_cmd_i                                (reset_cmd_i),
        .done_o                                     (done_o),
        .wdata_o                                    (wdata),
        .wren_o                                     (wren),
        .wrempty_i                                  (wrempty),
        .wrfull_i                                   (wrfull),
        .sram_rd_if                                 (sram_rd_if),
    );

    VPU_NRW_FIFO #(
        .DEPTH_LG2                                  ($clog2(OPERAND_QUEUE_DEPTH)),
        .WRDATA_WIDTH                               (DIM_SIZE),
        .RDDATA_WIDTH                               (OPERAND_WIDTH*VLANE_CNT),
        .RST_MEM                                    (0) 
    ) VPU_SRC_OPERAND_QUEUE (   
        .rst_n                                      (rst_n),

        .wrclk                                      (clk),
        .wren_i                                     (wren),
        .wdata_i                                    (wdata),
        .wrempty_o                                  (wrempty),
        .wrfull_o                                   (wrfull),
        
        .rdclk                                      (clk),
        .rden_i                                     (rden_i),
        .rdata_o                                    (rdata_o),
        .rdempty_o                                  (rdempty_o),
        .rdfull_o                                   (rdfull_o)
    );


endmodule