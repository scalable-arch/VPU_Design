`include "VPU_PKG.svh"

module VPU_SRC_PORT
#(

)
(   
    input   wire                                    clk,
    input   wire                                    rst_n,
    
    // REQ_IF.dst
    REQ_IF.dst                                      req_if,

    // From/To VPU_CONTROLLER
    input   wire                                    reset_cmd_i,
    output  logic                                   done_o[SRAM_R_PORT_CNT],
    input   wire                                    rden_i[SRAM_R_PORT_CNT],

    //SRAM_IF
    VPU_SRC_PORT_IF.host                            vpu_src_port_if,

    //To VLANE
    output  logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   rdata_o[SRAM_R_PORT_CNT],
    output  logic                                   rdempty_o[SRAM_R_PORT_CNT],
    output  logic                                   rdfull_o[SRAM_R_PORT_CNT]
);
    import VPU_PKG::*;

    logic   [SRAM_DATA_WIDTH-1:0]                   wdata[SRAM_R_PORT_CNT];
    logic                                           wren[SRAM_R_PORT_CNT];
    logic                                           wrempty[SRAM_R_PORT_CNT];
    logic                                           wrfull[SRAM_R_PORT_CNT];

    //instance array of interface
    SRAM_R_PORT_IF                                  sram_r_port_if[SRAM_R_PORT_CNT]();

    genvar j;
    generate
        for (j=0; j < SRAM_R_PORT_CNT; j=j+1) begin : GEN_SRC_PORT
            VPU_SRC_PORT_CONTOLLER #(
                //...
            ) VPU_SRC_PORT_CTRL (
                .clk                                (clk),
                .rst_n                              (rst_n),

                .rvalid_i                           (req_if.rvalid_i[j]),
                .raddr_i                            (req_if.raddr_i[j]),
                .valid_i                            (req_if.valid_i),
                .ready_o                            (req_if.ready_o),

                .reset_cmd_i                        (reset_cmd_i),
                .done_o                             (done_o[j]),

                .wdata_o                            (wdata[j]),
                .wren_o                             (wren[j]),
                .wrempty_i                          (wrempty[j]),
                .wrfull_i                           (wrfull[j]),

                .sram_rd_if                         (sram_r_port_if[j]),
            );

            VPU_NRW_FIFO #(
                .DEPTH_LG2                          ($clog2(OPERAND_QUEUE_DEPTH)),
                .WRDATA_WIDTH                       (SRAM_DATA_WIDTH),
                .RDDATA_WIDTH                       (OPERAND_WIDTH*VLANE_CNT),
                .RST_MEM                            (0) 
            ) VPU_SRC_OPERAND_QUEUE (   
                .rst_n                              (rst_n),

                .wrclk                              (clk),
                .wren_i                             (wren[j]),
                .wdata_i                            (wdata[j]),
                .wrempty_o                          (wrempty[j]),
                .wrfull_o                           (wrfull[j]),
                
                .rdclk                              (clk),
                .rden_i                             (rden_i[j]),
                .rdata_o                            (rdata_o[j]),
                .rdempty_o                          (rdempty_o[j]),
                .rdfull_o                           (rdfull_o[j])
            );
        end
    endgenerate

    genvar k;
    generate
        for (k=0; k < SRAM_R_PORT_CNT; k=k+1) begin : ASSIGN_VPU_SRC_PORT_IF
            assign  vpu_src_port_if.req[k]          = sram_r_port_if[k].req;
            assign  vpu_src_port_if.rid[k]          = sram_r_port_if[k].rid;
            assign  vpu_src_port_if.addr[k]         = sram_r_port_if[k].addr;
            assign  vpu_src_port_if.reb[k]          = sram_r_port_if[k].reb;
            assign  vpu_src_port_if.rlast[k]        = sram_r_port_if[k].rlast;  
            
            assign  sram_r_port_if[k].ack           = vpu_src_port_if.ack[k];        
            assign  sram_r_port_if[k].rdata         = vpu_src_port_if.rdata[k];
            assign  sram_r_port_if[k].rvalid        = vpu_src_port_if.rvalid[k];
        end
    endgenerate



endmodule