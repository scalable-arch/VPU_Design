`include "VPU_PKG.svh"

module VPU_ALU_UI_ADD_SUB
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From SRC_PORT
    input   [OPCODE_WIDTH-1:0]              op_0,
    input   [OPCODE_WIDTH-1:0]              op_1,
    input   [OPCODE_WIDTH-1:0]              op_2,
    input   [SRAM_R_PORT_CNT-1:0]           op_valid,
    input                                   sub_n,
    //From VPU_CONTROLLER
    input                                   en,

    //To VPU_DST_PORT
    output  [OPCODE_WIDTH-1:0]              result_o,
);
    import VPU_PKG::*;
    
    logic   [OPCODE_WIDTH-1:0]              result, _result;
    logic   [OPCODE_WIDTH-1:0]              _op_1;
    
    // Operation
    always_comb begin
        if(en) begin
            _op_1                           = (sub_n == 1'b0) ? !(op_1) + 'd1 : op_1;
            _result                         = op_0 + _op_1;
            if(op_valid[SRAM_R_PORT_CNT-1]) begin
                result                      = _result + op_2;
            end else begin
                result                      = _result;
            end
        end else begin
            result                          = {OPCODE_WIDTH{1'b0}};
        end
    end

    // Assign
    assign result_o                         = result;

endmodule