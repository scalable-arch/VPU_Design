`include "VPU_PKG.svh"

module VPU_EXEC_UNIT
#(

)
(
    input   wire                                        clk,
    input   wire                                        rst_n,

    input   wire                                        start_i,
    input   VPU_PKG::vpu_exec_req_t                     op_func_i,

    input   wire    [VPU_PKG::DWIDTH_PER_EXEC-1:0]      operand_i[VPU_PKG::SRC_OPERAND_CNT],
    input   wire    [VPU_PKG::SRC_OPERAND_CNT-1:0]      operand_valid_i,

    output  wire    [VPU_PKG::DWIDTH_PER_EXEC-1:0]      dout_o,
    output  wire                                        done_o
);
    import VPU_PKG::*;
    
    wire    [OPERAND_WIDTH-1:0]                         operand[VLANE_CNT][SRC_OPERAND_CNT];

    wire    [DWIDTH_PER_EXEC-1:0]                       exec_dout;
    wire    [DWIDTH_PER_EXEC-1:0]                       red_dout;
    logic   [DWIDTH_PER_EXEC-1:0]                       dout, dout_n;
    wire    [VLANE_CNT-1:0]                             exec_done;   
    wire                                                red_done;
    logic                                               done, done_n;

    logic   [EXEC_CNT_LG2-1:0]                          cnt, cnt_n; 


    //----------------------------------------------
    // VPU_EXEC_DELAY
    //----------------------------------------------
    
    //VPU_CNTR # (
    //    .MAX_DELAY_LG2                          (MAX_DELAY_LG2)
    //) VPU_CNTR (
    //    .clk                                    (clk),
    //    .rst_n                                  (rst_n),
    //    .count                                  (delay_i),
    //    .start_i                                (start_i),
    //    .done_o                                 (exec_done)
    //);

    //----------------------------------------------
    // GENERATE_VLANES
    //----------------------------------------------
    genvar k,i;
    generate
        for (k=0; k < VLANE_CNT; k=k+1) begin : ASSIGN_OPERAND
            for (i=0; i < SRC_OPERAND_CNT; i=i+1) begin
                assign operand[k][i]                    = operand_i[i][(k*OPERAND_WIDTH)+:OPERAND_WIDTH];
            end
        end
    endgenerate
    
    genvar j;
    generate
        for (j=0; j < VLANE_CNT; j=j+1) begin
            VPU_LANE #(
                //...
            ) VPU_LANE (
                .clk                                    (clk),
                .rst_n                                  (rst_n),
                .start_i                                (start_i),
                .op_func_i                              (op_func_i),
                //.delay_i                                (delay_i),
                .operand_i                              (operand[j]),
                .operand_valid_i                        (operand_valid_i),
                .dout_o                                 (exec_dout[(j*OPERAND_WIDTH)+:OPERAND_WIDTH]),
                .done_o                                 (exec_done[j])
            );
        end
    endgenerate

    VPU_REDUCTION_UNIT # (
    ) VPU_REDUCTION_UNIT (
        .clk                                            (clk),
        .rst_n                                          (rst_n),
        .start_i                                        (start_i),
        .op_func_i                                      (op_func_i),
        //.delay_i                                        (delay_i),
        .operand_i                                      (operand_i[0]),
        .dout_o                                         (red_dout),
        .done_o                                         (red_done)
    );

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            dout                                        <= {DWIDTH_PER_EXEC{1'b0}};
            done                                        <= 1'b0;
        end else begin
            dout                                        <= dout_n;
            done                                        <= done_n;
        end
    end

    always_comb begin
        dout_n                                            = {DWIDTH_PER_EXEC{1'b0}};
        done_n                                            = 1'b0;
        if(op_func_i.op_type==EXEC) begin
            dout_n                                        = exec_dout;
            done_n                                        = exec_done[0];
        end else begin
            dout_n                                        = red_dout;
            done_n                                        = red_done;
        end
    end
    assign  dout_o                                      = dout;
    assign  done_o                                      = done;
endmodule
