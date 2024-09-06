`include "/home/sg05060/generic_npu/src/VPU/RTL/Header/VPU_PKG.svh"

module VPU_ALU_SI_MAX
#(
    
)
(
    //input   wire                                    clk,
    //input   wire                                    rst_n,
    
    //From SRC_PORT
    input   signed  [VPU_PKG::OPERAND_WIDTH-1:0]    op_0,
    input   signed  [VPU_PKG::OPERAND_WIDTH-1:0]    op_1,
    input   signed  [VPU_PKG::OPERAND_WIDTH-1:0]    op_2,
    input   [VPU_PKG::SRAM_R_PORT_CNT-1:0]          op_valid,

    //From VPU_CONTROLLER
    input                                           en,

    //To VPU_DST_PORT
    output  signed  [VPU_PKG::OPERAND_WIDTH-1:0]    result_o
);
    import VPU_PKG::*;
    
    logic   signed  [OPERAND_WIDTH-1:0]             result, _result;
    logic   signed  [OPERAND_WIDTH-1:0]             _op_0, _op_1, _op_2;

    //Enable
    always_comb begin
        _op_0                                       = {OPERAND_WIDTH{1'b0}};
        _op_1                                       = {OPERAND_WIDTH{1'b0}};
        _op_2                                       = {OPERAND_WIDTH{1'b0}};
        if(en) begin
            _op_0                                   = op_0;
            _op_1                                   = op_1;
            _op_2                                   = op_2;
        end
    end
    
    // Operation
    always_comb begin
        _result                                     = (_op_0 >= _op_1) ? _op_0 : _op_1;
        result                                      = _result;
        if(op_valid[SRAM_R_PORT_CNT-1]) begin
            result                                  = (_result >= _op_2) ? _result : _op_2;
        end 
    end
    
    // Assign
    assign result_o                                 = result;

endmodule