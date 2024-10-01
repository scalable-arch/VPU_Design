`include "VPU_PKG.svh"

module VPU_FP_ADD_SUB
#(
    
)
(
    //input   wire                            clk,
    //input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_1,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_2,
    input   [VPU_PKG::SRAM_R_PORT_CNT-1:0]  op_valid,
    input                                   sub_n,
    //From VPU_CONTROLLER
    input                                   en,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o
);
    import VPU_PKG::*;
    
    wire   [OPERAND_WIDTH-1:0]              result_0, result_1;
    logic   [OPERAND_WIDTH-1:0]             result;
    
    // Operation
    FP_ADD_SUB # (
    ) fp_add_sub_0 (
        ._lhs(op_0),
        ._rhs(op_1),
        .en(en),
        .sub_n(sub_n),
        .res(result_0)
    );

    FP_ADD_SUB # (
    ) fp_add_sub_1 (
        ._lhs(result_0),
        ._rhs(op_2),
        .en(en & op_valid[SRAM_R_PORT_CNT-1]),
        .sub_n(1'b1),
        .res(result_1)
    );

    always_comb begin
        result                          = {OPERAND_WIDTH{1'b0}};
        if(op_valid[SRAM_R_PORT_CNT-1]) begin
            result                      = result_1;
        end else begin
            result                      = result_0;
        end
    end

    // Assign
    assign result_o                         = result;

endmodule