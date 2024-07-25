module VPU_DST_PORT
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From/To VPU_CONTROLLER
    input   wire                            reset_cmd_i,
    output  wire                            done_o,

    // From VPU_LANE
    input   wire                            wb_data_wren_i,
    input   [OPERAND_WIDTH*VLANE_CNT-1:0]   wb_data_i,

    // REQ_IF
    REQ_IF.dst                              req_if,

    // SRAM_W_PORT
    SRAM_W_PORT_IF.host                     sram_w_port_if,
);
    import VPU_PKG::*;

    VPU_WB_UNIT #(
        //...
    ) vpu_wb_unit (
        .clk                (clk),
        .rst_n              (rst_n),
        .reset_cmd_i        (reset_cmd_i),
        .done_o             (done_o),

        .wb_data_wren_i     (wb_data_wren_i),
        .wb_data_i          (wb_data_i),

        .req_if             (req_if),
        .sram_w_port_if     (sram_w_port_if),        
    );
    
endmodule
    
