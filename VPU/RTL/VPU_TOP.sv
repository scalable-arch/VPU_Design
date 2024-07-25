`include "VPU_PKG.svh"
module VPU_TOP
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    // VPU REQUEST INTERFACE
    VPU_IF.device                           vpu_if,

    // SRAM PORT INTERFACE
    VPU_SRC_PORT_IF.host                    vpu_src_port_if,
    VPU_DST_PORT_IF.host                    vpu_dst_port_if,
);
    import VPU_PKG::*;

    wire                                    req_queue_rden;
    REQ_IF                                  req_if(clk,rst_n);    
    wire    [SRAM_R_PORT_CNT-1:0]           opget_done_pack;
    wire                                    opget_done_unpack[SRAM_R_PORT_CNT];
    wire                                    operand_queue_rden[SRAM_R_PORT_CNT];
    wire                                    wb_done;
    wire                                    reset_cmd;

    wire    [OPERAND_WIDTH*VLANE_CNT-1:0]   operand_queue_rdata[SRAM_R_PORT_CNT];
    wire                                    operand_queue_rdempty[SRAM_R_PORT_CNT];
    wire                                    operand_queue_rdfull[SRAM_R_PORT_CNT];
    
    VPU_DECODER #(
        //...
    ) vpu_decoder (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .vpu_if                             (vpu_if),
        .aempty_o                           ()
        .empty_o                            (),
        .rden_i                             (req_queue_rden),
        .req_if                             (req_if),
    );

    VPU_CONTROLLER #(

    ) vpu_controller (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .req_if                             (req_if),

        .opget_done_i                       (opget_done_pack),
        .req_queue_rden_o                   (req_queue_rden),
        .operand_queue_rden_o               (operand_queue_rden),
        .wb_done_i                          (wb_done),
        .reset_cmd_o                        (reset_cmd)
    );

    VPU_SRC_PORT #(

    ) vpu_src_port (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .req_if                             (req_if),
        .reset_cmd_i                        (reset_cmd),
        .done_o                             (opget_done_unpack).
        .vpu_src_port_if                    (vpu_src_port_if),
        .rden_i                             (operand_queue_rden),
        .rdata_o                            (operand_queue_rdata),
        .rdempty_o                          (operand_queue_rdempty),
        .rdfull_o                           (operand_queue_rdfull),
    );

    VPU_DST_PORT #(
    
    ) vpu_dst_port (   
        .clk                                (clk),
        .rst_n                              (rst_n),
        .reset_cmd_i                        (reset_cmd),
        .done_o                             (wb_done),
        .wb_data_wren_i                     (),
        .wb_data_i                          (),
        .req_if                             (req_if),
        .sram_w_port_if                     (vpu_dst_port_if)
    );

    genvar k;
    generate
        for (k=0; k < SRAM_R_PORT_CNT; k=k+1) begin : PACKING_OPGET_DONE_SIGNAL
            assign opget_done_pack[k]       = opget_done_unpack[k];
        end
    endgenerate
endmodule