`include "VPU_PKG.svh"

module VPU_FP_MUL
#(
    
)
(
    //input   wire                            clk,
    //input   wire                            rst_n,
    
    //From SRC_PORT
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_0,
    input   [VPU_PKG::OPERAND_WIDTH-1:0]    op_1,
    
    //From VPU_CONTROLLER
    input                                   en,

    //To VPU_DST_PORT
    output  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o
);
    import VPU_PKG::*;
    
    wire   [OPERAND_WIDTH-1:0]              result;
    
    // Operation
    FP_MUL # (
    ) fp_mul_0 (
        ._lhs                               (op_0),
        ._rhs                               (op_1),
        .en                                 (en),
        .res                                (result)
    );

    // Assign
    assign result_o                         = result;

endmodule