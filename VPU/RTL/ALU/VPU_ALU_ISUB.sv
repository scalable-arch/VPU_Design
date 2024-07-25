`include "VPU_PKG.svh"
module VPU_ALU_ISUB
#(
    
)
(
    input   wire                            clk,
    input   wire                            rst_n,
    
    //From REQ_IF
    input   [MAX_DELAY_LG2-1:0]             delay_i,

    //From SRC_PORT
    input   [OPCODE_WIDTH-1:0]              op_0,
    input   [OPCODE_WIDTH-1:0]              op_1,
    input   [OPCODE_WIDTH-1:0]              op_2,
    input   [SRAM_R_PORT_CNT-1:0]           op_valid,

    //From VPU_CONTROLLER
    input                                   start_i,

    //To VPU_DST_PORT
    output  [OPCODE_WIDTH-1:0]              result_o,
    output                                  done_o,
);
    import VPU_PKG::*;
    
    logic                                   done;
    logic   [OPCODE_WIDTH-1:0]              result;

    VPU_TIMING_CNTR #(
        .CNTR_WIDTH                         (2)
    ) DELAY_CNTR (
        .clk                                (clk),
        .rst_n                              (rst_n),
        .reset_cmd_i                        (start_i),
        .reset_value_i                      (delay_i),
        //.is_zero_n_o, (),   // one-cycle earlier version
        .is_zero_o                          (done),
    );

    // Operation
    always_comb begin
        _result                             = op_0 - op_1;
        if(op_valid[SRAM_R_PORT_CNT-1]) begin
            result                          = _result - op_2;
        end else begin
            result                          = _result;
        end
    end

    // Assign
    assign result_o                         = result;
    assign done_o                           = done;
endmodule