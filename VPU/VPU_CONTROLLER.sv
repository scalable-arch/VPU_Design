`include "VPU_PKG.svh"

module VPU_CONTROLLER
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    REQ_IF.dst                              req_if,
    //input   wire                            req_valid_i,
    
    input   wire    [SRAM_R_PORT_CNT-1:0]   opget_done_i,
    output  wire                            req_queue_rden_o,
    //output  wire    [SRAM_R_PORT_CNT-1:0]   opget_reset_cmd_o,
    output  wire                            operand_queue_rden_o,

    input   wire                            wb_done_i,

    output  wire                            reset_cmd_o,
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 3'b000;
    localparam  S_GETOP                     = 3'b001;
    localparam  S_EXEC_1                    = 3'b010;
    localparam  S_EXEC_2                    = 3'b011;
    localparam  S_WB                        = 3'b100;

    logic   [2:0]                           state,  state_n;

    logic                                   reset_cmd;
    logic                                   req_queue_rden;
    logic                                   operand_queue_rden;
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
        end else begin
            state                           <= state_n;
        end
    end
    
    always_comb begin
        state_n                             = state;
    
        reset_cmd                           = 1'b0;
        operand_queue_rden                  = 1'b0;
        req_queue_rden                      = 1'b0;

        case(state)
            S_IDLE: begin
                if(req_if.valid) begin
                    state_n                 = S_GETOP;
                end                            
            end

            S_GETOP: begin
                if(&opget_done_i) begin
                    state_n                 = S_EXEC_1;
                end
            end

            S_EXEC_1: begin
                if(/*vexec_done_i*/) begin
                    state_n                 = S_EXEC_2;
                    operand_queue_rden      = 1'b1;
                end
            end

            S_EXEC_2: begin
                if(/*vexec_done_i*/) begin
                    state_n                 = S_WB;
                    operand_queue_rden      = 1'b1;
                end
            end

            S_WB: begin
                if(wb_done_i) begin
                    state_n                 = S_IDLE;
                    reset_cmd               = 1'b1;
                    req_queue_rden          = 1'b1;
                end
            end
        endcase
    end
    assign  reset_cmd_o                     = reset_cmd;
    assign  req_queue_rden_o                = req_queue_rden;
    assign  operand_queue_rden_o            = operand_queue_rden;
    
endmodule