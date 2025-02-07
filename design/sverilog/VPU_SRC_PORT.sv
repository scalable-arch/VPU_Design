`include "VPU_PKG.svh"

module VPU_SRC_PORT
#(

)
(   
    input   wire                                    clk,
    input   wire                                    rst_n,

    input   VPU_PKG::vpu_instr_decoded_t            instr_decoded_i,

    // From/To VPU_CONTROLLER
    input   wire                                    start_i,
    output  logic                                   done_o,
    input   wire    [VPU_PKG::SRAM_R_PORT_CNT-1:0]  operand_fifo_rden_i,
    //To VLANE
    output  logic   [VPU_PKG::DWIDTH_PER_EXEC-1:0]  operand_fifo_rdata_o[VPU_PKG::SRAM_R_PORT_CNT],

    //SRAM_IF
    VPU_SRC_PORT_IF.host                            vpu_src0_port_if,
    VPU_SRC_PORT_IF.host                            vpu_src1_port_if,
    VPU_SRC_PORT_IF.host                            vpu_src2_port_if
);
    import VPU_PKG::*;

    logic   [SRAM_R_PORT_CNT-1:0]                   done;

    logic   [SRAM_DATA_WIDTH-1:0]                   operand_fifo_wdata[SRAM_R_PORT_CNT];
    logic                                           operand_fifo_wren[SRAM_R_PORT_CNT];

    logic   [SRAM_DATA_WIDTH-1:0]                   operand_fifo_rdata[SRAM_R_PORT_CNT];
    //instance array of interface
    //SRAM_R_PORT_IF                                  sram_r_port_if[SRAM_R_PORT_CNT]();

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

    VPU_SRC_PORT_CONTROLLER #(
        //...
    ) vpu_src0_port_ctrl (
        .clk                                (clk),
        .rst_n                              (rst_n),

        .rvalid_i                           (instr_decoded_i.rvalid[0]),
        .raddr_i                            (instr_decoded_i.raddr0),

        .start_i                            (start_i),
        .done_o                             (done[0]),

        .operand_fifo_wdata_o               (operand_fifo_wdata[0]),
        .operand_fifo_wren_o                (operand_fifo_wren[0]),

        .sram_rd_if                         (vpu_src0_port_if)
    );

    VPU_SRC_PORT_CONTROLLER #(
        //...
    ) vpu_src1_port_ctrl (
        .clk                                (clk),
        .rst_n                              (rst_n),

        .rvalid_i                           (instr_decoded_i.rvalid[1]),
        .raddr_i                            (instr_decoded_i.raddr1),

        .start_i                            (start_i),
        .done_o                             (done[1]),

        .operand_fifo_wdata_o               (operand_fifo_wdata[1]),
        .operand_fifo_wren_o                (operand_fifo_wren[1]),

        .sram_rd_if                         (vpu_src1_port_if)
    );

    VPU_SRC_PORT_CONTROLLER #(
        //...
    ) vpu_src2_port_ctrl (
        .clk                                (clk),
        .rst_n                              (rst_n),

        .rvalid_i                           (instr_decoded_i.rvalid[2]),
        .raddr_i                            (instr_decoded_i.raddr2),

        .start_i                            (start_i),
        .done_o                             (done[2]),

        .operand_fifo_wdata_o               (operand_fifo_wdata[2]),
        .operand_fifo_wren_o                (operand_fifo_wren[2]),

        .sram_rd_if                         (vpu_src2_port_if)
    );

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