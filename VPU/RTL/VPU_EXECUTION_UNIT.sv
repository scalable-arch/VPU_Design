`include "VPU_PKG.svh"

module VPU_EXECUTION_UNIT
#(
    //...
)
(
    input   wire                            clk,
    input   wire                            rst_n,

    // From/To VPU_DECODER
    REQ_IF.dst                              req_if,

    // From/To VPU_CONTROLLER
    input   wire                            start_i, 
    input   wire                            done_o,
    
    // From/To VPU_SRC_PORT
    input   [OPERAND_WIDTH*VLANE_CNT-1:0]   rdata_i[SRAM_R_PORT_CNT],

);
    import VPU_PKG::*;
    

endmodule