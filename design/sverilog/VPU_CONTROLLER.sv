`include "VPU_PKG.svh"

module VPU_CONTROLLER
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire                            ctrl_valid_i,
    input   VPU_PKG::vpu_instr_decoded_t    instr_decoded_i,
    output  wire                            ctrl_ready_o,
    
    // OPGET SubState
    output  wire                            opget_start_o,
    input   wire                            opget_done_i,
    
    output  wire    [VPU_PKG::SRC_OPERAND_CNT-1:0]   operand_queue_rden_o,

    // Execution SubState
    output  wire                            exec_start_o,
    input   wire                            exec_done_i,

    // WB SubState
    output  wire                            wb_data_valid_o,
    output  wire                            wb_start_o,
    input   wire                            wb_done_i

);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 3'b000;
    localparam  S_GETOP                     = 3'b001;
    localparam  S_EXEC_1                    = 3'b010;
    localparam  S_EXEC_2                    = 3'b011;
    localparam  S_WB                        = 3'b100;

    logic   [2:0]                           state,  state_n;

    logic                                   ready;
    logic                                   opget_start, opget_start_n;
    logic                                   exec_start, exec_start_n;
    logic                                   wb_start;
    logic                                   wb_data_valid;
    logic                                   operand_queue_rden;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
            opget_start                     <= 1'b0;
            exec_start                      <= 1'b0;
        end else begin
            state                           <= state_n;
            opget_start                     <= opget_start_n;
            exec_start                      <= exec_start_n;
        end
    end
    
    always_comb begin
        state_n                             = state;
        opget_start_n                       = opget_start;
        exec_start_n                        = exec_start;

        ready                               = 1'b0;
        wb_start                            = 1'b0;
        wb_data_valid                       = 1'b0;
        operand_queue_rden                  = 1'b0;

        case(state)
            S_IDLE: begin
                ready                       = 1'b1;
                if(ctrl_valid_i && ctrl_ready_o) begin
                    opget_start_n           = 1'b1;
                    state_n                 = S_GETOP;
                end                            
            end

            S_GETOP: begin
                opget_start_n               = 1'b0;
                if(opget_done_i) begin
                    exec_start_n            = 1'b1;
                    state_n                 = S_EXEC_1;
                end
            end

            S_EXEC_1: begin
                exec_start_n                = 1'b0;
                if(exec_done_i) begin
                    if(instr_decoded_i.op_func.op_type == EXEC) begin
                        wb_data_valid       = 1'b1;
                    end
                    operand_queue_rden      = 1'b1;
                    exec_start_n            = 1'b1;
                    state_n                 = S_EXEC_2;
                end
            end

            S_EXEC_2: begin
                exec_start_n                = 1'b0;
                if(exec_done_i) begin
                    wb_data_valid           = 1'b1;
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

    assign  ctrl_ready_o                    = ready;
    assign  opget_start_o                   = opget_start;
    assign  exec_start_o                    = exec_start;
    assign  wb_start_o                      = wb_start;
    assign  wb_data_valid_o                 = wb_data_valid;
    genvar k;
    generate
        for (k=0; k < SRAM_R_PORT_CNT; k=k+1) begin : PACKING_OPERAND_QUEUE_RDEN
            assign operand_queue_rden_o[k]  = (operand_queue_rden & instr_decoded_i.rvalid[k]);
        end
    endgenerate

endmodule