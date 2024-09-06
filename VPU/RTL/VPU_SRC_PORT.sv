`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"

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
    input   wire    [VPU_PKG::SRAM_R_PORT_CNT-1:0]  operand_fifo_rden_i,
    //To VLANE
    output  logic   [VPU_PKG::DWIDTH_PER_EXEC-1:0]  operand_fifo_rdata_o[VPU_PKG::SRAM_R_PORT_CNT],

    //SRAM_IF
    VPU_SRC_PORT_IF.host                            vpu_src_port_if
);
    import VPU_PKG::*;

    logic   [SRAM_R_PORT_CNT-1:0]                   done;

    logic   [SRAM_DATA_WIDTH-1:0]                   operand_fifo_wdata[SRAM_R_PORT_CNT];
    logic                                           operand_fifo_wren[SRAM_R_PORT_CNT];

    logic   [SRAM_DATA_WIDTH-1:0]                   operand_fifo_rdata[SRAM_R_PORT_CNT];
    //instance array of interface
    SRAM_R_PORT_IF                                  sram_r_port_if[SRAM_R_PORT_CNT]();

    // Operand Buffers
    logic   [SRAM_DATA_WIDTH-1:0]                   operand_buff[SRAM_R_PORT_CNT];
    
    // Execution Cycle
    logic   [EXEC_CNT_LG2-1:0]                      cnt, cnt_n;

    always_ff @(posedge clk) begin
        for(int i=0; i<SRAM_R_PORT_CNT; i++) begin
            if(!rst_n) begin
                operand_buff[i]                     <= {SRAM_DATA_WIDTH{1'b0}};
            end else if(operand_fifo_wren[i]) begin
                operand_buff[i]                     <= operand_fifo_wdata[i];
            end
        end
    end

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            cnt                                     <= {EXEC_CNT_LG2{1'b0}};
        end else begin
            cnt                                     <= cnt_n;
        end 
    end

    always_comb begin
        cnt_n                                       = cnt;
        if(cnt_n == EXEC_CNT) begin
            cnt_n                                   = {EXEC_CNT_LG2{1'b0}};
        end else if(|operand_fifo_rden_i) begin
            cnt_n                                   = cnt + 'd1;
        end
    end

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

    genvar j;
    generate
        for (j=0; j < SRAM_R_PORT_CNT; j=j+1) begin : GEN_SRC_PORT
            VPU_SRC_PORT_CONTROLLER #(
                //...
            ) vpu_src_port_ctrl (
                .clk                                (clk),
                .rst_n                              (rst_n),

                .rvalid_i                           (req_if.rvalid[j]),
                .raddr_i                            (req_if.raddr[j]),
                .valid_i                            (req_if.valid),

                .start_i                            (start_i),
                .done_o                             (done[j]),

                .operand_fifo_wdata_o               (operand_fifo_wdata[j]),
                .operand_fifo_wren_o                (operand_fifo_wren[j]),

                .sram_rd_if                         (sram_r_port_if[j])
            );
        end
    endgenerate

    /*
    genvar l;
    generate
        for(l=0; l < SRAM_R_PORT_CNT; l=l+1) begin
            assign operand_fifo_rdata_o[l]          = operand_buff[l][(cnt*DWIDTH_PER_EXEC)+:DWIDTH_PER_EXEC];
        end
    endgenerate
    */
    genvar l;
    generate
        for(l=0; l < SRAM_R_PORT_CNT; l=l+1) begin
            always_comb begin
                if(cnt == 'd0) begin
                    operand_fifo_rdata[l]               = operand_buff[l][0+:DWIDTH_PER_EXEC];
                end else begin
                    operand_fifo_rdata[l]               = operand_buff[l][(DWIDTH_PER_EXEC)+:DWIDTH_PER_EXEC];
                end
            end
            assign  operand_fifo_rdata_o[l]         = operand_fifo_rdata[l];
        end
    endgenerate

    assign  done_o                                  = (!start_i) & (&done);
    
endmodule