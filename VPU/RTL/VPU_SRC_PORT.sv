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
    input   wire                                    start_i,
    output  logic                                   done_o,
    input   wire    [SRAM_R_PORT_CNT-1:0]           operand_fifo_rden_i,
    //To VLANE
    output  logic   [OPERAND_WIDTH*VLANE_CNT-1:0]   operand_fifo_rdata_o[SRAM_R_PORT_CNT],

    //SRAM_IF
    VPU_SRC_PORT_IF.host                            vpu_src_port_if
);
    import VPU_PKG::*;

    logic   [SRAM_R_PORT_CNT-1:0]                   done;

    logic   [SRAM_DATA_WIDTH-1:0]                   operand_fifo_wdata[SRAM_R_PORT_CNT];
    logic                                           operand_fifo_wren[SRAM_R_PORT_CNT];
    
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

                .start_i                            (start_i),
                .done_o                             (done[j]),

                .operand_fifo_wdata_o               (operand_fifo_wdata[j]),
                .operand_fifo_wren_o                (operand_fifo_wren[j]),

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
                .wren_i                             (operand_fifo_wren[j]),
                .wdata_i                            (operand_fifo_wdata[j]),
                .wrempty_o                          (),
                .wrfull_o                           (),
                
                .rdclk                              (clk),
                .rden_i                             (operand_fifo_rden_i[j]),
                .rdata_o                            (operand_fifo_rdata_o[j]),
                .rdempty_o                          (),
                .rdfull_o                           ()
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
    assign  done_o                                  = (!start_i) & (&done);

endmodule