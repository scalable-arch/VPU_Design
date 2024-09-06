`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"

module VPU_ALU_SI_DIV
#(
    
)
(
    //input   wire                                    clk,
    //input   wire                                    rst_n,
    
    //From SRC_PORT
    input   signed  [VPU_PKG::OPERAND_WIDTH-1:0]    op_0,
    input   signed  [VPU_PKG::OPERAND_WIDTH-1:0]    op_1,

    //From VPU_CONTROLLER
    input                                           en,

    //To VPU_DST_PORT
    output  signed  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o
);
    import VPU_PKG::*;
    
    logic   signed  [OPERAND_WIDTH-1:0]             result;
    logic   signed  [OPERAND_WIDTH-1:0]             _op_0, _op_1;

    //Enable
    always_comb begin
        _op_0                                       = {OPERAND_WIDTH{1'b0}};
        _op_1                                       = {OPERAND_WIDTH{1'b0}};
        if(en) begin
            _op_0                                   = op_0;
            _op_1                                   = op_1;
        end
    end
    
    // Operation
    always_comb begin
        result                                      = (_op_0 / _op_1);
    end
    
    // Assign
    assign result_o                                 = result;

endmodule