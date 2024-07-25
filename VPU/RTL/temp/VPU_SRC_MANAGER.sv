`include "VPU_PKG.svh"

module VPU_SRC_PORT_MANAGER
#(

)
(
    input   wire                                    clk,
    input   wire                                    rst_n,

    //From DECODER                         
    REQ_IF.dst                                      req_if,

    // From/To VPU_CONTROLLER
    input   wire                                    reset_cmd_i,
    output  logic                                   done_o[SRAM_R_PORT_CNT],

    // From/To SRAM
    VPU_SRC_PORT_IF.host                            vpu_src_port_if, 

    // From/To VLANE
    input   wire                                    rden_i[SRAM_R_PORT_CNT],
    output  logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   rdata_o[SRAM_R_PORT_CNT],
    output  logic                                   rdempty_o[SRAM_R_PORT_CNT],
    output  logic                                   rdfull_o[SRAM_R_PORT_CNT]
);
    import VPU_PKG::*;

    //instance array of interface
    SRAM_R_PORT_IF                                  sram_r_port_if[SRAM_R_PORT_CNT]();
    
    genvar j;
    generate
        for (j=0; j < SRAM_R_PORT_CNT; j=j+1) begin : GEN_SRC_PORT
            VPU_SRC_PORT #(
                //...
            ) vpu_src_port (   
                .clk                                (clk),
                .rst_n                              (rst_n),

                .rvalid_i                           (req_if.ravlid[j]),
                .raddr_i                            (req_if.raddr[j]),
                .valid_i                            (req_if.valid),
                .ready_o                            (req_if.ready),

                .reset_cmd_i                        (reset_cmd_i),
                .done_o                             (done_o[j]),

                .sram_rd_if                         (sram_r_port_if[j]),

                .rden_i                             (rden_i[j]),
                .rdata_o                            (rdata_o[j]),
                .rdempty_o                          (rdempty_o[j]),
                .rdfull_o                           (rdfull_o[j])
            );
        end
    endgenerate

    genvar k;
    generate
        for (k=0; k < SRAM_R_PORT_CNT; k=k+1) begin : GEN_SRC_PORT_IF
            assign  vpu_src_port_if.req[k]          = sram_r_port_if.req[k];
            assign  vpu_src_port_if.rid[k]          = sram_r_port_if.rid[k];
            assign  vpu_src_port_if.addr[k]         = sram_r_port_if.addr[k];
            assign  vpu_src_port_if.reb[k]          = sram_r_port_if.reb[k];
            assign  vpu_src_port_if.rlast[k]        = sram_r_port_if.rlast[k];  
            
            assign  sram_r_port_if.ack[k]           = vpu_src_port_if.ack[k];        
            assign  sram_r_port_if.rdata[k]         = vpu_src_port_if.rdata[k];
            assign  sram_r_port_if.rvalid[k]        = vpu_src_port_if.rvalid[k];
        end
    endgenerate

endmodule