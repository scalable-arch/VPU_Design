`include "VPU_PKG.svh"

module VPU_EXEC_UNIT
#(

)
(
    input   wire                                        clk,
    input   wire                                        rst_n,

    input   wire                                        start_i,
    input   VPU_PKG::vpu_h2d_req_opcode_t               opcode_i,
    input   wire                                        is_reduction_i,
    input   wire                                        is_sum_i,

    input   wire    [VPU_PKG::EXEC_UNIT_DATA_WIDTH-1:0] operand_i[VPU_PKG::SRC_OPERAND_CNT],
    input   wire    [VPU_PKG::SRC_OPERAND_CNT-1:0]      operand_valid_i,

    output  wire    [VPU_PKG::EXEC_UNIT_DATA_WIDTH-1:0] dout_o,
    output  wire                                        done_o
);
    import VPU_PKG::*;
    
    wire    [OPERAND_WIDTH-1:0]                         operand[VLANE_CNT][SRC_OPERAND_CNT];
    wire    [EXEC_UNIT_DATA_WIDTH-1:0]                  exec_dout;
    wire    [EXEC_UNIT_DATA_WIDTH-1:0]                  red_dout;
    wire    [VLANE_CNT-1:0]                             exec_done;   
    wire                                                red_done;

    logic   [EXEC_UNIT_DATA_WIDTH-1:0]                  dout, dout_n;
    logic                                               done, done_n;

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
                .opcode_i                               (opcode_i),
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
        .opcode_i                                       (opcode_i),
        .is_sum_i                                       (is_sum_i),
        .operand_i                                      (operand_i[0]),
        .dout_o                                         (red_dout),
        .done_o                                         (red_done)
    );

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            dout                                        <= {EXEC_UNIT_DATA_WIDTH{1'b0}};
            done                                        <= 1'b0;
        end else begin
            dout                                        <= dout_n;
            done                                        <= done_n;
        end
    end

    always_comb begin
        dout_n                                          = {EXEC_UNIT_DATA_WIDTH{1'b0}};
        done_n                                          = 1'b0;
        if(is_reduction_i) begin
            dout_n                                      = red_dout;
            done_n                                      = red_done;
        end else begin
            dout_n                                      = exec_dout;
            done_n                                      = exec_done[0];
        end
    end
    assign  dout_o                                      = dout_n;
    assign  done_o                                      = done_n;
endmodule
