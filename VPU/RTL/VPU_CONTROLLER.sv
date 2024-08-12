`include "VPU_PKG.svh"

module VPU_CONTROLLER
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    REQ_IF.dst                              req_if,
    
    // OPGET SubState
    output  wire                            opget_start_o,
    input   wire                            opget_done_i,
    
    output  wire                            operand_queue_rden_o[SRAM_R_PORT_CNT-1:0],

    // Execution SubState
    output  wire                            exec_start_o,
    input   wire                            exec_done_i,

    // WB SubState
    output  wire                            wb_start_o,
    input   wire                            wb_done_i,

);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 3'b000;
    localparam  S_GETOP                     = 3'b001;
    localparam  S_EXEC_1                    = 3'b010;
    localparam  S_EXEC_2                    = 3'b011;
    localparam  S_WB                        = 3'b100;

    logic   [2:0]                           state,  state_n;

    logic                                   ready;
    logic                                   opget_start;
    logic                                   exec_start;
    logic                                   wb_start;
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

        ready                               = 1'b0;
        opget_start                         = 1'b0;
        exec_start                          = 1'b0;
        wb_start                            = 1'b0;
        operand_queue_rden                  = 1'b0;

        case(state)
            S_IDLE: begin
                ready                       = 1'b1;
                if(req_if.valid && ready) begin
                    opget_start             = 1'b1;
                    state_n                 = S_GETOP;
                end                            
            end

            S_GETOP: begin
                if(opget_done_i) begin
                    exec_start              = 1'b1;
                    state_n                 = S_EXEC_1;
                end
            end

            S_EXEC_1: begin
                if(exec_done_i) begin
                    operand_queue_rden      = 1'b1;
                    exec_start              = 1'b1;
                    state_n                 = S_EXEC_2;
                end
            end

            S_EXEC_2: begin
                if(exec_done_i) begin
                    operand_queue_rden      = 1'b1;
                    wb_start                = 1'b1;
                    state_n                 = S_WB;
                end
            end

            S_WB: begin
                if(wb_done_i) begin
                    // response..?          = 1'b1;
                    state_n                 = S_IDLE;
                end
            end
        endcase
    end

    assign  req_if.ready                    = ready;
    assign  opget_start_o                   = opget_start;
    assign  exec_start_o                    = exec_start;
    assign  wb_start_o                      = wb_start;
    
    genvar k;
    generate
        for (k=0; k < SRAM_R_PORT_CNT; k=k+1) begin : PACKING_OPERAND_QUEUE_RDEN
            assign operand_queue_rden_o[k]  = (operand_queue_rden & req_if.rvalid[k]);
        end
    endgenerate

endmodule