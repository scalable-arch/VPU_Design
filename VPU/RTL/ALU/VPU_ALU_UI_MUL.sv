`include "VPU_PKG.svh"

module VPU_ALU_UI_MUL
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [OPCODE_WIDTH-1:0]              op_0,
    input   [OPCODE_WIDTH-1:0]              op_1,

    //From VPU_CONTROLLER
    input                                   en,

    //To VPU_DST_PORT
    output  [OPCODE_WIDTH-1:0]              result_o,
);
    import VPU_PKG::*;
    
    logic   [OPCODE_WIDTH-1:0]              result;

    // Operation
    always_comb begin
        if(en) begin
            result                          = op_0 * op_1;
        end else begin
            result                          = {OPERAND_WIDTH{1'b0}};
        end
    end

    // Assign
    assign result_o                         = result;

endmodule