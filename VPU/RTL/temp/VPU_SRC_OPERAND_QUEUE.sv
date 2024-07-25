`include "VPU_PKG.svh"

module VPU_SRC_OPERAND_QUEUE
#(

)
(   
    input   wire                                    clk,
    input   wire                                    rst_n,


    input   wire                                    wren_i[SRAM_R_PORT_CNT], 
    input   wire    [DIM_SIZE-1:0]                  wdata_i[SRAM_R_PORT_CNT], 
    output  logic                                   wrempty_o[SRAM_R_PORT_CNT],
    output  logic                                   wrfull_o[SRAM_R_PORT_CNT],
    
    input   wire                                    rden_i[SRAM_R_PORT_CNT],
    output  logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   rdata_o[SRAM_R_PORT_CNT],
    output  logic                                   rdempty_o[SRAM_R_PORT_CNT],
    output  logic                                   rdfull_o[SRAM_R_PORT_CNT],
);
    import VPU_PKG::*;

    genvar i;
    generate
        for (i=0; i < SRAM_R_PORT_CNT; i=i+1) begin : GEN_SRC_OPERAND_QUEUE
            VPU_NRW_FIFO #(
                //parameter       DEPTH_LG2           = $clog2(DIM_SIZE/OPERAND_WIDTH/VLANE_CNT),
                .DEPTH_LG2           ($clog2(OPERAND_QUEUE_DEPTH)),
                .WRDATA_WIDTH        (DIM_SIZE),
                .RDDATA_WIDTH        (OPERAND_WIDTH*VLANE_CNT),
                .RST_MEM             (0)
            ) NRW_FIFO_INST (   
                .rst_n                              (rst_n),
        
                .wrclk                              (clk),
                .wren_i                             (wren_i[i]),
                .wdata_i                            (wdata_i[i]),
                .wrempty_o                          (wrempty_o[i]),
                .wrfull_o                           (wrfull_o[i]),
                
                .rdclk                              (clk),
                .rden_i                             (rden_i[i]),
                .rdata_o                            (rdata_o[i]),
                .rdempty_o                          (rdempty_o[i]),
                .rdfull_o                           (rdfull_o[i])
            );
        end
    endgenerate
endmodule