`include "/home/sg05060/VPU_Design/VPU/RTL/Header/VPU_PKG.svh"

module VPU_FP_DIV
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
    output  [VPU_PKG::OPERAND_WIDTH-1:0]     result_o
);
    localparam  NSIG                        = 7;

    logic   signed [NSIG+2:0]               aSig, bSig, rSig;
    logic   [NSIG+2:0]                      qSig;

    //----------------------------------------------
    // 1. Checks for Zeros
    //----------------------------------------------
    
    //----------------------------------------------
    // 2. Initialize Register and Evaluate the Sign
    //----------------------------------------------
    AC / BR
    Qs = As ^ Bs
    Q = 0
    SC = n - 1
    //----------------------------------------------
    // 3. Align the dividend
    //----------------------------------------------

    //----------------------------------------------
    // 4. Subtract the exponent
    //----------------------------------------------

    //----------------------------------------------
    // 5. Divide the mastissa
    //----------------------------------------------
    always_comb begin
        qSig                                = 0;
        aSig                                = {2'b00,aSigWire};
        bSig                                = {2'b00,bSigWire};
    end

endmodule