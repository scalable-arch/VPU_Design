`include "VPU_PKG.svh"

module VPU_CONTROLLER
#(

)
(
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire                            ctrl_valid_i,
    input   VPU_PKG::vpu_h2d_req_instr_t    instr_latch_i,
    input   wire                            is_sum_i,
    input   wire                            is_reduction_i,
    input   wire [VPU_PKG::SRAM_READ_PORT_CNT-1:0]  operand_rvalid_i,
    input   wire [VPU_PKG::STREAM_ID_WIDTH-1:0]     stream_id_i,
    output  wire                            ctrl_ready_o,
    
    // OPGET SubState
    output  wire                            opget_start_o,
    input   wire                            opget_done_i,
    output  wire    [VPU_PKG::SRC_OPERAND_CNT-1:0]  operand_queue_rden_o,

    // Execution SubState
    output  wire                            exec_start_o,
    input   wire                            exec_done_i,
    // WB SubState
    output  wire                            wb_data_valid_o,
    output  wire                            wb_start_o,
    input   wire                            wb_done_i,

    VPU_RESPONSE_IF.device                  vpu_response_if
);
    import VPU_PKG::*;

    localparam  S_IDLE                      = 2'b00;
    localparam  S_GETOP                     = 2'b01;
    localparam  S_EXEC                      = 2'b10;
    localparam  S_WB                        = 2'b11;

    logic   [1:0]                           state,  state_n;
    logic                                   ready;
    logic                                   opget_start, opget_start_n;
    logic                                   exec_start, exec_start_n;
    logic                                   exec_start_delayed;
    logic                                   exec_done_delayed;
    logic                                   wb_start;
    logic                                   wb_data_valid;
    logic                                   operand_queue_rden, operand_queue_rden_n;
    logic                                   response_valid, response_valid_n;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state                           <= S_IDLE;
            opget_start                     <= 1'b0;
            exec_start                      <= 1'b0;
            exec_start_delayed              <= 1'b0;
            operand_queue_rden              <= 1'b0;
            exec_done_delayed               <= 1'b0;
            response_valid                  <= 1'b0;
        end else begin
            state                           <= state_n;
            opget_start                     <= opget_start_n;
            exec_start                      <= exec_start_n;
            exec_start_delayed              <= exec_start;
            operand_queue_rden              <= operand_queue_rden_n;
            exec_done_delayed               <= exec_done_i;
            response_valid                  <= response_valid_n;
        end
    end
    
    always_comb begin
        state_n                             = state;
        opget_start_n                       = opget_start;
        exec_start_n                        = exec_start;
        operand_queue_rden_n                = operand_queue_rden;
        response_valid_n                    = response_valid;

        ready                               = 1'b0;
        wb_start                            = 1'b0;
        wb_data_valid                       = 1'b0;

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
                    operand_queue_rden_n    = 1'b1;
                    state_n                 = S_EXEC;
                end
            end

            S_EXEC: begin
                exec_start_n                = 1'b0;
                operand_queue_rden_n        = 1'b0;

                if(exec_done_i) begin
                    if(is_reduction_i) begin
                        wb_data_valid               = 1'b1;
                        operand_queue_rden_n        = 1'b1;
                        wb_start                    = 1'b1;
                        state_n                     = S_WB;
                    end else begin
                        if(exec_done_delayed) begin
                            wb_data_valid           = 1'b1;
                            operand_queue_rden_n    = 1'b1;
                            wb_start                = 1'b1;
                            state_n                 = S_WB;
                        end else begin
                            wb_data_valid       = 1'b1;
                        end
                    end
                end
            end

            S_WB: begin
                operand_queue_rden_n        = 1'b0;
                if(wb_done_i) begin
                    response_valid_n        = 1'b1;
                end
                if(vpu_response_if.resp_valid & vpu_response_if.resp_ready) begin
                    response_valid_n        = 1'b0;
                    state_n                 = S_IDLE;
                end
            end
        endcase
    end

    assign  ctrl_ready_o                    = ready;
    assign  opget_start_o                   = opget_start;
    assign  exec_start_o                    = exec_start | exec_start_delayed;
    assign  wb_start_o                      = wb_start;
    assign  wb_data_valid_o                 = wb_data_valid;
    genvar k;
    generate
        for (k=0; k < SRAM_READ_PORT_CNT; k=k+1) begin : PACKING_OPERAND_QUEUE_RDEN
            assign operand_queue_rden_o[k]  = (operand_queue_rden & operand_rvalid_i[k]);
        end
    endgenerate

    assign  vpu_response_if.resp_stream_id  = stream_id_i;
    assign  vpu_response_if.resp_valid      = response_valid;
endmodule