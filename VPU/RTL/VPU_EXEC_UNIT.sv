`include "VPU_PKG.svh"

module VPU_EXEC_UNIT
#(

)
(
    input   wire                                        clk,
    input   wire                                        rst_n,

    input   wire                                        start_i,
    input   vpu_exec_req_t                              op_func_i,
    input   wire    [MAX_DELAY_LG2-1:0]                 delay_i,

    input   wire    [(OPERAND_WIDTH*VLANE_CNT)-1:0]     operand_i[OPERAND_CNT],
    input   wire    [OPERAND_CNT-1:0]                   operand_valid_i,

    output  wire    [(OPERAND_WIDTH*VLANE_CNT)-1:0]     dout_o,
    output  wire                                        done_o
);
    import VPU_PKG::*;

    logic   wire    [OPERAND_WIDTH-1:0]                 operand[VLANE_CNT][OPERAND_CNT];
    
    //----------------------------------------------
    // VPU_EXEC_DELAY
    //----------------------------------------------
    VPU_TIMING_CNTR #(
        .CNTR_WIDTH                                     (MAX_DELAY_LG2)
    ) VPU_TIMING_CNTR (
        .clk                                            (clk),
        .rst_n                                          (rst_n),
        .reset_cmd_i                                    (start_i),
        .reset_value_i                                  (delay_i),
        .is_zero_o                                      (done_o),

    )

    //----------------------------------------------
    // GENERATE_VLANES
    //----------------------------------------------
    genvar k,i;
    generate
        for (k=0; k < VLANE_CNT; k=k+1) begin : GENERATE_VLANE
            for (i=0; i < OPERAND_CNT; i=i+1) begin
                operand[k][i]                           = operand_i[i][(k*OPERAND_WIDTH)+:OPERAND_WIDTH];
            end
        end
    endgenerate
    
    genvar j;
    generate
        for (j=0; j < VLANE_CNT; j=j+1) begin : GENERATE_VLANE
            VPU_LANE #(
                //...
            ) VPU_LANE (
                .clk                                    (clk),
                .rst_n                                  (rst_n),
                .start_i                                (start_i),
                .op_func_i                              (op_func_i),
                .delay_i                                (delay_i),
                .operand_i                              (operand[j]),
                .operand_valid_i                        (operand_valid_i),
                .dout_o                                 (dout_o[(j*OPERAND_WIDTH)+:OPERAND_WIDTH])
            );
        end
    endgenerate
    
endmodule